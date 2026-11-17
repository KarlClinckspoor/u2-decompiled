# Ultima II: the game's mechanics, read from its source

This is how *Ultima II: The Revenge of the Enchantress* (the PC version, `ULTIMAII.EXE`, as
reissued by Origin in 1989 and sold by GOG) actually works: turns, character generation, combat,
magic, money, travel through time and space, dungeons, and the end of the game. It is read from
the byte-identical assembly in `src/*.ASM` (the ground truth) and the C reading aid in `c/*.c`,
not from the manual, wikis or play. Where the manual or common knowledge disagree, this is what
the program does. The claims that were at first only computed from the code have since been run in
the C test harness (`c/test/`); section 16 says how, and what is still open.

**Conventions**

- **Citations** are `MODULE.ASM:Routine` with the routine's original address (`@0B4D`);
  `python tools/syms.py NAME` (or `ADDR`) maps one to the other. The C file of the same name
  (`c/main.c` for `MAIN.ASM`, ...) has a function of the same name.
- **Numbers.** `0x..`/`..h` is hexadecimal. Map codes, tiles and moods are given in hex.
- **BCD.** Almost every counter the player sees is packed BCD (two decimal digits per byte):
  hit points (2 bytes, 0000-9999), food (2 bytes + hundredths), experience, gold (2 bytes each),
  the six attributes, and every item count (1 byte, 00-99). BCD sums are done with
  `adc`/`daa` and **wrap without a check**: 99 + 1 = 00, 9999 + 1 = 0000 (see `c/bcd.h`).
  Several rules compare or add a BCD byte **as if it were binary**; then the byte's hex value
  matters: attribute "25" is the byte 25h = 37. Such cases are flagged as **BCD-as-binary**.
- **Random numbers.** `rnd` is one call of `TEXTIO.ASM:Random` (@5217), a byte 0-255 (section 12).
  `rnd & m` is a **bit mask**, not a modulo: `rnd & 77h` gives only values whose bits 3 and 7 are
  clear. "1 in 4" means a test such as `rnd < 40h`. Probabilities are exact over the 256 values.
