#!/usr/bin/env python3
"""Build the test harness and run its scenarios.

    python3 c/test/run.py [--keep] [SCENARIO ...]

Builds c/test/harness.c with every c/*.c (gcc; MSYS2's at C:\\msys64\\mingw64\\bin is found if it is
not on the PATH), then plays each scenario: a list of keys into the game, with files in a fresh work
directory under build/ctest/ (gamedata/ is only read), and checks the text screen the game ends with
(or the reason it stopped). Pictures are left in build/ctest/*.png.

A scenario is (name, keys, checks, player_patch). player_patch, if any, is {offset: value} applied to
the PLAYER file that an earlier "create" run made (offsets are the record's: D address - 36h); the
character is made once, by the 'create' scenario, and copied.
"""
import os, re, shutil, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, 'build', 'ctest')
EXE = os.path.join(OUT, 'harness.exe' if os.name == 'nt' else 'harness')
GAMEDIR = os.path.join(ROOT, 'gamedata')

CREATE = '{ESC}C151515151515M11KARL{ENTER}Y'     # 15 in all six, male human fighter, KARL


def price_model(item, intelligence, charisma):
    """CalcPrice (INPUT.ASM 20AB), independently: the BCD series 4, 8, 12, 20 ... for item + 8 - b steps,
    b the number of significant bits of intelligence + charisma added as plain bytes (carry of item + 8 included)."""
    s = (intelligence + charisma + (1 if item + 8 > 255 else 0)) & 255
    bits = 1
    while s >> bits:
        bits += 1
    n = item + 8 - bits
    cur, prev = 4, 4
    for _ in range(n):
        cur, prev = cur + prev, cur
    return int(str(cur % 10000), 16)

SCENARIOS = [
    # name, keys, strings that must be in the final screen / stop line, PLAYER patch
    ('menu',    '{ESC}', ['CHOICE:', 'stopped: out of keys'], None),
    ('demo',    '{ESC}D', ['video mode 4', 'picture:'], None),
    ('create',  CREATE + '{ESC}PZ', ['KARL', 'A LEVEL 00 MALE HUMAN FIGHTER', 'STRENGTH-35', 'AGILITY-15',
                                      'INTELL.-20', 'WISDOM-15', 'CHARISMA-15'], None),
    ('sign',    '{ESC}PE', ['ENTER-THE SIGN READS:', 'ANOS: 1423 B.C.'], {0x24: 58, 0x25: 51}),
    ('step',    '{ESC}P{RIGHT}', ['EAST'], None),
    ('status',  '{ESC}P', ['H.P.=0400', 'FOOD=0400', 'GOLD=0400'], None),
    # Record offsets: TimeZone 13h, MapType 14h, SurfaceX/Y 24h/25h, Torches 2Eh (era 2 of the
    # character: its surface map has a dungeon at 25,5, a castle at 35,22, a tower at 24,40 ...).
    ('dungeon', '{ESC}PEI', ['ENTER-DUNGEON', "IT'S DARK!", 'IGNITE TORCH', 'map type 5'],
     {0x24: 25, 0x25: 5, 0x2E: 5}),
    ('dungeon-walk', '{ESC}PEI{UP}{LEFT}{LEFT}{DOWN}', ['TURN LEFT', 'RETREAT', 'player at 7,5'],
     {0x24: 25, 0x25: 5, 0x2E: 5}),
    ('castle',  '{ESC}PE', ['ENTER-CASTLE', 'map type 3'], {0x24: 35, 0x25: 22}),
    ('tower',   '{ESC}PE', ['ENTER-TOWER', 'map type 4'], {0x24: 24, 0x25: 40}),
    # Start in the towne (map type 2) next to a merchant; Transact east.
    ('merchant', '{ESC}PT{RIGHT}', ['TRANSACT-EAST', 'A MERCHANT SAYS:', 'map type 2'],
     {0x13: 2, 0x14: 2, 0x24: 30, 0x25: 6}),
    # --- with cheats (see harness.c: {SET:Var=val} and {GOTO:era,type,x,y}) ---
    # Teleport on the surface: walk-in position of the era's village, then Enter.
    ('teleport', '{ESC}P{SET:PlayerX=38}{SET:PlayerY=46}E', ['ENTER-VILLAGE', 'map type 1'], None),
    ('klimb',   '{ESC}P{GOTO:2,4,11,11}K', ['KLIMB', 'TO LEVEL 01', 'map type 4'], None),
    ('descend', '{ESC}P{GOTO:2,5,11,11}D', ['DESCEND', 'TO LEVEL 01', 'map type 5'], None),
    # Attack the person at 6,5 of the towne with the best weapon and an agility that always hits:
    # (8 * 8 + 35h) / 4 = 29 a hit against 60 hit points: the third hit kills.
    ('combat',  '{ESC}P{GOTO:2,2,5,5}{SET:ReadyWeapon=8}{SET:Attributes[1]=0xFF}A{RIGHT}A{RIGHT}A{RIGHT}',
     ['HIT!!!', 'KILLED--GOLD+'], None),
    # The shops of the towne, standing at a counter (T + direction): the pub always gives tip 1
    # (docs/FINDINGS.md), a drink costs 5.
    ('pub',     '{ESC}P{GOTO:2,2,10,51}T{UP}1', ['HERE, HAVE A STRONG ONE!', 'THE BARKEEP SAYS:',
                 "ISN'T THIS A GREAT GAME?", 'GOLD=0395'], None),
    # CalcPrice for intelligence 20 and charisma 15 (BCD, added as binary: 35h) is 0084 (price_model agrees
    # below), 400 - 84 = 316.
    ('horse',   '{ESC}P{GOTO:2,2,51,53}T{UP}Y', ['RIDE SWIFTLY!', 'GOLD=0316'], None),
    ('horse-price', '{ESC}P{GOTO:2,2,51,53}T{UP}', ['HORSE %04X' % price_model(4, 0x20, 0x15)], None),
    ('horse-no', '{ESC}P{GOTO:2,2,51,53}T{UP}N', ['O.K. BYE THEN...', 'GOLD=0400'], None),
    ('poor',    '{ESC}P{GOTO:2,2,51,53}{SET:GoldHi=0}{SET:GoldLo=0x10}T{UP}Y', ['YOU DONT HAVE THAT MUCH!', 'GOLD=0010'], None),
    # The price quirk of docs/FINDINGS.md: intelligence 80 + charisma 80 wraps to 0, the dearest prices.
    ('price-quirk', '{ESC}P{GOTO:2,2,51,53}{SET:Attributes[5]=0x80}{SET:Attributes[3]=0x80}T{UP}',
     ['HORSE %04X' % price_model(4, 0x80, 0x80)], None),
    # Space: the rocket (PlayerTile 28h), reflect armour and fuel; launch, hyperwarp to Earth's own
    # coordinates, then H)yperwarp to 1,4,1 (deep space), and L)anding is denied there.
    ('launch',  '{ESC}P{SET:PlayerTile=0x28}{SET:WornArmour=5}{SET:ItemCounts[15]=0x10}L',
     ['HYPERWARP ENGAGED!', 'YOU ARE ORBITING EARTH.', 'FUEL=09'], None),
    ('space-deep', '{ESC}P{SET:PlayerTile=0x28}{SET:WornArmour=5}{SET:ItemCounts[15]=0x10}LH141',
     ['PREPARE FOR HYPERWARP!', 'YOU ARE IN DEEP SPACE.', 'FUEL=08'], None),
    ('space-denied', '{ESC}P{SET:PlayerTile=0x28}{SET:WornArmour=5}{SET:ItemCounts[15]=0x10}LH411L',
     ['REQUEST DENIED!'], None),
    ('space-land', '{ESC}P{SET:PlayerTile=0x28}{SET:WornArmour=5}{SET:ItemCounts[15]=0x10}LL',
     ['LANDING REQUESTED!', '(PRESS ANY KEY)'], None),
    # The documented bug (docs/FINDINGS.md): the first Ctrl-Right at the default speed sends the
    # delay table's division out of range.
    ('ctrl-right', '{ESC}P{CTRL-RIGHT}', ['stopped: divide error'], None),
]


