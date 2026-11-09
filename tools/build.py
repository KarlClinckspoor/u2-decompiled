#!/usr/bin/env python3
"""Build ULTIMAII.EXE from src/ with the original tools and compare it with the original.

    python3 tools/build.py [--keep]

Reads src/u2.lnk: one assembly module per line, in link order ("file [; comment]"). Each is
assembled with MASM 3.00 (with a listing), the objects linked with Microsoft LINK 3.05 (MASM 4.0)
into build/u2/ULTIMAII.EXE (map ULTIMAII.MAP). tools/postlink.py then appends the envelope remains
from gamedata/ULTIMAII.EXE, and the file's sha1 is checked against the GOG release.
Exit status 0 when the file is identical.
"""
import hashlib, os, re, shutil, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import dos, postlink

EXE = 'ULTIMAII'
SHA1 = '6efae26cdaedf30426d35cf935b50e5639387cec'    # GOG ULTIMAII.EXE, 37344 bytes


def main():
    src = os.path.join(ROOT, 'src')
    out = os.path.join(ROOT, 'build', 'u2')
    shutil.rmtree(out, ignore_errors=True)
    os.makedirs(out)
    mods = [l.split(';')[0].strip() for l in open(os.path.join(src, 'u2.lnk'))]
    mods = [m for m in mods if m]
    cmds, objs = [], []
    for m in mods:
        stem = os.path.splitext(os.path.basename(m))[0].upper()
        shutil.copy(os.path.join(src, m), os.path.join(out, stem + '.ASM'))
        for f in os.listdir(src):                  # include files
            if f.upper().endswith('.INC'):
                shutil.copy(os.path.join(src, f), os.path.join(out, f.upper()))
        cmds.append('D:\\MASM3\\MASM %s.ASM,%s.OBJ,%s.LST; >> BUILD.LOG' % (stem, stem, stem))
        objs.append(stem)
    open(os.path.join(out, 'LINK.RSP'), 'w', newline='').write(
        '+\r\n'.join(objs) + '\r\n%s\r\n%s/M\r\n;\r\n' % (EXE, EXE))
    cmds.append('D:\\MASM4\\LINK @LINK.RSP >> BUILD.LOG')
    dos.run(out, cmds)

    log = open(os.path.join(out, 'BUILD.LOG'), 'rb').read().decode('latin1').replace('\r', '')
    bad = []
    for l in log.split('\n'):
        m = re.match(r'^\s*(\d+)\s+(\d+)\s*$', l)          # MASM's "warning / severe errors" counts
        if (m and int(m.group(1)) + int(m.group(2))) or re.search(
                r'Error \d|error L|Unresolved|Undefined|more than once', l):
            bad.append(l)
    for o in objs:
        if not os.path.exists(os.path.join(out, o + '.OBJ')):
            bad.append('no object for ' + o)
    built = os.path.join(out, EXE + '.EXE')
    if not os.path.exists(built) or bad:
        print(log)
        print('\n'.join(bad))
        sys.exit(2)

    orig = os.path.join(ROOT, 'gamedata', EXE + '.EXE')
    data, added, ho = postlink.postlink(open(built, 'rb').read(), open(orig, 'rb').read())
    open(built, 'wb').write(data)
    print('postlink: %d envelope bytes appended, entry %04X:%04X' % (added, ho[11], ho[10]))
    h = hashlib.sha1(data).hexdigest()
    print('%s.EXE %d bytes sha1 %s' % (EXE, len(data), h))
    if h == SHA1:
        print('IDENTICAL to the GOG release')
        sys.exit(0)
    print('DIFFERS from the GOG release (%s)' % SHA1)
    sys.exit(subprocess.run([sys.executable, os.path.join(HERE, 'exediff.py'), built, orig]).returncode or 1)


if __name__ == '__main__':
    main()