- **Marks.** **(inferred)** marks a conclusion drawn from how several pieces of code interact (or
  from code plus game data) rather than read from one routine. **[data]** marks something read
  from the game's data files in `gamedata/` (maps, monster and talk files). **(FINDINGS)** means
  the point is already in `docs/FINDINGS.md`; it was re-checked against the code here.
  **(tested)** means the claim was run in the test harness `c/test/` (the game's C, headless) and
  the assembly of the path exercised was re-read; the key string that reproduces it is given in
  `code` (notation and method: section 16).
- **Map codes and tiles.** A map byte is a tile number × 4 ("map code"); movement and the map
  window work with half codes (map code / 2). Both appear below; the text says which.

| map code | half | what | map code | half | what |
|---|---|---|---|---|---|
| 00 | 00 | water | 44 | 22 | horse |
| 04 | 02 | marsh (swamp) | 48 | 24 | frigate / pirate ship |
| 08 | 04 | grass (in towns: floor outside) | 4C | 26 | plane |
| 0C | 06 | woods | 50 | 28 | rocket |
| 10 | 08 | mountains | 54 | 2A | armour lying on the ground |
| 14 | 0A | village | 58 | 2C | weapon lying on the ground (also the sea serpent's code 2Ch as a *monster*) |
| 18 | 0C | towne | 5C | 2E | force field |
| 1C | 0E | tower | 60-6C | 30-36 | guard, jester, merchant, king |
| 20 | 10 | castle | 70 | 38 | town floor (cobble) |
| 24 | 12 | dungeon | 78, 7C | 3C, 3E | town wall, shop counter |
| 28 | 14 | sign | 80-EC | 40-76 | letters (shop signs; A0 = locked door "I") |
| 2C-40 | | monsters (see 4.9) | C0 | 60 | time door |
| | | | F0-FC | 78-7E | fighter, cleric, wizard, thief (also the player on foot) |

Contents: [1 Overview](#1-overview--core-game-loop) ·
[2 Character creation](#2-character-creation--attributes) · [3 Progression](#3-progression) ·
[4 Combat](#4-combat) · [5 Magic](#5-magic) · [6 Economy](#6-inventory-equipment--economy) ·
[7 World & travel](#7-world-structure--travel) · [8 Dungeons](#8-dungeons--towers) ·
[9 NPCs](#9-npcs--conversation) · [10 Party](#10-party) · [11 Survival](#11-survival-food-hp-healing-status-death--resurrection) ·
[12 RNG](#12-random-number-generation) · [13 Quest](#13-quest-structure--endgame) ·
[14 Commands](#14-commands) · [15 Bugs & quirks](#15-notable-bugs-quirks-dead-code--differences-from-the-apple-ii-original) ·
[16 Testing & open questions](#16-testing-and-what-is-still-open)

---

## At a glance

Things the code does that a player would not expect:

- **Four of the six attributes do almost nothing.** Stamina and Wisdom are only ever displayed.
  Charisma and Intelligence only lower shop prices. Strength sets melee damage and which armour
  you may wear; Agility sets the hit chance and which weapon you may ready (section 2.4).
- **Experience does nothing but print a level.** The level is the hundreds of the BCD
  experience. Its one mechanical use is the damage of the Magic Missile spell (3, 5.3).
- **There is no healing.** Hit points never regenerate. The only way to gain them is to pay a king
  50 gold for +300 (+200, +100 at higher totals), as often as you like (9.3, 11.2).
- **The only way to raise an attribute** is to offer gold to the hotel clerk of the 1990 A.D. towne
  (or, because the code does not check the planet, to the Historian of the Mars towne):
  6 times in 8, +4 × the hundreds offered, with no cap (3.2).
- **Damage from monsters is a random bit-subset of their total, not a sum.** The hits of a turn are
  added into one byte, which is then ANDed with a random byte and `77h`. Four guards hitting in the
  same turn add up to 100h, wrap to 0, and **do no damage at all** (4.6).
- **Standing in woods doubles monster damage** (it doubles the running total at every hit) (4.6).
- **In towns every damaging turn also costs MapType × 100 hit points**: 100 in a village, 200 in a
  towne, 300 in a castle. That, not the guards' strength, is why guards are deadly (4.6).
- **Towns, castles and dungeons reset on every visit**; their maps are never saved. Dungeon chests
  refill and the armour/weapon pick-ups in castles reappear (7.6).
- **`P` passes a turn for free; the space bar costs 0.10 food.** Flying the plane costs no food and
  no turns at all, and the frigate sails without eating (11.1).
- **Negate Time** stops monster *movement* only: adjacent monsters still hit and cast, town
  wanderers still wander, and dungeon monsters ignore it (5.4).
- **Death is a hang, not a game over**: the program loops forever and the last automatic save is
  untouched, so rebooting resumes from your last town/dungeon entrance (11.4).

---

## 1. Overview & core game loop

### 1.1 Program flow

`START.ASM:ProgramEntry` (@0100) seeds the random generator from the BIOS tick count, sets the
default speed, and runs the title screens and the demonstration (`TitleScreen` @013E). Escape
reaches the menu (`MainMenu` @0242): **C** creates a character (`CHARGEN.ASM:CreateCharacter`
@5400), **P** plays (`MAIN.ASM:GameStart` @0764). Character creation ends by writing the PLAYER
file and jumping back to `ProgramEntry`.

`GameStart` reads PLAYER (an empty name means "NO CHARACTER ON DISK", wait for Escape, retry
forever), reads the MONSTERS shape file, loads the map and monster file of the saved place, puts
the player **on foot** (`PlayerTile = 78h + 2 × class`) at the saved surface position, clears
the four timers (time stop, legs, arms, sleep), puts a parked rocket back on the map, and enters
`MainLoop`. It never returns.

### 1.2 One turn

There is no clock: **every command is one turn**. `MAIN.ASM:MainLoop` (@086F) runs one command;
every command handler ends with `jmp EndCommand`; `EndCommand` (@0A33) runs the monsters; their
loop ends in `EndTurn` (@0BAF) (surface and towns) or straight back in `MainLoop` (towers and
dungeons). In order:

1. **Command** (`MainLoop`). In a tower or dungeon (`MapType ≥ 4`) `DUNGEON.ASM:DungeonLoop`
   (@27C0) reads the key instead (section 8). Otherwise "CMD:" is printed and:
   - **Asleep** (`SleepTurns ≠ 0`): 20 "Z"s are printed and the turn is lost.
   - **Wait for a key**: one poll per speed-scaled delay. Every 256 polls the map is redrawn
     (water animates) and the plane's engine sounds if you are in it. After 64 × 256 polls
     (`Temp21`/`Temp22` from 00h/C0h) with no key, the turn passes by itself ("PASS").
   - **Space**: "PASS", **0.10 food**.
   - **Arrow key**: the position is changed first, then `MOVE.ASM:CheckStep` (@2423) judges the
     square (section 7.3). Refused: the position is put back, "--INVALID MOVE!". An allowed step
     flips `LightTurns` between 00h and FFh (outdoors this byte is reused as the horse's
     half-turn flag, see 7.4).
   - **A-Z**: `LightTurns := 0`, then the command through the 26-entry jump table `CmdJumpTbl`
     (@0730). Any other key: "-ILLEGAL COMMAND!" and a beep; **that still costs a turn**.
2. **Monsters** (`EndCommand`): the turn counters `Temp20` (attacks), `Temp21` (hits), `Temp22`
   (damage) are cleared, then by `MapType`: 0 `OutdoorMonsters` (@0A6D, then `SpawnMonster`);
   1-3 `EVENTS.ASM:TownTurn` (@101C); 4-5 `EVENTS.ASM:DungeonTurnTower` (@115F).
3. **End of turn** (`EndTurn`, surface and towns only): redraw; one attack sound per attack and a
   flash per hit (`TEXTIO.ASM:XorPlayerMark` @5255 XORs `AttackMarkBmp`, a 16 × 16 white disc, over
   the player's square at pixel (90h, 50h) for the length of the hit sound, and once more to take
   it away: the figure shows inverted inside a disc. It is the disc `XorAttackMark` @523E puts on
   the neighbouring square when the player hits) **(tested, 16)**; apply the turn's damage (4.6);
   status lines; on the surface move the time door
   (7.5); then **count down** `LegsParalyzed`, `ArmsParalyzed`, `SleepTurns`, `TimeStopTurns`
   (each stops at 0).

Towers and dungeons do **not** use `EndTurn`: monster blows subtract hit points directly, and
the turn ends with the torch, the 3D view and 0.10 food (`DungeonTurnTower`). Consequently the
legs, arms and time-stop timers **do not count down underground** (sleep is counted down by
`DungeonLoop` itself) **(inferred)**: a paralysis caught outdoors is still there when you come
back up. Underground neither paralysis matters: the dungeon Attack and Advance ignore both.

### 1.3 What costs a turn

Everything, including Z)tats, Y)ell, J)ump, M)agic, a failed command, an illegal key and a
direction prompt that times out (`MOVE.ASM:ReadDirection` @2362 gives up after 65 536 polls
without a direction key, prints "PASS" and ends the turn with a beep). Turning left or right in a
dungeon is a full turn. The only actions outside the turn system are **flying the plane** (the
whole flight is one command, 7.4), **space flight** (7.7) and shop dialogues (one turn each).

### 1.4 Keys outside the command set

`TEXTIO.ASM:ReadKey` (@4F4D) handles these itself and reports "no key":
**Ctrl-S** toggles the sound; **Ctrl-Left** / **Ctrl-Right** change the saved speed setting by
±200h within `SpeedMin`..3A00h and rescale the delay table. The keyboard buffer is emptied after
every key (no type-ahead). The arrow keys become the direction codes 0Eh/19h/05h/17h; a typed
Ctrl-N/Ctrl-W/Ctrl-E is filtered out, Ctrl-Y (19h) is not and acts as "south".

---

## 2. Character creation & attributes

### 2.1 The procedure

`CHARGEN.ASM:CreateCharacter` (@5400). C on the menu reads PLAYER; if the first byte of the name
is not 0 it prints "NOT A BLANK PLAYER DISK" and **hangs** (`jmp $`): there is one character
per disk, and to start again the PLAYER file must be blanked.

1. **Attributes**: "POINTS LEFT TO DISTRIBUTE: 90". Six two-digit entries in the order
   strength, agility, stamina, charisma, wisdom, intelligence (`TEXTIO.ASM:ReadTwoDigits`,
   decimal digits only). `SpendAttrPoints` (@5A66) rejects a value below 10 (`< 0Ah` on the BCD
   byte, so 00-09) or above the points left (BCD subtraction with borrow); a rejection rings three
   bells and **restarts the whole sheet**. Points need not all be spent. With the minimum of 10
   each, 30 points are free: one attribute can start at 40 at most.
2. **Sex**: M or F (other keys ask again). The key itself is stored in `PlayerSex` ('M'/'F').
3. **Race**: 1-4. **Type** (class): 1-4.
4. **Name**: up to 12 characters; Backspace restarts the name; Enter ends it.
5. **SATISFACTORY (Y/N)**: N redraws the whole sheet (attributes again); Y writes the
   character and restarts the program.

### 2.2 Bonuses (BCD additions)

| choice | bonus | | choice | bonus |
|---|---|---|---|---|
| Male | Strength +5 | | Fighter | Strength **+15** |
| Female | Charisma +10 | | Cleric | Wisdom +10 |
| Human | Intelligence +5 | | Wizard | Intelligence +10 |
| Elf | Agility +5 | | Thief | Agility +10 |
| Dwarf | Strength +5 | | | |
| Hobbit | Wisdom **+10** | | | |

`CreateCharacter`, the blocks after the prompts (@5751-@5959). The manual says fighter +10 and
hobbit +5 (FINDINGS). The largest starting values are therefore Strength 40+5+5+15 = 65 (male
dwarf fighter) and Agility 40+5+10 = 55 (elf thief).

### 2.3 Starting state

On Y the code sets only: surface position (20, 20) = (14h, 14h), `TimeZone = 2` (1423 B.C.),
hit points 400, food 400, gold 400 (`HitPointsHi = FoodHi = GoldHi = 04`). Everything else comes
from the blank PLAYER file, i.e. zero: no weapon (hands), no armour (skin), no items, experience
0, `Planet = 0`, `SpeedSetting = 0` (GameStart then sets the default 00FFh) and `TimeDoorTimer =
0` **[data: GOG's PLAYER is all zeros]**. Because the door timer is decremented before it is
tested, **the first time door appears only at the end of the 256th surface turn** (then every 8),
and at the era's *second* spot, (48, 24), because the spot is advanced before the door is placed
**(tested:** `{ESC}P` P×256 `{SET:PlayerX=47}{SET:PlayerY=24}{RIGHT}` goes through the door and
ends at (47, 28) in 9 000 000 B.C.; with P×255 the same step only walks to (48, 24)**)**.

### 2.4 What each attribute does

Every reference to the six bytes outside character creation and Z)tats (`tools/syms.py --refs`):

| attribute | used by | effect |
|---|---|---|
| Strength | `CMDAL.ASM:CmdAttack` @2C04, `Attack_Dungeon` @2EA8; `CMDMZ.ASM:CmdWear` @448D | melee damage; armour limit |
| Agility | `CmdAttack` @2BDD, `Attack_Dungeon` @2E84; `CMDMZ.ASM:CmdReady` @3EDD | hit chance; weapon limit |
| Charisma | `INPUT.ASM:CalcPrice` @20C5 | shop prices |
| Intelligence | `CalcPrice` @20C2 | shop prices |
| Stamina | Z)tats only | **nothing** |
| Wisdom | Z)tats only | **nothing** |

All four uses are **BCD-as-binary**: the byte's hex value is compared or added (sections 4.1, 4.2,
6.3). Race and class have no other effect on play, with three exceptions: the class picks the
player's on-foot figure (78h + 2 × class), only a cleric may buy in the cleric's shop and only a
wizard in the wizard's, and a thief steals with one coin flip instead of two (9.4). Sex has no
mechanical effect (and the cleric's "SISTER" greeting is unreachable, 15).

### 2.5 The bug at the TYPE prompt

The race key is converted from ASCII at the top of the TYPE loop, so **every wrong key at the
TYPE prompt subtracts another 31h from the race** (`CreateCharacter` @5879). Z)tats then prints a
garbage race (FINDINGS, checked in play). The race has no mechanical effect, so nothing else
breaks.

---

## 3. Progression

### 3.1 Experience and level

Experience is a 4-digit BCD number (`ExpHi:ExpLo`). Z)tats prints `ExpHi` as "A LEVEL nn"
(`CMDMZ.ASM:CmdZtats` @458D), so **level = experience / 100**. There is no level-up routine: the
level changes nothing about hit points, attributes, hit chance or damage. The only reader of
`ExpHi` besides the display is the Magic Missile spell (damage `2 × ExpHi + 30`, 5.3).

Experience per kill (`CMDAL.ASM:Attack_Damage` @2DE1, `AttackD_Killed` @2F41):

| where | experience | gold |
|---|---|---|
| surface or town (Attack, Fire) | `(rnd & 3) + 1` = 1-4 | `(rnd & 17h) | 1`: 1, 3, 5, 7, 11, 13, 15 or 17 (BCD) |
| tower or dungeon (Attack, spells) | `rnd & 7` = 0-7 | same |

Experience is added with carry into `ExpHi`, but the carry out of `ExpHi` is lost: at 9999 it
wraps to 0000.

### 3.2 Raising attributes: the hotel clerk

Attributes are never raised by play. The only routine that writes them after creation is
`CMDMZ.ASM:CmdOffer` (@3C2E), case "any other talk number" (@3D7E):

- Conditions: the person offered to has a talk number (`MonsterMood ≥ 80h`), the map is a towne
  (`MapType = 2`) and `TimeZone = 3`; the mood is not 81h, 82h or 83h.
- You pay n hundred gold (one digit, 0-9; 0 is accepted).
- `rnd & 7`: 0-5 picks strength, agility, stamina, charisma, wisdom or intelligence; 6-7 nothing
  ("THANK YOU VERY MUCH!", gold gone).
- The attribute gets four BCD additions of n with a **single** `clc` before them: `attr = attr
  + n + n + n + n`, wrapping past 99, and the carry of a wrap leaks into the next addition
  (95 + 4 × 5 gives 16, not 15; FINDINGS, checked in play).

**[data]** In the era-3 towne (MAPX32) the person with talk 84h is the clerk of the "Hotel
California" at (10, 57) (TLKX32 string 4). **The code does not test `Planet`**, and `TimeZone`
holds the planet number away from Earth, so the Mars towne (MAPG32, planet 3, map type 2)
qualifies too **(tested, 9.2)**: its MONG32 has talk numbers 81h-84h, and there the Historian (84h,
at (15, 47)) does the clerk's work.

There is no upper limit; the only "cap" is the wrap past 99. Offering 0 gold to the clerk still
says "ALAKAZAM!" and adds 0.

### 3.3 Raising hit points

Only the kings, for 50 gold (9.3). Nothing else adds hit points.

---

## 4. Combat

There is no separate combat screen. Fighting happens on the map, one blow per turn, against an
adjacent monster; monsters move, cast and hit during their turn.

### 4.1 The player's melee attack

`CMDAL.ASM:CmdAttack` (@2B8F). Underground see 4.8. On the surface and in towns:

1. Refused ("PARALIZED!", beep) while `ArmsParalyzed ≠ 0`.
2. A direction (four directions, no diagonals). `MOVE.ASM:FindMonsterInDir` (@23E6) looks for a
   live monster (slot 31 down to **1**; slot 0 is never looked at) at player + direction. The
   square is **not wrapped** at the map edge, so a monster across the edge of the surface map
   cannot be attacked. None: "--MISS".
3. **To hit**: `(rnd >> 1) < Agility`, BCD-as-binary (`rcr al,1` then `cmp al,[Agility]`, `jb`
   = hit). With agility A (decimal) the byte is `16 × (A div 10) + A mod 10`:

   | agility | byte | hit chance | | agility | byte | hit chance |
   |---|---|---|---|---|---|---|
   | 10 | 10h = 16 | 12.5% | | 50 | 50h = 80 | 62.5% |
   | 20 | 20h = 32 | 25% | | 60 | 60h = 96 | 75% |
   | 30 | 30h = 48 | 37.5% | | 70 | 70h = 112 | 87.5% |
   | 40 | 40h = 64 | 50% | | 80+ | ≥ 80h | 100% |

4. A hit in a town calls `EVENTS.ASM:AlertTownGuards` (@113A): slots 0-7 (the guards) and the
   victim's slot become hostile (mood 1). Outdoors it does nothing.
5. **Damage** = `((ReadyWeapon × 8 + Strength) mod 256) >> 2` (@2BFB-@2C0E), Strength
   BCD-as-binary. The weapon adds exactly 2 per weapon number. Examples:

   | strength | hands | dagger | sword (5) | phaser (8) | quick sword (9) |
   |---|---|---|---|---|---|
   | 20 (20h = 32) | 8 | 10 | 18 | 24 | 26 |
   | 40 (40h = 64) | 16 | 18 | 26 | 32 | 34 |
   | 65 (65h = 101) | 25 | 27 | 35 | 41 | 43 |
   | 99 (99h = 153) | 38 | 40 | 48 | 54 | 56 |

   **(tested)** All 25 combinations of strength 20/35/40/65/99 with weapons 0, 1, 5, 8, 9 took
   exactly `(8w + S) >> 2` from a 255-HP townsman, e.g. `{ESC}P{GOTO:2,2,5,5}{SET:Attributes[1]=0xFF}`
   `{SET:Attributes[0]=0x65}{SET:ReadyWeapon=9}{SET:MonsterHP[15]=255}A{RIGHT}` with `U2_MONSTERS=1`
   leaves slot 15 at 212 (43 taken). The hit roll of step 3: 500 attacks each at agility 10h, 25h,
   40h, 70h, 80h hit 13.0%, 32.0%, 51.0%, 85.4%, 100% (expected 12.5, 28.9, 50, 87.5, 100).
   The sum cannot wrap in play: the largest BCD strength, 99h, with the quick sword makes 225.

6. `Attack_Damage` (@2C19): `HP - damage` with SEC/SBC semantics; **the monster dies only if
   damage > HP**. Hit down to exactly 0 it survives (and then flees, 4.5) (FINDINGS; **tested**: a
   29-point blow leaves a 29-HP victim alive at 0 and kills a 28-HP one).
7. On a kill the map square gets back the tile the monster stood on, loot is given by kind (4.7),
   the slot is cleared, and gold and experience are added (3.1).

### 4.2 Weapons

`CMDMZ.ASM:CmdReady` (@3E50): weapon 0 (hands) is always owned. A weapon n may be readied only if
`n × 8 < Agility` (BCD-as-binary, FINDINGS, checked in play), so the real minimum agilities are:

| # | weapon | damage bonus | min. agility | shop price index |
|---|---|---|---|---|
| 0 | hands | 0 | 1 | - |
| 1 | dagger | +2 | 09 | 1 |
| 2 | mace | +4 | 11 | 2 |
| 3 | axe | +6 | 19 | 3 |
| 4 | bow | +8 | 21 | 4 |
| 5 | sword | +10 | 29 | 5 |
| 6 | great sword | +12 | 31 | 6 |
| 7 | light sword | +14 | 39 | 7 |
| 8 | phaser | +16 | 41 | 8 |
| 9 | quick sword | +18 | 49 | not sold (13.3) |

There are **no ranged weapons**: the bow and the phaser hit an adjacent square like the dagger.
The only ranged attack is the frigate's cannon (4.3). Weapons never break and are not used up.

### 4.3 The frigate's cannon

`CMDAL.ASM:CmdFire` (@35C1), only aboard the frigate (`PlayerTile = 24h`). Direction, then the
adjacent monster (same search as Attack). **No to-hit roll**; damage = `rnd | 20h` (32-255), through
`Attack_Damage` (so the kill rules and loot apply, and Minax would teleport). It does not alert
guards.

### 4.4 Armour

`CMDMZ.ASM:CmdWear` (@43F3): digits 7-9 count as 0 (skin). Armour n may be worn only if
`n × 8 < Strength` (BCD-as-binary, FINDINGS, checked in play):

| # | armour | monster hit chance | min. strength | shop price index |
|---|---|---|---|---|
| 0 | skin | 50% | 1 | - |
| 1 | cloth | 43.75% | 09 | 2 |
| 2 | leather | 37.5% | 11 | 4 |
| 3 | chain | 31.25% | 19 | 6 |
| 4 | plate | 25% | 21 | 8 |
| 5 | reflect | 18.75% | 29 | 10 |
| 6 | power | 12.5% | 31 | 12 |

Armour **never reduces damage**; it only turns blows aside. A monster blow (surface, town and
dungeon alike) hits when `rnd < 80h` **and** `(rnd & 7) ≥ WornArmour` (`MAIN.ASM:MonsterAttack`
@0B62, `EVENTS.ASM:DungeonMonsterAttack` @1357), so P(hit) = (8 − armour) / 16 **(tested:** one
guard's blows landed in 75 of 150 turns against skin, 98 of 320 against chain, 42 of 320 against
power; the loss per hit stayed the same, 4.6**)**. Reflect or power armour is also required to
survive a rocket launch (7.7).

### 4.5 Monster movement and AI (surface and towns)

`MAIN.ASM:OutdoorMonsters` (@0A6D) runs slots 31 down to 1 (slot 0 is unused outdoors) and
calls `MonsterTurn` (@0AA7) for every occupied slot, **regardless of its mood**. On horseback, on
the half-turns when `LightTurns ≥ 80h`, only the fast monsters (pirate ship 48h, balron 3Ch, sea
serpent 2Ch) move: slow monsters move every other step of a horse (7.4).

`MonsterTurn`:

1. **Spell**: if the raw distance (no wrap) is below 3 on both axes and `rnd < 20h` (1 in 8), the
   monster casts by kind: daemon 34h paralyses the legs, devil 38h the arms, wizard F8h a magic
   missile, balron 3Ch sleep (4.10). Others do nothing. The monster still acts afterwards.
2. **Direction**: `TEXTIO.ASM:DirToPlayer` (@4F11) gives −1/0/+1 per axis the short way round the
   wrapping map (the difference is shifted left twice before its sign is taken).
   **Flee**: with `MonsterHP < 0Fh` both components are negated.
3. If monster + direction (wrapped mod 64) is the player's square, **attack** (`MonsterAttack`);
   otherwise **step** (`INPUT.ASM:MonsterStepToward` @2122). Monsters therefore attack diagonally,
   which the player cannot.

`MonsterStepToward`: a monster with `HP < 10h` first heals 1 (so a fleeing monster regains
strength, stops fleeing at 0Fh and comes back). It then tries the diagonal step, then the step
along y (if dy ≠ 0), then the step along x; the first square `MonsterCanEnter` (@2199) allows is
taken (`MoveMonsterToTarget` @2201; never onto the player's square). `MonsterCanEnter`:

- nothing moves while `TimeStopTurns ≠ 0` (N)egate time, 5.4);
- the sea serpent and the pirate ship move only on water (00);
- a monster with map code below 78h (i.e. not a fighter/cleric/wizard/thief) may cross a force
  field (5Ch);
- otherwise only grass 08, woods 0Ch and town floor 70h are allowed (never water, marsh,
  mountains, walls, counters, letters or another monster);
- in a town, row 0 and column 0 are refused.

Town monsters behave by **mood** (`EVENTS.ASM:TownTurn` @101C, slots 31 down to **0**):

| mood | behaviour |
|---|---|
| 0, or 80h+n | stands still (80h+n: has talk string n) |
| 1 | hostile: `MonsterTurn` as outdoors (casts, attacks, approaches) |
| 2 | follows the player (`DirToPlayer` + `MonsterStepToward`) — most shop merchants **[data]** |
| 3+ | wanders |

A wanderer keeps its step (`MonsterStepX/Y`); 1 in 4 (`rnd < 40h`) it picks a new one,
`SignOf(rnd)` per axis (−1 with 128/256, +1 with 127/256, 0 with 1/256). The target must be within
4..3Bh on both axes, must **not share the player's column, nor his row** (tested separately), and
must be town floor (70h) or grass (08); then `MoveMonsterToTarget` moves it **without calling
`MonsterCanEnter`**, so wanderers ignore Negate Time.

### 4.6 Monster attacks and damage (surface and towns)

`MAIN.ASM:MonsterAttack` (@0B4D): `Temp20` += 1 (an attack). A thief (FCh) first tries to steal
(4.10). Then the blow (4.4); a hit adds to the turn's damage byte (this whole section is
**tested**; the runs are listed at its end):

```
T = (T + (MonsterHP >> 2) + 1) mod 256        ; current HP of the monster
if TileHere == 6 (woods under the player): T = (2 × T) mod 256
```

`MAIN.ASM:EndTurn` (@0BD1) then applies, once per turn, if `T ≠ 0`:

```
damage = (rnd AND T AND 77h) + 1              ; BCD, 01..78
HP     = HP − damage                          ; BCD, borrow chained; below 0: PlayerDies
if MapType ≠ 0: HP_hundreds = HP_hundreds − MapType   ; village 100, towne 200, castle 300
```

Consequences:

- The damage is a **random subset of the bits of T** (those within 77h), plus 1. It is not
  proportional to the number or strength of the attackers. Per hit, for the monsters that spawn
  outdoors at full health (4.9):

  | monster | HP | T per hit | possible damage (one hit, not in woods) |
  |---|---|---|---|
  | orc | 10h | 05 | 1, 2, 5, 6 |
  | thief | 20h | 09 | 1, 2 |
  | daemon, sea serpent | 40h | 11h | 1, 2, 11, 12 |
  | fighter | 80h | 21h | 1, 2, 21, 22 |
  | pirate ship | A0h | 29h | 1, 2, 21, 22 |
  | devil | C0h | 31h | 1, 2, 11, 12, 21, 22, 31, 32 |
  | wizard | E0h | 39h | same as devil |
  | balron, guard | FFh | 40h | 1 or 41 |

- **Sums wrap.** Two guards make T = 80h, which ANDed with 77h leaves 0: 1 damage. Four guards make
  100h = 0: **no damage at all**, not even the town's MapType hundreds (the whole block is
  skipped when T = 0). Three guards make C0h, which after the mask is one guard's 40h again.
