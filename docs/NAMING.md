# Naming and commenting conventions

How the source in `src/` is named and commented. The rules exist so that names never change the
bytes (`tools/build.py` must stay IDENTICAL) and so that the tools keep working.

## Hard rules (the tools enforce or rely on these)

- **Rename only with `tools/rename.py MAP`.** It renames a symbol everywhere at once (its
  definition, EXTRN/PUBLIC lines, every use, and mentions in comments) and refuses invalid
  names. Map lines are `OLD NEW ; optional note`.
- A name: letters, digits, `_`; not starting with a digit; **at most 31 characters** (MASM
  ignores the rest); **unique ignoring case** (MASM ignores case); not a MASM reserved word
  (instruction, register, directive or operator: `loop`, `length`, `name`, `size`, `type`,
  `mask`, `width`, `str`, `out`, `stack`, `page`, `title`, `label`, `seg`, `offset` ...).
- **Every code line keeps its `;@ADDR` tag as the last thing on the line.** An inline comment
  goes between the instruction and the tag: `	mov al, byte ptr Food	; low byte	;@1234`.
  Comment lines (starting with `;`) and blank lines carry no tag.
- **Lines at most 120 characters.** (MASM 4.00 silently drops everything after an over-long line.)
- Never change an instruction, a `db`/`dw` value, a label's position, a segment line, EXTRN /
  PUBLIC lines (rename.py maintains those) or the `ASSUME` lines.
- `D_START` and `D_END` keep their names (tools use them); `STACK_PARA`, `CGROUP`, `CODE`,
  `DATA` stay.

## Style

MASM ignores case; write names in CamelCase for reading.

| what | style | examples |
|---|---|---|
| routine (a `call` target) | VerbObject | `PrintInline`, `ReadKey`, `DrawTile`, `LoadMapFile` |
| command handler (jump table at 0730) | `Cmd` + command | `CmdAttack`, `CmdBoard`, ..., `CmdZtats` |
| other entry points / big blocks | descriptive | `MainLoop`, `GameStart`, `DungeonLoop` |
| label inside a routine | `Routine_What` (shorten the routine part if needed) | `PrintInline_Loop`, `Attack_Miss`, `Rnd_Done` |
| CS tables and CS variables | noun, `Tbl` for tables | `TerrainNameTbl`, `CgaRowSegTbl`, `FcbMapName`, `SoundPortSave` |
| DS variables | noun, what it holds | `CursorCol`, `CursorRow`, `RandSeed`, `PlayerHP`, `Food` |
| DS tables / arrays | plural or `Tbl` | `TilePtrTbl`, `TileBitmaps`, `MonsterHP` |
| BSS buffer pointers | `...Ptr` | `MapBufPtr`, `TalkBufPtr`, `MonsterBufPtr` |
| dead code (nothing reaches it) | `Dead_` + what it was | `Dead_LoadPicCas`, `Dead_InsertPlayerDisk` |

- Every label has a name, local branch targets included: name a new one for what happens there
  (`_Next`, `_Done`, `_Loop`, `_CheckY`), and in a chain of compares for the test it starts
  (`_TryArms`). A jump that only extends a short branch's range is `_ToTarget`.
- A cs: operand into the middle of an instruction stays `Name+n`; the instruction gets a
  comment saying what is patched (self-modifying code).
- Keep the original's terms where the game has them (the manual in `gamedata/`, the strings
  the game prints): `Ztats`, `HitPoints`, `Food`, `Exp`, `Gold`, `Torches`, `Keys`,
  `Tools`, `Hyperwarp`, `XenoYakoZabo`, ...

## Comments

- **Module header**: below the existing two lines, a short overview: what the module does,
  its main entry points, the data it owns or mostly uses.
- **Routine header** before each routine (call target or table entry):

```
;------------------------------------------------------------------------------
; PrintInline: print the zero-terminated text after the call (in CS) at the
; cursor, then return past it. Bit 7 of each character is ignored; 8Dh = CR.
; In: CursorCol/CursorRow. Out: cursor advanced. Uses: AX (saves the rest).
;------------------------------------------------------------------------------
```

- Inline comments where the meaning is not obvious from the names: what a value means
  (`cmp al, 2Eh ; '.' = open floor?`), the 6502 idioms (`stc/cmc/sbb` = SEC/SBC), file and
  BIOS/DOS calls, self-modifying writes, speed-dependent delays.
- Say what you don't know: `; ?` or "probably", rather than guessing silently.
- English, short, no ASCII art beyond the routine rule lines.
