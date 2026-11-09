#!/usr/bin/env python3
"""Run DOS commands headless in DOSBox: C: is a work directory, D: is build/tc (the toolchain).

    python3 tools/dos.py WORKDIR "CMD" ["CMD" ...]

As a module: run(workdir, [cmds]) -> None. D:\\MASM3 and D:\\MASM4 hold the assemblers and
linkers (tools/setup.py); the TC environment variable names another toolchain directory.
Each call uses its own config file, so several runs can go at once.
(Shared with u1-decompiled, whose copy also puts its Lattice compiler on the PATH.)
"""
import os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
TC = os.environ.get('TC') or os.path.join(ROOT, 'build', 'tc')
# DOSBOX overrides; otherwise dosbox on the PATH, else the GOG copy in gamedata/ (Windows)
DOSBOX = (os.environ.get('DOSBOX') or shutil.which('dosbox') or
          next((p for p in (os.path.join(ROOT, 'gamedata', 'DOSBOX', 'DOSBox.exe'),)
                if os.path.exists(p)), 'dosbox'))

CONF = """[sdl]
fullscreen=false
[dosbox]
memsize=16
machine=svga_s3
[cpu]
core=dynamic
cycles=max
[speaker]
pcspeaker=false
tandy=off
[mixer]
nosound=true
[midi]
mpu401=none
[autoexec]
mount c "{c}"
mount d "{d}"
set PATH=D:\\LC;Z:\\
set INCLUDE=D:\\INC\\
c:
"""


def run(workdir, cmds, timeout=300):
    workdir = os.path.abspath(workdir)
    # the commands go in a batch file: DOSBox 0.74's [autoexec] overflows at about 4 KB
    bat = os.path.join(workdir, '_RUN.BAT')
    with open(bat, 'w', newline='') as f:
        f.write('@ECHO OFF\r\n' + ''.join(c + '\r\n' for c in cmds))
    fd, conf = tempfile.mkstemp(suffix='.conf')
    with os.fdopen(fd, 'w') as f:
        f.write(CONF.format(c=workdir, d=TC))
        f.write('CALL _RUN.BAT\nexit\n')
    env = dict(os.environ, SDL_VIDEODRIVER='dummy', SDL_AUDIODRIVER='dummy')
    try:
        extra = ['-noconsole'] if os.name == 'nt' else []
        subprocess.run([DOSBOX, '-conf', conf, '-exit'] + extra, env=env, timeout=timeout,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       cwd=os.path.dirname(conf))   # -noconsole writes stdout.txt/stderr.txt there
    finally:
        os.unlink(conf)
        if os.path.exists(bat):
            os.unlink(bat)


if __name__ == '__main__':
    run(sys.argv[1], sys.argv[2:])
