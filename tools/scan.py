import sys, struct, re, hashlib
p = sys.argv[1]
b = open(p, 'rb').read()
print('size', len(b), 'sha1', hashlib.sha1(b).hexdigest())
sig, last, pages, nrel, hdrpar, minalloc, maxalloc, ss, sp, csum, ip, cs, relofs, ovl = struct.unpack('<2s13H', b[:28])
print(sig, 'last', last, 'pages', pages, 'nrel', nrel, 'hdr', hdrpar * 16, 'min', minalloc, 'max', maxalloc,
      'SS:SP %04X:%04X' % (ss, sp), 'CS:IP %04X:%04X' % (cs, ip), 'csum %04X' % csum, 'relofs', relofs, 'ovl', ovl)
img_end = (pages - 1) * 512 + (last or 512)
print('image bytes', img_end - hdrpar * 16, 'file tail beyond image', len(b) - img_end)
rels = [struct.unpack('<HH', b[relofs + 4 * i:relofs + 4 * i + 4]) for i in range(nrel)]
print('relocs', ['%04X:%04X' % (s, o) for o, s in rels][:60])
print('header bytes 1C..', b[28:relofs].hex())
# checksum
img = b[:img_end] + (b'\0' if img_end & 1 else b'')
s = 0
for i in range(0, len(img), 2):
    if i == 0x12: continue
    s = (s + struct.unpack('<H', img[i:i + 2])[0]) & 0xFFFF
print('checksum valid' if ((s + csum) & 0xFFFF) == 0xFFFF else 'checksum mismatch (sum %04X)' % s)
code = b[hdrpar * 16:img_end]
for sigtxt in [b'Lattice', b'Microsoft', b'Borland', b'Turbo', b'MS Run-Time', b'Copyright', b'(C)', b'(c)',
               b'Origin', b'Sierra', b'Garriott', b'R6', b'stack', b'null pointer', b'Abnormal', b'Divide']:
    for m in re.finditer(re.escape(sigtxt), code):
        print('sig', sigtxt, hex(m.start()), code[max(0, m.start() - 16):m.start() + 48])
print('--- strings ---')
for m in re.finditer(rb'[\x20-\x7e]{6,}', code):
    print('%05X %s' % (m.start(), m.group().decode()))
