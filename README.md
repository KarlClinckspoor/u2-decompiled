# u2-decompiled

Source code for the PC version of **Ultima II: The Revenge of the Enchantress** (Sierra On-Line
1983, reissued by Origin in 1989), rebuilt with the original tools into an executable identical
to the GOG release, byte for byte.

## Status

| executable | what | status |
|---|---|---|
| ULTIMAII.EXE | the whole game (one program) | **rebuilds identical** (37344 bytes, sha1 `6efae26c…`) from 19 assembly modules in `src/`. The remains of Origin's 1989 protection envelope are copied from the original at build time (`tools/postlink.py`) |

The game is hand-written 8086 assembly, a close transliteration of the Apple II 6502 code; there
is no compiler output in it. The source was generated from the executable (`tools/gen.py`) and is
now edited by hand. It is **relocatable**: every address is a symbol with a real name (`tools/syms.py`
gives each name's original address), so code and data can be added or moved;
`tools/shift.py` checks this and shifted builds play normally. It is split into one module per
subsystem (title, main loop, events, shops, commands, screen, text and file I/O, character
generation, map view, sound, 3D view, space, endgame) plus one for the data. One instruction is
left as `db`. It is named and commented: an overview per module, a header per routine, real names for
1032 symbols (docs/NAMING.md has the conventions, docs/FINDINGS.md what the code revealed).

## Toolchain

Assembly: **MASM 4.00** (MASM 3.00 gives the identical file: `ASM=MASM3`). Link: Microsoft
**LINK 3.05** (2.40 and 3.00 give the same file).

The repository contains neither the game nor the tools. Put the GOG files in `gamedata/` and the
toolchain archives in `tools/` (MASM 3.0 floppy image under `tools/masm300/`, the
"Microsoft Macro Assembler 4.0 (5.25).7z" archive); the sister projects' copies
(`../u6-decompiled`, `../u1-decompiled`) are used when these are missing. Then:

```sh
python3 tools/setup.py     # unpacks MASM 3.00/LINK 3.00 and MASM 4.00/LINK 3.05 into build/tc (needs 7-Zip)
python3 tools/build.py     # builds build/u2/ULTIMAII.EXE and checks it against the GOG release
python3 tools/shift.py     # relocation test: builds with code and data moved, checks only addresses changed
python3 tools/play.py      # plays a build in a DOSBox window (a copy of the game files under build/)
```

Builds run the DOS tools in headless DOSBox: `dosbox` on the PATH, or the one named by the
`DOSBOX` environment variable; on Windows the GOG copy in `gamedata/DOSBOX/` is used when
neither is set. The disassembly tools need `capstone` (`pip install capstone`, in a venv if the
system Python refuses).

## Layout

- `src/*.ASM`: the game, one module per subsystem (START has `ORG 100h` and the entry `L0100`;
  U2DATA is the data segment). MASM needs CRLF line ends (.gitattributes keeps them)
- `src/u2.lnk`: link order, one module per line, with what each holds
- `tools/build.py`: assemble, link, post-link, compare; `tools/postlink.py`: the envelope step
  (works for Ultima I's ULTIMA.EXE too); `tools/dos.py`: headless DOSBox runner;
  `tools/setup.py`: toolchain
- `tools/shift.py`: relocation test; `tools/play.py`: run a build in DOSBox
- `tools/cuts.py`, `tools/split.py`: where modules may be cut, and the splitter that made them
- `tools/syms.py`, `tools/rename.py`, `tools/lint.py`: symbol table, renaming, source checks
- `c/`: the game read as C, a reading aid (not a port, not byte-matching); one module so far
  (`shops.c`). `tools/ccheck.py` checks it against the assembly (anchors, texts, calls, tables)
- `tools/sprites.py`: draws the map tiles and the dungeon monster shapes to PNG
- `tools/gen.py`, `tools/regen.py`, `tools/u2an.py`: generate the relocatable source from the
  executable and iterate until it assembles identically (for re-deriving pieces; `src/` is the
  source of truth)
- `tools/disrange.py`, `refs.py`, `rdis.py`, `data.py`, `scan.py`, `stats.py`: disassembly, references
  and CS writes, coverage, data-segment map, header and statistics (each takes the EXE path)
- `docs/HANDOFF.md`: state, findings and next steps
