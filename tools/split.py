#!/usr/bin/env python3
"""Split the single-module source into modules: one per subsystem plus one for the data.

    python3 tools/split.py U2.ASM [--out DIR]

Works on the text of a single-module source as gen.py lays it out, not on the executable, so
edits made by hand survive. src/ was made with
    python3 tools/gen.py gamedata/ULTIMAII.EXE build/U2.ASM tools/U2.force
    python3 tools/split.py build/U2.ASM
(src/ has been edited since: names and comments).

Code lines go to the module whose range holds their ;@ address (lines without a tag, such as labels and ASSUMEs, go with the next tagged line); a db line that
straddles a boundary is cut in two. Every symbol a module uses but doesn't define becomes an
EXTRN there (NEAR for `X:` labels, BYTE for `X label byte`, ABS for absolute equates) and a
PUBLIC where it is defined; an alias equate (`X equ byte ptr Y+1`) is copied into the modules
that use it instead. Writes DIR/<MODULE>.ASM (CRLF) and DIR/u2.lnk; DIR defaults to src/.

A boundary must not split an 8-bit branch (MASM can't make an 8-bit reference to an external
label): every cut is checked with tools/cuts.py's rule first.
"""
import argparse, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

# (module, first address, what it holds); each runs to the next one's start. Data: U2DATA.
MODULES = [
    ('START',   0x0100, 'startup, title screen and demonstration, delay loops'),
    ('MAIN',    0x0730, 'command jump table (A-Z), game start, the outdoor main loop and movement'),
    ('EVENTS',  0x0E70, 'monster attacks and spells, darkness and torches, random events'),
    ('SHOPS',   0x154E, 'towns: pub (tips), temple, oracle, armour and weapon shops, transport'),
    ('INPUT',   0x2028, 'number and money entry, "illegal command", monster movement'),
    ('LOAD',    0x2290, 'loading the map, monster, talk and player files'),
    ('MOVE',    0x2362, 'moving (pass, north/south/east/west), force fields, saving the player'),
    ('DUNGEON', 0x26F9, 'the dungeon and tower loop: advance, turn, retreat, traps'),
    ('CMDAL',   0x2B65, 'commands A-L (attack, board, cast, descend, enter, fire, get, ...)'),
    ('CMDMZ',   0x3B92, 'commands M-Z (magic, negate, offer, pass, quit, ready, steal, ...); status'),
    ('SCREEN',  0x48CD, 'video tables (CGA segments, masks), clearing, tiles and pixels'),
    ('TEXTIO',  0x4C60, 'terrain names; keyboard, text output, numbers, random numbers, file I/O'),
    ('CHARGEN', 0x5400, 'character generation'),
    ('MAPVIEW', 0x5AB1, 'drawing the outdoor and town map window'),
    ('SOUND',   0x5C90, 'PC speaker sounds'),
    ('VIEW3D',  0x6000, 'the 3D dungeon and tower view, line drawing'),
    ('SPACE',   0x6999, 'space flight: fuel, hyperwarp, planets'),
    ('ENDGAME', 0x7242, 'the end of Minax and the end of the game'),
]
DATA_MODULE = ('U2DATA', 'the data segment: variables, tables, tile bitmaps')

SYMDEF = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)(:|\s+label\s+(byte|word)\b|\s+equ\s+(.*))', re.I)
IDENT = re.compile(r'\b[A-Za-z_][A-Za-z0-9_]*\b')
TAG = re.compile(r';@([0-9A-F]{4})\s*$')


def code_part(l):
    return l.split(';')[0]


def split_db(line, at, cut):
    """Cut a tagged 'db' line at address cut: two lines."""
    m = re.match(r'^(\s*db\s+)([^;]*?)(\s*;@([0-9A-F]{4}))\s*$', line)
    if not m:
        raise SystemExit('split: a boundary at %04X falls inside a line that is not a db: %s' % (cut, line))
    items = [x.strip() for x in m.group(2).split(',')]
    k = cut - at
    return ('\tdb ' + ','.join(items[:k]) + '\t;@%04X' % at,
            '\tdb ' + ','.join(items[k:]) + '\t;@%04X' % cut)


