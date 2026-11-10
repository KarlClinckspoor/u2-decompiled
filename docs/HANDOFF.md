# Handoff: Ultima II decompilation (u2-decompiled)

State as of 2026-11-09, after the second session (repository, envelope step, relocatable
source, split into 19 modules, names and comments). Read this first, then docs/NAMING.md
(conventions) and docs/FINDINGS.md (what the code revealed: bugs, mechanics, patches). The sister project `../u1-decompiled` (docs/HANDOFF.md, MAP.md,
MATCHING.md) is the model for conventions.

## Headline

**ULTIMAII.EXE rebuilds byte-identical as a file** (37344 bytes, sha1 6efae26c…) from
**19 modules in `src/`** (one per subsystem plus one for the data, linked in the order of
`src/u2.lnk`) with `python3 tools/build.py`: MASM 4.00 (or MASM 3.00: `ASM=MASM3`, same file)
+ LINK 3.05 in one DOSBox run, then `tools/postlink.py` adds the envelope remains from gamedata.

**The source is relocatable**: every address in it is a symbol (`Lxxxx` in CODE, `D_xxxx` in
DATA, BSS buffers and the stack as `D_END+n`), so code and data can be inserted, removed or moved.
`tools/shift.py` proves it statically (padding inserted at the start of the code, or of any
module, and of the data: every one of the 4585 symbolic lines moves by the right amount,
nothing else changes). Shifted builds were played in DOSBox (single module: code +17 / data
+300; split: +33 bytes at the start of MAIN / data +9): title, the whole demonstration (town, 3D
dungeon, space), character generation and save, loading the save, world map, walking, status
screen; same behaviour as the identical build. Only one instruction is still `db` (5D31,
`cmp bx,0FFFFh` in the long 81 form, which MASM can't produce; it's a constant). `src/` is the
source of truth, edited by hand. Unlike U1 there is no C at all: the whole game is hand-written
8086 assembly.

**Named and commented**: every module has an overview, every routine a header (what it does,
in, out, registers), and inline comments; 1032 symbols carry real names (`PrintInline`,
`MainLoop`, `CmdAttack`, `PlayerX`, `HitPointsHi`, `MonsterHP`, `TilePtrTbl`, ...), following
docs/NAMING.md. 188 local branch targets keep their `Lxxxx` names on purpose (plain "next part"
labels); `tools/syms.py` maps any name to its original address and back.

## The executable

