#!/usr/bin/env python3
"""Generate a relocatable MASM source for ULTIMAII.EXE (code 0100-740B, data 7410-8AC0).

    gen.py EXE OUT.ASM [FORCEFILE]

Code is found by recursive disassembly (tools/u2an.py). Every address in it is written as a
symbol, so code and data can grow or move:
  Lxxxx     CODE: branch targets, CS data referenced by cs: operands, the 0730 jump table
            (dw Lxxxx); a reference into the middle of an instruction is Lxxxx+n
  D_xxxx    DATA (ASSUME DS:DATA): every offset a DS operand with a 16-bit displacement names,
            and the targets of the pointer table at D_05B0 (dw D_xxxx)
  D_START   offset 0 of DATA (its first line); sizes and the CS view are measured from it
  D_END     end of the initialised data; the BSS buffers and the stack lie after it, so their
            addresses (the pointers at D_0472..D_0476, SS in the startup) are D_END+n
  C_DATA    the data segment seen from CS (two cs: reads at 4AE7/4AF2), at the paragraph
            after the code (C_BASE, offset 0 of CODE, pads to it)
Displacements of 8 bits ([di+6]) and immediates stay numbers: they are constants in the
original (MASM gives every symbol a 16-bit displacement; every 16-bit immediate was checked:
counts, sizes, video offsets and segments, key codes, sound parameters). es: operands address
video memory or the BIOS data area and stay numbers too. The DATA segment comes first in the
file (after an empty CODE declaration that keeps CODE first in the link), so code refers only
backwards to data symbols.
Instructions MASM can't reproduce or that are listed in FORCEFILE are written as db.
Each code line is tagged ;@addr (its address in the original) for tools/regen.py.
"""
import sys, re, os, bisect
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import capstone
from capstone import x86
import u2an
from u2an import CODE_END, CODE_LAST, DATA_SIZE

# words in DATA that hold addresses: offset -> kind ('D' data, 'B' BSS buffer)
PTR_TABLES = {0x05B0: 64}                 # 64 pointers to the 0x42-byte records 0630..166E
BSS_PTRS = (0x0472, 0x0474, 0x0476)       # map, monster and talk buffers (1800, 2900, 2800)
CS_TO_DATA = True                         # cs: operands >= CODE_END address the data segment
BSS_STACK_END = 0x3100                    # SS = DS + 0310h: data, BSS and buffers below 3100


def hx(v):
    s = '%X' % v
    return ('0' + s if s[0] in 'ABCDEF' else s) + 'h'


STR = {'movsb', 'movsw', 'stosb', 'stosw', 'lodsb', 'lodsw', 'cmpsb', 'cmpsw', 'scasb', 'scasw'}
OK = set('''mov add adc sub sbb and or xor cmp test inc dec neg not push pop call jmp ret
 shl shr sal sar rol ror rcl rcr mul imul div idiv cbw cwd lea xchg in out int nop
 stc clc cmc std cld sti cli pushf popf lahf sahf jcxz loop loope loopne iret daa das
 jo jno jb jae je jne jbe ja js jns jp jnp jl jge jle jg'''.split())