- **Woods doubles** the running total at each hit, so earlier hits are doubled again by later ones.
  Towns have woods too **[data]** (e.g. (5, 5) of the 1423 B.C. towne): a
  single guard hitting there makes T = 80h, so each of his hits costs exactly 1 + the hundreds.
- The **MapType hundreds** are what make town fights deadly: any turn in which a guard (or anything)
  lands a blow in a castle costs at least 301 hit points, against a starting 400.
- The wizard's magic missile adds 40h to T (4.10).

**The test runs.** One P)ass per turn, the attackers put beside the player with the harness
cheats, hit points set back to 9999 before every turn; the attacks, hits and T of each turn were
logged (method: section 16). Every loss observed is one the formulas give, and every one they give
was observed:

| where | attackers | turns | losses seen, by hits in the turn |
|---|---|---|---|
| 1423 B.C. surface, grass (17, 18) | one monster with each HP of the table above | 200 each | exactly the table's values (orc 1, 2, 5, 6 ... devil and wizard all eight; balron 1, 41) |
| same, woods (20, 20) | the same | 200 each | T doubled: orc 0Ah → 1, 3; thief 12h → 1, 3, 11, 13; fighter 42h → 1, 3, 41, 43 |
| village MAPX21, grass (2, 8) | 1 guard | 150 | 101 or 141 |
| towne MAPX22, grass (5, 8) | 1 guard | 150 | 201 (41 times) or 241 (34) |
| castle MAPX23, (5, 8) (a moat square; only woods count) | 1 guard | 150 | 301 or 341 |
| towne, woods (5, 5) | 1 guard | 150 | always 201 (T = 80h) |
| towne, grass (5, 8) | 2 or 3 guards | 150 each | 1 hit 201/241; 2 hits always 201; 3 hits 201/241 |
| towne, grass (5, 8) | 4 guards | 300 | the same, and **4 hits (12 turns): 0** |

To reproduce: `{ESC}P{GOTO:2,2,5,8}{SET:HitPointsHi=0x99}{SET:HitPointsLo=0x99}{SET:MonsterX[0]=4}`
`{SET:MonsterY[0]=8}{SET:MonsterMood[0]=1}` then P×8 ends with H.P.=9798 (the guard's first hit
lands on turn 8: 201). Adding `{SET:MonsterX[1]=6}{SET:MonsterY[1]=8}{SET:MonsterMood[1]=1}`
`{SET:MonsterX[2]=5}{SET:MonsterY[2]=7}{SET:MonsterMood[2]=1}{SET:MonsterX[3]=5}{SET:MonsterY[3]=9}`
`{SET:MonsterMood[3]=1}` makes four guards: P×20, P×21, P×22, P×23 end with H.P.=5859, 5859, 5658,
5658; turn 21 is four misses, **turn 23 is four hits**. A surface monster is made the same way,
e.g. `{GOTO:2,0,17,18}{SET:MonsterX[31]=16}{SET:MonsterY[31]=18}{SET:MonsterMood[31]=1}`
`{SET:MonsterHP[31]=0x10}{SET:MonsterTile[31]=0x30}` for the orc.

### 4.7 Loot

`CMDAL.ASM:Attack_Damage` (@2CD3-@2D88), by the victim's map code, before the gold and experience:

| victim | loot |
|---|---|
| guard 60h | Keys +2 |
| thief FCh | Tools +1 (1 in 4); then item `rnd & 0Fh`, +1 unless 0 (each of items 1-15 with 1/16; never the ring) |
| fighter F0h | magic helm +1 (1 in 4); Torches + `(rnd & 3) + 1` (1-4) |
| wizard F8h | wand or staff (1 in 2 each) |
| Minax 40h | the end of the game (13.4) |
| anything else | nothing |

Underground kills (`AttackD_Killed` @2ED1) give only gold and experience. Thieves are the only
source of ankhs, skull keys, brass buttons, blue tassles, strange coins, green idols, boots and
cloaks, and one of two sources of tri-lithium (13.2).

### 4.8 Fighting underground

`CMDAL.ASM:Attack_Dungeon` (@2E16): no direction is asked; the target is the cell in front
(position + facing). **Arms paralysis is ignored** and guards are not involved. If the low 3 bits
of the cell are 0: "MISS". Otherwise the monster is looked up by position and level; the hit roll
and damage are as on the surface (`(rnd >> 1) < Agility`; `(weapon × 8 + Strength) >> 2`; dies only
if damage > HP). The look-up loop is buggy (15): it does not check that the slot is in use.

Dungeon monsters' turn and attacks: 8.4.

### 4.9 Spawning (surface)

`MAIN.ASM:SpawnMonster` (@0C9C), after the monsters' moves, on every surface map (Earth and
planets), never in towns:

1. The highest free slot (31 down to 1); none: nothing.
2. `x = rnd`; continue only if `x < 3Fh` (63/256), so **x is never 63**.
3. `y = rnd`; continue only if `y < 80h`; `y &= 3Fh`. (Together: 12.3% per turn.)
4. `MonsterUnder = map byte at (x, y)`; `SpawnCounter += 1` (a byte saved with the player).
5. The kind is picked by the **lowest set bit** of `SpawnCounter`, a fixed rotation:

   | bit | share of attempts | monster | code | HP | needs |
   |---|---|---|---|---|---|
   | 0 | 1/2 | orc | 30h | 10h | grass (08) |
   | 1 | 1/4 | thief | FCh | 20h | grass |
   | 2 | 1/8 | daemon | 34h | 40h | grass |
   | 3 | 1/16 | sea serpent | 2Ch | 40h | water (00) |
   | 4 | 1/32 | fighter | F0h | 80h | grass |
   | 5 | 1/64 | pirate ship | 48h | A0h | water |
   | 6 | 1/128 | devil | 38h | C0h | grass |
   | 7 | 1/256 | wizard | F8h | E0h | grass |
   | none (counter 0) | 1/256 | balron | 3Ch | FFh | grass |

6. On the wrong terrain (anything other than exactly grass, or exactly water for the sea kinds,
   which also refuses a square holding another monster) the counter is decremented and nothing
   appears: the **same kind is tried again** next time. The player's own square is not checked
   (he is not in the map), so a monster can appear on top of him. The free slot's x, y and
   `MonsterUnder` are written before the checks (harmless: tile 0 marks the slot free).

Monsters never despawn. Earth's surface monsters are saved with the map (7.6).

### 4.10 Monster spells and specials

All in `EVENTS.ASM`. Each flashes the screen.

| routine | caster | effect | save |
|---|---|---|---|
| `SpellParalyzeLegs` @0E70 | daemon | `LegsParalyzed = rnd & 0Fh` (0-15 turns): steps refused | magic boots owned and `rnd ≥ 40h` (3 in 4) |
| `SpellParalyzeArms` @0EC2 | devil | `ArmsParalyzed = rnd & 0Fh`: surface Attack refused | magic cloak, 3 in 4 |
| `SpellSleep` @0F48 | balron | `SleepTurns = rnd & 0Fh`: turns lost | green idol, 3 in 4 |
| `SpellMagicMissile` @0F12 | wizard | `Temp20 += 2`, `Temp21 += 2`, `T += 40h` | none |
| `ThiefStealItem` @0FCD | thief, when attacking | 1 in 4: item `rnd & 0Fh` −1 if owned ("A THIEF STOLE SOMETHING!") | none |
| `MinaxCurse` @0F8E | Minax | −100 HP every turn she is within 3 squares (both axes) | none |

A paralysis or sleep of 0 turns is possible (the roll includes 0). Items are never consumed by
saving: a single pair of boots saves forever. **The thief can steal the ring** (item 0), which
then must be obtained again (13.3).

### 4.11 Fleeing

The player has no flee command: you walk away. Monsters move one square per turn, like the
player (half as often while you ride a horse). Leaving a town over its edge or entering a
place reloads the area and ends pursuit.

---

## 5. Magic

### 5.1 Who can cast

Anyone. `CMDAL.ASM:CmdCast` (@310B) checks no class. The requirements, in order:

1. `Wands + Staffs ≠ 0` (a binary add of the two BCD counts, so 99h + 67h = 100h fails, a
   curiosity) — else "NEED WAND OR STAFF!".
2. A spell readied with M)agic (`ReadySpell ≠ 0`; M itself does not check ownership).
3. `SpellCounts[ReadySpell] ≠ 0` — else "NO SPELL!".
4. **One charge is used up now**, even if the spell then fails.
5. Only in a tower or dungeon: elsewhere "-FAILED!".

Wands and staffs are never used up. Spells are bought five at a time; only clerics can buy in the
cleric's shop and only wizards in the wizard's (6.4), so in practice the class decides the
spell list.

### 5.2 The spells

| # | spell | sold by | effect (`CmdCast`, labels @321E-@3309) |
|---|---|---|---|
| 1 | Light | both | `LightTurns = 96h` (150 turns), like a torch |
| 2 | Down Ladder | both | one level deeper (dungeon) / one floor down (tower) |
| 3 | Up Ladder | both | the reverse; from level 0 out to the surface |
| 4 | Passwall | cleric | the cell in front becomes 0 if it is a wall (bit 7); fails if the cell's x or y (mod 16) is 0 |
| 5 | Surface | cleric | `ExitToSurface` |
| 6 | Prayer | cleric | `rnd < 80h` (1 in 2): Kill; else fails |
| 7 | Magic Missile | wizard | damage to the monster in front (5.3) |
| 8 | Blink | wizard | to x = `(rnd & 0Fh) | 1`, y likewise (odd 1-15) on this level, if that cell is 0 |
| 9 | Kill | wizard | the monster in front dies (`AttackD_Killed`) |

The monster in front is found by `FindMonsterAhead` (@330C), which, unlike the Attack search,
checks that the slot is in use and on the player's level.

**Ladder spells** test the cell at `LookX/LookY` on the next level without setting it; after the
3D view that is the square **behind** the player (FINDINGS, checked in play). The spell succeeds
if that cell is completely empty (0), and the player moves to the new level at his own position:
**Up Ladder can leave you inside a wall**. Down Ladder fails on level 15. Neither needs a ladder.

**Passwall** only protects row 0 and column 0 (the outer walls of every level are on x = 0 and
y = 0 **[data]**; the far side wraps onto them, 8.1).

### 5.3 Magic Missile damage

`Cast_MagicMissile` (@32AD):

```
al  = 2 × ExpHi                (BCD-as-binary; carry c1)
dmg = al + 1Eh + c1            (carry c2)
HP  = HP − dmg − (1 − c2)      (the SEC of the subtraction is missing)
dies if that borrows, i.e. if HP < dmg + (1 − c2)
```

So normally **30 + 2 × level-byte + 1** hit points are taken and the monster dies if
`HP ≤ 30 + 2 × level-byte` (FINDINGS). Level 10 (byte 10h = 16) does 63; level 50 (50h = 80) does
191. The sum is 8-bit: **from level 71 (71h) up it wraps** (71h: 2 × 113 + 30 = 256 → 0, and with
c2 = 1 nothing extra: 0 damage), and above 7Fh the doubling overflows too (level 80: 31)
**(inferred)**.

### 5.4 Non-spell magic items

| item | command | effect |
|---|---|---|
| magic helm (item 5) | V)iew (`CMDMZ.ASM:CmdView` @437E) | used up; surface or town only: the whole 64 × 64 map at 4 × 2 pixels per square until a key (`DUNGEON.ASM:DrawHelmMap` @29D2) |
| strange coin (13) | N)egate time (`CmdNegateTime` @3BCE) | used up; `TimeStopTurns = 20` |
| ring (0) | passive | force fields do no damage (7.3) |
| boots (3), cloak (4), green idol (14) | passive | saves against legs, arms, sleep (4.10) |
| torch | I)gnite (`CmdIgniteTorch` @3794) | underground only (elsewhere nothing, nothing used): one torch, `LightTurns = 96h` |

**Negate Time** only makes `MonsterCanEnter` refuse every square. It does not stop: monster
attacks (the attack test comes before the step), monster spells, town wanderers (which do not call
`MonsterCanEnter`), spawning, or anything underground (the dungeon turn never reads the timer). The
20 turns count down only in `EndTurn` (surface and towns) **(inferred)**.

---

## 6. Inventory, equipment & economy

### 6.1 What the player carries

The PLAYER record (`PlayerRecord`, D:0036, 256 bytes) holds counts, all BCD 00-99, that **wrap
without a check** (buying the hundredth of anything gives 00):

- weapons 0-9 (`WeaponCounts`), armour 0-6 (`ArmourCounts`), spells 1-9 (`SpellCounts`);
- torches, keys, tools;
- 16 items (`ItemCounts`):

