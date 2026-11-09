#!/usr/bin/env python3
"""Draw the game's pictures to PNG files: the 64 map tiles and the dungeon monster shapes.

    python3 tools/sprites.py [--out DIR] [--scale N]

Writes DIR/tiles.png (default DIR build/sprites): the 64 16x16 tile bitmaps TileBmp00-3F in
TilePtrTbl order, 8 per row, read from src/U2DATA.ASM, in CGA palette 1 (black, cyan, magenta,
white). Tile n is map code n*4 (map files, monster files, MonsterTile) and half code n*2 (the
tile caches, PlayerTile, CheckStep).

And DIR/dungeon.png: the block shapes in gamedata/MONSTERS (the monster buffer, MonsterBufPtr),
two per row: page 0 holds the small generic shapes drawn beyond depth 1 (offsets from
MonsterShapeOfsTbl: 80h C0h E0h F0h F8h), pages 1-7 the dungeon monster kinds 1-7, page 8 is a
leftover fragment (a kind has 3 bits). Each shape is pairs (X, pattern*32 + Y) up to X = 0, one 4x4
block per pair at (X*4, Y*4) of the 256x128 view, filled with the byte FillPatternTbl[pattern]
as FillBlock4x4 does (0FFh, 11h, 88h, 0CCh, 33h, 0, 0, 0).

Identified (shapes compared with the Ultima Codex's Ultima II icon pages):
  tiles  0Bh sea serpent, 0Ch orc, 0Dh daemon, 0Eh devil, 0Fh balron, 10h Minax, 11h horse,
         12h frigate (also the pirate ship), 13h plane, 14h rocket, 18h guard, 19h jester,
         1Ah merchant, 1Bh king, 3Ch-3Fh fighter, cleric, wizard, thief (and the player on foot)
  kinds  1 orc, 2 ghost, 3 carrion creeper, 4 viper, 5 gremlin, 6 minotaur, 7 balron
"""
import argparse, os, re, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PAL = [(0, 0, 0), (85, 255, 255), (255, 85, 255), (255, 255, 255)]
GREY = (70, 70, 70)
FILL = [0xFF, 0x11, 0x88, 0xCC, 0x33, 0, 0, 0]          # FillPatternTbl (SCREEN.ASM)


def write_png(path, pix):
    h, w = len(pix), len(pix[0])
    raw = b''.join(b'\0' + bytes(v for p in row for v in p) for row in pix)

    def chunk(t, d):
        return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


def canvas(w, h):
    return [[GREY] * w for _ in range(h)]


def put(pix, x0, y0, s, colour):
    for dy in range(s):
        row = pix[y0 + dy]
        for dx in range(s):
            row[x0 + dx] = colour


def tiles(src):
    """{label: bytes} of TileBmpNN and the TilePtrTbl order."""
    lines = open(src, 'rb').read().decode('latin1').split('\r\n')
    bmp, cur = {}, None
    for l in lines:
        m = re.match(r'^(TileBmp[0-9A-F]{2}) label byte', l)
        if m:
            cur = m.group(1)
            bmp[cur] = []
            continue
        m = re.match(r'^\s*db\s+([^;]*)', l)
        if m and cur:
            bmp[cur] += [int(x.strip().rstrip('hH'), 16) for x in m.group(1).split(',')]
            if len(bmp[cur]) >= 0x42:
                cur = None
    i = next(k for k, l in enumerate(lines) if l.startswith('TilePtrTbl label'))
    order = [m.group(1) for m in (re.match(r'^\s*dw (TileBmp\w+)', l) for l in lines[i + 1:]) if m][:64]
    return bmp, order


def draw_tiles(src, out, s):
    bmp, order = tiles(src)
    cw = 16 * s + 8
    pix = canvas(8 * cw + 8, 8 * cw + 8)
    for n, name in enumerate(order):
        b = bmp[name]
        w, h, px = b[0], b[1], b[2:]
        ox, oy = (n % 8) * cw + 8, (n // 8) * cw + 8
        for y in range(h):
            for x in range(w):
                for k in range(4):
                    put(pix, ox + (x * 4 + k) * s, oy + y * s, s, PAL[(px[y * w + x] >> (6 - 2 * k)) & 3])
    write_png(out, pix)
    return len(order)


def shapes(b):
    out = []
    for page in range((len(b) + 255) // 256):
        for start in ([0x80, 0xC0, 0xE0, 0xF0, 0xF8] if page == 0 else [0]):
            o, blocks = page * 256 + start, []
            while o + 1 < len(b) and b[o] != 0:
                blocks.append((b[o], b[o + 1] & 31, b[o + 1] >> 5))
                o += 2
            out.append(('page %d +%02Xh' % (page, start), blocks))
    return out


def draw_dungeon(path, out, s):
    sh = shapes(open(path, 'rb').read())
    vw, vh, g = 256 * s, 128 * s, 8
    pix = canvas(2 * vw + 3 * g, ((len(sh) + 1) // 2) * (vh + g) + g)
    for n, (_, blocks) in enumerate(sh):
        ox, oy = (n % 2) * (vw + g) + g, (n // 2) * (vh + g) + g
        for y in range(vh):
            pix[oy + y][ox:ox + vw] = [(0, 0, 0)] * vw
        for bx, by, pat in blocks:
            byte = FILL[pat]
            for k in range(4):
                if bx * 4 + k < 256 and by * 4 + 3 < 128:
                    c = PAL[(byte >> (6 - 2 * k)) & 3]
                    for dy in range(4):
                        put(pix, ox + (bx * 4 + k) * s, oy + (by * 4 + dy) * s, s, c)
    write_png(out, pix)
    return [(name, len(b)) for name, b in sh]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=os.path.join(ROOT, 'build', 'sprites'))
    ap.add_argument('--scale', type=int, default=4)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    n = draw_tiles(os.path.join(ROOT, 'src', 'U2DATA.ASM'), os.path.join(a.out, 'tiles.png'), a.scale)
    print('tiles.png: %d tiles' % n)
    sh = draw_dungeon(os.path.join(ROOT, 'gamedata', 'MONSTERS'), os.path.join(a.out, 'dungeon.png'),
                      max(1, a.scale // 2))
    print('dungeon.png: ' + ', '.join('%s (%d blocks)' % x for x in sh))


if __name__ == '__main__':
    main()
