"""Recursive disassembly of ULTIMAII.EXE code segment (image 0000-7410), CS = image base.
Usage: rdis.py EXE [--inline ADDR:KIND ...]   KIND = z (ASCIIZ) or a number of bytes."""
import sys, collections, capstone
from capstone import x86

exe = sys.argv[1]
img = open(exe, 'rb').read()[512:]
CODE_END = 0x7410
INLINE = {0x4FDF: 'z', 0x52CA: 8}
for a in sys.argv[2:]:
    if a.startswith('--'): continue
    k, v = a.split(':')
    INLINE[int(k, 16)] = 'z' if v == 'z' else int(v)

md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
md.detail = True
kind = bytearray(CODE_END)     # 0 unknown, 1 code start, 2 code cont, 3 inline data
entries = [0x100]
TABLES = {0x730: 26}
for a in sys.argv[2:]:
    if a.startswith('--table='):
        k, v = a[8:].split(':'); TABLES[int(k, 16)] = int(v)
for t, n in TABLES.items():
    for i in range(n):
        entries.append(int.from_bytes(img[t + 2 * i:t + 2 * i + 2], 'little'))
    for i in range(t, t + 2 * n): kind[i] = 3
funcs = set([0x100])
indirect = []
calls_to = collections.Counter()
seen = set()
while entries:
    pc = entries.pop()
    while 0 <= pc < CODE_END and pc not in seen:
        ins = next(md.disasm(img[pc:pc + 16], pc), None)
        if ins is None:
            print('BAD decode at %04X' % pc); break
        seen.add(pc)
        kind[pc] = 1
        for i in range(1, ins.size): kind[pc + i] = 2
        nxt = pc + ins.size
        g = ins.groups
        m = ins.mnemonic
        tgt = None
        if ins.operands and ins.operands[0].type == x86.X86_OP_IMM and (capstone.CS_GRP_JUMP in g or capstone.CS_GRP_CALL in g):
            tgt = ins.operands[0].imm & 0xFFFF
        elif capstone.CS_GRP_JUMP in g or capstone.CS_GRP_CALL in g:
            indirect.append((pc, m, ins.op_str))
        if m == 'call':
            if tgt is not None:
                calls_to[tgt] += 1
                funcs.add(tgt)
                entries.append(tgt)
                if tgt in INLINE:
                    k = INLINE[tgt]
                    if k == 'z':
                        e = img.index(b'\0', nxt) + 1
                    else:
                        e = nxt + k
                    for i in range(nxt, e): kind[i] = 3
                    nxt = e
            pc = nxt
            continue
        if m in ('ret', 'retf', 'iret', 'hlt') or m == 'jmp':
            if tgt is not None: entries.append(tgt)
            break
        if tgt is not None:
            entries.append(tgt)
        pc = nxt

cov = collections.Counter(kind[0x100:CODE_END])
print('code bytes', cov[1] + cov[2], 'inline data', cov[3], 'unreached', cov[0], 'of', CODE_END - 0x100)
print('functions (call targets)', len(funcs))
print('indirect branches:')
for p, m, o in indirect: print('  %04X %s %s' % (p, m, o))
# routines that touch their return address early
print('call targets that pop/inspect the stack first:')
for t in sorted(funcs):
    ins = list(md.disasm(img[t:t + 24], t))[:4]
    s = '; '.join('%s %s' % (i.mnemonic, i.op_str) for i in ins)
    if ins and (ins[0].mnemonic == 'pop' or 'sp' in s and 'mov bp, sp' in s):
        print('  %04X x%d  %s' % (t, calls_to[t], s))
# gaps
print('unreached gaps >= 4 bytes:')
i = 0x100
gaps = []
while i < CODE_END:
    if kind[i] == 0:
        j = i
        while j < CODE_END and kind[j] == 0: j += 1
        if j - i >= 4: gaps.append((i, j))
        i = j
    else:
        i += 1
for a, b in gaps:
    blk = img[a:b]
    z = blk.count(0) / len(blk)
    pr = sum(32 <= c < 127 for c in blk) / len(blk)
    print('  %04X-%04X %5d  zero %.0f%%  print %.0f%%  %s' % (a, b, b - a, z * 100, pr * 100, blk[:24].hex()))
open(exe + '.kind', 'wb').write(bytes(kind)) if False else None

