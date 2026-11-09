"""Generate a single MASM source for ULTIMAII.EXE (code 0100-7410 + data 7410-8AC0).
    gen.py EXE OUT.ASM [FORCEFILE]
Code found by recursive disassembly (inline-string calls and the command table known);
everything else is DB. Instructions listed in FORCEFILE are written as DB."""
import sys, re, os, capstone
from capstone import x86

exe, out = sys.argv[1], sys.argv[2]
force = set()
if len(sys.argv) > 3 and os.path.exists(sys.argv[3]):
    force = {int(x, 16) for x in open(sys.argv[3]).read().split()}
img = open(exe, 'rb').read()[512:]
CODE_END, DATA_END = 0x7410, 0x8AC0
INLINE = {0x4FDF: 'z', 0x52CA: 8}
TABLES = {0x730: 26}

md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
md.detail = True
kind = bytearray(CODE_END)
insn = {}
entries = [0x100]
for t, n in TABLES.items():
    for i in range(n):
        entries.append(int.from_bytes(img[t + 2 * i:t + 2 * i + 2], 'little'))
    for i in range(t, t + 2 * n): kind[i] = 3
seen = set()
while entries:
    pc = entries.pop()
    while 0x100 <= pc < CODE_END and pc not in seen and kind[pc] != 3:
        ins = next(md.disasm(img[pc:pc + 16], pc), None)
        if ins is None: break
        seen.add(pc); insn[pc] = ins
        kind[pc] = 1
        for i in range(1, ins.size): kind[pc + i] = 2
        nxt = pc + ins.size
        g, m = ins.groups, ins.mnemonic
        tgt = None
        if ins.operands and ins.operands[0].type == x86.X86_OP_IMM and (capstone.CS_GRP_JUMP in g or capstone.CS_GRP_CALL in g):
            tgt = ins.operands[0].imm & 0xFFFF
        if tgt is not None: entries.append(tgt)
        if m == 'call':
            if tgt in INLINE:
                e = img.index(b'\0', nxt) + 1 if INLINE[tgt] == 'z' else nxt + INLINE[tgt]
                for i in range(nxt, e): kind[i] = 3
                nxt = e
            pc = nxt; continue
        if m in ('ret', 'retf', 'iret', 'hlt', 'jmp'): break
        pc = nxt

# labels: branch targets that are instruction starts
labels = set()
for a, ins in insn.items():
    if ins.operands and ins.operands[0].type == x86.X86_OP_IMM and (capstone.CS_GRP_JUMP in ins.groups or capstone.CS_GRP_CALL in ins.groups):
        t = ins.operands[0].imm & 0xFFFF
        if t in insn: labels.add(t)
for t, n in TABLES.items():
    for i in range(n):
        v = int.from_bytes(img[t + 2 * i:t + 2 * i + 2], 'little')
        if v in insn: labels.add(v)

def hx(v):
    s = '%X' % v
    return ('0' + s if s[0] in 'ABCDEF' else s) + 'h'

def num(m):
    return hx(int(m.group(1), 16))

STR = {'movsb', 'movsw', 'stosb', 'stosw', 'lodsb', 'lodsw', 'cmpsb', 'cmpsw', 'scasb', 'scasw'}
OK = set('''mov add adc sub sbb and or xor cmp test inc dec neg not push pop call jmp ret
 shl shr sal sar rol ror rcl rcr mul imul div idiv cbw cwd lea xchg in out int nop
 stc clc cmc std cld sti cli pushf popf lahf sahf jcxz loop loope loopne iret
 jo jno jb jae je jne jbe ja js jns jp jnp jl jge jle jg'''.split())