| # | item | use | # | item | use |
|---|---|---|---|---|---|
| 0 | ring | force-field immunity; needed for Minax (13) | 8 | red gem | **none** |
| 1 | wand | casting | 9 | skull key | board the plane |
| 2 | staff | casting | 10 | green gem | **none** |
| 3 | boots | save vs. legs | 11 | brass button | launch the plane |
| 4 | cloak | save vs. arms | 12 | blue tassle | board the frigate |
| 5 | helm | V)iew | 13 | strange coin | N)egate time |
| 6 | gem | **none** | 14 | green idol | save vs. sleep |
| 7 | ankh | board the rocket | 15 | tri-lithium | launch and fuel the rocket |

Items 6, 8 and 10 are read by nothing but Z)tats. There is no carrying limit and no weight.

### 6.2 Where things come from

| thing | sources |
|---|---|
| gold | kills (1-17), dungeon chests (6.6) |
| food | food shop (+100), stealing in a village (+100) |
| weapons | weapon shop (1-8), stealing in a towne (1-8), pick-ups and chests (1-7), Offer to talk 83h (1-8), Offer to talk 81h (quick sword) |
| armour | armour shop (1-6), stealing in a towne (1-4), pick-ups and chests (1-3) |
| spells | cleric's and wizard's shops only |
| keys | killing guards (+2) |
| torches | killing fighters (1-4) |
| tools | killing thieves (1 in 4) |
| helms | killing fighters (1 in 4) |
| wands, staffs | killing wizards |
| items 1-15 | killing thieves (1/16 each); tri-lithium also from chests on dungeon/tower level 15 |
| ring | Offer to talk 82h after earning it (13.3) |
| hit points | kings (9.3) |
| attributes | Offer to the hotel clerk (3.2) |

**Nothing can be sold.** There is no shop that buys.

### 6.3 Prices

`INPUT.ASM:CalcPrice` (@20AB) computes every shop price from a price index n:

```
s     = (Intelligence + Charisma) mod 256     ; BCD-as-binary
b     = number of significant bits of s        ; 1 for s = 0 or 1, ..., 8 for 80h-FFh
steps = n + 8 − b
(price, prev) = (4, 4); repeat steps times: (price, prev) = (price + prev, price)   ; BCD, wraps at 10000
```

The series is 8, 12, 20, 32, 52, 84, 136, 220, 356, 576, 932, 1508, 2440, 3948, 6388, then
10336 → **0336** (the carry out of the thousands is lost), ... Prices in gold:

| n | used for | b = 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|
| 1 | dagger; spell 1 ×5 | 220 | 136 | 84 | 52 | 32 | 20 | 12 | 8 |
| 2 | mace; cloth; spell 2 | 356 | 220 | 136 | 84 | 52 | 32 | 20 | 12 |
| 3 | axe; spell 3; **100 food** | 576 | 356 | 220 | 136 | 84 | 52 | 32 | 20 |
| 4 | bow; leather; spell 4; **horse** | 932 | 576 | 356 | 220 | 136 | 84 | 52 | 32 |
| 5 | sword; spell 5 | 1508 | 932 | 576 | 356 | 220 | 136 | 84 | 52 |
| 6 | great sword; chain; spell 6 | 2440 | 1508 | 932 | 576 | 356 | 220 | 136 | 84 |
| 7 | light sword; spell 7 | 3948 | 2440 | 1508 | 932 | 576 | 356 | 220 | 136 |
| 8 | phaser; plate; spell 8 | 6388 | 3948 | 2440 | 1508 | 932 | 576 | 356 | 220 |
| 9 | spell 9 (kill) | **0336** | 6388 | 3948 | 2440 | 1508 | 932 | 576 | 356 |
| 10 | reflect | 6724 | **0336** | 6388 | 3948 | 2440 | 1508 | 932 | 576 |
| 12 | power | 3784 | 7060 | 6724 | **0336** | 6388 | 3948 | 2440 | 1508 |

Armour n uses index 2n; weapons and spells index n. The sum `s` uses the two BCD bytes as binary:
intelligence 20 + charisma 20 = 40h → b = 7. **b = 8 needs s ≥ 80h** (e.g. 40 + 40), which character
creation cannot reach **(tested, by enumeration)**: of the 1 947 792 attribute sheets
`CHARGEN.ASM:SpendAttrPoints` (@5A66) accepts (six values of at least 10, at most 90 together), with
every sex, race and class, none gives s above 75h or below 20h. **Every new character starts in
class b = 6 or 7.** 75h needs a female human wizard with 50 points in Charisma and Intelligence
together (typed 40 and 10: 50h + 25h); `{ESC}C101010401010F13WIZ{ENTER}Y{ESC}P{GOTO:2,2,51,53}T{UP}`
is offered the horse for 0052, the b = 7 price. b = 8 comes only from the clerk (3.2). Past FFh the
sum wraps: 80 + 80 = 100h → 0 → b = 1, the dearest prices in the game (FINDINGS). 95 + 95 = 2Ah
pays what 15 + 15 pays.

`INPUT.ASM:PayPrice` (@2052) subtracts the BCD price from the gold; if that borrows, the price is
added back, "YOU DONT HAVE THAT MUCH!", beep, and the command ends (the turn passes).

### 6.4 The shops

Shops are reached with T)ransact across a counter: the square in the direction must be a counter
(7Ch) or a letter (map code ≥ 80h), and the square beyond it a merchant (map code 68h).
`SHOPS.ASM:ShopDispatch` (@1590) then picks the shop from the **quarter of the map the player
stands in** (x and y below or from 20h) and the map type:

| quarter | towne (MapType 2) | village, castle (1, 3) |
|---|---|---|
| north-west | weapons | oracle |
| north-east | armour | food |
| south-west | pub | wizard's spells |
| south-east | transport | cleric's spells |

| shop | routine | what |
|---|---|---|
| weapons | `ShopWeapons` @1E4F | one of weapons 1-8 at index n; 0 and 9 leave |
| armour | `ShopArmour` @1D1D | one of armour 1-6 at index 2n |
| pub | `ShopPub` @15E4 | 1: a drink for 5 gold, always tip 1 ("ISN'T THIS A GREAT GAME?"; the random tip is overwritten, FINDINGS); 2: tip t = 0-9 gold, hear tip `t + SignOf(rnd)` (t+1 or t−1, exactly t 1/256; outside 0-9 → tip 0) |
| transport | `ShopTransport` @1F75 | a horse at index 4: you are **immediately mounted** (`PlayerTile = 22h`); whatever you rode is replaced |
| oracle | `ShopOracle` @1AE0 | pay d hundred gold (one digit, 0 free) and hear verse d (`OracleVerseTbl` @1B6A) |
| food | `ShopFood` @1799 | +100 food at index 3 (`FoodHi` +1, wrapping at 9900) |
| cleric | `ShopClericSpells` @1841 | clerics only: five of spell 1-6 at index n |
| wizard | `ShopWizardSpells` @19AF | wizards only: menu 1-6 = spells 1, 2, 3, 7, 8, 9, five at index (spell number) |

The pub's ten tips (`PubTipTbl` @16BC) are hints about which monsters carry which items (fighters
helms, aviators skull keys, sailors blue tassles, mages wands, guards keys, ankhs open space,
planes need brass buttons). The oracle's ten verses (paid 0-900 gold) are one poem about the ring
and an old man under a tree.

### 6.5 Food

Food is `FoodHi:FoodLo:FoodFrac`, hundreds, units, hundredths (BCD). Consumption (11.1);
starvation is death when the subtraction borrows below 0000.00.

### 6.6 Pick-ups and chests

`CMDAL.ASM:CmdGet` (@363B):

- **Surface and towns**: on map code 54h (armour) or 58h (weapon); the square becomes 08.
  Armour `rnd & 3`: 0 "EMPTY!", else cloth/leather/chain. Weapon `rnd & 7`: 0 empty, else
  dagger..light sword. **[data]** The era-2 and era-3 castles each hold 8 armour and 8 weapon
  pick-ups; MAPX11, MAPX41 and MAPX03 a few more.
- **Underground**: the cell under the player must be exactly 40h (a bare chest). It becomes 0. On
  level 15: **tri-lithium +1**. Otherwise `rnd ≥ 40h` (3 in 4): gold
  `((rnd & 1Fh) + 2 × level) & 77h` (BCD-added, at most 77), else a weapon on even levels and
  armour on odd levels (same rolls as above).

Because towns and dungeons are reloaded from disk on every visit (7.6), **chests and pick-ups
refill each time you enter** **(inferred)**.

---

## 7. World structure & travel

### 7.1 Maps and files

Every place is one 4 KB map file and one 256-byte monster file, plus a 256-byte talk file for
villages, townes and castles: `MAP`/`MON`/`TLK` + letter + zone digit + type digit
(`LOAD.ASM:LoadMapAndMonsters` @2290, `LoadTalkFile` @22D5). The letter is X on Earth and G
elsewhere (patched by `SPACE.ASM:SetMapFileLetter` @720B); the zone digit is `TimeZone` (the era
on Earth, the planet number elsewhere); the type digit is `MapType`:

| MapType | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| place | surface | village | towne | castle | tower | dungeon |

The surface and towns are 64 × 64; towers and dungeons are 16 levels of 16 × 16 (8.1). The
monster file is the image of the eight 32-byte arrays `MonsterX`, `Y`, `HP`, `Tile`, `Under`
(underground: the level), `Mood`, `StepX`, `StepY`.

**[data]** What exists:

| zone | surface | village | towne | castle | tower | dungeon |
|---|---|---|---|---|---|---|
| Earth 0, Legends | X00 | | | **X03** (Minax) | | |
| Earth 1, 9 000 000 B.C. | X10 | X11 | | | | X15 |
| Earth 2, 1423 B.C. (start) | X20 | X21 | X22 | X23 (king) | X24 | X25 |
| Earth 3, 1990 A.D. | X30 | X31 | X32 (hotel) | X33 (king) | X34 | X35 |
| Earth 4, 2112 A.D. | X40 | X41 (planes, rockets) | | | | X45 |
| 1 Mercury | G10 | | | | | G15 |
| 2 Venus | G20 | | | | | |
| 3 Mars | G30 | | G32 | | | |
| 4 Jupiter | G40 | G41 | | | G44 | G45 |
| 5 Saturn | G50 | | | | | |
| 6 Uranus | G60 | G61 | | | | |
| 7 Neptune | G70 | G71 | | | | |
| 8 Pluto | G80 | G81 | G82 | | | G85 |
| 9 Planet X | G90 | | G92 | G93 (king, Father Antos) | | |

(Jupiter's dungeon entrance is the odd map byte 26h, which the map window reads as 24h.)

### 7.2 Entering and leaving places

`CMDAL.ASM:CmdEnter` (@3389): surface only, **on foot only** ("-ONLY ON FOOT!"). The half code
underfoot / 2 picks the place: 5 village, 6 towne, 7 tower, 8 castle, 9 dungeon, 10 sign. The
surface position is remembered (`SurfaceX/Y`) and `SaveGame` runs. Towns start at (31, 62),
bottom middle, with the talk file; towers and dungeons at (5, 5) on level 0 facing east (on the
up ladder in every dungeon **[data]**). Entering is a command, so `LightTurns` was just reset:
**you always enter a dungeon in the dark** **(inferred)**.

The **sign** prints the era from `TimeZone`: 0 "LEGENDS", 1 "9,000,000 B.C.", 2 "1423 B.C.",
3 "1990 A.D.", anything else "2112 A.D." — so the sign on Uranus (zone 6) also reads 2112 A.D.
**[data] (inferred)**.

Leaving a town: step off the edge (any coordinate outside 0-3Fh) → `MOVE.ASM:LeaveToSurface`
(@243E), which ends the turn. Leaving a tower or dungeon: climb from level 0 (or descend from a
tower's level 0), the Up Ladder or Surface spell → `CMDAL.ASM:ExitToSurface` (@3844). Both reload
the surface from disk and, on Earth, write the PLAYER file; away from Earth they put the parked
rocket (50h) back at `RocketX/Y`.

### 7.3 Terrain and steps

`MOVE.ASM:CheckStep` (@2423), in order:

1. In a town, a position outside 0-3Fh: leave (above).
2. **Marsh** (half 02): −5 HP (BCD), death below 0.
3. **Force field** (half 2Eh): with a ring, "RING PROTECTS FROM FIELD!"; without, "FIELD CAUSES
   1000 DAMAGE!" (`HitPointsHi −= 10h`, death below 0). *(After a marsh step the test compares
   the hit points instead of the tile, harmless, FINDINGS.)*
4. Legs paralysed: refused ("--PARALIZED!").
5. By transport:

| transport | rule | food per step | delays |
|---|---|---|---|
| on foot (`StepOnFoot` @2575) | time door (half 60h) → time travel; water and mountains refused; transports, pick-ups, force field and town floor allowed; anything else from half 16h refused; everything below allowed | 0.19 | 1 |
| horse (`StepHorse` @2626) | as on foot, and no marsh | 0.38 | 2 |
| plane on the ground (`StepPlane`) | as the horse, and no woods | 0.38 | 1 |
| frigate | water only (half 00) | **0** | 0 |
| rocket | never moves on the ground | - | - |

Walls (78h), counters, letters, locked doors (A0h), monsters and people are all ≥ half 16h:
impassable. An allowed step wraps the position round the 64 × 64 map (surface maps wrap; towns are
bordered by grass, `OffMapTile = 4`). The horse's marsh and the plane's woods refusals come
after the position was already wrapped, which can leave the player off the map at an edge
(FINDINGS; the Earth maps' edges are water and grass, so probably never seen).

### 7.4 Vehicles

| vehicle | board (B, `CmdBoard` @2F6F) | operate | leave (X, `CmdXit` @44D4) |
|---|---|---|---|
| horse 22h | nothing needed (also bought, 6.4) | walks; slow monsters move only every other step | on grass |
| frigate 24h | blue tassle | sails on water; F)ire | on grass **or water** |
| plane 26h | skull key | walks (no woods/marsh); L)aunch needs a brass button | on grass |
| rocket 28h | ankh | L)aunch needs tri-lithium (7.7) | on grass |

Boarding is only on foot and not underground; the vehicle leaves the map (grass under it, water
under the frigate). X-it writes the vehicle back as a map code: leaving the frigate on grass
strands it. The vehicle is not saved with the player: after a reload you are on foot **(inferred)**.

**The horse's half-turns.** Every allowed step flips `LightTurns` (00h ↔ FFh); any command, the
space bar or the idle pass resets it to 0. On horseback, when it is FFh after a step, only the
fast monsters move (`OutdoorMonsters`): so on a horse ordinary monsters move once per two steps.
The cost is double food and a longer real-time delay.

