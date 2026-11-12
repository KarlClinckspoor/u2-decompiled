# c/ -- the game read as C

A **reading aid**: for a routine in `../src`, "this is roughly what it does, written the way a C
programmer would". It is **not a port**, **not byte-matching**, and **has never been run against
the game**. The assembly is the ground truth; where the two disagree, the C is wrong.

Status: eight modules so far, every routine of each:
`main.c` = `src/MAIN.ASM` (the main loop and the turn), `events.c` = `src/EVENTS.ASM` (what monsters do
to the player), `cmdal.c` = `src/CMDAL.ASM` (commands A to L, the fight, the ladder code), `cmdmz.c` =
`src/CMDMZ.ASM` (commands M to Z), `shops.c` = `src/SHOPS.ASM`, `input.c` = `src/INPUT.ASM` (number
and money entry, the shops' prices, the monsters' step outdoors and in towns), `load.c` =
`src/LOAD.ASM` (the map, monster and talk files; saving) and `move.c` = `src/MOVE.ASM` (a step and its
rules by transport, the direction a command asks for, the time doors). Not yet: START, DUNGEON,
SCREEN, TEXTIO, CHARGEN, MAPVIEW, SOUND, VIEW3D, SPACE, ENDGAME (the data U2DATA is declared in
`u2.h` as far as the eight modules use it).

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
- **What it leaves out:** the timing loops, the screen, the DOS file calls. `u2.h` declares what
  the C files need from them.

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
