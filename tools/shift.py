#!/usr/bin/env python3
"""Relocation test: build with padding inserted in the code and/or the data, then check that the
result is the original with every address moved and nothing else changed.

    python3 tools/shift.py [--code N] [--data M] [--at MODULE] [--out DIR]

N bytes (NOPs) go at the start of MODULE's code (default the first module, after `ORG 100h`:
before the entry point), so code from the module's first address S on moves by N and code
before it stays; M zero bytes go at the start of DATA. Default N=3, M=5 (odd amounts, so a
missed address can't hide behind paragraph alignment). Every original instruction at A must
reappear at A (A < S) or A+N with the same bytes, except operands that are addresses: code
addresses move the same way, data offsets by M, data seen from CS by the data segment's new
start plus M; the startup's DATA segment value and its stack-segment constant follow the new
sizes. Inserting in the middle checks the modules' EXTRN/PUBLIC wiring. The initialised data
must reappear at M with only the pointer words moved. Output in build/shift/ULTIMAII.EXE
(runnable: LINK's header, no envelope).

What this can't see: an address the source still writes as a number keeps its value in both
builds, so it looks like a constant. Run the shifted game to catch those.
"""
import argparse, collections, os, re, struct, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import build, syms, u2an
from u2an import CODE_END, CODE_LAST, DATA_SIZE

TAG = re.compile(r';@([0-9A-F]{4})\s*$')


def pad(byte, n):
    """n bytes as explicit db lines of 16: MASM 4.00 silently drops everything after an
    over-long line, and dies writing a listing of some DUPs."""
    return ['\tdb ' + ','.join([byte] * min(16, n - i)) for i in range(0, n, 16)]


def edit_for(n, m, at):
    def edit(stem, text):
        lines = text.split('\r\n')
        out = []
        code_at = None
        if stem == at and n:
            code_at = next(i for i, l in enumerate(lines) if l.startswith('ASSUME CS:CODE'))
            if lines[code_at + 1].strip().upper() == 'ORG 100H':
                code_at += 1
        for i, l in enumerate(lines):
            out.append(l)
            if i == code_at:
                out.extend(pad('90h', n))
            if l.startswith('D_START ') and m:
                out.extend(pad('0', m))
        return '\r\n'.join(out)
    return edit


def module_lines(stem):
    return open(os.path.join(build.SRC, stem + '.ASM'), 'rb').read().decode('latin1').split('\r\n')


def first_address(stem):
    for l in module_lines(stem):
        t = TAG.search(l)
        if t:
            return int(t.group(1), 16)
    return None


def image(path):
    d = open(path, 'rb').read()
    h = struct.unpack('<14H', d[:28])
    return d[h[4] * 16:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--code', type=int, default=3)
    ap.add_argument('--data', type=int, default=5)
    ap.add_argument('--at', help='module whose code gets the padding (default: the first)')
    ap.add_argument('--out', default=os.path.join(ROOT, 'build', 'shift'))
    a = ap.parse_args()
    N, M = a.code, a.data
    stems = [os.path.splitext(m)[0].upper() for m in build.modules()]
    at = (a.at or stems[0]).upper()
    if at not in stems:
        sys.exit('shift: no module %s' % at)
    S = 0x100 if at == stems[0] else first_address(at)
    if S is None:
        sys.exit('shift: module %s has no code' % at)
    built = build.link(a.out, edit_for(N, M, at))

    def cmove(x):                                       # where original code address x went
        return x + N if x >= S else x
    orig = open(os.path.join(ROOT, 'gamedata', 'ULTIMAII.EXE'), 'rb').read()
    an = u2an.analyse(orig)
    o, s = an.img, image(built)
    dstart = (CODE_LAST + N + 15) // 16 * 16           # new start of DATA (CS offset)
    PD = dstart - CODE_END                              # its move, in bytes
    print('shift: code +%d from %04X (%s), data +%d; DATA now at CS:%04X (+%d)' % (N, S, at, M, dstart, PD))
    if len(s) != dstart + M + DATA_SIZE:
        sys.exit('shift: image is %X bytes, expected %X: the assembler dropped something' % (
            len(s), dstart + M + DATA_SIZE))

    # instructions the source writes with a symbol: each must move when its target moves (a
    # wrong base doesn't show otherwise, it just looks like a constant)
    table = syms.table()
    symbolic = {}                                       # address -> (text, symbols used)
    for stem in stems:
        for l in module_lines(stem):
            t = TAG.search(l)
            code = re.sub(r'^\w+:', '', l.split(';')[0])
            used = [table[w.upper()] for w in syms.IDENT.findall(code) if w.upper() in table]
            if 'CGROUP' in code.upper():
                used.append(None)
            if t and used and not code.strip().lower().startswith('dw'):
                symbolic[int(t.group(1), 16)] = (code.strip(), used)
    moved = collections.Counter()
    bad = []
    changed = set()

    for addr in sorted(an.insn):
        i1 = an.insn[addr]
        na = cmove(addr)
        i2 = next(u2an.md.disasm(s[na:na + 16], na), None)
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
        if addr == 0x105:                    # add ax,STACK_PARA
            moved['stack segment'] += 1
            changed.add(addr)
            continue
        for p1, p2 in zip(u2an.operands(i1), u2an.operands(i2)):
            if p1.type == 'imm':
                if p2.imm == p1.imm:
                    continue
                k = 'code' if u2an.is_branch(i1) and p2.imm == cmove(p1.imm) else None
            elif p1.type == 'mem':
                if (p1.base, p1.index, p1.seg) != (p2.base, p2.index, p2.seg):
                    k = None
                elif p2.disp == p1.disp:
                    continue
                elif p1.seg == 'cs' and p1.disp >= CODE_END:
                    k = 'cs-data' if (p2.disp - p1.disp) & 0xFFFF == PD + M else None
                elif p1.seg == 'cs':
                    k = 'code' if p2.disp == cmove(p1.disp) else None
                elif p1.seg == 'ds':
                    k = 'data' if (p2.disp - p1.disp) & 0xFFFF == M else None
                else:
                    k = None
            else:
                continue
            if k is None:
                bad.append('%04X: %s %s  ->  %s %s' % (addr, i1.mnemonic, i1.op_str, i2.mnemonic, i2.op_str))
            else:
                moved[k] += 1
                changed.add(addr)

    for a2, (text, used) in sorted(symbolic.items()):
        at2 = a2 if a2 in an.insn else a2 - 1       # "db 2Eh" + lea: the lea line is tagged +1
        must = False
        for sym in used:
            if sym is None:                         # cs:CGROUP:...
                must = must or bool(PD + M)
            elif sym.seg == 'C' and sym.addr is not None:
                must = must or bool(N and sym.addr >= S)
            elif sym.seg == 'D' and sym.kind != 'ABS':
                must = must or bool(M)
        if must and at2 not in changed:
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
            w2 = int.from_bytes(s[cmove(x):cmove(x) + 2], 'little')
            if w2 == cmove(w1):
                if w2 != w1:
                    moved['code (table)'] += 1
            else:
                bad.append('table %04X: %04X -> %04X' % (x, w1, w2))
            x += 2
            continue
        if o[x] != s[cmove(x)]:
            bad.append('code data %04X: %02X -> %02X' % (x, o[x], s[cmove(x)]))
        x += 1
    if s[S:S + N] != b'\x90' * N:
        bad.append('code padding not where expected')

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
        if x + 1 < DATA_SIZE and (w2 - w1) & 0xFFFF == M:
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