**The plane in flight** (`CMDAL.ASM:Launch_Plane` @39FA). One square per frame in the last heading
(north to begin with), over any terrain, until L lands it on a square that is exactly grass (08)
("LAND--NOT HERE!!!!!" otherwise). **The whole flight is one command**: no food, no monster turns,
no time door movement **(inferred)**. In a town, reaching row 0 or column 0 is the way out to the
surface (planes stand in MAPX32 and MAPX41 **[data]**).

### 7.5 Time doors

`DUNGEON.ASM:MoveTimeDoor` (@26F9), from `EndTurn` on the surface, **on Earth only**:
`TimeDoorTimer` is decremented; when it reaches 0 the door (map code C0h) at the current spot is
replaced by the terrain it covered (if it is still there), the timer is set to 8 and
`TimeDoorSpot` advances to the next of four spots (0, 2, 4, 6 → offsets in `TimeDoorTbl` @2798). The
door is put there only if the square is natural terrain (below 14h: water, marsh, grass, woods,
mountains); otherwise there is no door for 8 turns. The door can appear under the player.

| era | spot 0 | spot 1 | spot 2 | spot 3 |
|---|---|---|---|---|
| 0 Legends | (29, 56) | (31, 56) | (33, 56) | (35, 56) |
| 1 Pangea | (34, 8) | (47, 28) | (36, 56) | (20, 37) |
| 2 1423 B.C. | (16, 16) | (48, 24) | (42, 24) | (19, 52) |
| 3 1990 A.D. | (56, 52) | (28, 12) | (33, 23) | (20, 52) |
| 4 2112 A.D. | (18, 23) | (50, 34) | (52, 24) | (8, 11) |

Stepping on a door (on foot, horse or plane; the frigate cannot) runs `MOVE.ASM:EnterTimeDoor`
(@2677): the door's square gets its terrain back, `SaveGame`, then

```
era = spot            ; spot 0-3
if era ≥ TimeZone: era = era + 1        ; skip the present
TimeZone = era; load the surface; player at TimeDoorTbl[era][spot]
```

So **spot 0 always leads to Legends** (from Legends itself to era 1), and spot k to era k or k+1.
Only the turn count decides where the door currently is, and so where it leads. You arrive at the
same spot number in the new era; normally no door is there (the destination map was saved without
one) and the next door appears when the shared timer runs out **(tested**, in the runs below: from
the 1990 A.D. door at (56, 52), spot 0, to (29, 56) of Legends with 7 turns left on the timer**)**.

**The castle time doors (tested).** **[data]** The Legends castle (MAPX03) has four C0h squares in
its "TIME ZONE" room, at (15, 25), (20, 25), (21, 25) and (26, 25). `StepOnFoot` treats them like
any time door, but `EnterTimeDoor` neither changes `MapType` nor looks at which door was used: it
loads the **castle** file of the era picked by the current `TimeDoorSpot`, i.e. by whatever the
surface door was doing when the castle was entered (from Legends, spot k leads to era k + 1):

| `TimeDoorSpot` | file | what happens |
|---|---|---|
| 0 | MAPX13 | no such file: "WRONG DISK"; `TEXTIO.ASM:ReadWriteFile` (@52CA) waits for Escape and tries again, for ever |
| 2 | MAPX23 | the 1423 B.C. castle, player at (48, 24), on a shop counter of that map |
| 4 | MAPX33 | the 1990 A.D. castle, player at (33, 23), open floor |
| 6 | MAPX43 | no such file: "WRONG DISK", as for 0 |

`{ESC}P{GOTO:0,3,15,26}{SET:TimeDoorSpot=4}{UP}` (or `=0`, `=2`, `=6`) shows each case. What else the
code path does, each seen in those runs:

- The player is put on the *surface* door coordinates of the new era, read as castle coordinates.
- `LoadTalkFile` is not called, so the people of the new castle speak the Legends castle's lines:
  `...{SET:TimeDoorSpot=2}{UP}{DOWN}T{LEFT}` makes Commander Decker (talk 84h of MAPX23) say Minax's
  "A coward dies a thousand deaths ...".
- `SaveGame` runs in the Legends castle before the jump: MAPX03 is written with the used door
  replaced by `TimeDoorUnder` (the terrain under the last surface door; 00, water, for a character
  who has never had one), and PLAYER with `MapType = 3` and **`SurfaceX/Y` = the door's castle
  coordinates**. Leaving the new castle over its edge therefore puts the player at (15, 25) of the
  new era's surface (or wherever the door stood), not at its castle:
  `...{SET:TimeDoorSpot=2}{UP}{SET:PlayerX=31}{SET:PlayerY=63}{DOWN}` ends at 15,25, map type 0, in
  1423 B.C.
- After the "WRONG DISK" hang (`...{SET:TimeDoorSpot=0}{UP}{ESC}{ESC}`: the message again at every
  Escape) a restart resumes inside the Legends castle, on the square where the door was.

So the castle doors are a working way out of Legends during 16 of every 32 surface turns and a hang
during the other 16. The player arrives in Legends through a door of spot 0, at (29, 56), with at
most 7 turns left on it; the castle is at (32, 32). The spot at the castle gate therefore depends
only on the number of surface turns the walk took (it changes every 8; turns inside the castle do
not count): entered while the surface door is at its second or third place, (31, 56) or (33, 56),
the room is safe.

**Stale doors (tested).** `SaveGame` writes a surface map together with PLAYER, and the door timer
stands still everywhere but on Earth's surface (`MoveTimeDoor` returns at once on a planet and is
not called in towns or underground). Entering a place, quitting or a rocket trip therefore brings
the player back to a map whose door is where `TimeDoorSpot` says. Launching from the 2112 A.D.
surface with a door on the map, 20 turns on Mars and the flight back leave exactly that door, with
the count-down where it was, and it moves on normally:
`{ESC}P{GOTO:4,0,20,20}{SET:TimeDoorTimer=1}PPP{SET:PlayerTile=0x28}{SET:WornArmour=5}`
`{SET:ItemCounts[15]=0x10}LL{SET:GoldLo=0}{SET:GoldLo=0}`, a space and P×5 (door at (50, 34) with 6
turns left at the launch, 5 after the landing at (37, 42), then on to (52, 24); the two
`{SET:GoldLo=0}` only delay the landing key until the rocket is over grass).

The one way to leave a saved door behind is to leave Legends from inside its castle (by a castle
time door, or in the rocket that stands there): MAPX00 was saved at E)nter with its door on it.
On coming back through a surface door (always spot 0), the old door is still there. It works as a
door (it leads where the current spot leads), there can be **two doors at once**, for 8 or 16
turns, but it does not stay: when the cycle reaches its spot `MoveTimeDoor` finds the square taken
and places nothing, and 8 turns later it removes the door there as its own, writing the terrain
the previous spot covered. Run, with an all-zero MONX00 in the work directory (the 31 monsters of
the Legends surface otherwise put the player to sleep):
`{ESC}P{GOTO:0,0,32,32}{SET:TimeDoorSpot=2}{SET:TimeDoorTimer=1}PE{SET:PlayerX=15}{SET:PlayerY=26}{UP}`
`{SET:PlayerX=31}{SET:PlayerY=63}{DOWN}{SET:TimeDoorTimer=1}P{SET:TimeDoorTimer=1}P{SET:PlayerX=55}`
`{SET:PlayerY=52}{RIGHT}` ends at (29, 56) of Legends with the old door at (33, 56) on the map; P×7
more and there is a second one at (31, 56); 8 turns later only (33, 56); 8 turns later only
(35, 56).

### 7.6 Saving and persistence

`LOAD.ASM:SaveGame` (@22FD) writes the current map, the monster table and PLAYER, **on Earth
only** (`Planet = 0`). It runs on E)nter (before `MapType` changes, so it saves the surface), on a
time door, on Q)uit, and on L)aunch from Earth's surface. Leaving a town or dungeon on Earth
writes PLAYER only. Consequences **(inferred)**:

- **Earth's surface** (its monsters, the time door, a parked vehicle) persists.
- **Towns, castles, towers and dungeons never persist**: they are reloaded from their files on
  every entry. Killed guards, opened doors, taken pick-ups, emptied chests and stolen goods are all
  back next time (except the castle time-door case above).
- **Other planets never persist**, not even their surface, and nothing is saved while you are
  there: dying (or quitting) on a planet resumes from the moment of launch on Earth, with the
  rocket put back (`RocketParked`, `GameStart` @0832).

### 7.7 Space travel

`CMDAL.ASM:CmdLaunch` (@38B0) in the rocket: needs tri-lithium ("SHIP INCAPABLE OF LAUNCH!").
From Earth's surface the rocket's position is remembered (`RocketParked = 1`) and the game saved.
Then `SPACE.ASM:SpaceFlight` (@6999):

1. The rocket starts at the coordinates of the planet left; **1 tri-lithium** is used; a hyperwarp
   animation plays (`Hyperwarp` @6DFD).
2. **Without reflect or power armour worn (`WornArmour < 5`): "YOU HAVE EXPLODED!"** and the
   game hangs.
3. The command loop (`SpaceCmdLoop` @6A79): the arrow keys only move the star field's centre
   ("LEFT", "RIGHT", "CLIMB", "DIVE"); **H** hyperwarps (1 tri-lithium, "NO FUEL!" without; three
   digits XENO, YAKO, ZABO, 0-9 each); **L** lands.
4. After every hyperwarp (including the launch): if the fuel left has `(TriLithium & 3) = 3` (a
   BCD low digit of 3 or 7, i.e. a launch or warp begun with 4 or 8 in the last digit), "SHIP OFF
   COURSE!" and each coordinate becomes `StarRnd() & 7` (0-7): in practice **always (7, 1, 1)**,
   deep space (tested, section 12). Then `FindOrbit` (@7030): (4, 4, 4) is the sun, "YOU HIT THE
   SUN!", hang; a planet's coordinates set `Planet`; anything else is deep space (`Planet = 0Ah`),
   where landing is denied.

| # | planet | Xeno | Yako | Zabo |
|---|---|---|---|---|
| 0 | Earth | 6 | 6 | 6 |
| 1 | Mercury | 5 | 4 | 5 |
| 2 | Venus | 3 | 3 | 4 |
| 3 | Mars | 6 | 2 | 3 |
| 4 | Jupiter | 1 | 3 | 4 |
| 5 | Saturn | 2 | 8 | 5 |
| 6 | Uranus | 9 | 4 | 6 |
| 7 | Neptune | 4 | 0 | 5 |
| 8 | Pluto | 0 | 1 | 4 |
| 9 | Planet X | 9 | 9 | 9 |
| | the sun | 4 | 4 | 4 |

(`PlanetXenoTbl` @7012, `PlanetYakoTbl`, `PlanetZaboTbl`.)

**Landing** (`SpaceCmdLand` @7185): on Earth `TimeZone = 4` — **you always come back to 2112 A.D.** —
elsewhere `TimeZone = planet`, letter G, `MapType = 0`. Back in `CmdLaunch` the map scrolls
diagonally under the rocket ("(PRESS ANY KEY)": two rows per frame, one column every fourth row);
the square under the rocket when a key is pressed must be grass (`& 7Fh = 08`) or **the player
dies**. On another planet the landing spot is remembered as the parked rocket. Space flight takes
no game turns and no food.

---

## 8. Dungeons & towers

### 8.1 Layout

A tower or dungeon file is 16 levels of 16 × 16 cells, one 256-byte page each (cell = y × 16 + x).
A cell byte:

| bits | meaning |
|---|---|
| 80h | wall |
| C0h | door (wall + 40h): passable when advancing |
| E0h | secret door: drawn as a plain wall, passable when advancing |
| 40h (no 80h) | chest |
| 20h | ladder down (D)escend) |
| 10h | ladder up (K)limb); 30h is both |
| low 3 bits | monster kind 1-7 (set at run time) |
| 08h | **never set**. The code treats the low *four* bits as the monster field (Advance and Retreat test `& 0Fh`, kills and monster steps clear with `& F0h`), but the only values ever OR-ed in are the kinds 1-7 (`SpawnDungeonMonsters` @1521, the monster step @1284), no map file has the bit in its 16 levels and the dungeon monster files are empty **(tested: data scan of all ten files, and every store through `DungeonCellPtr`)**. It matters only on Pluto's "level 16" (8.6) |

**[data]** Row 0 and column 0 are wall on every level of every file except two corners (cell
(0, 0) of MAPG15 level 3, cell (0, 15) of MAPG44 level 15); the far side is open, and a step past x = 15
or y = 15 reads (through the address arithmetic of `ReadDungeonCell` @1451 / `GetDungeonCell` @68C0)
the wall of row 0 or column 0, so levels are closed. The maps use only the values 00, 10, 20, 30,
40, 80, C0, E0. Dungeons count levels downwards (`Descend` = level + 1); towers count floors upwards
(`Klimb` = level + 1) and are left by descending from level 0. The dungeon and tower layouts are
fixed in the files (no random generation); the four Earth dungeons X15, X25, X35 and X45 are the
same maze, X15 differing in two cells **[data]**.

### 8.2 Moving

`DUNGEON.ASM:DungeonLoop` (@27C0). Up arrow ADVANCE (`DungeonAdvance` @2861), left TURN LEFT
(@2912), right TURN RIGHT (@2944), down RETREAT (@2977), space PASS, letters the commands.
Each is a full turn. Asleep: 20 Z's and `SleepTurns − 1`.

- **Advance** is blocked ("-BLOCKED!", beep) if the cell ahead has any of its low 4 bits set (a
  monster) or is exactly 80h (a plain wall); doors and secret doors are walked through.
- **Retreat** is blocked if the cell behind has bit 7 or any low 4 bit set: you cannot back
  through a door.
