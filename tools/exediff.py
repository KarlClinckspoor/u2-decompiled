#!/usr/bin/env python3
"""Compare two MZ executables: header fields, relocation table (set and order), load image.

    python3 tools/exediff.py BUILT.EXE ORIGINAL.EXE

Exit status 0 when the files are identical.
"""
import struct, sys

FIELDS = ['sig', 'last', 'pages', 'nrel', 'hdrpar', 'minalloc', 'maxalloc', 'ss', 'sp', 'csum', 'ip', 'cs',
          'relo', 'ovl']


def load(p):
    d = open(p, 'rb').read()
    h = struct.unpack('<14H', d[:28])
    rel = [struct.unpack('<HH', d[h[12] + 4 * i:h[12] + 4 * i + 4]) for i in range(h[3])]
    return d, h, rel, d[h[4] * 16:]


def main():
    a, b = sys.argv[1], sys.argv[2]
    da, ha, ra, ia = load(a)
    db, hb, rb, ib = load(b)
    if da == db:
        print('IDENTICAL (%d bytes)' % len(da))
        return 0
    for n, x, y in zip(FIELDS, ha, hb):
        if x != y:
            print('header %-8s built %04x  original %04x' % (n, x, y))
    if da[:ha[4] * 16][28:] != db[:hb[4] * 16][28:]:
        if set(ra) != set(rb):
            print('relocations: %d extra, %d missing' % (len(set(ra) - set(rb)), len(set(rb) - set(ra))))
            print('  extra  ', ' '.join('%x:%x' % (s, o) for o, s in sorted(set(ra) - set(rb), key=lambda r: (r[1], r[0]))[:12]))
            print('  missing', ' '.join('%x:%x' % (s, o) for o, s in sorted(set(rb) - set(ra), key=lambda r: (r[1], r[0]))[:12]))
        elif ra != rb:
            print('relocations: same set, different order')
        else:
            print('header padding differs')
    n = min(len(ia), len(ib))
    diffs = [i for i in range(n) if ia[i] != ib[i]]
    if len(ia) != len(ib):
        print('image size: built %x, original %x' % (len(ia), len(ib)))
    if diffs:
        print('image: %d differing bytes, first at %05x' % (len(diffs), diffs[0]))
        runs = []
        for x in diffs:
            if runs and x - runs[-1][1] <= 4:
                runs[-1][1] = x
            else:
                runs.append([x, x])
        for s, e in runs[:20]:
            print('  %05x-%05x  built %s  original %s' % (s, e, ia[s:e + 1][:12].hex(' '), ib[s:e + 1][:12].hex(' ')))
    return 1


if __name__ == '__main__':
    sys.exit(main())