GOG release, one program: `gamedata/ULTIMAII.EXE`, 37344 bytes,
sha1 6efae26cdaedf30426d35cf935b50e5639387cec. Title screen says "(C)-1983,1989 BY LORD BRITISH
AND ORIGIN": the 1983 Sierra PC version as reissued by Origin in 1989.
Other game files (not code): MAPG*/MAPX* (maps, 4096/4224 bytes), MONG*/MONX*/MONSTERS (monsters),
TLKG*/TLKX* (talk), PIC* (16 KB CGA screens: DNG DRA MIN OUT SPA TWN), PLAYER (384-byte save;
GOG's is empty: "P" then loops on "NO CHARACTER ON DISK", Escape only retries; create one with "C").

| image range | what |
|---|---|
| 0000-0100 | zeros: the source had `ORG 100h` in the code segment (LINK writes them) |
| 0100-740B | code segment (CS = load segment), entry 0100; 740B-7410 padding to the paragraph |
| 7410-8AC0 | data segment, PARA aligned, 0x16B0 initialised bytes; `mov ax,DATA` at 0100 is the only relocation (0000:0101) |
| 8AC0-8AE0 | envelope stub (header CS:IP 08AC:0000): sets SS=load seg, SP=0, RETFs to load:0100 |
| 8AE0-8FE0 | envelope tail, 0x500 bytes |

At run time the program sets DS = load+0741h, SS = DS+0310h, SP = 0100h. DS memory map:

| DS offset | what |
|---|---|
| 0000-058F | variables ("zero page" style: cursor at 2E/2F, random seed at 023F, FCB at 0245, ...) |
| 05B0-062F | 64 pointers to the 0x42-byte records at 0630-166E (TilePtrTbl, `dw TileBmpNN`; read at 4AC7, and through CS at 4AE7/4AF2) |
| 0630-16AF | those records, then other tables |
| 16B0-17FF | BSS (`D_END`), not in the file |
| 1800-27FF | map buffer (pointer MapBufPtr, files MAPxxx, 0x1000 bytes) |
| 2800-28FF | talk buffer (pointer TalkBufPtr, TLKxxx, 0x100) |
| 2900-30FF | monster buffer (pointer MonsterBufPtr, MONSTERS/MONxxx, 0x800) |
| 3100-31FF | stack (SS = DS+0310h, SP = 0100h) |

Header: 512-byte header, min 0000 max FFFF, SS:SP 09FE:0064, invalid checksum (sum B98D,
stored EA36).

### The envelope = the same one as U1's ULTIMA.EXE

The tail after the stub is the same as U1 ULTIMA.EXE's: its first 0x20E bytes are the same
content XOR a per-EXE key (the two differ by a constant 0xEF), the bytes to 0x2F7 are identical,
then zeros. Both are remnants of a removed 1989 protection/loader envelope. The pre-envelope
header must have been CS:IP 0000:0100, SS:SP 0000:0000 (no stack segment), which is exactly what
LINK produces from our source.

`tools/postlink.py` appends stub + tail from gamedata at build time, sets CS:IP 08AC:0000, SS:SP
09FE:0064 and the checksum EA36 (pages/last-page follow from the length). The U2 envelope also
**moved the relocation table**: LINK writes relo=001E with a word 0001 at 001C and the one entry
(0000:0101) at 001E; the original has relo=001C and the entry at 001C (the 0001 word is gone).
U1's ULTIMA.EXE kept LINK's layout. The tool lays the header out again when the offsets differ,
and refuses unless the relocation entries, the other header fields and the resulting header all
equal the original's. Never commit the envelope bytes.
The same tool rebuilds U1's ULTIMA.EXE identical too (checked by relinking u1's objects in a
scratch directory). U1 still has its own `src/ultima/postlink.py` (no checksum or relocation
handling, which it doesn't need); switching it over is optional.

## Code character (why this is not U1)

- Pure assembly: no runtime library, no `push bp; mov bp,sp` frames, no compiler idioms.
- A close transliteration of the Apple II 6502 code: `stc; cmc; sbb` (6502 SEC/SBC carry),
  byte arithmetic, "zero page" variables at low DS offsets, strings terminated with 0x8D
  (high-bit CR) and printed with `and al,7Fh`, the add-with-carry random generator at 5217 over
  a 6-byte seed at DS:023F (seeded from the BIOS tick count at 0100), `daa`/`das` for BCD
  counters (78 of them).
- Strings are inline after `call 4FDF` (ASCIIZ, printed from CS, returns past the string;
  334 calls). `call 52CA` (file loader) is followed by an 8-byte inline file name. No other
  routine was found that inspects its return address, but check new ones as code is understood.
- Commands are dispatched through a 26-word jump table at CS:0730 (`jmp bx` at 0A2E, A-Z).
  That is the only indirect branch.
- Segments: DS = DATA throughout (except 5354, where it is B800 for one DTA call when loading a
  PIC file). ES = 40h at startup, then video segments from the CS table at 48DC (B800/BA00), or
  DS/CS around 154F. So a DS operand is a data address, a cs: operand a code address, an es:
  operand video memory or BIOS data.
- String tables in CS: 4C60 (terrain names, read by 508C "print the n-th string"), 16BC (pub
  tips), 1B6A (oracle verses), 5288; loaded with `lea ax,cs:[...]`. Bitmaps/tables in CS at
  2798, 48CD-4A1C (48D0/48D4 masks, 48DC video segments), 5D9B (sound values), 620D, 6CAC, 7012.
- Self-modifying / CS variables: 46 writes to CS (list from tools/refs.py), mostly patching the
  digits of the inline FCB file names ("MAPXFF  ", "MONXFF  ", "TLKXFF  " at 22B6-2357) and work
  variables at 4F04, 5C90, 5DA1, 6990-6998.
- DOS 1.x style: FCB file I/O (int 21h AH=0F/10/1A/27); BIOS video int 10h (mode 1 text, mode 4
  CGA only), keyboard int 16h (input routine 4F4D, Escape = FF1B), timer int 1Ah, PC speaker
  (in/out 61h, 42h/43h at 5CED).
- CPU-speed dependent delay loops (e.g. 0711). 06AC, which seems to have been a timing calibration, now
  just does `mov word [74h],0FFh; ret`.
- **The 1989 release looks binary-patched over the 1983 build:** dead islands of code that nothing
  references remain (04A8 loads "PICCAS", a file the release does not have; 06B3 is the left-over
  tail of the old 06AC; 0778 "(INSERT PLAYER DISK)" + wait for Escape, jumped over by the
  `jmp short` at 0776; also 3116, 5380, 5CED, 5E56, 5F0D). They stay as bytes (or as dead code
  labelled as such). A copy of the 1983 Sierra PC release would show what Origin changed.

### Assembler fingerprints

- Forward `jmp` without SHORT assembled as `EB xx 90` (113 cases): MASM's two-pass reservation.
  The generator emits these as `jmp L` and lets MASM recreate the NOP.
- reg,reg moves in the "to register" form (8B/8A/03/0A...), 83 /x with sign-extended imm8.
- 16-bit displacements for small DS offsets (`mov al,[di+0076h]` = `8A 85 76 00`, 18 places).
  MASM does that for **named variables**, and written as `D_0076[di]` they assemble exactly:
  those offsets were variable names in the source. 8-bit displacements (`[di+6]`, 9 places)
  were numbers.
- `lea ax,cs:[16BCh]` keeps a 2E prefix that MASM 3/4 drop (3 places: 16A8, 1B56, 527F).
  Written as `db 2Eh` + `lea ax, L16BC`. Either another assembler (IBM MASM 1.0 / MS MASM 1.x,
  1983) or the prefix was written explicitly. Not resolved.
- `cmp bx,0FFFFh` at 5D31 in the long form (81 FB FF FF): MASM 3/4 always pick 83 FB FF.

## How the source is laid out

### Modules (src/u2.lnk order; boundaries chosen with tools/cuts.py)

| module | original addresses | what |
|---|---|---|
| START | 0100-0730 | startup (`ORG 100h`, entry `L0100`), title screen and demonstration, delay loops |
| MAIN | 0730-0E70 | command jump table (A-Z), game start, the outdoor main loop and movement |
| EVENTS | 0E70-154E | monster attacks and spells, darkness and torches, random events |
| SHOPS | 154E-2028 | towns: pub (tips), temple, oracle, armour and weapon shops, transport |
| INPUT | 2028-2290 | number and money entry, "illegal command"; monster movement (step toward/away, may it enter a tile, move) |
| LOAD | 2290-2362 | loading the map, monster, talk and player files |
| MOVE | 2362-26F9 | moving (pass, north/south/east/west), force fields, saving the player |
| DUNGEON | 26F9-2B65 | the dungeon and tower loop: advance, turn, retreat, traps |
| CMDAL | 2B65-3B92 | commands A-L |
| CMDMZ | 3B92-48CD | commands M-Z; the status screen (Z) |
| SCREEN | 48CD-4C60 | video tables (CGA segments, masks), clearing, tiles and pixels |
| TEXTIO | 4C60-5400 | terrain names; keyboard, text output, numbers, random numbers, file I/O |
| CHARGEN | 5400-5AB1 | character generation |
| MAPVIEW | 5AB1-5C90 | drawing the outdoor/town map window (tile caches TileCache/TileCacheShown) |
| SOUND | 5C90-6000 | PC speaker sounds (SoundOff, toggled by Ctrl-S) |
| VIEW3D | 6000-6999 | the 3D dungeon and tower view, line drawing (67B3) |
| SPACE | 6999-7242 | space flight: fuel, hyperwarp, planets |
| ENDGAME | 7242-740B | the end of Minax and the end of the game |
| U2DATA | (7410-8AC0) | the DATA segment: variables, tables, tile bitmaps |

The module names describe what the strings and a quick read show. Every module has 42-49 KB of MASM symbol space free.

### Conventions (tools/gen.py wrote them, tools/split.py cut the result)

- Each module starts `CODE SEGMENT BYTE PUBLIC / CODE ENDS` (keeps CODE first in the link), then
  `DATA SEGMENT PARA PUBLIC` with the data EXTRNs (or, in U2DATA, the data itself), then
  `CGROUP GROUP CODE, DATA`, then the CODE part with its EXTRNs and PUBLICs.
  `ASSUME CS:CODE, DS:DATA`. BYTE alignment makes the CODE pieces join without gaps; LINK pads
  the end of the code to the paragraph where DATA starts (740B-7410), as in the original.
- Cross-module references: `EXTRN Lxxxx:NEAR` (code label), `:BYTE` (`label byte`: CS data,
  D_ variables), `STACK_PARA:ABS`; the defining module says `PUBLIC`. An alias equate
  (`MapBufPtrHi equ byte ptr MapBufPtr+1`) is copied into the modules that use it.
- **An 8-bit branch (jcc, short jmp, loop, jcxz, and MASM's forward `jmp` = EB xx 90) must not
  cross a module boundary**: MASM has no 8-bit external reference and would make it a 3-byte
  E9 (or refuse). tools/cuts.py lists where cuts are allowed; split.py checks it.
- DATA: `D_START` (offset 0, must stay the first line), `Name label byte` at every offset a
  DS operand names (gen.py called them D_xxxx after the offset; now named, with a note each),
  `dw TileBmpNN` for the pointer table TilePtrTbl,
  `dw D_END+150h` etc. for the BSS buffer pointers, `D_END` at the end, then
  `STACK_PARA equ (D_END-D_START+1A50h+15)/16`, the paragraphs of data + BSS + buffers (startup:
  `add ax, STACK_PARA` makes SS). BSS buffers are D_END+150h (map), +1150h (talk), +1250h
  (monsters). `MapBufPtrHi equ byte ptr MapBufPtr+1` is the one label inside a pointer word.
- CODE: `Name:` at branch targets, `Name label byte` at CS data (gen.py called them Lxxxx;
  local "next part" labels still are); a cs: operand into the middle of an instruction is
  `Name+n`. The two cs: reads of the data (4AE7/4AF2, in SCREEN)
  are `cs:CGROUP:TilePtrTbl` between `ASSUME CS:CGROUP` and `ASSUME CS:CODE`: an offset relative to
  the group, which starts with CODE, is CS-relative.
- Operands always carry `byte ptr`/`word ptr`; every code line ends with `;@addr`, its address
  in the original (tools rely on it; keep it on lines that still correspond to the original).
- Still numbers on purpose: 8-bit displacements, all immediates (each 16-bit one was checked:
  counts, sizes, video offsets and segments, key codes, sound parameters), es: operands.

## Toolchain

- **MASM 4.00** builds it by default; **MASM 3.00** gives the identical file (`ASM=MASM3
  python3 tools/build.py`). Before the split, MASM 3.00 ran out of memory on the single file
  (~1220 labels) and MASM 4.00 had only ~8 KB left; now each module has 42 KB+ free.
- MASM 4.00 quirks seen in DOSBox: a source line longer than its limit (a 1160-character `db`)
  makes it **silently drop everything after it** (no error, CODE comes out empty); writing a
  listing of some `db n dup (...)` lines makes it **exit silently without an object**. build.py
  writes no listing by default and checks that every module produced an object; shift.py checks
  the image length. split.py keeps EXTRN/PUBLIC lines to 6 names.
- A GROUP needs a segment register assumed to it: `cs:CGROUP:x` under `ASSUME CS:CODE` is
  error 68 "Can't reach with segment reg", hence the local `ASSUME CS:CGROUP`.
- LINK 2.40, 3.00 and 3.05 all give the same EXE: 512-byte header, min 0000 max FFFF (same as
  the original), CS:IP 0000:0100, SS:SP 0000:0000, checksum 09DD, "Warning: no STACK segment".
- Command lines that work in DOSBox: `LINK U2;` and `LINK @LINK.RSP` (build.py's, with /M for a
  map). The form `LINK U2.OBJ,U2.EXE,NUL,NUL;` silently writes nothing.
- `tools/setup.py` unpacks MASM 3.00/LINK 3.00 (from the u6 floppy image) and MASM 4.00/LINK
  3.05 (from the MASM 4.0 archive in u1/tools) into `build/tc`; they are byte-identical to
  u1's copies. DOSBox: `gamedata/DOSBOX/DOSBox.exe`. Python with capstone: on Karl's machine
  `../u1-decompiled/build/venv/Scripts/python.exe`. Nothing was installed.
- `tools/dis.py` was renamed `disrange.py`: in tools/ it shadowed the standard library's `dis`,
  which capstone imports.

## Repository

Git repo (master), working directly in `C:\Users\karl9\Downloads\Claude\u2-decompiled\`.
`.gitignore` keeps out `gamedata/`, `build/` and archives; `.gitattributes` keeps `*.ASM` CRLF.

| file | what |
|---|---|
| `src/*.ASM` | the game in 19 modules (table above), the source of truth: edit by hand |
| `src/u2.lnk` | link order, one module per line |
| `tools/build.py` | assemble each module (MASM 4.00, or `ASM=MASM3`), LINK 3.05 with map, postlink, check the sha1 of the whole file; exediff on a mismatch. Output in `build/u2/`. `build.link(dir, edit)` is the reusable part |
| `tools/shift.py` | relocation test: `shift.py [--code N] [--data M] [--at MODULE]` builds with padding inserted at the start of the code (or of MODULE) and of the data, and checks that only addresses moved; leaves a runnable `build/shift/ULTIMAII.EXE` |
| `tools/play.py` | play a build in a DOSBox window with GOG's settings (CGA, 500 cycles), using a copy of the game files under build/ (`play.py [EXE] [--dir DIR]`) |
| `tools/sprites.py` | draws the 64 map tiles (from src/U2DATA.ASM) and the dungeon monster shapes (from gamedata/MONSTERS) to `build/sprites/*.png`, with the identified names in its docstring |
| `tools/postlink.py` | the envelope step (see above); also usable as a script `postlink.py BUILT ORIG` |
| `tools/dos.py` | headless DOSBox (C: = workdir, D: = build/tc or `$TC`), shared with u1 |
| `tools/setup.py`, `fat12.py` | toolchain unpacking (fat12 from u1) |
| `tools/exediff.py` | header/relocation/image comparison (from u1) |
| `tools/u2an.py` | shared analysis: recursive disassembly (inline-string calls, jump table) and operand facts (effective segment, displacement size) |
| `tools/cuts.py` | where module boundaries are allowed (no 8-bit branch across), with a map of function starts, callers, command letters and first strings |
| `tools/split.py` | cuts a single-module source into modules with EXTRN/PUBLIC (module table inside); it made src/ from gen.py's output (before the names and comments) |
| `tools/syms.py` | symbol table worked out from the source: `syms.py NAME|ADDR` looks up, `--refs NAME` lists uses; also a module for the other tools |
| `tools/rename.py` | renames symbols in all modules at once from a map (`OLD NEW` lines), checking MASM's rules; re-wraps comments and EXTRN/PUBLIC lines that get too long |
| `tools/lint.py` | CRLF line ends, line length, `;@` tags; `--code-unchanged REV` proves only comments changed |
| `tools/gen.py` | generates the relocatable single-module source from the EXE (conventions above); instructions MASM can't reproduce or listed in the force file become `db`. Writes `U2.ins` (instruction starts). For re-deriving pieces, never to overwrite src/ |
| `tools/regen.py` | the loop gen -> MASM -> LINK -> compare image, adding size-mismatched lines to the force file. `regen.py [WORKDIR] [MASM4/MASM3]`, default `build/regen` |
| `tools/U2.force` | 5D31, the one instruction MASM can't encode (seed for regen.py) |
| `tools/rdis.py` | coverage report: code / inline data / unreached gaps, indirect branches |
| `tools/disrange.py`, `refs.py`, `data.py`, `scan.py`, `stats.py` | disassemble ranges; find references and CS writes; data-segment map and envelope comparison; header/strings scan; call and DOS-call statistics (each takes the EXE path) |

Build and check:

```sh
PY=../u1-decompiled/build/venv/Scripts/python.exe   # any Python 3; capstone for gen/shift/analysis tools
$PY tools/setup.py      # once
$PY tools/build.py      # -> "IDENTICAL to the GOG release", exit 0
$PY tools/shift.py      # -> "OK: only addresses moved"; also e.g. --at TEXTIO --code 7, --code 291 --data 0
$PY tools/play.py build/shift/ULTIMAII.EXE --dir build/play_shift   # play the shifted build
```

In DOSBox, send real key presses (computer-use `key`), not typed text: SDL reads scancodes.

Coverage of the code segment: 20.4 KB as instructions, 6 KB inline/table data, ~3 KB
unreached (string tables, bitmaps, dead code). All of it is reproduced, as `db` where not code.

## Next steps (in order)

Done in session 2: repository, path-independent tools, post-link step with whole-file sha1
check, relocatable source with static and runtime relocation tests, split into 19 modules,
names and comments (eight parallel agents commented disjoint modules and proposed names; the
proposals were merged and applied in one rename). From here on: edit `src/*.ASM` by hand, run
`tools/lint.py` and `tools/build.py` after every change that should keep the file identical, and
`tools/shift.py` (with `--at` the module you touched) after changes to how addresses are
written. Rename only with `tools/rename.py`. Moving code between modules: keep 8-bit branches
inside one module and add the EXTRN/PUBLIC lines.

1. **Finish the readable pass**. Done: VIEW3D's coordinate table is 16 named rows (ViewXL ...
   ViewChestTopY, read as `ViewXL[di+2]`); every monster tile and dungeon kind is identified
   (docs/FINDINGS.md, "Who the monsters are"; `tools/sprites.py` draws them). Left: the few
   open questions at the end of FINDINGS; name the remaining 161 `Lxxxx` labels where a name
   helps; check the comments against play where they say "?".
2. Try the findings in play. Done in DOSBox: the Ctrl-Right hang, the character-generation race
   bug, the pub's fixed tip, the Ready and Wear BCD limits, the class/race bonuses, the ladder
   spells (they check the square behind the player; Up Ladder can land you inside a wall).
   Unlock's sideways-only check was settled from the maps (no door needs north/south). Not
   checkable by playing: Magic Missile's extra point (monster hit points are never shown),
   Steal's alarm on a stale slot; these and the other reading-only bugs would need a debugger
   or a memory dump. Items for a test (spells, armour, wand, torches) can be set in the PLAYER
   record too (file offset = the D address from `syms.py` minus 36h). Test trick: a character can be placed anywhere by editing
   SurfaceX/SurfaceY (bytes 24h/25h) of the PLAYER file in the play directory, never in gamedata/.
   The game empties the keyboard buffer on every key: send keys about 0.8 s apart.
3. Optional: a port (the u4/u6 `port` directories are models). The speed-dependent delay
   loops and FCB I/O are what a port must replace.

## Loose ends / questions

- Which assembler did Sierra/Origin use? The 2E prefix on LEA and the long-form `cmp` at 5D31
  hint at something older than MASM 3. MASM 1.x/2.x or IBM MASM 1.0 disks would settle it.
- Is the 1989 EXE a 1983 build patched in binary, or reassembled from patched source? The dead
  islands point to binary patches; a 1983 Sierra release image would answer this.
- The envelope's encrypted 0x20E bytes were not decrypted (the per-EXE key is unknown; the
  two keys differ by 0xEF). Not needed for the rebuild.
- shift.py can't see an address still written as a number (it looks like a constant in both
  builds); the play tests covered the main paths but not every command, towns' talk, combat or
  the endgame.
- GOG's launcher text says "Ultima 1" (copy-paste in dosboxULTIMA2_single.conf). Irrelevant.