def find_gcc():
    gcc = shutil.which('gcc')
    if gcc:
        return gcc
    cand = r'C:\msys64\mingw64\bin\gcc.exe'
    if os.path.exists(cand):
        os.environ['PATH'] = os.path.dirname(cand) + os.pathsep + os.environ['PATH']
        return cand
    sys.exit('no gcc (MSYS2 is expected at C:\\msys64\\mingw64\\bin)')


def build():
    os.makedirs(OUT, exist_ok=True)
    subprocess.check_call([sys.executable, os.path.join(HERE, 'gendata.py')])
    srcs = sorted(os.path.join(ROOT, 'c', f) for f in os.listdir(os.path.join(ROOT, 'c')) if f.endswith('.c'))
    cmd = [find_gcc(), '-std=gnu99', '-Wall', '-g', '-I', os.path.join(ROOT, 'c'), '-o', EXE,
           os.path.join(HERE, 'harness.c')] + srcs
    subprocess.check_call(cmd)


def play(name, keys, workdir, extra_env=None):
    png = os.path.join(OUT, name + '.png')
    env = dict(os.environ)
    env.update(extra_env or {})
    r = subprocess.run([EXE, GAMEDIR, workdir, keys, png], capture_output=True, text=True, env=env, timeout=300)
    return r.stdout + r.stderr


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    build()
    if not os.path.isdir(GAMEDIR):
        sys.exit('no gamedata/ (the game files are not part of the repository)')
    todo = [s for s in SCENARIOS if not args or s[0] in args]
    failed = 0
    made = None                                   # a work directory with a character in it
    for name, keys, checks, patch in todo:
        work = os.path.join(OUT, 'work-' + name)
        shutil.rmtree(work, ignore_errors=True)
        os.makedirs(work)
        if keys.startswith('{ESC}P'):             # needs the character
            if made is None:                     # make the character once
                made = os.path.join(OUT, 'work-character')
                shutil.rmtree(made, ignore_errors=True)
                os.makedirs(made)
                play('character', CREATE + '{ESC}P', made)
            shutil.copy(os.path.join(made, 'PLAYER'), os.path.join(work, 'PLAYER'))
            if patch:
                b = bytearray(open(os.path.join(work, 'PLAYER'), 'rb').read())
                for off, val in patch.items():
                    b[off] = val
                open(os.path.join(work, 'PLAYER'), 'wb').write(bytes(b))
        out = play(name, keys, work, {'U2_GIVEUP': '3000'})
        bad = [c for c in checks if c not in out]
        print('%-11s %s' % (name, 'ok' if not bad else 'FAILED: missing %r' % bad))
        if bad:
            failed += 1
            print(out)
    print('%d scenario(s), %d failed' % (len(todo), failed))
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
