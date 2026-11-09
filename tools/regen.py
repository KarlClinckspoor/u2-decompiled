#!/usr/bin/env python3
"""Re-derive the source from the executable: gen.py -> MASM (with listing) -> LINK -> compare the
load image with ULTIMAII.EXE, and repeat, adding every instruction that assembles differently to
the force file (those are written as db), until the image is identical.

    python3 tools/regen.py [WORKDIR] [MASM3|MASM4]      (ITER env: max iterations, default 40)

WORKDIR defaults to build/regen and gets U2.ASM, U2.LST, U2.ins and U2.force (seeded from
tools/U2.force, the 22 addresses the loop forced). src/U2.ASM is the source of truth since it was
frozen; this is a tool for re-deriving pieces, its output is never copied over src/ wholesale.
"""
import os, shutil, sys, subprocess, struct
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import dos as dosmod
exe = os.path.join(ROOT, 'gamedata', 'ULTIMAII.EXE')
work = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'build', 'regen')
asm = sys.argv[2] if len(sys.argv) > 2 else 'MASM3'
os.makedirs(work, exist_ok=True)
if not os.path.exists(os.path.join(work, 'U2.force')):
    shutil.copy(os.path.join(HERE, 'U2.force'), os.path.join(work, 'U2.force'))


def dos(cmds):
    dosmod.run(work, cmds, timeout=600)

orig = open(exe, 'rb').read()
oimg = orig[512:][:0x8AC0]
ffile = os.path.join(work, 'U2.force')
for it in range(int(os.environ.get('ITER', '40'))):
    subprocess.run([sys.executable, '-I', os.path.join(HERE, 'gen.py'), exe, os.path.join(work, 'U2.ASM'), ffile], check=True)
    for f in ('U2.OBJ', 'U2.EXE', 'ASM.LOG', 'LNK.LOG'):
        p = os.path.join(work, f)
        if os.path.exists(p): os.unlink(p)
    dos(['D:\\%s\\MASM U2.ASM,U2.OBJ,U2.LST; > ASM.LOG' % asm, 'D:\\MASM4\\LINK U2; > LNK.LOG'])
    log = open(os.path.join(work, 'ASM.LOG'), 'rb').read().decode('latin1')
    if not os.path.exists(os.path.join(work, 'U2.EXE')):
        print(log[-3000:]); print(open(os.path.join(work, 'LNK.LOG'), 'rb').read().decode('latin1')); sys.exit('no EXE')
    new = open(os.path.join(work, 'U2.EXE'), 'rb').read()
    h = struct.unpack('<14H', new[:28])
    nimg = new[h[4] * 16:]
    print('iter %d: built image %X bytes, orig %X; header CS:IP %04X:%04X SS:SP %04X:%04X nrel %d' % (
        it, len(nimg), len(oimg), h[11], h[10], h[7], h[8], h[3]))
    rel = [struct.unpack('<HH', new[h[12] + 4 * i:h[12] + 4 * i + 4]) for i in range(h[3])]
    print('  relocs', ['%04X:%04X' % (s, o) for o, s in rel])
    n = min(len(nimg), len(oimg))
    diffs = [i for i in range(n) if nimg[i] != oimg[i]]
    print('  differing bytes', len(diffs), 'first', ['%04X' % d for d in diffs[:12]])
    if not diffs and len(nimg) == len(oimg):
        print('IDENTICAL image'); break
    import re
    from bisect import bisect_right
    force = set(open(ffile).read().split()) if os.path.exists(ffile) else set()
    st = [int(x) for x in open(os.path.join(work, 'U2.ins')).read().split()]
    lst = open(os.path.join(work, 'U2.LST'), 'rb').read().decode('latin1').split('\n')
    rows = []
    for l in lst:
        m = re.match(r'^\s*([0-9A-F]{4})\s.*;@([0-9A-F]{4})', l)
        if m: rows.append((int(m.group(1), 16), int(m.group(2), 16), l.strip()))
    rows.append((rows[-1][0] + (0x740B - rows[-1][1]), 0x740B, 'end'))
    stset = set(st)
    bad = [(r1, r2) for r1, r2 in zip(rows, rows[1:]) if r2[0] - r1[0] != r2[1] - r1[1]]
    added = 0
    if bad:
        print('  %d lines assemble to a different size, e.g.' % len(bad))
        for r1, r2 in bad[:6]: print('    %s  (want %d, got %d)' % (r1[2], r2[1] - r1[1], r2[0] - r1[0]))
        for r1, r2 in bad:
            k = '%04X' % r1[1]
            if r1[1] in stset and k not in force: force.add(k); added += 1
        if not added:
            print('  cannot fix automatically:'); [print('   ', r1[2]) for r1, r2 in bad[:10]]; break
    else:
        for d in diffs:
            if d >= 0x7410: continue
            k = '%04X' % st[bisect_right(st, d) - 1]
            if k not in force: force.add(k); added += 1
    open(ffile, 'w').write(' '.join(sorted(force)) + '\n')
    print('  forced +%d (total %d)' % (added, len(force)))
    if not added: break
