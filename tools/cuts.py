#!/usr/bin/env python3
"""Where can the code be cut into modules? A map of the code segment for choosing boundaries.

    python3 tools/cuts.py [--all]

An 8-bit relative branch (jcc, short jmp, loop, jcxz) can't reach a label in another module
(MASM has no 8-bit external fixup), so a cut at address C is allowed only if no such branch
spans it. Prints the function starts (call targets) where a cut is allowed, each with its
callers, whether the command table uses it, and the first inline string it prints. --all also
lists allowed cuts that are not function starts.
"""
import collections, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import u2an
from u2an import CODE_LAST


def spans(a):
    """(lo, hi) for every 8-bit relative branch: a cut C with lo < C <= hi splits it."""
    out = []
    for ad, ins in a.insn.items():
        t = u2an.direct_target(ins)
        if t is None:
            continue
        b0 = ins.bytes[0]
        short = b0 == 0xEB or 0x70 <= b0 <= 0x7F or b0 in (0xE0, 0xE1, 0xE2, 0xE3)
        if short:
            out.append((min(ad, t), max(ad, t)))
    return out


def allowed(a):
    """Set of addresses (instruction starts and data bytes) where a cut is allowed."""
    cover = bytearray(CODE_LAST + 1)
    for lo, hi in spans(a):
        for c in range(lo + 1, hi + 1):
            cover[c] = 1
    ok = set()
    for c in range(0x100, CODE_LAST):
        if not cover[c] and a.kind[c] != 2:
            ok.add(c)
    return ok


def main():
    a = u2an.analyse(open(os.path.join(ROOT, 'gamedata', 'ULTIMAII.EXE'), 'rb').read())
    ok = allowed(a)
    callers = collections.defaultdict(list)
    for ad, ins in a.insn.items():
        if ins.mnemonic == 'call':
            t = u2an.direct_target(ins)
            if t is not None:
                callers[t].append(ad)
    table = {int.from_bytes(a.img[t + 2 * i:t + 2 * i + 2], 'little'): chr(65 + i)
             for t, n in u2an.TABLES.items() for i in range(n)}
    starts = sorted(set(callers) | set(table))

    def first_string(f, nxt):
        for ad in sorted(x for x in a.insn if f <= x < nxt):
            ins = a.insn[ad]
            if ins.mnemonic == 'call' and u2an.direct_target(ins) == 0x4FDF:
                s = a.img[ad + 3:a.img.index(b'\0', ad + 3)]
                txt = bytes(c & 0x7F for c in s).decode('latin1')
                txt = ''.join(c if ' ' <= c < '\x7f' else ' ' for c in txt).strip()
                if txt:
                    return txt[:40]
        return ''
    for i, f in enumerate(starts):
        nxt = starts[i + 1] if i + 1 < len(starts) else CODE_LAST
        mark = 'cut ok' if f in ok else '      '
        cmd = 'cmd ' + table[f] if f in table else '     '
        print('%04X %s %s  %2d callers  %s' % (f, mark, cmd, len(callers[f]), first_string(f, nxt)))
    if '--all' in sys.argv:
        prev = None
        runs = []
        for c in sorted(ok):
            if prev is not None and c == prev + 1:
                runs[-1][1] = c
            else:
                runs.append([c, c])
            prev = c
        print('\nallowed cut ranges:')
        for s, e in runs:
            print('  %04X-%04X' % (s, e))


if __name__ == '__main__':
    main()
