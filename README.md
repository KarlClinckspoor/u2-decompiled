# u2-decompiled

Source code for the PC version of **Ultima II: The Revenge of the Enchantress** (Sierra On-Line
1983, reissued by Origin in 1989), rebuilt with the original tools into an executable identical
to the GOG release, byte for byte.

## Status

| executable | what | status |
|---|---|---|
| ULTIMAII.EXE | the whole game (one program) | **rebuilds identical** (37344 bytes, sha1 `6efae26c…`) from one assembly source, `src/U2.ASM`. The remains of Origin's 1989 protection envelope are copied from the original at build time (`tools/postlink.py`) |

The game is hand-written 8086 assembly, a close transliteration of the Apple II 6502 code; there
is no compiler output in it. The source was generated from the executable (`tools/gen.py`) and is
now edited by hand. It is **relocatable**: every address is a symbol (`Lxxxx` in code, `D_xxxx`
in data, named after their original addresses for now), so code and data can be added or moved;
`tools/shift.py` checks this and a shifted build plays normally. One instruction is left as `db`.
Next come splitting it into modules, then names and comments (docs/HANDOFF.md).

## Toolchain

Assembly: **MASM 4.00** (MASM 3.00 gives the same code but runs out of symbol space). Link:
Microsoft **LINK 3.05** (2.40 and 3.00 give the same file).

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

- `src/U2.ASM`: the game. One DATA segment, then one CODE segment (`ORG 100h`, entry `L0100`).
  MASM needs CRLF line ends (.gitattributes keeps them)
- `src/u2.lnk`: link order, one module per line (a single module for now)
- `tools/build.py`: assemble, link, post-link, compare; `tools/postlink.py`: the envelope step
  (works for Ultima I's ULTIMA.EXE too); `tools/dos.py`: headless DOSBox runner;
  `tools/setup.py`: toolchain
- `tools/shift.py`: relocation test; `tools/play.py`: run a build in DOSBox
- `tools/gen.py`, `tools/regen.py`, `tools/u2an.py`: generate the relocatable source from the
  executable and iterate until it assembles identically (for re-deriving pieces; `src/` is the
  source of truth)
- `tools/disrange.py`, `refs.py`, `rdis.py`, `data.py`, `scan.py`, `stats.py`: disassembly, references
  and CS writes, coverage, data-segment map, header and statistics (each takes the EXE path)
- `docs/HANDOFF.md`: state, findings and next steps
