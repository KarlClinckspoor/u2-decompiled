#!/usr/bin/env python3
"""Shared analysis of ULTIMAII.EXE: recursive disassembly of the code segment and operand facts.

    import u2an; a = u2an.analyse(open('gamedata/ULTIMAII.EXE','rb').read())

a.img (load image), a.insn {addr: capstone insn}, a.kind (per byte: 0 unknown, 1 instruction
start, 2 instruction continuation, 3 inline/table data), a.targets (direct branch targets).
operands(ins) yields Op records with what matters for symbol recovery: memory operands with
their effective segment, registers and displacement size, immediates with their size.
"""
import collections
import capstone
from capstone import x86

CODE_END = 0x7410          # image offset of the end of the code segment (LINK pads 740B-7410)
CODE_LAST = 0x740B         # last code byte + 1
DATA_END = 0x8AC0          # end of the initialised data segment in the image
DATA_SIZE = DATA_END - CODE_END  # 0x16B0
INLINE = {0x4FDF: 'z', 0x52CA: 8}  # calls followed by inline data: ASCIIZ string, 8 bytes
TABLES = {0x730: 26}       # jump tables in CS: address -> number of words

md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
md.detail = True

SEGREG = {x86.X86_REG_CS: 'cs', x86.X86_REG_DS: 'ds', x86.X86_REG_ES: 'es', x86.X86_REG_SS: 'ss'}

Op = collections.namedtuple('Op', 'n type size seg base index disp disp_size imm imm_size text')


class Analysis:
    pass


def is_branch(ins):
    return capstone.CS_GRP_JUMP in ins.groups or capstone.CS_GRP_CALL in ins.groups


def direct_target(ins):
    if is_branch(ins) and ins.operands and ins.operands[0].type == x86.X86_OP_IMM:
        return ins.operands[0].imm & 0xFFFF
    return None


def analyse(exe_bytes):
    img = exe_bytes[512:]
    kind = bytearray(CODE_END)
    insn = {}
    entries = [0x100]
    for t, n in TABLES.items():
        for i in range(n):
            entries.append(int.from_bytes(img[t + 2 * i:t + 2 * i + 2], 'little'))
        for i in range(t, t + 2 * n):
            kind[i] = 3
    seen = set()
    while entries:
        pc = entries.pop()
        while 0x100 <= pc < CODE_END and pc not in seen and kind[pc] != 3:
            ins = next(md.disasm(img[pc:pc + 16], pc), None)
            if ins is None:
                break
            seen.add(pc)
            insn[pc] = ins
            kind[pc] = 1
            for i in range(1, ins.size):
                kind[pc + i] = 2
            nxt = pc + ins.size
            tgt = direct_target(ins)
            if tgt is not None:
                entries.append(tgt)
            m = ins.mnemonic
            if m == 'call':
                if tgt in INLINE:
                    e = img.index(b'\0', nxt) + 1 if INLINE[tgt] == 'z' else nxt + INLINE[tgt]
                    for i in range(nxt, e):
                        kind[i] = 3
                    nxt = e
                pc = nxt
                continue
            if m in ('ret', 'retf', 'iret', 'hlt', 'jmp'):
                break
            pc = nxt
    a = Analysis()
    a.img, a.kind, a.insn = img, kind, insn
    a.targets = {t for t in (direct_target(i) for i in insn.values()) if t is not None}
    for t, n in TABLES.items():
        for i in range(n):
            a.targets.add(int.from_bytes(img[t + 2 * i:t + 2 * i + 2], 'little'))
    return a


def prefix_seg(ins):
    for p in ins.prefix:
        if p == 0x2E: return 'cs'
        if p == 0x3E: return 'ds'
        if p == 0x26: return 'es'
        if p == 0x36: return 'ss'
    return None


def operands(ins):
    """Op records for ins's explicit operands (memory: effective segment after prefixes)."""
    out = []
    enc = ins.encoding if hasattr(ins, 'encoding') else None
    psg = prefix_seg(ins)
    for n, o in enumerate(ins.operands):
        if o.type == x86.X86_OP_MEM:
            base = ins.reg_name(o.mem.base) if o.mem.base else None
            index = ins.reg_name(o.mem.index) if o.mem.index else None
            seg = psg or ('ss' if base == 'bp' else 'ds')
            dsz = 0
            if base is None and index is None:
                dsz = 2
            else:
                mod = ins.modrm >> 6
                dsz = {0: 0, 1: 1, 2: 2}.get(mod, 0)
            out.append(Op(n, 'mem', o.size, seg, base, index, o.mem.disp & 0xFFFF, dsz, None, 0, ins.op_str))
        elif o.type == x86.X86_OP_IMM:
            out.append(Op(n, 'imm', o.size, None, None, None, None, 0, o.imm & 0xFFFF, o.size, ins.op_str))
        else:
            out.append(Op(n, 'reg', o.size, None, ins.reg_name(o.reg), None, None, 0, None, 0, ins.op_str))
    return out
