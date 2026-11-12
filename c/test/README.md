# c/test -- a test harness for the C

Runs the C of `../` headless, against stand-ins for the machine, to see that it actually plays.
`python3 c/test/run.py` builds `harness.c` with every `c/*.c` (gcc) and plays the scenarios in
`run.py`: the title and menu, the demonstration, character generation (with the Ztats screen), the
sign of an era, a step, entering a dungeon (with the torch and the 3D view), walking in it, a castle,
a tower, a merchant, and the first Ctrl-Right (which must end in the divide error of
docs/FINDINGS.md). It needs the game files in `gamedata/` (not in the repository); they are only
read, files the game writes go to `build/ctest/work-*`. Pictures are left in `build/ctest/*.png`.

`harness GAMEDIR WORKDIR "KEYS" [OUT.png]` runs one scenario by hand: the keys are characters and
`{ESC} {UP} {DOWN} {LEFT} {RIGHT} {ENTER} {BS} {CTRL-RIGHT} {CTRL-LEFT} {CTRL-S}`; the arrow
keys are the game's direction keys. It stops when the keys are used up and the game keeps polling
(`U2_GIVEUP` polls, default 3000), or when the game hangs or divides by zero, and prints the text
screen and writes the graphics as a PNG. Each key arrives after a few empty polls, as a person's
would: the game empties the keyboard buffer on every key.

What the harness is made of:

- the **machine** (`harness.c`): the keyboard, a 40x25 text screen and the CGA memory, DOS FCB
  files, the ports (ignored), and the BIOS tick. The text screen is addressed the way the BIOS
  does it, row * 40 + column, so a character written at column 40 lands at column 0 of the next
  row (the game does that once, in ClearBottomLines);
- the **data segment** (`gendata.py` -> `gen/gen_data.h`, not kept): the starting values of all
  variables from `src/U2DATA.ASM`, and where each one lies in the data segment, so that the PLAYER
  file and the monster file (which the C reads and writes as one 256-byte block) are moved to and
  from the separate C variables.

What it shows so far: the C runs the whole path from the title through character generation to
the map, towns, dungeons and the 3D view, and reproduces the documented divide error. What it
does not cover: combat, shops past the first words, spells, space flight and everything the
scenarios do not press.
