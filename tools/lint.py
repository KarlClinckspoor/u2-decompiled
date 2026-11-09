#!/usr/bin/env python3
"""Check (and fix line ends of) the modules in src/.

    python3 tools/lint.py [MODULE ...] [--code-unchanged REV]

For each module (default: all in src/u2.lnk): rewrites the file with CRLF line ends (MASM needs
them; an editor may have inserted bare LFs), then checks that no line is longer than 120
characters and that a `;@ADDR` tag is only ever the last thing on its line, once.
--code-unchanged REV also checks that the code is the same as in git revision REV: the
sequence of non-empty code parts (each line up to its first `;`, whitespace normalised) must be
equal, so only comments and blank lines differ. Exit status 1 on any problem.
"""
import os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import syms


def code_seq(text):
    out = []
    for l in text.replace('\r\n', '\n').split('\n'):
        c = ' '.join(l.split(';')[0].split())
        if c:
            out.append(c)
    return out


def main():
    args = sys.argv[1:]
    rev = None
    if '--code-unchanged' in args:
        k = args.index('--code-unchanged')
        rev = args[k + 1]
        del args[k:k + 2]
    mods = [m if m.upper().endswith('.ASM') else m.upper() + '.ASM' for m in args] or syms.modules()
    bad = 0
    for m in mods:
        path = os.path.join(syms.SRC, m)
        raw = open(path, 'rb').read()
        text = raw.decode('latin1').replace('\r\n', '\n').replace('\r', '\n')
        lines = text.split('\n')
        if lines and lines[-1] == '':
            lines.pop()
        fixed = ('\r\n'.join(lines) + '\r\n').encode('latin1')
        if fixed != raw:
            open(path, 'wb').write(fixed)
            print('%s: line ends normalised to CRLF' % m)
        for i, l in enumerate(lines, 1):
            if len(l.expandtabs(8)) > 120:
                print('%s:%d: longer than 120 characters' % (m, i))
                bad += 1
            n = l.count(';@')
            if n > 1 or (n == 1 and not re.search(r';@[0-9A-F]{4}\s*$', l)):
                print('%s:%d: ;@ tag not alone at the end of the line' % (m, i))
                bad += 1
        if rev:
            try:
                old = subprocess.run(['git', 'show', '%s:src/%s' % (rev, m)], cwd=ROOT, check=True,
                                     capture_output=True).stdout.decode('latin1')
            except subprocess.CalledProcessError:
                print('%s: not in %s' % (m, rev))
                bad += 1
                continue
            a, b = code_seq(old), code_seq(fixed.decode('latin1'))
            if a != b:
                k = next((j for j in range(min(len(a), len(b))) if a[j] != b[j]), min(len(a), len(b)))
                print('%s: code differs from %s at code line %d: %r -> %r' % (
                    m, rev, k + 1, a[k] if k < len(a) else None, b[k] if k < len(b) else None))
                bad += 1
    if bad:
        sys.exit('lint: %d problems' % bad)
    print('lint: OK (%d modules)' % len(mods))


if __name__ == '__main__':
    main()