def conv(ins):
    """MASM text for ins, or None to fall back to DB."""
    m, o = ins.mnemonic, ins.op_str
    pre = ''
    if m.startswith('rep'):
        parts = m.split()
        if len(parts) == 2 and parts[1] in STR:
            if 'cs:' in o or 'ss:' in o or ('es:' in o and parts[1].startswith(('lods',))):
                return None
            return parts[0] + ' ' + parts[1]
        return None
    if m in STR:
        if re.search(r'(cs|ss|es):\[si\]', o):
            return None
        return m
    if m not in OK:
        return None
    if capstone.CS_GRP_JUMP in ins.groups or capstone.CS_GRP_CALL in ins.groups:
        if ins.operands[0].type == x86.X86_OP_IMM:
            t = ins.operands[0].imm & 0xFFFF
            if t not in labels: return None
            lab = 'L%04X' % t
            if m == 'jmp':
                op = ins.bytes[0]
                fwd = t > ins.address
                if op == 0xEB:
                    if fwd:
                        nop = img[ins.address + 2] == 0x90
                        return ('jmp ' + lab, 1) if nop else 'jmp short ' + lab
                    return 'jmp ' + lab
                if op == 0xE9:
                    d = t - (ins.address + 2)
                    if -128 <= d <= 127 and not fwd:
                        return None     # MASM would make it short
                    return 'jmp ' + lab if not fwd or d > 127 + 1 else None
                return None
            return m + ' ' + lab
        # indirect
        o2 = o.replace('word ptr ', 'word ptr ')
    if 'ptr [' in o or 'ptr cs:' in o or 'ptr es:' in o or 'ptr ss:' in o or 'ptr ds:' in o or o.startswith('[') or ', [' in o:
        pass
    o = re.sub(r'0x([0-9a-f]+)', num, o)
    # direct memory without registers -> ds:[x]
    def mem(mm):
        seg, inner = mm.group(1), mm.group(2)
        if re.search(r'\b(bx|bp|si|di)\b', inner):
            return (seg or '') + '[' + inner.replace(' ', '') + ']'
        return (seg or 'ds:') + '[' + inner.replace(' ', '') + ']'
    o = re.sub(r'((?:cs|ds|es|ss):)?\[([^\]]+)\]', mem, o)
    if m in ('lea',) and 'ds:[' in o:
        o = o.replace('ds:[', '[')
        o = re.sub(r'\[([0-9A-F]+h)\]', r'ds:[\1]', o)
    return (m + ' ' + o).strip()

lines = []
w = lines.append
w('; ULTIMAII.EXE regenerated by gen.py')
w('CODE SEGMENT')
w('ASSUME CS:CODE')
w('ORG 100h')

def db(bs, at=None):
    for i in range(0, len(bs), 16):
        w('\tdb ' + ','.join(hx(b) for b in bs[i:i + 16]) + ('\t;@%04X' % (at + i) if at is not None else ''))

pc = 0x100
dbbuf = []
nforced = ndb = 0
def flush():
    global dbbuf
    if dbbuf: db(bytes(dbbuf), pc - len(dbbuf)); dbbuf = []
CODE_LAST = 0x740B
while pc < CODE_LAST:
    if kind[pc] == 1 and pc in insn:
        ins = insn[pc]
        if pc == 0x100:
            flush(); w('L0100:\tmov ax, DATA'); pc += 3; continue
        r = None if pc in force else conv(ins)
        skip = 0
        if isinstance(r, tuple): r, skip = r
        if r is None:
            if pc in labels: flush(); w('L%04X:' % pc)
            dbbuf.extend(ins.bytes); pc += ins.size; nforced += 1; continue
        flush()
        w(('L%04X:' % pc if pc in labels else '') + '\t' + r + '\t;@%04X' % pc)
        pc += ins.size + skip
    else:
        dbbuf.append(img[pc]); pc += 1; ndb += 1
flush()
w('CODE ENDS')
w('DATA SEGMENT PARA')
d = img[CODE_END:DATA_END]
db(d)
w('DATA ENDS')
w('END L0100')
open(out, 'w', newline='').write('\r\n'.join(lines) + '\r\n')
open(os.path.join(os.path.dirname(out), 'U2.ins'), 'w').write(' '.join(str(a) for a in sorted(insn)))
print('instructions %d, as db %d, labels %d, data-in-code bytes %d' % (len(insn), nforced, len(labels), ndb))
