import sys, re, collections, capstone
b = open(sys.argv[1], 'rb').read()[512:]
code = b[:0x7410]
print('tail of code 7380-7410:', code[0x7380:0x7410].hex())
print('data 7410-7480:', b[0x7410:0x7480].hex())
# int 21h function numbers: look for mov ah,NN (B4 NN) within 6 bytes before CD 21
fn = collections.Counter()
for m in re.finditer(rb'\xcd\x21', code):
    w = code[max(0, m.start() - 8):m.start()]
    i = w.rfind(b'\xb4')
    fn['%02X' % w[i + 1] if i >= 0 else '?'] += 1
print('int 21h by AH:', dict(fn))
ints = collections.Counter('%02X' % code[m.start() + 1] for m in re.finditer(rb'\xcd', code))
print('int opcodes (rough):', ints.most_common(12))
# call targets
md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
calls = collections.Counter()
for m in re.finditer(rb'\xe8', code):
    t = (m.start() + 3 + int.from_bytes(code[m.start() + 1:m.start() + 3], 'little', signed=True)) & 0xFFFF
    calls[t] += 1
print('top call targets:', [('%04X' % t, n) for t, n in calls.most_common(15)])
print('jmp short + nop (MASM forward-ref):', len(re.findall(rb'\xeb[\x00-\x7f]\x90', code)))
print('push bp;mov bp,sp frames:', len(re.findall(rb'\x55\x8b\xec', code)))
