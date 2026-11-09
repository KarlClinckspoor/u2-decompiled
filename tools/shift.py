#!/usr/bin/env python3
"""Relocation test: build with padding inserted at the start of the code and/or the data, then
check that the result is the original with every address moved and nothing else changed.

    python3 tools/shift.py [--code N] [--data M] [--out DIR]

N bytes (NOPs) go after `ORG 100h`, before the entry point; M zero bytes go at the start of
DATA. Default N=3, M=5 (odd amounts, so a missed address can't hide behind paragraph
alignment). Every original instruction at A must reappear at A+N with the same bytes, except
operands that are addresses: code addresses move by N, data offsets by M, data seen from CS by
the data segment's new start plus M; the startup's DATA segment value and its stack-segment
constant follow the new sizes. The initialised data must reappear at M with only the pointer
words moved. Output in build/shift/ULTIMAII.EXE (runnable: LINK's header, no envelope).

What this can't see: an address the source still writes as a number keeps its value in both
builds, so it looks like a constant. Run the shifted game to catch those.
"""
import argparse, collections, os, re, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import build, u2an
from capstone import x86
from u2an import CODE_END, CODE_LAST, DATA_SIZE


def pad(byte, n):
    """n bytes as explicit db lines of 16: MASM 4.00 silently drops everything after an
    over-long line, and dies writing a listing of some DUPs."""
    return ['\tdb ' + ','.join([byte] * min(16, n - i)) for i in range(0, n, 16)]


def edit_for(n, m):
    def edit(stem, text):
        lines = text.split('\r\n')
        out = []
        for l in lines:
            out.append(l)
            if l.strip().upper() == 'ORG 100H' and n:
                out.extend(pad('90h', n))
            if l.startswith('D_START ') and m:
                out.extend(pad('0', m))
        return '\r\n'.join(out)
    return edit


