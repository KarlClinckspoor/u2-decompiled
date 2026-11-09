#!/usr/bin/env python3
"""Unpack the assemblers and linkers into build/tc/.

    python3 tools/setup.py [--archives DIR] [--masm3 IMG]

Needs 7-Zip (`7z` on the PATH, or in Program Files on Windows); the floppy images inside are
read with tools/fat12.py. The archives are the user's own copies (never committed):

  MASM 3.0 floppy image                      MASM 3.00, LINK 3.00, LIB  -> build/tc/MASM3
  Microsoft Macro Assembler 4.0 (5.25).7z    MASM 4.00, LINK 3.05, LIB  -> build/tc/MASM4

They are looked for in --archives (default tools/), then in the sister projects
(../u1-decompiled/tools for MASM 4.0, ../u6-decompiled/tools/masm300 for the MASM 3.0 image).
"""
import argparse, glob, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
TC = os.path.join(ROOT, 'build', 'tc')
SIS = os.path.dirname(ROOT)

SEVENZ = shutil.which('7z') or next((p for p in (r'C:\Program Files\7-Zip\7z.exe',
                                                  r'C:\Program Files (x86)\7-Zip\7z.exe')
                                     if os.path.exists(p)), '7z')


def sh7z(archive, out):
    subprocess.run([SEVENZ, 'x', '-y', '-o' + out, archive], check=True, stdout=subprocess.DEVNULL)


def fat(img, out):
    subprocess.run([sys.executable, '-I', os.path.join(HERE, 'fat12.py'), img, out], check=True,
                   stdout=subprocess.DEVNULL)


def find(pats, what):
    for p in pats:
        m = sorted(glob.glob(p))
        if m:
            return m[0]
    raise SystemExit('missing: %s (looked for %s)' % (what, ', '.join(pats)))


def copy(srcdir, names, dst):
    os.makedirs(dst, exist_ok=True)
    have = {n.upper(): n for n in os.listdir(srcdir)}
    for n in names:
        shutil.copy(os.path.join(srcdir, have[n.upper()]), os.path.join(dst, n.upper()))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--archives', default=os.path.join(ROOT, 'tools'))
    ap.add_argument('--masm3', help='MASM 3.0 floppy image')
    a = ap.parse_args()
    tmp = tempfile.mkdtemp()
    try:
        m3 = a.masm3 or find([os.path.join(a.archives, 'masm300', '*.img'),
                              os.path.join(SIS, 'u6-decompiled', 'tools', 'masm300', '*.img')],
                             'MASM 3.0 image')
        fat(m3, os.path.join(tmp, 'm3'))
        copy(os.path.join(tmp, 'm3'), ['MASM.EXE', 'LINK.EXE', 'LIB.EXE'], os.path.join(TC, 'MASM3'))

        m4 = find([os.path.join(a.archives, 'Microsoft Macro Assembler 4.0*.7z'),
                   os.path.join(SIS, 'u1-decompiled', 'tools', 'Microsoft Macro Assembler 4.0*.7z')],
                  'MASM 4.0 archive')
        sh7z(m4, os.path.join(tmp, 'm4'))
        img = glob.glob(os.path.join(tmp, 'm4', '*', '*.img'))[0]
        fat(img, os.path.join(tmp, 'm4x'))
        copy(os.path.join(tmp, 'm4x'), ['MASM.EXE', 'LINK.EXE', 'LIB.EXE', 'EXEMOD.EXE'],
             os.path.join(TC, 'MASM4'))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    for r, ds, fs in sorted(os.walk(TC)):
        if fs:
            print(os.path.relpath(r, TC), ', '.join(sorted(fs)))


if __name__ == '__main__':
    main()
