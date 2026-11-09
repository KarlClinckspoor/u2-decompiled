# Handoff: Ultima II decompilation (u2-decompiled)

State as of 2026-11-09, after the second session (repository, envelope step, frozen source).
Read this first. The sister project `../u1-decompiled` (docs/HANDOFF.md, MAP.md, MATCHING.md)
is the model for conventions.

## Headline

**ULTIMAII.EXE rebuilds byte-identical as a file** (37344 bytes, sha1 6efae26c…) from
`src/U2.ASM` with `python3 tools/build.py`: MASM 3.00 + LINK 3.05 in one DOSBox run (~15 s),
then `tools/postlink.py` adds the envelope remains from gamedata. 104 of 8146 instructions are
still written as `db` (gen.py's count). `src/U2.ASM` is frozen: it is the source of truth and is
edited by hand from now on. Unlike U1 there is no C at all: the whole game is hand-written 8086
assembly, so what comes next is symbol recovery and a readability pass, not C matching.

## The executable

GOG release, one program: `gamedata/ULTIMAII.EXE`, 37344 bytes,
sha1 6efae26cdaedf30426d35cf935b50e5639387cec. Title screen says "(C)-1983,1989 BY LORD BRITISH
AND ORIGIN": the 1983 Sierra PC version as reissued by Origin in 1989.
Other game files (not code): MAPG*/MAPX* (maps, 4096/4224 bytes), MONG*/MONX*/MONSTERS (monsters),
TLKG*/TLKX* (talk), PIC* (16 KB CGA screens: DNG DRA MIN OUT SPA TWN), PLAYER (384-byte save).

| image range | what |
|---|---|
| 0000-0100 | zeros: the source had `ORG 100h` in the code segment (LINK writes them) |
| 0100-740B | code segment (CS = load segment), entry 0100; 740B-7410 LINK padding |
| 7410-8AC0 | data segment, PARA aligned, 0x16B0 initialised bytes; `mov ax,DATA` at 0100 is the only relocation (0000:0101) |
| 8AC0-8AE0 | envelope stub (header CS:IP 08AC:0000): sets SS=load seg, SP=0, RETFs to load:0100 |
| 8AE0-8FE0 | envelope tail, 0x500 bytes |

At run time the program sets DS = load+0741h, SS = DS+0310h, SP = 0100h, so the data segment is
0x3100 bytes (BSS from DS:16B0) plus a 256-byte stack. Header: 512-byte header, min 0000 max FFFF,
SS:SP 09FE:0064, invalid checksum (sum B98D, stored EA36).

### The envelope = the same one as U1's ULTIMA.EXE

The tail after the stub is the same as U1 ULTIMA.EXE's: its first 0x20E bytes are the same
content XOR a per-EXE key (the two differ by a constant 0xEF), the bytes to 0x2F7 are identical,
then zeros. Both are remnants of a removed 1989 protection/loader envelope. The pre-envelope
header must have been CS:IP 0000:0100, SS:SP 0000:0000 (no stack segment), which is exactly what
LINK produces from our source.

**Done (`tools/postlink.py`)**: appends stub + tail from gamedata at build time, sets CS:IP
08AC:0000, SS:SP 09FE:0064 and the checksum EA36 (pages/last-page follow from the length). The U2
envelope also **moved the relocation table**: LINK writes relo=001E with a word 0001 at 001C and
the one entry (0000:0101) at 001E; the original has relo=001C and the entry at 001C (the 0001 word
is gone). U1's ULTIMA.EXE kept LINK's layout. The tool lays the header out again when the offsets
differ, and refuses unless the relocation entries, the other header fields and the resulting
header all equal the original's. Never commit the envelope bytes.
The same tool rebuilds U1's ULTIMA.EXE identical too (checked by relinking u1's objects in a
scratch directory). U1 still has its own `src/ultima/postlink.py` (no checksum or relocation
handling, which it doesn't need); switching it over is optional.

## Code character (why this is not U1)

- Pure assembly: no runtime library, no `push bp; mov bp,sp` frames, no compiler idioms.
- A close transliteration of the Apple II 6502 code: `stc; cmc; sbb` (6502 SEC/SBC carry),
  byte arithmetic, "zero page" variables at low DS offsets (cursor at DS:2E/2F, etc.), strings
  terminated with 0x8D (high-bit CR) and printed with `and al,7Fh`, the add-with-carry random
  generator at 5217 over a 6-byte seed at DS:023F (seeded from the BIOS tick count at 0100).
- Strings are inline after `call 4FDF` (ASCIIZ, printed from CS, returns past the string;
  334 calls). `call 52CA` is followed by 8 bytes of inline parameters. No other routine was
  found that inspects its return address, but check new ones as code is understood.
- Commands are dispatched through a 26-word jump table at CS:0730 (`jmp bx` at 0A2E, A-Z).
  That is the only indirect branch.
- String tables in CS: 4C60 (terrain names, read by 508C "print the n-th string"), 16BC (pub
  tips), 1B6A (oracle verses), both loaded with `lea ax,cs:[...]`. Bitmaps/tables in CS at
  2798, 48CD-4A1C, 5288, 620D, 6CAC, 7012. DS:05B0+ is a word table, DS:0AA4+ CGA tile bitmaps.
- Self-modifying / CS variables: 46 writes to CS (list from tools/refs.py), mostly patching the
  digits of the inline FCB file names ("MAPXFF  ", "MONXFF  ", "TLKXFF  " at 22B6-2357) and work
  variables at 4F04, 5C90, 5DA1, 6990-6998.
- DOS 1.x style: FCB file I/O (int 21h AH=0F/10/1A, few calls); BIOS video int 10h (mode 1
  text, mode 4 CGA only), keyboard int 16h, timer int 1Ah, PC speaker (in/out 61h, 42h/43h at 5CED).
- CPU-speed dependent delay loops (e.g. 0711). 06AC, which seems to have been a timing calibration, now
  just does `mov word [74h],0FFh; ret`.
- **The 1989 release looks binary-patched over the 1983 build:** dead islands of code that nothing
  references remain (04A8 loads "PICCAS", a file the release does not have; 06B3 is the left-over
  tail of the old 06AC; also 3116, 5380, 5CED, 5E56, 5F0D). They must stay as bytes (or as dead
  code labelled as such). A copy of the 1983 Sierra PC release would show what Origin changed.

### Assembler fingerprints

- Forward `jmp` without SHORT assembled as `EB xx 90` (113 cases): MASM's two-pass reservation.
  The generator emits these as `jmp L` and lets MASM recreate the NOP.
- reg,reg moves in the "to register" form (8B/8A/03/0A...), 83 /x with sign-extended imm8.
- 16-bit displacements for small DS offsets (`mov al,[di+0076h]` = `8A 85 76 00`, 19 places).
  MASM does that for **named variables** (relocatable offsets), so those offsets were variable
  names in the source: a free hint for symbol recovery.
- `lea ax,cs:[16BCh]` keeps a 2E prefix that MASM 3/4 drop. Either another assembler (IBM MASM
  1.0 / MS MASM 1.x, 1983) or the prefix was written explicitly. Not resolved; MASM 3.00 and
  MASM 4.00 both reproduce everything else.

## Toolchain

- MASM 3.00 and MASM 4.00 both assemble the source with no errors and give the same object for
  the image. MASM 3.00 has 12 KB of symbol space free with ~900 labels; a fully labelled source
  (thousands of labels) may need MASM 4.00 or splitting into modules.
- LINK 2.40, 3.00 and 3.05 all give the same EXE: 512-byte header, min 0000 max FFFF (same as
  the original), CS:IP 0000:0100, SS:SP 0000:0000, checksum 09DD, "Warning: no STACK segment".
- Command lines that work in DOSBox: `LINK U2;` and `LINK @LINK.RSP` (build.py's, with /M for a
  map). The form `LINK U2.OBJ,U2.EXE,NUL,NUL;` silently writes nothing.
- `tools/setup.py` unpacks MASM 3.00/LINK 3.00 (from the u6 floppy image) and MASM 4.00/LINK
  3.05 (from the MASM 4.0 archive in u1/tools) into `build/tc`; they are byte-identical to
  u1's copies. DOSBox: `gamedata/DOSBOX/DOSBox.exe`. Python with capstone: on Karl's machine
  `../u1-decompiled/build/venv/Scripts/python.exe`. Nothing was installed.

## Repository

Git repo (master), working directly in `C:\Users\karl9\Downloads\Claude\u2-decompiled\`.
`.gitignore` keeps out `gamedata/`, `build/` and archives; `.gitattributes` keeps `*.ASM` CRLF.

| file | what |
|---|---|
| `src/U2.ASM` | the game, the source of truth (frozen 2026-11-09 from gen.py's output; edit by hand) |
| `src/u2.lnk` | link order, one module per line (just U2.ASM until the split) |
| `tools/build.py` | assemble each module (MASM 3.00, listing), LINK 3.05 with map, postlink, check the sha1 of the whole file; exediff on a mismatch. Output in `build/u2/` |
| `tools/postlink.py` | the envelope step (see above); also usable as a script `postlink.py BUILT ORIG` |
| `tools/dos.py` | headless DOSBox (C: = workdir, D: = build/tc or `$TC`), shared with u1 |
| `tools/setup.py`, `fat12.py` | toolchain unpacking (fat12 from u1) |
| `tools/exediff.py` | header/relocation/image comparison (from u1) |
| `tools/gen.py` | recursive disassembly (inline-string calls, jump table) -> one MASM file: CODE `ORG 100h` + DATA PARA; labels `Lxxxx` for every branch target; each line tagged `;@addr`; instructions MASM can't reproduce or that are in the force file become `db`. Writes `U2.ins` (instruction starts) |
| `tools/regen.py` | the loop gen -> MASM -> LINK -> compare image, adding size-mismatched lines to the force file (formerly build.py). `regen.py [WORKDIR] [MASM3/MASM4]`, default `build/regen`; one pass reproduces `src/U2.ASM` exactly |
| `tools/U2.force` | the 22 addresses the loop forced (seed for regen.py) |
| `tools/rdis.py` | coverage report: code / inline data / unreached gaps, indirect branches |
| `tools/dis.py`, `refs.py`, `data.py`, `scan.py`, `stats.py` | disassemble ranges; find references and CS writes; data-segment map and envelope comparison; header/strings scan; call and DOS-call statistics (each takes the EXE path) |

Build:

```sh
PY=../u1-decompiled/build/venv/Scripts/python.exe   # any Python 3; capstone only for gen/dis tools
$PY tools/setup.py      # once
$PY tools/build.py      # -> "IDENTICAL to the GOG release", exit 0
```

Coverage of the code segment: 20.4 KB as instructions, 6 KB inline/table data, ~3 KB
unreached (string tables, bitmaps, dead code). All of it is reproduced, as `db` where not code.

## Next steps (in order)

Done in session 2: repository, path-independent tools, post-link step with whole-file sha1
check, frozen source. From here on: edit `src/U2.ASM` by hand and run `tools/build.py` after
every change.

1. **Make it relocatable** (so code can be edited without moving everything): every absolute
   address must become a symbol.
   - DS operands: create `D_xxxx` labels in the DATA segment (`ASSUME DS:DATA`) and refer to
     them by name. Use the 19 disp16 sites as named variables; this also removes their `db`.
   - CS addresses used as data (`lea ax,cs:[16BCh]`, `cs:[di+4C60h]`, the 0730 table, the
     self-modifying writes): labels in CODE, `dw Lxxxx` for the jump table.
   - Look at each remaining `db`-forced instruction (104) and decide its real form.
   - Test: insert a NOP at the start and check the game still runs (the U4/U6 projects
     did this kind of check).
2. **Split into modules** by subsystem once the source is relocatable: title/demo (0100-06xx),
   command loop and commands (0730 table), towns/shops/pub/oracle text, dungeon/tower view,
   space/hyperwarp (69F0-71xx), character generation (5400-5A61), print/keyboard/sound/video
   support (4A1C-53F8, 5C95-6000), endgame (7240-740B). Parallel agents can each take a
   disjoint range (the U1 method).
3. **Readable pass**: names and comments. References: the Ultima_2_manual.pdf here, the Apple
   II version's disassemblies/knowledge, existing U2 file-format docs (maps, monsters, PLAYER),
   and the abedegno Exhume skills (`../underworld-exhumed-enhanced/exhume/`: readability-pass,
   syncnames.py), as noted in U1's handoff.
4. Optional: a port (the u4/u6 `port` directories are models). The speed-dependent delay
   loops and FCB I/O are what a port must replace.

## Loose ends / questions

- Which assembler did Sierra/Origin use? The 2E prefix on LEA hints at something older than
  MASM 3. MASM 1.x/2.x or IBM MASM 1.0 disks would settle it (and might remove some `db`s).
- Is the 1989 EXE a 1983 build patched in binary, or reassembled from patched source? The dead
  islands point to binary patches; a 1983 Sierra release image would answer this.
- The envelope's encrypted 0x20E bytes were not decrypted (the per-EXE key is unknown; the
  two keys differ by 0xEF). Not needed for the rebuild.
- GOG's launcher text says "Ultima 1" (copy-paste in dosboxULTIMA2_single.conf). Irrelevant.
