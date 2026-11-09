#!/usr/bin/env python3
"""Symbol table of the source in src/: every name, where it is defined and what address it stands
for in the original, worked out from the source itself (so it survives renaming).

    python3 tools/syms.py                 list all symbols: kind, segment, address, module
    python3 tools/syms.py NAME|ADDR ...   look up names or original addresses (hex: 4FDF, D:0472)
    python3 tools/syms.py --refs NAME     every line that uses NAME (module:line: text)

Code labels get the ;@ address of their line (or of the next tagged line, for a label on a line
of its own); data labels get their offset in DATA, counted from D_START through the db/dw lines.
As a module: table() -> {NAME_UPPER: Sym}, refs(name) -> [(module, lineno, text)].
"""
import collections, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, 'src')

Sym = collections.namedtuple('Sym', 'name kind seg addr module lineno')
SYMDEF = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)(:|\s+label\s+(byte|word)\b|\s+equ\s+(.*))', re.I)
TAG = re.compile(r';@([0-9A-F]{4})\s*$')
IDENT = re.compile(r'\b[A-Za-z_][A-Za-z0-9_]*\b')


def modules():
    mods = [l.split(';')[0].strip() for l in open(os.path.join(SRC, 'u2.lnk'))]
    return [m for m in mods if m]


def read(module):
    return open(os.path.join(SRC, module), 'rb').read().decode('latin1').split('\r\n')


def count_items(s):
    """Number of items in a db/dw operand list (handles n DUP (x))."""
    n = 0
    for item in s.split(','):
        m = re.match(r'\s*(\d+)\s+dup\b', item, re.I)
        n += int(m.group(1)) if m else 1
    return n


def table():
    syms = {}
    for mod in modules():
        lines = read(mod)
        seg = None
        off = None
        pending = []                     # code labels waiting for the next tagged line
        for i, l in enumerate(lines):
            code = l.split(';')[0]
            s = code.strip()
            u = s.upper()
            if u.startswith('DATA SEGMENT'):
                seg, off = 'D', None
                continue
            if u.startswith('CODE SEGMENT'):
                seg = 'C'
                continue
            if u in ('DATA ENDS', 'CODE ENDS'):
                seg = None
                continue
            d = SYMDEF.match(l)
            if d:
                name = d.group(1)
                if d.group(2) == ':':
                    kind = 'NEAR'
                elif d.group(3):
                    kind = d.group(3).upper()
                else:
                    kind = 'ALIAS' if re.search(r'\bptr\b', d.group(4), re.I) else 'ABS'
                addr = None
                if seg == 'D':
                    if name.upper() == 'D_START':
                        off = 0
                    if kind == 'ALIAS':
                        m = re.search(r'ptr\s+([A-Za-z_]\w*)\s*([+-]\s*\d+)?', d.group(4), re.I)
                        base = syms.get(m.group(1).upper()) if m else None
                        if base and base.addr is not None:
                            addr = base.addr + int((m.group(2) or '0').replace(' ', ''))
                    elif kind != 'ABS':
                        addr = off
                sym = Sym(name, kind, seg, addr, mod, i + 1)
                syms[name.upper()] = sym
                if seg == 'C' and kind in ('NEAR', 'BYTE', 'WORD'):
                    pending.append(name.upper())
                code = code[len(d.group(0)):] if d.group(2) == ':' else ''
            if seg == 'C':
                t = TAG.search(l)
                if t and pending:
                    a = int(t.group(1), 16)
                    for p in pending:
                        syms[p] = syms[p]._replace(addr=a)
                    pending = []
            elif seg == 'D' and off is not None:
                m = re.match(r'\s*(db|dw)\s+(.*)', code, re.I)
                if m:
                    off += count_items(m.group(2)) * (1 if m.group(1).lower() == 'db' else 2)
    return syms


def refs(name):
    out = []
    w = re.compile(r'\b%s\b' % re.escape(name), re.I)
    for mod in modules():
        for i, l in enumerate(read(mod)):
            if w.search(l.split(';')[0]):
                out.append((mod, i + 1, l.strip()))
    return out


def main():
    args = sys.argv[1:]
    t = table()
    if args and args[0] == '--refs':
        for name in args[1:]:
            for mod, n, text in refs(name):
                print('%s:%d: %s' % (mod, n, text))
        return
    if not args:
        for s in sorted(t.values(), key=lambda s: (s.seg or 'Z', s.addr if s.addr is not None else -1)):
            print('%-31s %-5s %s:%s  %s:%d' % (s.name, s.kind, s.seg or '-',
                                              '%04X' % s.addr if s.addr is not None else '----',
                                              s.module, s.lineno))
        return
    for q in args:
        m = re.match(r'^(?:([CD]):)?([0-9A-Fa-f]{1,4})$', q)
        hits = []
        if q.upper() in t:
            hits = [t[q.upper()]]
        if m and not hits:
            seg, a = m.group(1), int(m.group(2), 16)
            hits = [s for s in t.values() if s.addr == a and (seg is None or s.seg == seg.upper())]
        if not hits:
            print('%s: no such symbol' % q)
        for s in hits:
            print('%-31s %-5s %s:%s  %s:%d' % (s.name, s.kind, s.seg,
                                              '%04X' % s.addr if s.addr is not None else '----',
                                              s.module, s.lineno))


if __name__ == '__main__':
    main()
