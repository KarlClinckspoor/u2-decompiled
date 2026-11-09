# Findings about the original program

What reading the code turned up (the comment pass of 2026-11-09). Addresses are the original's;
`python3 tools/syms.py ADDR` gives the current name. Items marked **Checked in play** were
reproduced in DOSBox with the rebuilt EXE (GOG settings, `tools/play.py`) on 2026-11-09; the rest
are found by reading only.

## Bugs in the original

- **Ctrl-Right at the default speed** (ReadKey, 4F8E): SpeedSetting = 00FFh minus 200h wraps
  to FEFFh, which passes the unsigned check; CalcDelayTbl's `div` then overflows (divide error,
  likely a crash) or the delays become huge. Ctrl-Left's 3A00h limit looks chosen to avoid the
  same overflow. **Checked in play**: at the default speed, one Ctrl-Right and the game hangs
  for good (DOSBox's divide-error handler returns to the faulting `div`); twice reproduced, with
  normal steps working just before.
- **Ready and Wear** compare a binary n*8 with a BCD agility/strength: the real limits are
  08, 10, 18 ... 48 decimal-looking BCD, not 8, 16, 24. **Checked in play** (Ready): with
  agility 15 the mace (weapon 2, limit 16) readies; the axe (limit 24) gets "THOU ART NOT AGILE
  ENOUGH TO WIELD!".
- **Offer's attribute gift** (ALAKAZAM) adds 4 x the amount with no cap: an attribute can wrap
  past 99.
- **Steal's alarm** (1 in 8) makes monster Temp20 hostile, but Steal never sets Temp20.
- **Unlock** only looks east or west: doors open only sideways.
- **Character generation**: each wrong key at the TYPE prompt goes back through 5879 and takes
  another 31h off PlayerRace; Ztats then prints a garbage race. **Checked in play**: human plus
  two wrong keys saved race byte 9Eh (31h - 3 x 31h), and Ztats reads "A LEVEL 00 MALE  FIGHTER"
  with no race.
- **Dungeon Attack** (2E6A): the search loop tests AL (the field that failed) instead of the
  index, can run below entry 0, and doesn't check the slot is alive (a 6502 DEC/LDX/BNE slip).
- **Magic missile** (32C0): subtract without SEC, usually 1 hit point extra.
- **Ladder spells** (322B/325A) test the cell at LookX/LookY without setting it: after the 3D
  view that is the square behind the player.
- **Pub "BUY"**: `and al,3` then `mov al,1` throws the random tip away: a drink always gives
  tip 1. **Checked in play**: five drinks in Towne Linda's PUB DE VARG, five times "ISN'T THIS A
  GREAT GAME?". (Tipping n gold gives tip n+1 or n-1: tipping 4 three times gave tips 3, 5, 5.)
- **Dungeon key time-out**: a 16-bit DI where the 6502 had an 8-bit Y: 255 then 65536 rounds.
- **Monster search** (23E6) doesn't wrap at the map edge and never checks slot 0; town
  wanderers never step into the player's row or column (x and y tested separately).
- **The horse/plane test for the time door** (265E) can never be true.
- **Dungeon damage** (1382) adds two non-BCD values and subtracts them with `das`.
- **Counts wrap**: buying food, spells, armour or weapons never checks the BCD byte (99 -> 00).
- **Sound wrappers** (5E3B, 5EAC, 5ED7, 5EF2) return with BP changed; 5E83's last note has
  divisor 0 (an 18 Hz buzz).
- **Escape during a title/demo wait** leaves a word on the stack (0696).
- **Wear's "NOT OWNED!"** has no error beep (Ready's has); Magic doesn't check the spell is
  owned (Cast does).

## Game mechanics

- MapType (D_004A): 0 surface, 1 village, 2 towne, 3 castle, 4 tower, 5 dungeon. TimeZone
  (D_0049): Earth's time zone 0-4 (or the planet elsewhere?). The two are the digits of the
  MAP/MON/TLK file names; Planet (D_006D): 0 Earth, 1-8 Mercury..Pluto, 9 planet X, 0Ah deep
  space.
- Character bonuses: female charisma +10, male strength +5; elf agility +5, dwarf strength +5,
  human intelligence +5, hobbit wisdom +10; fighter strength +15, cleric wisdom +10, wizard
  intelligence +10, thief agility +10. Fighter +15 and hobbit +10 differ from the manual (+10,
  +5); male +5, human +5 and fighter +15 checked in play. The name is at most 12 characters.
- The monster table: 8 arrays of 32 bytes from MonsterX (x, y, hit points, tile, tile under or
  dungeon level, mood/talk, step dx, dy) = the MONxx file image. Slot 0 is unused outdoors; a
  monster can spawn on the player's square.
- Dungeons/towers: 16 levels of 16x16 cells, one 256-byte page each. Cell bits: 80h wall,
  C0h door, E0h secret door (drawn as wall, passable), 20h/10h ladder down/up, 40h chest, low 3
  bits the monster kind. Only the nearest monster is drawn; beyond distance 1 a generic shape.
  LightTurns (D_0026) = torch/Light turns left (150); the view is drawn only while it is
  nonzero. Traps happen only when a random byte is below the level (never on level 0); without
  tools a trap kills.
