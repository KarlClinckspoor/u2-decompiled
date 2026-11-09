import sys, capstone
b = open(sys.argv[1], 'rb').read()[512:]
md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
for spec in sys.argv[2:]:
    off, n = (int(x, 16) for x in spec.split(':'))
    print('=== %05X' % off)
    for i, ins in enumerate(md.disasm(b[off:off + 0x400], off)):
        if i >= n: break
        print('%05X  %-16s %s %s' % (ins.address, ins.bytes.hex(), ins.mnemonic, ins.op_str))