- **Traps** (only on Advance): after the step, `rnd < DungeonLevel` springs a trap ("ARGH! A
  TRAP!"): never on level 0, `level/256` per step deeper (5.9% on level 15). The torch goes out
  (`LightTurns = 0`); **without tools the player dies**; with tools one is used up
  ("ESCAPED! BY USE OF TOOLS!").

The idle time-out underground uses a 16-bit counter where the 6502 had 8 bits (255 polls, then
65 536; FINDINGS).

### 8.3 The 3D view

`VIEW3D.ASM:UpdateDungeonView` (@6000), after every dungeon turn. **Only while `LightTurns ≠ 0`**
is the view drawn: up to 7 cells ahead with the side walls, doors, ladders and chests
(`DrawViewWalls` @6144); a wall ends the view (a door only in the player's own cell lets it go on).
Then the nearest monster in the line of sight (`DrawViewMonster` @68ED): at distance 1 its own shape
(page 1-7 of the MONSTERS file), farther away a generic, smaller shape. In the dark nothing is
drawn ("IT'S DARK!"), but monsters still move and attack. The view also leaves the cell under,
ahead and behind in `TileHere`, `TileNorth`, `TileSouth` for the commands.

**Light**: a torch or the Light spell sets 96h (150) turns. The dungeon turn decrements it ("TORCH
BURNED OUT!" at 0). A trap or a ghost puts it out.

### 8.4 Dungeon monsters

**Slots and levels.** Underground, slot n belongs to level n / 2 (`MonsterUnder` holds the level):
levels 1-15 have **two** slots, level 0 only **one** (slot 0 is never used). So at most two
monsters exist on a level at a time.

**Spawning** (`EVENTS.ASM:SpawnDungeonMonsters` @147F), every dungeon turn, for every free slot:
x = `(rnd & 7) × 2 + 1`, y likewise (odd 1-15), level = slot / 2; if that cell is exactly 0, the
kind r = `rnd & 7` (7: none) is accepted if `2r ≤ level`, kind = r + 1. Hit points =
`((2 × kind + level) × 8) OR 10h`. Monsters on a level therefore reappear almost at once after
being killed.

| kind | monster (MONSTERS page) | from level | special (1 in 4) | HP on level 0 / 4 / 8 / 12 / 15 |
|---|---|---|---|---|
| 1 | orc | 0 | - | 16 / 48 / 80 / 112 / 152 |
| 2 | ghost | 2 | blows out the torch | - / 80 / 112 / 144 / 152 |
| 3 | carrion creeper | 4 | - | - / 80 / 112 / 144 / 184 |
| 4 | viper | 6 | - | - / - / 144 / 176 / 184 |
| 5 | gremlin | 8 | steals 100 food ("A GREMLIN STOLE SOME FOOD!"); death if less | - / - / 144 / 176 / 216 |
| 6 | minotaur | 10 | - | - / - / - / 208 / 216 |
| 7 | balron | 12 | "YOU FEEL A STRONG MAGIC!": sleep `rnd & 7` turns, no save | - / - / - / 208 / 248 |

(Names: FINDINGS, "Who the monsters are".)

**Movement** (`DungeonTurnTower` @115F), slots 31 down to 1: direction = sign of the difference
(`DirToPlayerDungeon` @152E, no wrap), negated when `HP < 0Fh` (flee). It tries a step in x, else in
y (no diagonals). A step onto the player's square is an attack. **Only monsters on the player's
level move**; they cannot enter a plain wall (80h) but pass doors, secret doors, ladders and chests,
and never a cell that holds another monster. Dungeon monsters do not heal.

**Attacks** (`DungeonMonsterAttack` @1308): `rnd < 40h` (1 in 4) gives kinds 2, 5 and 7 their special
instead of a blow (the others still strike). A blow hits as on the surface ((8 − armour) / 16) and
costs, **immediately** (no `EndTurn`, no MapType hundreds):

```
damage = (rnd & 77h) + ((4 × level) & 77h)     ; a binary sum, then subtracted as BCD with das
```

Bit 3 is masked out of the level term, so it runs 0, 4, 0, 4, 10h, 14h, 10h, 14h, 20h, 24h, 20h, 24h,
30h, 34h, 30h, 34h for levels 0-15. Read as decimal the loss is 0-77 plus 0-34: 0-77 on levels 0
and 2 (average 38.5), 4-81 on 1 and 3, 14-91 on 5 and 7, 34-111 on 13 and 15 (average 72.5).
Because the sum is not valid BCD, the hit points can be left with a non-decimal digit (FINDINGS).

**(tested)** 220 turns each on levels 0, 1, 3, 7 and 15 with an orc beside the player: about half
the blows landed and every loss was one of the 64 results the BCD model gives for that level,
inside the ranges above. `{ESC}P{GOTO:2,5,5,5}{SET:DungeonLevel=15}{SET:HitPointsHi=0x99}`
`{SET:HitPointsLo=0x99}{SET:MonsterX[31]=4}{SET:MonsterY[31]=5}{SET:MonsterHP[31]=200}`
`{SET:MonsterTile[31]=1}{SET:MonsterUnder[31]=15}` then P×1, P×3, P×4 end with H.P.=9890, 9814, 9764
(losses 109, 76, 50). From 5010 hit points on level 1 the results included 49FF and 492F. The
spawn rule was checked the same way: 30 turns after `{GOTO:2,5,5,5}` all 31 slots held a monster
with slot / 2 = level, 2 × (kind − 1) ≤ level and exactly the hit points of the formula.

### 8.5 Treasure

Chests: 6.6. Tri-lithium lies in every chest of level 15 **[data: level 15 holds 8 chests in the
four Earth mazes, 104 in the 1423 B.C. tower, 31 in the 1990 A.D. tower, 124 in Jupiter's tower,
94/31/130 in the Mercury, Jupiter and Pluto dungeons]**. The subdued balron in the 1990 A.D. castle
says as much (TLKX33 string 5).

### 8.6 Pluto's dungeon and "level 16"

**[data]** MAPG85 ends like a tower. Levels 1-13 have one cell with both ladders at (7, 7);
level 14 has a down ladder at (7, 7) and an up ladder at (1, 1); level 15 has **no up ladder**,
only a down ladder at (1, 1). That is the pair a tower has at its top (K)limb on 14, D)escend on
15); every other dungeon ends with an up ladder on level 15 and no down ladder. Read as a dungeon
it makes level 15, with its 130 chests of tri-lithium, a trap **(tested)**:

- It is reached by D)escend from (7, 7) of level 14, and there is no ladder back.
- The Up Ladder spell always fails there: it needs a completely empty cell on level 14 (5.2), and
  level 14 has none (it is all secret doors). `{ESC}P{GOTO:8,5,7,7}{SET:DungeonLevel=15}`
  `{SET:ItemCounts[1]=1}{SET:SpellCounts[3]=0x20}{SET:ReadySpell=3}C{LEFT}C{LEFT}C{LEFT}C`:
  "-FAILED!" in all four facings, a charge gone each time. Only the cleric's Surface spell leads
  out; anyone else dies there or restarts, back at the launch on Earth (7.6).
- D)escend on (1, 1) works, since `CMDAL.ASM:Ladder_LevelInc` (@3381) has no bound: "TO LEVEL 10"
  (16 printed through `daa`), `DungeonLevel = 10h`, and `ReadDungeonCell` (@1451) reads page 16 of
  the map buffer, which is the **talk buffer** (D:2800). Level 16 is the last talk file loaded,
  read as cells: a cell can be walked into only if its low four bits are 0 (the space and a few
  other characters). No monsters appear (there are no slots 32-33); traps spring 16 times in 256.
- The way back depends on byte 17 of that talk file, the cell under the player at (1, 1): K)limb
  needs its bit 10h. After Pluto's towne (TLKG82: 'r', F2h) K leads back to level 15. After
  Pluto's village (TLKG81: a space, A0h) it does not ("KLIMB-WHAT?"); that cell has bit 20h, so D
  goes on to "level 17" ("TO LEVEL 11"), the first page of the MONSTERS shape buffer (D:2900),
  whose cell (1, 1) is 17h: from there K leads back to 16 and D is refused. Of the 17 talk files
  6 give a way back up (G41, G71, G82, X21, X33, X41). With a talk buffer that was never loaded
  since the program started (zeros in the harness, whatever was in memory on a PC) the cell is
  empty and neither ladder command works.

The harness cheat cannot switch the file letter to G, so for these runs MAPG85 and MONG85 were
copied into the work directory as MAPX85 and MONX85, and likewise MAP/MON/TLK G82 and G81:
`{ESC}P{GOTO:8,5,1,1}{SET:DungeonLevel=15}D` prints "TO LEVEL 10", a following `K` "KLIMB-WHAT?";
`{ESC}P{GOTO:8,2,5,5}{GOTO:8,5,1,1}{SET:DungeonLevel=15}DK` "TO LEVEL 15"; with `{GOTO:8,1,5,5}`
first, `DKD` ends with "TO LEVEL 11" and `DKDDK` with "TO LEVEL 10".

---

## 9. NPCs & conversation

### 9.1 Transact

`CMDMZ.ASM:CmdTransact` (@4050) needs a direction. Outdoors: "FUNNY, NO RESPONSE!". In a town:

1. **Nobody in that square** but a counter with a merchant behind it: that quarter's shop (6.4).
2. **A person with a talk number** (`MonsterMood = 80h + n`): talk string n of the town's TLK file,
   then a pause (three × 65 535 empty loops and a speed delay). On Planet X in a castle, talk 81h
   (Father Antos **[data]**) sets `RingEarned` (13.3).
3. **Otherwise by kind**: the king takes the tribute (9.3); guard ("PAY YOUR TAXES!"), jester,
   merchant, fighter, cleric, wizard and thief each say one fixed line; anyone else
   "FUNNY, NO RESPONSE!".

There is no keyword conversation: each townsperson has at most one line. Talk files hold 4 or 5
strings **[data]**. Moods 80h+n people stand still; only they speak their string.

### 9.2 Offer

`CMDMZ.ASM:CmdOffer` (@3C2E): direction, "HOW MUCH (*100) ?", one digit (0-9 hundred gold, 0
allowed), paid at once. Unless the person has a talk number **and** `MapType = 2` **and**
`TimeZone = 3`, the answer is "THANK YOU VERY MUCH!" and the gold is gone. Otherwise by talk number:

| talk | in MAPX32 **[data]** | effect |
|---|---|---|
| 81h | Santre the Swashbuckler | ≥ 500 gold: "ENILNO IS YOURS!", `QuickSwordCount = 1` (set, not added) |
| 82h | an old man | ≥ 500 gold: the ring if `RingEarned` ("EARN THE RING!" otherwise; gold gone) |
| 83h | the Flopy Fighter | **any amount, even 0**: one random weapon 1-8 (`(rnd & 7) + 1`) |
| other | the hotel clerk (84h) | 6 in 8: attribute +4 × amount (3.2) |

Less than 500 to 81h/82h: thanks, gold gone.

**The same table applies in the Mars towne (tested).** **[data]** In MAPG32 talk 81h is Marlin
Perkins at (51, 52), 82h Owen K. Garriott at (49, 55), 83h Hecate at (2, 1) and 84h the Historian
at (15, 47). The harness flew there for real: `{ESC}P{SET:PlayerTile=0x28}{SET:WornArmour=5}`
`{SET:ItemCounts[15]=0x10}{SET:GoldHi=0x90}LH623L{SET:GoldLo=0}{SET:GoldLo=0}{SET:GoldLo=0}`, a
space, `X{SET:PlayerX=32}{SET:PlayerY=32}E` (launch, hyperwarp to 6-2-3, land, leave the rocket,
enter the towne; the three `{SET:GoldLo=0}` only delay the landing key until the rocket is over
grass). Continued with:

| keys | result |
|---|---|
| `{SET:PlayerX=50}{SET:PlayerY=52}O{RIGHT}5` | "ENILNO IS YOURS!"; Z)tats lists QUICK SWORDS-01 |
| `{SET:PlayerX=48}{SET:PlayerY=55}O{RIGHT}5` | "EARN THE RING!", 500 gold gone; with `{SET:RingEarned=1}` before it "THE RING IS YOURS!" |
| `{SET:PlayerX=2}{SET:PlayerY=2}O{UP}0` | "HERE TAKE THIS!", GOLD still 9000; three such offers gave a mace, a light sword and a phaser |
| `{SET:PlayerX=14}{SET:PlayerY=47}O{RIGHT}2` | "ALAKAZAM!", GOLD=8800; Z)tats shows AGILITY-23 (15 + 4 × 2) |

On Earth `{ESC}P{GOTO:3,2,55,36}O{UP}0` gets a dagger from the Flopy Fighter for 0 gold. Nothing in
`CmdOffer` reads `Planet`.

### 9.3 Kings

`CmdTransact`, king (map code 6Ch): "FIRST MY 50 G.P. TRIBUTE!" (`PayPrice` 50), then by the
hundreds of the hit points (BCD compares, which are correct here):

| hit points | raise |
|---|---|
| below 5000 | +300 |
| 5000-7499 | +200 |
| 7500-9899 | +100 |
| 9900+ | 0 (the 50 gold are still taken) |

Repeatable every turn. Kings with a monster slot stand in MAPX23, MAPX33 and MAPG93 **[data]** (the
king drawn in MAPX03 has no slot and cannot be addressed).

### 9.4 Stealing

`CMDMZ.ASM:CmdSteal` (@3F25): direction; the square must be a counter (7Ch, or a letter ≥ 80h) and
the one beyond it a merchant (68h). Success needs:

- a coin flip `rnd < 80h`, skipped for a **thief**; then a second `rnd < 80h` (thief 50%, others 25%);
- the town not alarmed (`MonsterMood[0] ≠ 1`, i.e. guard 0 not hostile);
- the right shop: a **village**'s north-east quarter (food: +100), or a **towne**'s north half
  (north-east: armour `(rnd & 3) + 1` = cloth..plate; north-west: weapon `(rnd & 7) + 1` =
  dagger..phaser). Anywhere else (castles, other shops) it always fails.

Any failure: "NO LUCK!" and 1 in 8 the guards are alerted (`AlertTownGuards`). That routine also
makes slot `Temp20` hostile, which Steal never sets: it holds the high byte of the direction
prompt's time-out counter, i.e. how many rounds of 256 polls you waited before pressing the
direction (FINDINGS). After a long wait it can exceed 31 and write the 1 past the 32-entry mood
table **(inferred)**.

### 9.5 Guards and the alarm

Slots 0-7 of most town files are the guards **[data]** (exceptions: the Legends castle, whose
slots 0-7 are six balrons, a daemon and a devil, and the Uranus and Neptune villages), mostly
mood 0 (standing). `AlertTownGuards` turns slots 0-7 hostile whatever they hold. A hit on anyone in a
town, or an unlucky steal, sets their mood to 1: they walk to you and fight (4.5-4.6). Killing a
guard gives two keys. There is no way to calm them, but leaving and re-entering reloads the town
(7.6). Guards (and anything else below map code 78h) may cross force fields.