def db_len(line):
    m = re.match(r'^\s*db\s+([^;]*)', line)
    return len(m.group(1).split(',')) if m else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('--out', default=os.path.join(ROOT, 'src'))
    a = ap.parse_args()
    lines = open(a.src, 'rb').read().decode('latin1').split('\r\n')
    if lines and lines[-1] == '':
        lines.pop()

    # the cuts must not split short branches
    import cuts, u2an
    an = u2an.analyse(open(os.path.join(ROOT, 'gamedata', 'ULTIMAII.EXE'), 'rb').read())
    ok = cuts.allowed(an)
    for name, start, _ in MODULES[1:]:
        if start not in ok:
            raise SystemExit('split: %s at %04X: an 8-bit branch crosses this address' % (name, start))

    # find the sections
    i_data = lines.index('DATA SEGMENT PARA PUBLIC')
    i_dend = lines.index('DATA ENDS', i_data)
    i_code = next(i for i in range(i_dend, len(lines)) if lines[i].startswith('CODE SEGMENT'))
    i_cend = max(i for i, l in enumerate(lines) if l.strip() == 'CODE ENDS')
    i_org = lines.index('ORG 100h', i_code)
    data_lines = lines[i_data + 1:i_dend]
    code_lines = lines[i_org + 1:i_cend]
    end_line = lines[i_cend + 1]
    assert end_line.startswith('END')

    # code lines -> modules (cut db lines that straddle a boundary)
    starts = [s for _, s, _ in MODULES]
    names = [n for n, _, _ in MODULES]

    def module_of(ad):
        k = 0
        for j, s in enumerate(starts):
            if ad >= s:
                k = j
        return k
    body = {n: [] for n in names}
    pending = []
    for l in code_lines:
        t = TAG.search(l)
        if not t:
            pending.append(l)
            continue
        ad = int(t.group(1), 16)
        n = db_len(l)
        parts = [(ad, l)]
        if n:
            for s in starts:
                if ad < s < ad + n:
                    first, second = split_db(parts[-1][1], parts[-1][0], s)
                    parts[-1] = (parts[-1][0], first)
                    parts.append((s, second))
        for k, (pad, pl) in enumerate(parts):
            m = names[module_of(pad)]
            if k == 0:
                body[m].extend(pending)
                pending = []
            body[m].append(pl)
    assert not pending, pending

    mods = names + [DATA_MODULE[0]]
    body[DATA_MODULE[0]] = data_lines

    # symbols
    defs = {}        # name -> (module, kind, text of line)
    for m in mods:
        for l in body[m]:
            d = SYMDEF.match(l)
            if d:
                sym = d.group(1)
                if d.group(2) == ':':
                    kind = 'NEAR'
                elif d.group(3):
                    kind = d.group(3).upper()
                else:
                    kind = 'ALIAS' if re.search(r'\bptr\b', d.group(4), re.I) else 'ABS'
                assert sym not in defs, sym
                defs[sym] = (m, kind, l)
    used = {m: set() for m in mods}
    for m in mods:
        for l in body[m]:
            c = code_part(l)
            d = SYMDEF.match(l)
            if d and d.group(2) == ':':
                c = c[len(d.group(0)):]
            elif d:
                c = d.group(4) or ''
            for w in IDENT.findall(c):
                if w in defs and defs[w][0] != m:
                    used[m].add(w)
    # aliases are copied: what they refer to is needed instead
    copies = {m: [] for m in mods}
    for m in mods:
        for w in sorted(used[m]):
            if defs[w][1] == 'ALIAS':
                copies[m].append(defs[w][2].split(';')[0].rstrip())
                for v in IDENT.findall(defs[w][2].split('equ', 1)[1]):
                    if v in defs and defs[v][0] != m:
                        used[m].add(v)
        used[m] = {w for w in used[m] if defs[w][1] != 'ALIAS'}
    public = {m: set() for m in mods}
    for m in mods:
        for w in used[m]:
            public[defs[w][0]].add(w)

    def decl(word, syms, typed):
        out = []
        syms = sorted(syms)
        for k in range(0, len(syms), 6):
            chunk = syms[k:k + 6]
            out.append('\t%s %s' % (word, ', '.join('%s:%s' % (s, defs[s][1]) if typed else s for s in chunk)))
        return out

    desc = {n: d for n, _, d in MODULES}
    desc[DATA_MODULE[0]] = DATA_MODULE[1]
    rng = {}
    for j, (n, s, _) in enumerate(MODULES):
        e = MODULES[j + 1][1] if j + 1 < len(MODULES) else 0x740B
        rng[n] = '%04X-%04X' % (s, e)
    os.makedirs(a.out, exist_ok=True)
    for m in mods:
        ext_data = {w for w in used[m] if defs[w][0] == DATA_MODULE[0]}
        ext_code = used[m] - ext_data
        out = ['; %s.ASM: %s.' % (m, desc[m]),
               '; Part of ULTIMAII.EXE (src/u2.lnk lists the modules in link order); %s.'
               % ('original addresses ' + rng[m] if m in rng else 'DATA segment, original image 7410-8AC0')]
        out += ['CODE SEGMENT BYTE PUBLIC', 'CODE ENDS', 'DATA SEGMENT PARA PUBLIC']
        out += decl('EXTRN', ext_data, True)
        if m == DATA_MODULE[0]:
            out += decl('PUBLIC', public[m], False)
            out += body[m]
        out += ['DATA ENDS', 'CGROUP GROUP CODE, DATA\t; for the cs: reads of DATA']
        out += copies[m]
        if m != DATA_MODULE[0]:
            out += ['', 'CODE SEGMENT BYTE PUBLIC']
            out += decl('EXTRN', ext_code, True)
            out += decl('PUBLIC', public[m], False)
            out += ['ASSUME CS:CODE, DS:DATA']
            if m == names[0]:
                out += ['ORG 100h']
            out += body[m]
            out += ['CODE ENDS']
        out += [end_line if m == names[0] else 'END']
        open(os.path.join(a.out, m + '.ASM'), 'wb').write(('\r\n'.join(out) + '\r\n').encode('latin1'))
        print('%-8s %4d lines, %3d extern, %3d public' % (m, len(out), len(used[m]), len(public[m])))
    with open(os.path.join(a.out, 'u2.lnk'), 'w', newline='') as f:
        f.write('; ULTIMAII.EXE link order (tools/build.py): one module per line\r\n')
        for m in mods:
            f.write('%s.ASM\t; %s\r\n' % (m, desc[m]))


if __name__ == '__main__':
    main()