class Gen:
    def __init__(self, exe, force):
        self.a = u2an.analyse(exe)
        self.img = self.a.img
        self.force = force
        self.starts = sorted(self.a.insn)
        self.labels = {t for t in self.a.targets if t in self.a.insn}   # code labels
        self.dlabels = {0}                 # data offsets that get a D_ label
        self.dptr = {}                     # data offset -> dw operand text
        self.prefix2e = set()              # lea with a CS prefix MASM drops: emit db 2Eh first

    # ---- symbols
    def cs_sym(self, t):
        """Symbol text for CS offset t (registers the label it needs)."""
        if t >= CODE_END:
            self.dlabels.add(t - CODE_END)
            return '[C_DATA+(%s-D_START)]' % self.dsym(t - CODE_END), True
        k = self.a.kind[t] if t < CODE_END else 0
        if k == 2:                          # inside an instruction: label its start
            s = self.starts[bisect.bisect_right(self.starts, t) - 1]
            self.labels.add(s)
            return 'L%04X+%d' % (s, t - s), False
        self.labels.add(t)
        return 'L%04X' % t, False

    def dsym(self, o):
        self.dlabels.add(o)
        return 'D_%04X' % o

    # ---- instructions
    def memtext(self, ins, op):
        """Rewritten text of ins's memory operand op, or None to keep the number."""
        regs = [r for r in (op.base, op.index) if r]
        if op.disp_size != 2:
            return None
        if op.seg == 'ds' and u2an.prefix_seg(ins) is None:
            if op.disp >= DATA_SIZE:
                return None
            sym, brk = self.dsym(op.disp), False
            seg = ''
        elif op.seg == 'cs':
            sym, brk = self.cs_sym(op.disp)
            seg = 'cs:'
        else:
            return None                     # es: (video, BIOS), ss:
        if brk:                             # [C_DATA+...] form, direct only
            assert not regs
            return seg + sym
        return seg + sym + ('[' + '+'.join(regs) + ']' if regs else '')

    def conv(self, ins):
        """MASM text for ins, or None to fall back to db. May return (text, skip)."""
        m, o = ins.mnemonic, ins.op_str
        if m.startswith('rep'):
            parts = m.split()
            if len(parts) == 2 and parts[1] in STR:
                if 'cs:' in o or 'ss:' in o or ('es:' in o and parts[1].startswith('lods')):
                    return None
                return parts[0] + ' ' + parts[1]
            return None
        if m in STR:
            if re.search(r'(cs|ss|es):\[si\]', o):
                return None
            return m
        if m not in OK:
            return None
        if u2an.is_branch(ins):
            t = u2an.direct_target(ins)
            if t is not None:
                if t not in self.labels:
                    return None
                lab = 'L%04X' % t
                if m == 'jmp':
                    op = ins.bytes[0]
                    fwd = t > ins.address
                    if op == 0xEB:
                        if fwd:
                            nop = self.img[ins.address + 2] == 0x90
                            return ('jmp ' + lab, 1) if nop else 'jmp short ' + lab
                        return 'jmp ' + lab
                    if op == 0xE9:
                        d = t - (ins.address + 2)
                        if -128 <= d <= 127 and not fwd:
                            return None     # MASM would make it short
                        return 'jmp ' + lab if not fwd or d > 127 + 1 else None
                    return None
                return m + ' ' + lab
        ops = u2an.operands(ins)
        mems = [p for p in ops if p.type == 'mem']
        o = re.sub(r'0x([0-9a-f]+)', lambda mm: hx(int(mm.group(1), 16)), o)
        if mems:
            new = self.memtext(ins, mems[0])
            if new is None:                 # numeric: direct memory gets an explicit ds:
                def mem(mm):
                    seg, inner = mm.group(1), mm.group(2)
                    if re.search(r'\b(bx|bp|si|di)\b', inner):
                        return (seg or '') + '[' + inner.replace(' ', '') + ']'
                    return (seg or 'ds:') + '[' + inner.replace(' ', '') + ']'
                o = re.sub(r'((?:cs|ds|es|ss):)?\[([^\]]+)\]', mem, o)
            else:
                o = re.sub(r'((?:cs|ds|es|ss):)?\[([^\]]+)\]', lambda mm: new, o, count=1)
            if m == 'lea':
                if o.split(', ')[1].startswith('cs:'):     # MASM drops the prefix on lea
                    self.prefix2e.add(ins.address)
                    o = o.replace(', cs:', ', ', 1)
                if new is None:
                    return None
        return (m + ' ' + o).strip()

    # ---- output
    def run(self):
        a, img = self.a, self.img
        # pass 1: collect every label (the text is produced again in pass 2)
        for pc in self.starts:
            if pc != 0x100 and pc not in self.force:
                self.conv(a.insn[pc])
        for t, n in PTR_TABLES.items():
            for i in range(n):
                v = int.from_bytes(img[CODE_END + t + 2 * i:CODE_END + t + 2 * i + 2], 'little')
                self.dptr[t + 2 * i] = self.dsym(v)
        for p in BSS_PTRS:
            v = int.from_bytes(img[CODE_END + p:CODE_END + p + 2], 'little')
            assert v >= DATA_SIZE
            self.dptr[p] = 'D_END+%s' % hx(v - DATA_SIZE)
        for t, n in u2an.TABLES.items():
            self.labels.add(t)
            for i in range(n):
                self.labels.add(int.from_bytes(img[t + 2 * i:t + 2 * i + 2], 'little'))

        L = []
        w = L.append
        w('; ULTIMAII.EXE: Ultima II (Sierra On-Line 1983, Origin 1989). Generated by tools/gen.py.')
        w('; MASM 4.00 + LINK 3.05 (MASM 3.00 runs out of symbol space); tools/build.py builds it.')
        w('CODE SEGMENT\t\t; declared first: LINK puts CODE before DATA')
        w('CODE ENDS')
        w('')
        w('DATA SEGMENT PARA')
        w('D_START label byte\t; offset 0 of DATA: keep it the first line (sizes are measured from it)')
        self.emit_data(w)
        w('D_END label byte\t; end of the initialised data; BSS buffers and stack follow')
        w('DATA ENDS')
        w('')
        w('CODE SEGMENT')
        w('ASSUME CS:CODE, DS:DATA')
        w('C_BASE label byte')
        w('ORG 100h')
        nforced = self.emit_code(w)
        w('IF ($-C_BASE) MOD 16\t; pad to the paragraph where DATA starts')
        w('\tdb 16-(($-C_BASE) MOD 16) dup (0)')
        w('ENDIF')
        w('C_DATA label byte\t; the data segment seen from CS')
        w('CODE ENDS')
        w('END L0100')
        self.nforced = nforced
        return L

    def dbl(self, w, bs, at=None):
        for i in range(0, len(bs), 16):
            w('\tdb ' + ','.join(hx(b) for b in bs[i:i + 16]) + ('\t;@%04X' % (at + i) if at is not None else ''))

    def emit_data(self, w):
        d = self.img[CODE_END:CODE_END + DATA_SIZE]
        inner = {o + 1 for o in self.dptr} & self.dlabels    # the high byte of a pointer word
        self.dlabels -= inner
        self.dlabels |= {o - 1 for o in inner}
        cuts = sorted(set(self.dlabels) | set(self.dptr) | {o + 2 for o in self.dptr} | {DATA_SIZE})
        o = 0
        for c in cuts:
            if c > DATA_SIZE:
                continue
            if o in self.dptr:
                w('\tdw %s' % self.dptr[o])
                if o + 1 in inner:
                    w('D_%04X equ byte ptr D_%04X+1' % (o + 1, o))
                o += 2
            if c > o:
                self.dbl(w, d[o:c])
                o = c
            if o in self.dlabels and o < DATA_SIZE:
                w('D_%04X label byte' % o)
        assert o == DATA_SIZE, hex(o)

    def emit_code(self, w):
        a, img = self.a, self.img
        pc, buf, nforced = 0x100, [], 0

        def flush():
            if buf:
                self.dbl(w, bytes(buf), pc - len(buf))
                del buf[:]
        tables = {t + 2 * i for t, n in u2an.TABLES.items() for i in range(n)}
        while pc < CODE_LAST:
            if pc in tables:
                flush()
                v = int.from_bytes(img[pc:pc + 2], 'little')
                w(('L%04X:' % pc if pc in self.labels else '') + '\tdw L%04X\t;@%04X' % (v, pc))
                pc += 2
                continue
            if a.kind[pc] == 1 and pc in a.insn:
                ins = a.insn[pc]
                if pc == 0x100:
                    w('L0100:\tmov ax, DATA')
                    pc += 3
                    continue
                if pc == 0x105:             # add ax,0310h: paragraphs of data + BSS + buffers
                    assert img[pc:pc + 3] == b'\x05\x10\x03'
                    w('\tadd ax, (D_END-D_START+%s+15)/16\t;@0105' % hx(BSS_STACK_END - DATA_SIZE))
                    pc += 3
                    continue
                r = None if pc in self.force else self.conv(ins)
                skip = 0
                if isinstance(r, tuple):
                    r, skip = r
                if r is None:
                    if pc in self.labels:
                        flush()
                        w('L%04X:' % pc)
                    buf.extend(ins.bytes)
                    pc += ins.size
                    nforced += 1
                    continue
                flush()
                lab = 'L%04X:' % pc if pc in self.labels else ''
                if pc in self.prefix2e:
                    w(lab + '\tdb 2Eh\t\t; cs: prefix, which MASM drops on lea\t;@%04X' % pc)
                    lab = ''
                    r = r + '\t;@%04X' % (pc + 1)
                else:
                    r = r + '\t;@%04X' % pc
                w(lab + '\t' + r)
                pc += ins.size + skip
            else:
                if pc in self.labels:
                    flush()
                    w('L%04X label byte' % pc)
                buf.append(img[pc])
                pc += 1
        flush()
        return nforced


def main():
    exe, out = sys.argv[1], sys.argv[2]
    force = set()
    if len(sys.argv) > 3 and os.path.exists(sys.argv[3]):
        force = {int(x, 16) for x in open(sys.argv[3]).read().split()}
    g = Gen(open(exe, 'rb').read(), force)
    lines = g.run()
    open(out, 'w', newline='').write('\r\n'.join(lines) + '\r\n')
    open(os.path.join(os.path.dirname(out) or '.', 'U2.ins'), 'w').write(' '.join(str(x) for x in g.starts))
    print('instructions %d, as db %d, code labels %d, data labels %d' % (
        len(g.starts), g.nforced, len(g.labels), len(g.dlabels)))


if __name__ == '__main__':
    main()