### 9.6 Locked doors

`CMDMZ.ASM:CmdUnlock` (@42F1): only east or west is examined ("NO DOOR THERE!" for north/south);
the square must be map code A0h; uses one key; the door becomes the player's own tile. **[data]** all
99 locked doors can be reached from the east or west (FINDINGS).

### 9.7 Minax

The enchantress is slot 31 of MAPX03 with mood 84h and 255 hit points **[data]**. With mood ≥ 80h
she never moves or attacks; she curses (`MinaxCurse`, −100 HP a turn) whenever the player is within 3
squares on both axes (checked for every slot in `TownTurn`). Hit and surviving, she flashes, warps
from (x, y) to (y, x) ("SHE'S GONE!!!") and her mood is set back to 84h (`Attack_Damage` @2C38),
undoing the "hostile" that the hit's alarm gave her. She does not heal. Killed: 13.4.

---

## 10. Party

There is no party. The game has one character; there are no hirelings, companions or followers that
fight for you (the "follow" mood of town merchants is only movement). Only one character can exist
per PLAYER file (2.1).

---

## 11. Survival: food, HP, healing, status, death & resurrection

### 11.1 Food

| action | food | routine |
|---|---|---|
| step on foot | 0.19 | `StepOnFoot` @2575 |
| step on horse / plane on the ground | 0.38 | `StepHorse` @2626 |
| step by frigate | 0 | `CheckStep` |
| space bar, or idle time-out (surface, town) | 0.10 | `MainLoop` pass |
| any letter command (incl. **P**ass) on the surface or in a town | 0 | - |
| every turn in a tower or dungeon | 0.10 | `DungeonTurnTower` → `EatFood(10h)` @12DB |
| plane flight, space flight | 0 | - |
| gremlin | 100 | `DungeonMonsterAttack` |

Starting with 400 food, you can walk about 2100 steps. When a subtraction borrows below zero the
player dies (`DieOfStarvation` → `PlayerDies`). There is no hunger warning.

**(tested)** `{ESC}P` and P×264 leaves FOOD=0400 (`CmdPass` @3DBC is "PASS" and `jmp EndCommand`);
`{ESC}P` and ten spaces FOOD=0399 (399.00). The food of a step is taken before the terrain is
judged (`StepOnFoot` @2599, ahead of its terrain tests at @25C0), so **a step the terrain refuses
("--INVALID MOVE!") still costs its 0.19** (0.38 mounted): `{ESC}P` and six `{RIGHT}` into the water
east of the starting square leave the player at 20,20 with FOOD=0398 (398.86). Only paralysed legs
refuse the step before the food is taken.

### 11.2 Hit points

Four BCD digits, 0000-9999. They are only lost (monsters, marsh, force fields, Minax, dungeon blows)
and only gained from kings (9.3). **No regeneration, no healing potions, no temple, no healing
spell.** Hit points are therefore a resource bought with gold: 50 gold per 300 HP up to 5000.
**(tested)** The only instructions in the program that store into `HitPointsHi/Lo` are the starting
value (CHARGEN @59ED), the king's raise (CMDMZ @42EB), the turn's damage (MAIN @0BF2-@0C17), the
dungeon blow (EVENTS @1394/@139F), Minax's curse (EVENTS @0FC4), the marsh and the force field
(MOVE @249E/@24A9, @2518) and death (MAIN @0C64); 264 quiet turns on the surface leave H.P.=0400.

### 11.3 Status effects

| status | set by | lasts | effect | counted down by |
|---|---|---|---|---|
| legs paralysed | daemon | 0-15 turns | steps refused (surface, town) | `EndTurn` only |
| arms paralysed | devil | 0-15 | surface A)ttack refused | `EndTurn` only |
| asleep | balron (surface 0-15, dungeon 0-7) | | turns lost | `EndTurn`; `DungeonLoop` |
| time stopped | N)egate time | 20 | monsters cannot step (5.4) | `EndTurn` only |
| poison | - | | none in this game (marsh costs 5 HP per step instead) | |

All four timers are cleared when the game is started (`GameStart`); they are not saved.

### 11.4 Death and "resurrection"

`MAIN.ASM:PlayerDies` (@0C62): hit points, food, experience and gold are set to 0 and shown,
"<name> IS DEAD!", and the program **loops forever**. It does not write anything. The disk still holds
the last automatic save (7.6), so rebooting and pressing P **resumes at the last save point**: the
entrance of the town or dungeon you died in, the time door you came through, or the launch site
**(inferred)**. The same endless loops end space deaths (explosion, the sun) and the victory. There is
no in-game resurrection.

---

## 12. Random number generation

`TEXTIO.ASM:Random` (@5217) is an additive lagged generator over a 6-byte history `RandSeed`..
`RandSeed5` (D:023F), newest first:

```
stc
al = RandSeed1 + RandSeed4 + RandSeed5 + 1   ; adc chain: the carry of the first add goes into the second
RandSeed = al; RandSeed1..5 = RandSeed..RandSeed4 (shift down)
return al
```

i.e. x(n) = x(n−1) + x(n−4) + x(n−5) + 1 + c (mod 256), where c is the carry out of
x(n−1) + x(n−4) + 1. `RandSeed` itself is only the staging byte.

**Seeding** (`START.ASM:ProgramEntry` @0100): the low byte t of the BIOS tick count; RandSeed and
RandSeed1 get t + 1, RandSeed2-5 get t. It is seeded once per program start (character creation
restarts the program, and reseeds). The generator is not called while the game polls the keyboard
on a map, so there the sequence depends only on the commands given; the one exception is space
flight, where `ENDGAME.ASM:ToggleSpaceBleep` (@7242) draws a random pitch for the "computer bleeps"
while the stars fly, so time spent in space does advance it **(inferred)**.

**Where it is used**: hit rolls, monster blows and damage, spells and saves, spawns, loot and gold,
chest contents, steals, the pub and the clerk, town wanderers, traps, Blink, Prayer, Minax's
dying world. The **star field** of space flight has its own two-byte generator `StarRnd` (@6D68:
new = s1 + 9 + s2 + carry, period 4307), reset to 3Bh/67h before each phase; it also chooses the
off-course destination.

**The off-course destination is not random (tested).** `SPACE.ASM:Hyperwarp` (@6DFD) restarts the
generator twice and then runs 128 + 128 + 63 frames in which every star is replaced many times from
the restarted sequence; the star field, and with it the number of `StarRnd` calls made before the
three coordinates are drawn, comes out the same whatever went before. Every run from a natural
state ended at **Xeno 7, Yako 1, Zabo 1**, deep space: the launch itself
(`{ESC}P{SET:PlayerTile=0x28}{SET:WornArmour=5}{SET:ItemCounts[15]=0x04}L`: "SHIP OFF COURSE!",
XENO=07 YAKO=01 ZABO=01), launches with 8 or 14 units or after other turns, and H)yperwarps begun
with 5 units after waits of 0 to 450 key polls, after arrow keys, with pauses between the digits
and to different targets (`...{SET:ItemCounts[15]=0x05}LH999`). A separate model of `MoveStars`
(@6B3D) and `StarRnd` written from the assembly gives (7, 1, 1) for the launch as well. Only a star
field scrambled by hand (all 64 stars set to random places just before the H) can end elsewhere:
(1, 3, 5) in 3 of 12 harness runs; in 2000 runs of the model 73% (7, 1, 1), 12% (1, 3, 5) and seven
rarer triples, none of them a planet or the sun. So going off course costs one unit of fuel and a
second warp, and nothing else.

---

## 13. Quest structure & endgame

### 13.1 The win condition

The game ends in exactly one place: `CMDAL.ASM:Attack_Damage` calls `ENDGAME.ASM:MinaxDead` when the
monster killed has map code 40h. Minax exists only in the Legends castle's monster file (MONX03)
**[data]**. She can only be killed by A)ttack (spells work only underground; the frigate cannot enter
a castle). Nothing else in the code checks for quest items or progress.

### 13.2 What the code makes necessary

Working backwards from Minax **(inferred from the code and data)**:

1. **Reach Legends**: a surface time door at spot 0 from any other era (7.5). **[data]** The
   Legends surface (MONX00) starts with all 31 outdoor slots filled, mostly balrons, daemons and
   devils with 255 hit points, packed around the castle; as outdoor monsters they all hunt the
   player regardless of mood, and nothing new spawns until slots are freed.
2. **Reach Minax** at (60, 3) of MAPX03: the chamber is closed by force fields **[data: 72 in the
   map]**, each step costing 1000 hit points without the **ring**. (A character with enough hit points
   from kings could pay instead.) While within 3 squares of her you lose 100 hit points a turn.
3. **The ring**: T)ransact with Father Antos (talk 81h) in the castle of Planet X (`Planet = 9`,
   `MapType = 3`) to set `RingEarned`; then O)ffer 500+ gold to the old man (talk 82h) in the 1990 A.D.
   towne. (The code's "there is no other way" verse aside, a thief may later steal the ring; it can be
   bought again for 500.) The hints: Brother Antos in the 1423 B.C. castle, "Search the stars for my
   kin"; Queen Susan on Planet X, "Father Antos awaits you!" **[data]**.
4. **Planet X** (9, 9, 9) needs a **rocket** (MAPX41 in 2112 A.D., and one in MAPX03 **[data]**), an
   **ankh** to board, **tri-lithium** to launch and one more unit per hyperwarp, and **reflect or
   power armour worn** (strength 29+ / 31+). Ankhs come only from killed thieves; tri-lithium from
   thieves and from chests on level 15 of a tower or dungeon.
5. **Killing her**: 255 hit points of damage in hits that each exceed what is left; every surviving
   hit warps her between (60, 3) and (3, 60). The quick sword (Offer 500+ to Santre, talk 81h, era-3
   towne; ready with agility 49+) adds +18 damage, the most of any weapon, but nothing requires it.

The frigate (blue tassle), the plane (skull key + brass button), helms, coins and the rest are aids,
not requirements.

### 13.3 Special NPCs by talk number

`MonsterMood` 81h-84h are the only hooks the code has into specific people; their meaning depends on
the map (9.2, 9.1). **[data]** In MAPX32 (1990 A.D. towne): 81h Santre (quick sword), 82h an old man
(ring), 83h the Flopy Fighter (random weapon), 84h the hotel clerk (attributes). In MAPG93 (Planet X
castle): 81h Father Antos (`RingEarned`).

### 13.4 The end

`ENDGAME.ASM:MinaxDead` (@72A0): "MINAX IS DEAD!! ALL HER WORKS SHALL DIE!"; 64 rounds of a sound and
64 random squares of the current map turned to blank (74h); "YOU FEEL A STRANGE FORCE!", the era-3
surface (MAPX30) is read over the map; the victory text ("YOU HAVE SAVED THE UNIVERSE, AND COMPLETED
ULTIMA ][! ..."), naming the sequel; then the player, drawn as the rocket, drifts over the wrapping map
forever (one row per frame, one column every fourth). Nothing is saved; the game must be rebooted.

---

## 14. Commands

The table `CmdJumpTbl` (@0730). Every command costs one turn (1.3). "Underground" = tower or dungeon.

| key | command | routine | mechanics |
|---|---|---|---|
| A | Attack | `CmdAttack` @2B8F | 4.1; underground the cell in front (4.8); refused with paralysed arms (surface) |
| B | Board | `CmdBoard` @2F6F | 7.4; on foot, not underground ("THINK AGAIN") |
| C | Cast | `CmdCast` @310B | 5.1-5.3; works only underground; a charge is used even on failure |
| D | Descend | `CmdDescend` @334D | underground on a 20h cell: dungeon level + 1, tower floor − 1 (below 0: out). **No upper bound in a dungeon** (8.6) |
| E | Enter | `CmdEnter` @3389 | 7.2; also reads signs |
| F | Fire | `CmdFire` @35C1 | 4.3; frigate only |
| G | Get | `CmdGet` @363B | 6.6 |
| H | Hyperspace | `CmdHyperspace` @3782 | "HYPER WHAT?" (in space H is read by the flight loop, 7.7) |
| I | Ignite torch | `CmdIgniteTorch` @3794 | underground: −1 torch, 150 turns of light |
| J | Jump | `CmdJump` @37DC | "JUMP...WHEE..." only |
| K | Klimb | `CmdKlimb` @37F1 | underground on a 10h cell: dungeon level − 1 (from 0: out), tower floor + 1 |
| L | Launch | `CmdLaunch` @38B0 | plane (7.4) or rocket (7.7) |
| M | Magic | `CmdMagic` @3B92 | ready spell 0-9 (no ownership check) |
| N | Negate time | `CmdNegateTime` @3BCE | −1 strange coin, 20 turns (5.4) |
| O | Offer gold | `CmdOffer` @3C2E | 9.2, 3.2 |
| P | Pass | `CmdPass` @3DBC | a turn, **no food** |
| Q | Quit/save | `CmdQuit` @3DC7 | save; surface, Earth and on foot only; the game continues |
| R | Ready weapon | `CmdReady` @3E50 | 4.2 |
| S | Steal | `CmdSteal` @3F25 | 9.4 |
| T | Transact | `CmdTransact` @4050 | 9.1, 9.3, shops 6.4 |
| U | Unlock | `CmdUnlock` @42F1 | 9.6; east/west only |
| V | View | `CmdView` @437E | −1 helm, map overview (surface, towns) |
| W | Wear armour | `CmdWear` @43F3 | 4.4 |
| X | X-it | `CmdXit` @44D4 | 7.4 |
| Y | Yell | `CmdYell` @4542 | echoes what you type until Enter; no effect |
| Z | Ztats | `CmdZtats` @4568 | status screen (level, sex, race, class, equipment, attributes, counts) |
| space | pass | `MainLoop` / `DungeonPass` @29BC | 0.10 food on the surface/in towns |
| arrows | move | `CheckStep` / `DungeonLoop` | 7.3; underground advance/turn/retreat (8.2) |

---

## 15. Notable bugs, quirks, dead code & differences from the Apple II original

### 15.1 Bugs and quirks (as the code runs)

From `docs/FINDINGS.md`, each re-checked against the routine named:

- **Ready/Wear limits** compare a binary n × 8 with BCD agility/strength (4.2, 4.4). (FINDINGS,
  checked in play)
- **Offer's attribute gift** has no cap and leaks one carry across its four additions (3.2).
  (FINDINGS, checked in play)
- **Prices** use Int + Cha as binary and wrap at 100h: 80 + 80 is the dearest (6.3). (FINDINGS)
- **A monster hit to exactly 0 HP survives** (SEC/SBC borrow test) (4.1). (FINDINGS)
- **Magic Missile** lacks the SEC: usually one extra point (5.3). (FINDINGS)
- **Ladder spells** test the square behind the player (5.2). (FINDINGS, checked in play)
- **Dungeon Attack's search** tests the last compared field instead of the slot number (a 6502
  DEC/LDX/BNE transliterated wrongly) and never checks `MonsterTile`: a free slot whose stale random
  position and level match the square ahead can be "killed" for gold and experience
  (`Attack_Dungeon` @2E6A). (FINDINGS)
