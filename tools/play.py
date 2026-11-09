#!/usr/bin/env python3
"""Play a build in a DOSBox window, with GOG's machine settings (CGA, 500 cycles).

    python3 tools/play.py [EXE] [--dir DIR] [--cycles N]

EXE defaults to build/u2/ULTIMAII.EXE. The game files (maps, monsters, talk, pictures and the
PLAYER save) are copied from gamedata/ into DIR (default build/play) once and the EXE next to
them, so gamedata/ is never written to; delete DIR to start from GOG's PLAYER file again.
Quit with ctrl-F9 or by closing the window.
"""
import argparse, os, shutil, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import dos

CONF = """[sdl]
fullscreen=false
windowresolution=original
output=surface
[dosbox]
machine=cga
memsize=16
[render]
aspect=false
scaler=normal2x
[cpu]
core=simple
cputype=386_slow
cycles={cycles}
[speaker]
pcspeaker=true
[autoexec]
mount c "{dir}"
c:
ULTIMAII.EXE
exit
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('exe', nargs='?', default=os.path.join(ROOT, 'build', 'u2', 'ULTIMAII.EXE'))
    ap.add_argument('--dir', default=os.path.join(ROOT, 'build', 'play'))
    ap.add_argument('--cycles', type=int, default=500)
    a = ap.parse_args()
    gd = os.path.join(ROOT, 'gamedata')
    if not os.path.isdir(a.dir):
        os.makedirs(a.dir)
        for f in os.listdir(gd):
            p = os.path.join(gd, f)
            if os.path.isfile(p) and '.' not in f:      # the game's data files have no extension
                shutil.copy(p, os.path.join(a.dir, f.upper()))
    shutil.copy(a.exe, os.path.join(a.dir, 'ULTIMAII.EXE'))
    fd, conf = tempfile.mkstemp(suffix='.conf')
    with os.fdopen(fd, 'w') as f:
        f.write(CONF.format(dir=os.path.abspath(a.dir), cycles=a.cycles))
    try:
        subprocess.run([dos.DOSBOX, '-conf', conf, '-noconsole'], cwd=os.path.dirname(conf))
    finally:
        os.unlink(conf)


if __name__ == '__main__':
    main()
