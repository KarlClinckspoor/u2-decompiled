# c/ -- the game read as C

A **reading aid**: for a routine in `../src`, "this is roughly what it does, written the way a C
programmer would". It is **not a port**, **not byte-matching**, and **has never been run against
the game**. The assembly is the ground truth; where the two disagree, the C is wrong.

Status (and `test/`: a harness that plays the C from the title on, see test/README.md): **all 19 modules**, every routine and table of each, one `.c` per assembly module of the same
name (`main.c` = `src/MAIN.ASM`, and so on; `u2.h` has the shared state and the routines of the other
modules, `bcd.h` the BCD arithmetic). Roughly, from the top: START (`start.c`: title, menu,
demonstration, the speed-scaled delays), MAIN (the loop and the turn), EVENTS (what monsters do to the
player), SHOPS, INPUT (number and money entry, prices, the monsters' step), LOAD (files, saving), MOVE
(a step and its rules, the time doors), DUNGEON (the loop underground, the helm's map), CMDAL and CMDMZ
(the commands), SCREEN (CGA pixels and tiles), TEXTIO (text, keys, random numbers, files), CHARGEN,
MAPVIEW (the map window), SOUND, VIEW3D (the 3D view), SPACE (space flight) and ENDGAME (Minax's end).
The data module U2DATA is declared in `u2.h` as far as the C uses it; the assembly's tables that the
C needs are in the `.c` of the module that owns them (the dead code and the padding are not).

## Rules

- **Anchored.** Every function and table is preceded by a comment line
  `/* asm: NAME @ADDR ... */`, naming the assembly symbol and its original address
  (`python3 tools/syms.py NAME` finds both). Read the C next to the routine it names.
- **Same names.** Variables and routines keep the assembly's names (`PlayerX`, `AmountHi`,
  `PayPrice`). The assembly's scratch bytes (`Temp1F`, `Temp21`, `DungeonLevel`...) become local
  variables, with the original name in a comment.
- **Same behaviour, bugs included.** A bug of the original is written as it behaves and marked
  `BUG, as in the original` (see `docs/FINDINGS.md`). The C never "fixes" anything.
- **Same texts.** Strings are exactly what the game prints (`\n` is the game's
  carriage return, 8Dh). Text tables are byte-for-byte the assembly's.
- **Registers and flags disappear.** A routine that returns its result in AL, or in the zero flag,
  returns a value. A routine that ends the player's turn (`jmp EndCommand`) just `return`s;
  `jmp EndCommandBeep` is `Beep(); return;`. A routine that abandons its caller on failure
  (`PayPrice`, `ReadDirection`) returns `false` and the caller returns.
  BCD arithmetic is `bcd_add` / `bcd_sub` (`bcd.h`), literal models of `clc / adc / daa` and
  `sub / das`, so counts wrap 99 -> 00 like the game's; `bcd_adc` carries the carry flag for code
  that chains additions (CmdOffer's attribute gift, where the leaked carry is a real quirk).
- **The turn.** The assembly's chain of jumps (every command ends `jmp EndCommand`, the monsters'
  loops jump on to EndTurn, EndTurn jumps back to MainLoop) becomes returns: `MainLoop` calls
  `EndCommand` after each pass, which runs the monsters' turn. A jump the C turns into a return
  is listed in the anchor: `returns: EndTurn MainLoop`.
- **What it leaves out:** the registers, dead code and padding. The machine itself, the BIOS, DOS,
  the ports and the CGA's memory, is not part of the game: `u2.h` declares it as stand-ins
  (`BiosReadKey`, `BiosWriteChar`, `DosOpenFcb`, `OutPort`, `VideoByte` ...), and the C calls them
  where the assembly executes an `int` or an `in`/`out`.
- **Jumps that never come back** (the title, the menu and the demonstration in `start.c`; the
  space command loop) are calls in the C, and what follows such a call is only the C unwinding.
- **Text.** `PrintChar` treats the game's two kinds of line end (0Dh and 0Ah) as the one `'\n'`;
  the only 0Ah in the game follow a 0Dh.
- **Loops over the same thing:** where the assembly repeats code that a C loop does (the six
  attributes, the crosshair's pixels), the anchor carries `unrolled:` with the number of calls the
  loop saves, and the check demands exactly that many fewer.

## Checking

```
python3 tools/ccheck.py --cc gcc
```

(The compiler: MSYS2's gcc at `C:\msys64\mingw64\bin` if it is not on the PATH.)

checks, for every anchored item, that the symbol exists at that address, that a function prints
exactly the same texts (a different order is accepted and reported as "reordered") and calls the
same routines at least as often, that a
table matches the assembly byte for byte, and that the file compiles (`-std=c99 -Wall -Wextra
-Wpedantic -fsyntax-only`). It lists the routines of each module that still have no C.

**It cannot check the logic**: the numbers, the conditions, the order of the calls. For those the
only checks are reading the C beside the assembly and playing the game. For `shops.c` the logic
was also exercised with a throwaway test program and stand-in routines (the pub's tips for every
amount and random value, the BCD wrap, every shop's menu mapping, the dispatcher's quarters),
and the pub's fixed tip and the BCD limits were seen in DOSBox; none of that is kept in the
repository.

## Adding a module

1. Declare what the module needs from the rest of the game in `u2.h` (state with its `D:xxxx`
   offset, routines with their `C:xxxx` address).
2. One `.c` per assembly module, same name; anchor every routine and table.
3. Run `ccheck.py --cc gcc`; where the C legitimately replaces a repeated idiom with a helper
   (the "wait for an ASCII key" loop is `ReadAsciiKey`), add the pair to `ALIASES` in `ccheck.py`.
   Where a C loop replaces repeated assembly (CmdZtats' six attributes), say so in the anchor:
   `/* asm: CmdZtats @4568 unrolled: PutChar-5 ... */` lowers the call counts the check demands.

Writing the C is also a way to find bugs, and to correct claims about them: the cleric's
"SISTER" that can never be said, the carry leak in the attribute gift, the monster hit down to
exactly 0 that lives; and the dungeon-attack search turned out to be far less harmful than the
first reading suggested. See `docs/FINDINGS.md`.
