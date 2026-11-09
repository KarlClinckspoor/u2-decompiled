#!/usr/bin/env python3
"""Rename symbols across all of src/, all at once, after checking the new names.

    python3 tools/rename.py MAP [MAP ...] [--dry] [--only MODULE]

A map has one rename per line: `OLD NEW` (anything after `;` is a comment; blank lines and
lines starting with `;` are skipped). OLD must be a symbol defined in src/ (tools/syms.py);
NEW must be a valid MASM name: letters, digits and `_`, not starting with a digit, at most 31
characters (MASM's significant length), not a MASM reserved word, and unique ignoring case
(MASM ignores case) among all names after the renames. Every whole-word occurrence of OLD in
every module is replaced, in comments too, so comments that mention a symbol stay right.
Nothing is written if any check fails. --only MODULE refuses renames of symbols that are
used outside MODULE (for working on one module while others are edited in parallel).
After renaming, run tools/build.py: names never change the bytes, so it must stay identical.
"""
import argparse, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import syms

RESERVED = set('''
AAA AAD AAM AAS ADC ADD AND CALL CBW CLC CLD CLI CMC CMP CMPS CMPSB CMPSW CWD DAA DAS DEC DIV
ESC HLT IDIV IMUL IN INC INT INTO IRET JA JAE JB JBE JC JCXZ JE JG JGE JL JLE JMP JNA JNAE JNB
JNBE JNC JNE JNG JNGE JNL JNLE JNO JNP JNS JNZ JO JP JPE JPO JS JZ LAHF LDS LEA LES LOCK LODS
LODSB LODSW LOOP LOOPE LOOPNE LOOPNZ LOOPZ MOV MOVS MOVSB MOVSW MUL NEG NOP NOT OR OUT POP POPF
PUSH PUSHF RCL RCR REP REPE REPNE REPNZ REPZ RET RETF RETN ROL ROR SAHF SAL SAR SBB SCAS SCASB
SCASW SHL SHR STC STD STI STOS STOSB STOSW SUB TEST WAIT XCHG XLAT XLATB XOR
BOUND ENTER LEAVE INS INSB INSW OUTS OUTSB OUTSW PUSHA POPA ARPL CLTS LAR LGDT LIDT LLDT LMSW
LSL LTR SGDT SIDT SLDT SMSW STR VERR VERW
AH AL AX BH BL BP BX CH CL CS CX DH DI DL DS DX ES SI SP SS
ASSUME COMMENT DB DD DQ DT DW DUP ELSE END ENDIF ENDM ENDP ENDS EQU EVEN EXITM EXTRN GROUP IF
IF1 IF2 IFB IFDEF IFDIF IFE IFIDN IFNB IFNDEF INCLUDE IRP IRPC LABEL LOCAL MACRO NAME ORG PAGE
PROC PUBLIC PURGE RECORD REPT SEGMENT STRUC SUBTTL TITLE RADIX ALIGN DOSSEG INCLUDELIB
AND EQ GE GT HIGH LE LENGTH LOW LT MASK MOD NE NOT OFFSET OR PTR SEG SHL SHR SHORT SIZE THIS TYPE
WIDTH XOR BYTE WORD DWORD QWORD TBYTE NEAR FAR ABS AT COMMON MEMORY PARA PUBLIC STACK
LIST NOLIST XLIST LALL SALL XALL CREF XCREF TFCOND SFCOND LFCOND ERR ERR1 ERR2 ERRE ERRNZ ERRDEF
ERRNDEF ERRB ERRNB ERRIDN ERRDIF OUT_ CODE DATA CGROUP
'''.split())
NAME = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')


def load_maps(paths):
    pairs = []
    for p in paths:
        for n, l in enumerate(open(p, encoding='utf-8', errors='replace'), 1):
            s = l.split(';')[0].strip()
            if not s:
                continue
            f = s.split()
            if len(f) != 2:
                raise SystemExit('%s:%d: expected "OLD NEW": %s' % (p, n, l.rstrip()))
            pairs.append((f[0], f[1], '%s:%d' % (p, n)))
    return pairs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('maps', nargs='+')
    ap.add_argument('--dry', action='store_true')
    ap.add_argument('--only')
    a = ap.parse_args()
    t = syms.table()
    pairs = load_maps(a.maps)
    errs = []
    olds = {}
    for old, new, where in pairs:
        if old.upper() not in t:
            errs.append('%s: %s is not a symbol in src/' % (where, old))
        if old.upper() in olds:
            errs.append('%s: %s is renamed twice (also %s)' % (where, old, olds[old.upper()][1]))
        olds[old.upper()] = (new, where)
        if not NAME.match(new):
            errs.append('%s: %s is not a valid name' % (where, new))
        if len(new) > 31:
            errs.append('%s: %s is longer than 31 characters' % (where, new))
        if new.upper() in RESERVED:
            errs.append('%s: %s is a MASM reserved word' % (where, new))
    final = {}                                  # upper name -> who has it after the renames
    for k, s in t.items():
        nm = olds[k][0] if k in olds else s.name
        if nm.upper() in final:
            errs.append('name %s would be used twice (%s and %s)' % (nm, final[nm.upper()], s.name))
        final[nm.upper()] = s.name
    if a.only:
        only = a.only.upper().replace('.ASM', '') + '.ASM'
        for old, new, where in pairs:
            outside = sorted({m for m, _, _ in syms.refs(old) if m.upper() != only})
            if outside:
                errs.append('%s: %s is used outside %s (%s)' % (where, old, only, ', '.join(outside)))
    if errs:
        print('\n'.join(errs))
        sys.exit('rename: nothing written (%d problems)' % len(errs))
    if not pairs:
        print('rename: nothing to do')
        return
    pat = re.compile(r'\b(%s)\b' % '|'.join(re.escape(o) for o, _, _ in pairs), re.I)
    rep = {o.upper(): n for o, n, _ in pairs}
    total = 0
    out = []
    for mod in syms.modules():
        path = os.path.join(syms.SRC, mod)
        text = open(path, 'rb').read().decode('latin1')
        new, n = pat.subn(lambda m: rep[m.group(1).upper()], text)
        too_long = [l for l in new.split('\r\n') if len(l) > 132]
        if too_long:
            sys.exit('rename: nothing written: %s would get a line longer than 132 characters: %s'
                     % (mod, too_long[0]))
        if n:
            out.append((path, new))
            total += n
            print('%-12s %4d replacements' % (mod, n))
    if not a.dry:
        for path, new in out:
            open(path, 'wb').write(new.encode('latin1'))
    print('rename: %d symbols, %d replacements%s' % (len(pairs), total, ' (dry run)' if a.dry else ''))


if __name__ == '__main__':
    main()