- Shops by map quarter (x/y below or above 20h): in a towne weapons, armour, pub, transport;
  elsewhere oracle, food, wizard, cleric. Prices: CalcPrice, lowered by intelligence + charisma.
- Movement costs: walking 1 delay and 0.19 food per step, horse 2 delays and 0.38 (slower than
  walking), plane 1 delay and 0.38, frigate free. A gremlin takes 100 food; below 0 is death.
- In town and dungeon areas each round of hits costs an extra MapType hundred hit points
  (0C09): why guards are so deadly.
- Board needs a blue tassle (frigate), a skull key (plane), an ankh (rocket); launching the
  plane needs a brass button, the rocket tri-lithium. Landing the rocket anywhere but grass
  kills. Spells work only in dungeons and towers; Prayer is a 50% Kill.
- Space: after a hyperwarp, if the remaining BCD fuel ends in 3 or 7 the ship goes off course
  (coordinates 0-7). Without reflect or power armour (WornArmour < 5) you explode after the
  launch animation. The direction keys in space only move the crosshair. Hitting the sun
  (4,4,4), exploding and the end scroll all end in `jmp $`.
- The time door moves every 8 surface turns, only on Earth (table at 2798: 5 periods x 4
  spots).
- Offer's specials (quick sword ENILNO, the ring, a random weapon, ALAKAZAM) only in map type 2
  of time zone 3; the ring also needs RingEarned (Transact, talk 81h, planet 9, map type 3).
- SpeedSetting (D_0074) is part of the PLAYER record, so the speed is saved; ToneDelay is entry
  6 of the delay table, so sounds follow the speed too.
- The 4C60 string table has 75 strings: terrain, weapons (13h+), armour (1Dh+), spells (24h+),
  items (2Eh+), attributes (3Eh+), races (44h+), classes (48h+).

## Who the monsters are

Tile n is map code n*4 (`python3 tools/sprites.py` draws all 64 tiles and the dungeon shapes to
build/sprites/). Names from comparing the shapes with the Ultima Codex's Ultima II icons
(wiki.ultimacodex.com, Category:Ultima II Icons) and from what the code does with each code:

| code | tile | creature | what the code does with it |
|------|------|----------|----------------------------|
| 2Ch | 0Bh | sea serpent | water only, fast (moves on the horse's half-turns) |
| 30h | 0Ch | orc | nothing special |
| 34h | 0Dh | daemon | casts "LEGS PARALYZED!" |
| 38h | 0Eh | devil | casts "ARMS PARALYZED!" |
| 3Ch | 0Fh | balron | casts "SLEEP SPELL!", fast |
| 40h | 10h | Minax | teleports when hit; killing her ends the game |
| 48h | 12h | pirate ship (the frigate's tile) | water only, fast |
| 60h | 18h | guard | +2 keys when killed |
| 64h | 19h | jester | its own Transact case |
| 68h | 1Ah | merchant | Transact across a counter: the shop of the map quarter |
| 6Ch | 1Bh | king | its own Transact case |
| F0h-FCh | 3Ch-3Fh | fighter, cleric, wizard, thief | also the player on foot, by class; the wizard casts magic missile, the thief steals |

Map codes 70h and 74h are tiles 1Ch (the brick pattern of town floors) and 1Dh (blank black).

Dungeon kinds (the low 3 bits of a cell; the shapes are pages 1-7 of the MONSTERS file): 1 orc,
2 ghost (blows out the torch), 3 carrion creeper, 4 viper, 5 gremlin (steals food; the game names
it), 6 minotaur, 7 balron ("YOU FEEL A STRONG MAGIC!", sleep). Page 8 of MONSTERS is a leftover
fragment that no kind reaches.

## The 1989 patches and dead code

- Disk-swap prompts were cut by turning `call PrintInline` (E8) into `jmp short` (EB) over the
  text: 0776 "(INSERT PLAYER DISK)" (the stray 48h at 0778 is the old call's last byte),
  CHARGEN 5412/5414 and 5A1E, SPACE 71CF and 7207 (where the new file-letter routine 720B
  sits inside the old string), with 3-byte calls turned into NOPs at 71F6, 7230 and MOVE 2378.
- Dead code nothing reaches: 04A8 (loads PICCAS), 06B3 (the 1983 timer calibration: loops
  over 20 timer ticks), 0389 (`mov di,30h`), 2024 (`nop; jmp 0A33`), 3117-3152 (a developer
  screen dump to the file PICXXX), 50E4 (a second sign routine), 5380, 5CED (old tone
  routine, called only from the dead 5F0D), 5E56. Zero padding at 3777, 4C55, 53F8, 5AA1,
  5C89, 5FFD suggests the pieces once started at fixed addresses.
- If PLAYER already holds a character, character generation prints NOT A BLANK PLAYER DISK
  and hangs (`jmp $`).

## Still unknown

Exactly what XorPlayerMark (5255) draws at a hit; why PlaneFlying stops water redraw;
the exact use of WorkX/WorkY and FacingDX/DY outside the view code; whether TimeZone is the
planet number away from Earth.