- **The pub's drink** always gives tip 1 (6.4). (FINDINGS, checked in play)
- **"SISTER"** is unreachable: the cleric's shop tests `PlayerSex = 1` but it holds 'M'/'F'
  (`ShopClericSpells`). (FINDINGS)
- **TYPE prompt**: wrong keys corrupt the race (2.5). (FINDINGS, checked in play)
- **Steal's alarm** hits slot `Temp20`, never set by Steal (9.4). (FINDINGS)
- **Unlock** looks only east/west (9.6). (FINDINGS)
- **FindMonsterInDir** neither wraps at the map edge nor checks slot 0 (4.1). (FINDINGS)
- **Horse/plane refusals at the map edge** can leave the player off the map (7.3). (FINDINGS)
- **The horse/plane time-door test** in `StepHorse` can never be true. (FINDINGS)
- **Dungeon damage** adds two non-BCD values and subtracts them with `das` (8.4). (FINDINGS)
- **BCD counts wrap** at 99 (food, spells, armour, weapons, gold, experience). (FINDINGS)
- **Ctrl-Right at the default speed** makes `SpeedSetting` FEFFh and `CalcDelayTbl`'s `div`
  overflow: the game hangs (`ReadKey` @4F8E). (FINDINGS, checked in play)
- **Wear's "NOT OWNED!"** has no beep; Magic does not check ownership. (FINDINGS)
- **Escape during a title wait** leaves a word on the stack (`WaitForEscape` @0696). (FINDINGS)

Found while writing this document by reading. Those marked **(tested)** were afterwards confirmed
in the harness (section 16); the others have not been run:

- **Offer's specials are not limited to Earth**: `TimeZone = 3` and `MapType = 2` also match the
  Mars towne (3.2, 9.2). **(tested)**
- **Offer to talk 83h with 0 gold** still gives a random weapon, including the phaser 1 time in 8.
  **(tested)**
- **Damage sums wrap and are masked** (4.6): four simultaneous guard hits do nothing, two do 1 HP
  plus the town's hundreds; wounded monsters can hit harder than healthy ones. **(tested)**
- **Woods doubles monster damage** at every hit (the 6502's "CPX #6" on the tile underfoot), in
  towns as well. **(tested)**
- **P passes for free** while the space bar costs 0.10 food **(tested)**; the frigate and the flying
  plane eat nothing; the whole plane flight takes no turns.
- **A step refused by the terrain still costs its food** (11.1). **(tested)**
- **Negate Time** does not stop attacks, spells, wanderers or dungeon monsters (5.4).
- **Paralysis and time stop do not count down underground** (1.2).
- **Signs read "2112 A.D."** on any planet (7.2).
- **Magic Missile wraps** from level 71 on (5.3).
- **Prices wrap past 9999**: with b = 1 the Kill spell costs 336, less than with b = 2 (6.3).
- **Level 0 of a dungeon has one monster slot**, the others two (8.4).
- **The thief can steal the ring**, though no thief ever drops one (4.10, 4.7).
- **Descend has no upper bound in a dungeon.** **[data]** Pluto's dungeon (MAPG85) has a down ladder
  on level 15 at (1, 1) and no up ladder there. D)escend makes `DungeonLevel = 16` and the talk
  buffer is read as the level; whether K)limb leads back depends on the last talk file loaded
  (8.6). **(tested)**
- **Level 15 of Pluto's dungeon cannot be left upwards** except by the cleric's Surface spell: no
  up ladder, and Up Ladder always fails under a level without an empty cell (8.6). **(tested)**
- **Legends castle time doors** lead to the castle of another era, or hang on a castle file that
  does not exist; they keep the Legends talk file and overwrite the surface position (7.5).
  **(tested)**
- **A surface time door can be left behind** on the Legends map and stand beside the current one
  for up to 16 turns (7.5). **(tested)**
- **The first surface time door** of a new character appears after 256 turns (2.3). **(tested)**
- **"SHIP OFF COURSE!" always leads to the same place**, (7, 1, 1) (12). **(tested)**
- **Towns and dungeons reset** on every visit, so chests and pick-ups refill (7.6) **(inferred)**.
- **Steal's stale slot** can exceed 31 and write past the mood table (9.4) **(inferred)**.
- **`Wands + Staffs`** is a binary sum that is zero at 100h (5.1).

### 15.2 Dead code and the 1989 patches

(FINDINGS, "The 1989 patches and dead code"; seen in the source as commented `db` islands.)

- Disk-swap prompts ("(INSERT PLAYER DISK)" at 0776, CHARGEN 5414/5A1E, SPACE 71CF/7207) were cut by
  turning `call PrintInline` into `jmp short` over the text; three-byte calls became NOPs (71F6,
  7230, and the five NOPs in `ReadDirection` @2378). `SPACE.ASM:SetMapFileLetter` (@720B) is
  written into the middle of one of those dead prompts, so the X/G letter of the file names is
  itself part of the patch: before it the planets' files must have had the Earth files' names on
  another disk **(inferred)**.
- Unreached: a castle picture loader for `PICCAS` (04A8, file absent), the 1983 timer calibration
  (06B3; `SetDefaultSpeed` @06AC now just stores 00FFh), a developer screen dump to `PICXXX` inside
  `CmdCast` (3117-3152), a second sign routine (50E4), an old tone routine (5CED/5F0D) and others.
- Page 8 of the MONSTERS shape file is a fragment no dungeon kind reaches (kinds are 1-7).
- Items 6, 8, 10 (gem, red gem, green gem) have names but no use.

### 15.3 Differences from the Apple II original

The repository has no Apple II code, so only what the PC code itself shows can be said:

- The program is a **close transliteration of the 6502 original** (`stc; cmc; sbb` for SEC/SBC,
  "zero page" variables, high-bit-terminated strings, BCD via `daa`/`das`). Several bugs are
  transliteration slips, i.e. **PC-only** behaviour: the dungeon Attack search (6502 LDX sets the
  flags), the dungeon key time-out (16-bit DI for the 6502's 8-bit Y), and probably the Magic
  Missile's missing SEC (FINDINGS).
- Speed control (Ctrl-Left/Right, saved in PLAYER) and its divide overflow are PC additions.
- The 1989 Origin reissue removed the floppy prompts and the timer calibration; with them gone, many
  delays depend on CPU speed.
- **Manual vs. code**: the manual's fighter +10 and hobbit +5 are +15 and +10 in the code (FINDINGS).

---

## 16. Testing, and what is still open

### 16.1 How the tests were run

The claims this document first drew only from reading were run in the harness of `c/test/` (its
README describes it). `python3 c/test/run.py` builds it and makes the standard character: 15 in all
six attributes, male human fighter (Strength 35, Agility 15, Intelligence 20), 400 hit points, food
and gold, at (20, 20) in 1423 B.C. A test is `harness gamedata WORKDIR "KEYS"` with that character's
PLAYER file copied into a fresh work directory. In the key strings quoted in this document `P×n`
stands for n times `P` and "a space" for the space bar; `{SET:...}` and `{GOTO:...}` are the
harness's cheats; a leading `...` stands for the start of the string given just before it. The
results quoted are the text screen and the "player at x,y, map type n" line the harness prints at
the end. The harness's BIOS tick is fixed, so `Random` starts the same way every time: each string
gives the same result on every run.

What the method can and cannot show:

- The harness runs the C, not ULTIMAII.EXE. For every path exercised the assembly was re-read
  against the C: `MonsterAttack`/`EndTurn`, `DungeonMonsterAttack`, the spawn rule of
  `SpawnDungeonMonsters`, `CmdAttack`/`Attack_Damage`, `CmdOffer`, `MoveTimeDoor`, `EnterTimeDoor`,
  `LoadMapAndMonsters`, `SaveGame`, `LeaveToSurface`, `ReadWriteFile`, `CmdDescend` and the ladder
  code, the ladder spells, `ReadDungeonCell`, `StepOnFoot`, `CmdPass`, `SpendAttrPoints`,
  `ReadTwoDigits`, `CalcPrice`, `StarRnd`, `Hyperwarp`, `XorPlayerMark`. **No difference between the
  C and the assembly was found.** (`MoveStars` was not compared line by line; a second model written
  from the assembly gives the harness's result, section 12.)
- What the screen does not show (a turn's attacks, hits and damage byte, map squares, the door
  variables, hit points turn by turn) was read with a scratch copy of `harness.c`, not in the
  repository, that adds a `{DUMP:...}` token and logs `Random`, `PlayAttackSound` and
  `PlayHurtSound` through the linker's `--wrap`; the game's C was compiled unchanged. The counts
  and loss sets of 4.1, 4.4, 4.6 and 8.4 come from those logs; the key strings quoted give the
  stated end states with the repository's harness.
- `XorPlayerMark` (1.2): besides the reading of @5255 and its bitmap, the 16 × 16 pixels of the
  player's square were dumped at the hit sound: the disc, with the player's figure dark inside it.
- `{GOTO}` cannot select the planets' files (letter G). Mars was reached by an actual flight (9.2);
  for Pluto's dungeon the files were copied under X names (8.6).
- There is no DOS underneath: "WRONG DISK" (7.5) is the harness reporting a missing file, which is
  what the FCB open of a missing file returns under DOS. Real-time behaviour (delays, the idle
  time-outs) is not modelled.

### 16.2 The former open questions

| # | question | result | where |
|---|---|---|---|
| 1 | Legends castle time doors: where they lead, and the "WRONG DISK" loop | **settled**: the 1423 B.C. or 1990 A.D. castle for `TimeDoorSpot` 2 or 4, an endless "WRONG DISK" for 0 or 6 | 7.5 |
| 2 | Pluto's dungeon, the ladder down from level 15 | **settled**: level 16 is the talk buffer; the way back depends on the last talk file; level 15 itself has no way up | 8.6 |
| 3 | The damage tables | **settled**: every table value and formula observed, including the four-guard wrap and the MapType hundreds | 4.1, 4.4, 4.6, 8.4 |
| 4 | Offer in the Mars towne; 0 gold to talk 83h | **settled**: all four specials work on Mars; a weapon for 0 gold | 3.2, 9.2 |
| 5 | Is the off-course destination random? | **settled**: no, it is (7, 1, 1) every time | 12, 7.7 |
| 6 | What `XorPlayerMark` draws | **settled**: a white disc XOR-ed over the player's square | 1.2 |
| 7 | Bit 3 of a dungeon cell | **settled**: nothing sets it; it is the unused top bit of a 4-bit monster field | 8.1 |
| 8 | What the 1989 patch changed | **still open** | 16.3 |
| 9 | Can character creation reach the best price class? | **settled**: no (exhaustive enumeration) | 6.3 |
| 10 | Stale time doors after a rocket trip | **corrected**: a rocket trip leaves none; the Legends castle exits do, and that door is removed again | 7.5 |

Also checked on the way: no hit point regeneration (11.2), P)ass free and the space bar 0.10 food
(11.1), the first time door after 256 surface turns (2.3), the dungeon monsters' hit point formula
(8.4), the weapon damage table and the hit chance (4.1), the armour's hit chances (4.4).

### 16.3 Still open

1. **The 1983 Sierra PC release**: what Origin's 1989 patch changed. The repository holds only the
   1989 program. What it shows of the patch is in 15.2 and FINDINGS: disk prompts jumped over, calls
   turned into NOPs, the timer calibration cut off, the file-letter routine written into a dead
   prompt, and the remains of a loader envelope. All of these are disk handling and timing; none
   of the routines tested here carries such a trace. But a patched constant or a changed
   instruction leaves no trace, so whether any rule of play differs from 1983 cannot be told
   without a 1983 disk image.
2. **Intent.** Whether the castle time doors were meant to work as they do (7.5), and whether the
   top of MAPG85 is a tower layout used by mistake (8.6), are questions about the authors; the
   code and data only show what happens.
3. **Level 16 with a talk buffer that was never loaded** (8.6): zeros in the harness; on a PC it is
   whatever DOS left in memory after the program's data.
4. **Not run.** Conclusions still marked **(inferred)** that no test above covers stand as read
   from the code: among them the timers that do not count down underground (1.2), Negate Time's
   limits (5.4), the Magic Missile wrap from level 71 (5.3), Steal's stale slot (9.4), the plane
   flight as one command (7.4), and death and restart (11.4).

### 16.4 Corrections from testing

Where a test contradicted or sharpened what this document said before:

- **Stale time doors** (was 16, item 10): a map saved at a rocket launch does not end up with two
  doors. The launch saves map and PLAYER together and the door timer does not run off Earth, so
  the door is consistent on return. A door is left behind only on the Legends surface, by leaving
  through the castle, and it is not permanent: `MoveTimeDoor` adopts and removes it when the cycle
  comes round (7.5).
- **Off-course destination** (was 12, 7.7): it does not depend on how long one waited; it is always
  (7, 1, 1).
- **First time door** (2.3): it appears at the end of the 256th turn at the era's *second* spot,
  not the first.
- **Castle time doors** (7.5): besides `MapType = 3`, the PLAYER record is saved with the door's
  castle coordinates as the surface position, so the new castle is left at the wrong place on the
  surface; and the talk file stays that of the Legends castle. Neither was in the earlier text.
- **Pluto's dungeon** (15.1, now 8.6): the ladders of levels 14-15 are not "swapped" but a tower's
  top; the point missed before is that level 15 has no way up at all, by ladder or by Up Ladder.
- **Food** (11.1): a step refused by the terrain still costs its food.
- **Dungeon blows** (8.4): the average loss on level 15 is 72.5, not 72; the ranges per level are
  now given exactly.
- **Price class** (6.3): the best sum at creation is exactly 75h (it read "about 75h"), and no
  character starts outside classes 6 and 7.
- **Woods** (4.6): the doubling also applies on the woods squares inside towns.
