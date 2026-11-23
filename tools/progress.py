#!/usr/bin/env python3
"""progress.py: progress card (docs/progress.svg) and numbers (docs/progress.json).

U2 is hand-written assembly: there is no compiler output to match, and the assembly in src/
already rebuilds the EXE byte for byte (tools/build.py). What is left to "decompile" is the
reading of each routine as C (c/, a reading aid, not byte-matching), so one tile is one routine
of src/ (the labels under a ;---- header, as tools/ccheck.py lists them), in link order and then
address order, and its status is:

  matched  the routine has a C reading: an `/* asm: NAME @ADDR` anchor in c/ (tools/ccheck.py
           checks the anchors, texts and calls; run it for the check, this script only counts)
  attempt  reserved (a draft that is not anchored yet)
  open     the routine has no C reading
  aside    set aside: not a routine to read (dead code of the 1983 build, padding): none counted

The percentage is matched / (matched + attempt + open).

    python3 tools/progress.py            # writes docs/progress.svg and docs/progress.json
    python3 tools/progress.py --check    # exit 1 if the committed files are stale
"""
import argparse, glob, json, os, sys
from html import escape

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import ccheck, syms  # noqa: E402

NAME = 'u2-decompiled'
UNIT = 'routines'
CAPTION = 'Function map: 1 routine per tile, in link order (src/u2.lnk), then by address'
COLORS = dict(matched='#2a8c3c', attempt='#b8860b', open='#64748b', aside='#3b5b8a')
HEADLINE = 'routines with a C reading'
LABELS = dict(matched='C reading', attempt='Attempt', open='Open', aside='Aside')


def read(path):
    with open(path, encoding='utf-8', newline='') as f:
        return f.read().replace('\r\n', '\n')


def anchored():
    """Upper-case names of the routines with a C reading (aliases included)."""
    table = syms.table()
    names = set()
    for path in sorted(glob.glob(os.path.join(ROOT, 'c', '*.c'))):
        for m in ccheck.ANCHOR.finditer(read(path)):
            names.add(m.group(1).upper())
            sym = table.get(m.group(1).upper())
            if sym:                       # `also: @ADDR`: other labels of the same routine
                for addr in ccheck.parse_options(m.group(3))['also']:
                    other = ccheck.label_at(table, sym.module, addr)
                    if other:
                        names.add(other.name.upper())
    return names


def classify():
    table = syms.table()
    done = anchored()
    aliased = {k.upper() for k in ccheck.ALIASES}
    funcs = []
    for mod in syms.modules():
        rs = ccheck.routines(syms.read(mod)) or []
        rows = []
        for r in rs:
            s = table.get(r.upper())
            addr = s.addr if s and s.addr is not None else 0
            st = 'matched' if r.upper() in done or r.upper() in aliased else 'open'
            rows.append((addr, r, st, mod))
        funcs += sorted(rows)
    return funcs


def summary(rows):
    c = {k: 0 for k in COLORS}
    for r in rows:
        c[r['status']] += 1
    total = c['matched'] + c['attempt'] + c['open']
    return dict(c, total=total, percent=round(100.0 * c['matched'] / total, 1) if total else 100.0)


def svg(flat):
    s = summary(flat)
    n = len(flat)
    W, PAD = 840, 20
    inner = W - 2 * PAD
    cols = 1
    for cols_try in range(20, 200):      # square tiles of at least 11 px
        if inner / cols_try < 11:
            break
        cols = cols_try
    cell = inner / cols
    top = 160
    H = int(top + -(-n // cols) * cell + 22)
    out = []
    a = out.append
    a('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" '
      'font-family="Roboto, Helvetica, Arial, sans-serif" role="img" aria-label="%s">'
      % (W, H, W, H, escape('Decompilation progress: %d of %d %s' % (s['matched'], s['total'], HEADLINE))))
    a('<rect width="%d" height="%d" rx="14" fill="#0f172a"/>' % (W, H))
    a('<text x="%d" y="38" font-size="21" fill="#ffffff">Decompilation progress</text>' % PAD)
    a('<text x="%d" y="38" font-size="15" fill="#ffffff" text-anchor="end">%s</text>' % (W - PAD, escape(NAME)))
    a('<text x="%d" y="62" font-size="15" fill="#e5e7eb">%s / %s %s (%.1f%%)</text>'
      % (PAD, format(s['matched'], ','), format(s['total'], ','), HEADLINE, s['percent']))
    a('<rect x="%d" y="74" width="%d" height="18" rx="5" fill="#334155"/>' % (PAD, inner))
    if s['total']:
        a('<rect x="%d" y="74" width="%.2f" height="18" rx="5" fill="%s"/>'
          % (PAD, inner * s['matched'] / s['total'], COLORS['matched']))
    for x, k in zip([PAD, 232, 430, 628], ['matched', 'attempt', 'open', 'aside']):
        a('<rect x="%d" y="104" width="10" height="10" fill="%s"/>' % (x, COLORS[k]))
        a('<text x="%d" y="113" font-size="12" fill="#e5e7eb">%s: %s</text>' % (x + 14, LABELS[k], format(s[k], ',')))
    a('<text x="%d" y="140" font-size="11" fill="#e5e7eb">%s</text>' % (PAD, escape(CAPTION)))
    for i, r in enumerate(flat):
        x, y = PAD + (i % cols) * cell, top + (i // cols) * cell
        a('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s" stroke="#0f172a" stroke-width="1">'
          '<title>%s %04X %s (%s)</title></rect>'
          % (x, y, cell, cell, COLORS[r['status']], r['module'], r['addr'], escape(r['name']), r['status']))
    a('</svg>')
    return '\n'.join(out) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    flat = [dict(addr=a, name=n, status=s, module=m) for a, n, s, m in classify()]
    mods = {}
    for r in flat:
        mods.setdefault(r['module'], []).append(r)
    result = {m: summary(rs) for m, rs in mods.items()}
    result['all'] = summary(flat)
    js = json.dumps(result, indent=1) + '\n'
    paths = {os.path.join(ROOT, 'docs', 'progress.json'): js, os.path.join(ROOT, 'docs', 'progress.svg'): svg(flat)}
    if args.check:
        stale = [p for p, t in paths.items() if not os.path.exists(p) or read(p) != t]
        if stale:
            print('stale:', *stale)
            sys.exit(1)
        return
    for p, t in paths.items():
        with open(p, 'w', encoding='utf-8', newline='\n') as f:
            f.write(t)
    for m, r in result.items():
        print('%-12s matched %3d  open %2d  -> %.1f%% of %d' % (m, r['matched'], r['open'], r['percent'], r['total']))


if __name__ == '__main__':
    main()