def image(path):
    d = open(path, 'rb').read()
    h = struct.unpack('<14H', d[:28])
    return d[h[4] * 16:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--code', type=int, default=3)
    ap.add_argument('--data', type=int, default=5)
    ap.add_argument('--out', default=os.path.join(ROOT, 'build', 'shift'))
    a = ap.parse_args()
    N, M = a.code, a.data
    built = build.link(a.out, edit_for(N, M))
    orig = open(os.path.join(ROOT, 'gamedata', 'ULTIMAII.EXE'), 'rb').read()
    an = u2an.analyse(orig)
    o, s = an.img, image(built)
    dstart = (CODE_LAST + N + 15) // 16 * 16           # new start of DATA (CS offset)
    PD = dstart - CODE_END                              # its move, in bytes
    exp = {'code': N, 'data': M, 'cs-data': PD + M}
    print('shift: code +%d, data +%d; DATA now at CS:%04X (+%d)' % (N, M, dstart, PD))
    if len(s) != dstart + M + DATA_SIZE:
        sys.exit('shift: image is %X bytes, expected %X: the assembler dropped something' % (
            len(s), dstart + M + DATA_SIZE))

    # instructions the source writes with a symbol: each must move (a wrong base doesn't show
    # otherwise, it just looks like a constant)
    symbolic = {}
    for m in build.modules():
        for l in open(os.path.join(build.SRC, m), 'rb').read().decode('latin1').split('\r\n'):
            t = re.search(r';@([0-9A-F]{4})\s*$', l)
            code = l.split(';')[0]
            code = re.sub(r'^\w+:', '', code)
            if t and re.search(r'\b(L[0-9A-F]{4}|D_[0-9A-F]{4}|D_END|D_START|C_DATA)\b', code) \
                    and not code.strip().startswith('dw'):
                symbolic[int(t.group(1), 16)] = code.strip()
    moved = collections.Counter()
    bad = []
    changed = set()

    def classify(d, allowed):
        for k in allowed:
            if (d - exp[k]) & 0xFFFF == 0:
                return k
        return None

    for addr in sorted(an.insn):
        i1 = an.insn[addr]
        i2 = next(u2an.md.disasm(s[addr + N:addr + N + 16], addr + N), None)
        if i2 is None or i2.size != i1.size or i2.mnemonic != i1.mnemonic:
            bad.append('%04X: %s %s  ->  %s' % (addr, i1.mnemonic, i1.op_str,
                                                 i2 and (i2.mnemonic + ' ' + i2.op_str)))
            continue
        if i1.bytes == i2.bytes and not u2an.is_branch(i1):
            continue
        if addr == 0x100:                    # mov ax,DATA: segment value (relocated by DOS)
            moved['segment'] += 1
            changed.add(addr)
            continue
        if addr == 0x105:                    # add ax,(D_END-D_0000+...)/16
            moved['stack segment'] += 1
            changed.add(addr)
            continue
        for p1, p2 in zip(u2an.operands(i1), u2an.operands(i2)):
            if p1.type == 'imm':
                d = (p2.imm - p1.imm) & 0xFFFF
                if d == 0:
                    continue
                k = classify(d, ['code']) if u2an.is_branch(i1) else None
            elif p1.type == 'mem':
                if (p1.base, p1.index, p1.seg) != (p2.base, p2.index, p2.seg):
                    k = None
                else:
                    d = (p2.disp - p1.disp) & 0xFFFF
                    if d == 0:
                        continue
                    if p1.seg == 'cs':
                        k = classify(d, ['cs-data'] if p1.disp >= CODE_END else ['code'])
                    elif p1.seg == 'ds':
                        k = classify(d, ['data'])
                    else:
                        k = None
            else:
                continue
            if k is None:
                bad.append('%04X: %s %s  ->  %s %s' % (addr, i1.mnemonic, i1.op_str, i2.mnemonic, i2.op_str))
            else:
                moved[k] += 1
                changed.add(addr)

    for a2, text in sorted(symbolic.items()):
        at = a2 if a2 in an.insn else a2 - 1        # "db 2Eh" + lea: the lea line is tagged +1
        must = (N and re.search(r'L[0-9A-F]{4}', text)) or (M and re.search(r'D_', text)) or (
            (PD + M) and 'C_DATA' in text)
        if must and at not in changed:
            bad.append('%04X: symbolic operand did not move: %s' % (a2, text))
    moved['(symbolic lines)'] = len(symbolic)

    # code bytes that are not instructions: inline strings, tables
    tables = {t + 2 * i for t, n in u2an.TABLES.items() for i in range(n)}
    x = 0x100
    while x < CODE_LAST:
        if an.kind[x] in (1, 2):
            x += 1
            continue
        if x in tables:
            w1 = int.from_bytes(o[x:x + 2], 'little')
            w2 = int.from_bytes(s[x + N:x + N + 2], 'little')
            if (w2 - w1) & 0xFFFF == N:
                moved['code (table)'] += 1
            else:
                bad.append('table %04X: %04X -> %04X' % (x, w1, w2))
            x += 2
            continue
        if o[x] != s[x + N]:
            bad.append('code data %04X: %02X -> %02X' % (x, o[x], s[x + N]))
        x += 1

    # initialised data
    od = o[CODE_END:CODE_END + DATA_SIZE]
    sd = s[dstart + M:dstart + M + DATA_SIZE]
    x = 0
    while x < DATA_SIZE:
        if od[x] == sd[x]:
            x += 1
            continue
        w1 = int.from_bytes(od[x:x + 2], 'little')
        w2 = int.from_bytes(sd[x:x + 2], 'little')
        if x + 1 < DATA_SIZE and (w2 - w1) & 0xFFFF == M and od[x + 1] != sd[x + 1] or (
                (w2 - w1) & 0xFFFF == M and x + 1 < DATA_SIZE):
            moved['data (pointer)'] += 1
            x += 2
            continue
        bad.append('data %04X: %02X -> %02X' % (x, od[x], sd[x]))
        x += 1
    if s[dstart:dstart + M] != bytes(M):
        bad.append('data padding not zero')

    for k, v in sorted(moved.items()):
        print('  moved %-16s %d' % (k, v))
    if bad:
        print('UNEXPECTED differences: %d' % len(bad))
        for b in bad[:40]:
            print('  ' + b)
        sys.exit(1)
    print('OK: only addresses moved. Shifted EXE: %s' % built)


if __name__ == '__main__':
    main()
