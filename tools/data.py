import sys, struct, hashlib
img = open(sys.argv[1], 'rb').read()[512:]
D0, D1 = 0x7410, 0x8AC0
d = img[D0:D1]
print('data seg %04X-%04X (%d bytes), DS offsets 0000-%04X' % (D0, D1, len(d), len(d)))
# nonzero runs (merge gaps < 16)
runs, i = [], 0
while i < len(d):
    if d[i]:
        j = i; z = 0
        while j < len(d) and z < 16:
            z = z + 1 if d[j] == 0 else 0
            j += 1
        runs.append((i, j - z)); i = j
    else:
        i += 1
for a, b in runs:
    blk = d[a:b]
    pr = sum(32 <= c < 127 or c == 0x8d for c in blk) / len(blk)
    print('  DS:%04X-%04X %5d print %.0f%% %s' % (a, b, b - a, pr * 100, blk[:32].hex()))
# envelope comparison
u1 = open(sys.argv[2], 'rb').read()
h = struct.unpack('<14H', u1[:28]); hs = h[4] * 16
stub1 = hs + h[11] * 16 + h[10]
print('U1 ULTIMA.EXE: image end %X, stub at image %X, bytes after stub start %X' % (len(u1) - hs, stub1 - hs, len(u1) - stub1))
t1 = u1[stub1 + 0x20:]; t2 = img[0x8AE0:]
print('U1 tail len %X, U2 tail len %X, equal=%s' % (len(t1), len(t2), t1 == t2))
print('U1 tail head', t1[:32].hex()); print('U2 tail head', t2[:32].hex())
x = bytes(a ^ b for a, b in zip(t1, t2)); print('xor head', x[:32].hex())
