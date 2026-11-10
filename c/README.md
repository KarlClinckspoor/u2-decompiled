# c/ -- the game read as C

A **reading aid**: for a routine in `../src`, "this is roughly what it does, written the way a C
programmer would". It is **not a port**, **not byte-matching**, and **has never been run against
the game**. The assembly is the ground truth; where the two disagree, the C is wrong.

Status: pilot, one module (`shops.c` = `src/SHOPS.ASM`, every routine of it).

## Rules

- **Anchored.** Every function and table is preceded by a comment line
  `/* asm: NAME @ADDR ... */`, naming the assembly symbol and its original address
  (`python3 tools/syms.py NAME` finds both). Read the C next to the routine it names.
- **Same names.** Variables and routines keep the assembly's names (`PlayerX`, `AmountHi`,
  `PayPrice`). The assembly's scratch bytes (`Temp1F`, `Temp21`, `DungeonLevel`...) become local
  variables, with the original name in a comment.
- **Same behaviour, bugs included.** A bug of the original is written as it behaves and marked
  `BUG, as in the original` (see `docs/FINDINGS.md`). The C never "fixes" anything.
- **Same texts, same order.** Strings are exactly what the game prints (`\n` is the game's
  carriage return, 8Dh). Text tables are byte-for-byte the assembly's.
- **Registers and flags disappear.** A routine that returns its result in AL, or in the zero flag,
  returns a value. A routine that ends the player's turn (`jmp EndCommand`) just `return`s.
  BCD arithmetic is `bcd_add` (`bcd.h`), a literal model of `clc / adc / daa`, so counts wrap
  99 -> 00 like the game's.
- **What it leaves out:** the timing loops, the screen, the DOS file calls. `u2.h` declares what
  the C files need from them.

## Checking

```
python3 tools/ccheck.py --cc gcc
```

checks, for every anchored item, that the symbol exists at that address, that a function prints
exactly the same texts in the same order and calls the same routines at least as often, that a
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
