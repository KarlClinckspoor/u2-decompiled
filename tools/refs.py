import sys, re, capstone
img = open(sys.argv[1], 'rb').read()[512:]
code = img[:0x7410]
md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
# who mentions these addresses as 16-bit immediates / displacements
targets = [int(x, 16) for x in sys.argv[2:]]
for t in targets:
    hits = [m.start() for m in re.finditer(re.escape(t.to_bytes(2, 'little')), code)]
    out = []
    for h in hits:
        # find an instruction that contains h: try decoding from h-1..h-4
        for back in range(1, 5):
            s = h - back
            ins = next(md.disasm(code[s:s + 8], s), None)
            if ins and s + ins.size > h and ins.size >= back + 2:
                out.append('%04X: %s %s' % (s, ins.mnemonic, ins.op_str)); break
    print('%04X <- %s' % (t, out[:8]))
# CS-segment writes (self-modifying code or CS variables)
w = []
for m in re.finditer(rb'\x2e(\x88|\x89|\xc6|\xc7|\xfe|\xff|\x80|\x83|\x81|\xd0|\xd1|\xa2|\xa3)', code):
    ins = next(md.disasm(code[m.start():m.start() + 8], m.start()), None)
    if ins and ins.mnemonic not in ('cmp', 'test', 'jmp', 'call', 'push') and ins.op_str.startswith(('byte ptr cs:', 'word ptr cs:')):
        w.append('%04X %s %s' % (ins.address, ins.mnemonic, ins.op_str))
print('CS writes:', len(w))
for x in w: print('  ', x)
