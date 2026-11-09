#!/usr/bin/env python3
"""Post-link step: put back the remains of Origin's 1989 protection envelope.

    python3 tools/postlink.py BUILT.EXE ORIGINAL.EXE

Ultima II's ULTIMAII.EXE and Ultima I's ULTIMA.EXE carry the remains of the same envelope. After
the load image LINK makes come filler, a small stub that sets SS:SP and jumps to the program's
real entry point (the header's entry point is the stub), and 0x500 bytes that look encrypted.
None of it is built from source: this copies everything after the linked image from the original
at build time (the repository holds none of it) and sets the header fields the envelope changed:
file size, SS:SP, CS:IP and the checksum.

    ULTIMAII.EXE  image ends 8AC0; stub at 8AC0, entry 08AC:0000, SS:SP 09FE:0064,
                  checksum EA36 (LINK writes 09DD); the relocation table (one entry) moved from
                  LINK's 001E to 001C, over the word 0001 LINK writes there
    ULTIMA.EXE    image ends 88E4; stub at 88F0, entry 088F:0000, SS:SP 09E1:0064,
                  checksum and relocation table unchanged from LINK's

It refuses to do anything unless the linked image is a prefix of the original's, the relocation
entries are the same (and in the same order), every other header field matches, and the header
it ends up with is the original's, so it can't hide a build difference.
"""
import struct, sys

FIELDS = ['sig', 'last', 'pages', 'nrel', 'hdrpar', 'minalloc', 'maxalloc', 'ss', 'sp', 'csum', 'ip', 'cs',
          'relo', 'ovl']
SET = {'last', 'pages', 'ss', 'sp', 'csum', 'ip', 'cs', 'relo'}     # what the envelope changed


def relocs(d, h):
    return d[h[12]:h[12] + 4 * h[3]]


def postlink(b, o):
    """b: the linked EXE (bytes), o: the original. Returns (finished EXE, bytes added, original header)."""
    b = bytearray(b)
    hb, ho = struct.unpack('<14H', b[:28]), struct.unpack('<14H', o[:28])
    bad = ['%s %04X/%04X' % (n, x, y) for n, x, y in zip(FIELDS, hb, ho) if n not in SET and x != y]
    if bad:
        raise SystemExit('postlink: header differs from the original (built/original): ' + ', '.join(bad))
    rel = relocs(b, hb)
    if rel != relocs(o, ho):
        raise SystemExit('postlink: relocation entries differ from the original')
    hsize = hb[4] * 16
    if hb[12] != ho[12]:                      # the envelope moved the table: lay the header out again
        b[0x1C:hsize] = bytes(hsize - 0x1C)
        b[ho[12]:ho[12] + len(rel)] = rel
        struct.pack_into('<H', b, 0x18, ho[12])
    if b[0x1C:hsize] != o[0x1C:hsize]:
        raise SystemExit('postlink: header after the fixed fields differs from the original')
    ib, io = b[hsize:], o[ho[4] * 16:]
    if ib != io[:len(ib)]:
        raise SystemExit('postlink: the linked image differs from the original; not adding the envelope')
    b += io[len(ib):]
    n = len(b)
    struct.pack_into('<HH', b, 2, n % 512, (n + 511) // 512)
    struct.pack_into('<HHH', b, 0x0E, ho[7], ho[8], ho[9])   # SS, SP, checksum
    struct.pack_into('<HH', b, 0x14, ho[10], ho[11])         # IP, CS
    return bytes(b), len(io) - len(ib), ho


def main():
    built, orig = sys.argv[1], sys.argv[2]
    out, added, ho = postlink(open(built, 'rb').read(), open(orig, 'rb').read())
    open(built, 'wb').write(out)
    print('postlink: envelope remains appended (%d bytes), entry %04X:%04X, SS:SP %04X:%04X, checksum %04X'
          % (added, ho[11], ho[10], ho[7], ho[8], ho[9]))


if __name__ == '__main__':
    main()
