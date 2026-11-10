#!/usr/bin/env python3
"""Check the C reading aid in c/ against the assembly in src/.

    python3 tools/ccheck.py [--cc gcc] [FILE.c ...]        (default: c/*.c)

--cc COMPILER also runs `COMPILER -std=c99 -Wall -Wextra -Wpedantic -fsyntax-only` on each file,
which catches typos and type errors (nothing is linked or run).

The C is an interpretation, not a build, so this can only check what is mechanical. For every C
function or table that is anchored with a comment line

    /* asm: NAME @ADDR ...

it checks that
  - NAME is a symbol of src/ and ADDR is its original address (tools/syms.py);
  - a FUNCTION prints exactly the texts the routine prints (the strings after `call PrintInline`),
    in the same order, character for character (8Dh and 0Dh read as '\\n', bit 7 ignored);
  - every routine the assembly calls or jumps to (outside the routine itself) is called from the
    C function at least as many times (the C may call more: helpers; ALIASES maps renamed ones);
  - a TABLE (`static const char X[] = "...";`) holds the same bytes as the assembly's db lines.
It also lists the routines of the same modules that have no C yet.
What it cannot check: the logic, the numbers, the order of the calls. Exit status 1 on any error.

The routine's extent in the assembly runs from its label to the next `;----` rule line or to the
next anchored label of the same module in the same C file, whichever comes first.
"""
import collections, glob, os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import syms

# asm name -> the C name that stands for it
ALIASES = {'ReadKey': 'ReadAsciiKey',            # ReadKey repeated until an ASCII key
           'PrintNth_Skip': 'PrintNthString'}    # the loop PrintTalkString and PrintCsTblString share
IGNORED_CALLEES = {'PrintInline', 'EndCommand', 'EndCommandBeep'}   # strings are compared instead / the turn ends
KEYWORDS = {'if', 'while', 'for', 'switch', 'return', 'sizeof', 'else', 'do', 'case', 'goto'}
ANCHOR = re.compile(r'^/\*\s*asm:\s*(\w+)\s*@([0-9A-Fa-f]{4})', re.M)
RULE = re.compile(r'^;-{20,}')


# ---- reading C ------------------------------------------------------------------------------

def blank_comments(s):
    """s with comments replaced by spaces (offsets and newlines kept); string literals untouched."""
    out, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c == '"' or c == "'":
            j = i + 1
            while s[j] != c:
                j += 2 if s[j] == '\\' else 1
            out.append(s[i:j + 1])
            i = j + 1
        elif s.startswith('/*', i):
            j = s.index('*/', i) + 2
            out.append(''.join(ch if ch == '\n' else ' ' for ch in s[i:j]))
            i = j
        elif s.startswith('//', i):
            j = s.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i))
            i = j
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def parse_literal(s, i):
    """The C string literal starting at s[i] == '"': (value, index after it)."""
    i += 1
    out = []
    while s[i] != '"':
        c = s[i]
        if c != '\\':
            out.append(c)
            i += 1
            continue
        i += 1
        c = s[i]
        if c in 'nrt':
            out.append({'n': '\n', 'r': '\r', 't': '\t'}[c])
            i += 1
        elif c in '\\\'"?':
            out.append(c)
            i += 1
        elif c in '01234567':
            v, k = 0, 0
            while k < 3 and s[i] in '01234567':
                v, i, k = v * 8 + int(s[i]), i + 1, k + 1
            out.append(chr(v))
        elif c == 'x':
            i += 1
            j = i
            while s[j] in '0123456789abcdefABCDEF':
                j += 1
            out.append(chr(int(s[i:j], 16) & 255))
            i = j
        else:
            raise ValueError('unsupported escape \\%s' % c)
    return ''.join(out), i + 1


def literals(s, i):
    """Concatenated adjacent string literals starting at or after s[i]: (value, end)."""
    parts = []
    while True:
        while i < len(s) and s[i].isspace():
            i += 1
        if i < len(s) and s[i] == '"':
            v, i = parse_literal(s, i)
            parts.append(v)
        else:
            return ''.join(parts), i


def item_extent(clean, pos):
    """('function', body_start, body_end) or ('table', start, end) for the C item after pos."""
    i = pos
    while clean[i] not in '{=;':
        i += 1
    if clean[i] == ';':
        return 'declaration', i, i
    if clean[i] == '=':
        j = i + 1
        while clean[j] != ';':
            if clean[j] == '"':
                _, j = parse_literal(clean, j)
            else:
                j += 1
        return 'table', i + 1, j
    depth, j = 0, i
    while True:
        c = clean[j]
        if c == '"' or c == "'":
            k = j + 1
            while clean[k] != c:
                k += 2 if clean[k] == '\\' else 1
            j = k + 1
            continue
        depth += (c == '{') - (c == '}')
        j += 1
        if depth == 0:
            return 'function', i, j


def c_texts(body):
    out = []
    for m in re.finditer(r'\bPrintInline\s*\(', body):
        v, _ = literals(body, m.end())
        out.append(v)
    return out


def c_callees(body):
    stripped = re.sub(r'"(?:[^"\\]|\\.)*"', '""', body)
    return collections.Counter(m.group(1) for m in re.finditer(r'\b([A-Za-z_]\w*)\s*\(', stripped)
                               if m.group(1) not in KEYWORDS)


# ---- reading the assembly -------------------------------------------------------------------

def db_bytes(line):
    return [int(x.strip().rstrip('hH'), 16) for x in line.split(';')[0].split('db', 1)[1].split(',')]


def decode(bs):
    return ''.join('\n' if b in (0x8D, 0x0D) else ('\0' if b == 0 else chr(b & 0x7F)) for b in bs)


def asm_texts(region):
    out, i = [], 0
    while i < len(region):
        if re.match(r'^(\w+:)?\s*call\s+PrintInline\b', region[i], re.I):
            bs, j = [], i + 1
            while j < len(region) and re.match(r'^\s*db\s', region[j]):
                bs += db_bytes(region[j])
                j += 1
                if bs and bs[-1] == 0:
                    break
            out.append(decode([b for b in bs if b != 0]))
            i = j
        else:
            i += 1
    return out


def asm_callees(region):
    labels = {m.group(1).upper() for l in region for m in [re.match(r'^(\w+):', l)] if m}
    out = collections.Counter()
    for l in region:
        m = re.match(r'^(?:\w+:)?\s*(?:call|jmp)\s+(?:short\s+)?([A-Za-z_]\w*)\s*(?:;|$)', l.split(';')[0].rstrip() + ';', re.I)
        if m and m.group(1).upper() not in labels and m.group(1) not in IGNORED_CALLEES:
            out[ALIASES.get(m.group(1), m.group(1))] += 1
    return out


def asm_table(lines, start):
    bs, i = [], start
    while i < len(lines) and re.match(r'^\s*db\s', lines[i]):
        bs += db_bytes(lines[i])
        i += 1
    return decode(bs)


def routines(lines):
    """Labels that follow a ;---- / comments / ;---- header."""
    rules = [i for i, l in enumerate(lines) if RULE.match(l)]
    out = []
    if len(rules) % 2:
        return None
    for k in range(1, len(rules), 2):
        for l in lines[rules[k] + 1:rules[k] + 6]:
            m = re.match(r'^(\w+)(:|\s+label\b)', l)
            if m:
                out.append(m.group(1))
                break
            if l.strip() and not l.startswith(';'):
                break
    return out


# ---- the check ------------------------------------------------------------------------------

def check(path, table, errors):
    text = open(path, encoding='utf-8').read()
    clean = blank_comments(text)
    anchors = []
    for m in ANCHOR.finditer(text):
        name, addr = m.group(1), int(m.group(2), 16)
        end = text.index('*/', m.start()) + 2
        anchors.append((name, addr, m.start(), end))
    # anchored labels per module (to cut routine extents)
    placed = {}
    for name, addr, _, _ in anchors:
        s = table.get(name.upper())
        if s:
            placed.setdefault(s.module, []).append(s.lineno)
    covered = {}
    shown = os.path.relpath(path, ROOT)
    for name, addr, start, end in anchors:
        where = '%s: %s @%04X' % (shown, name, addr)
        s = table.get(name.upper())
        if not s:
            errors.append('%s: not a symbol of src/' % where)
            continue
        if s.addr != addr:
            errors.append('%s: the assembly puts it at %s' % (where, '%04X' % s.addr if s.addr is not None else '?'))
            continue
        covered.setdefault(s.module, set()).add(name.upper())
        lines = syms.read(s.module)
        kind, b0, b1 = item_extent(clean, end)
        body = clean[b0:b1]
        first = s.lineno - 1
        if kind == 'table':
            want = asm_table(lines, first + 1)
            try:
                got, _ = literals(body, 0)
            except (ValueError, IndexError) as e:
                errors.append('%s: cannot read the table (%s)' % (where, e))
                continue
            if got + '\0' != want:
                errors.append('%s: table differs\n    asm: %r\n    C:   %r' % (where, want, got + '\\0'))
            else:
                print('ok  %-34s table, %d bytes' % (name + ' @%04X' % addr, len(want)))
            continue
        if kind != 'function':
            errors.append('%s: an anchor must precede a function or a table, not a declaration' % where)
            continue
        stop = len(lines)
        for j in range(first + 1, len(lines)):
            if RULE.match(lines[j]) or (j + 1) in placed.get(s.module, []):
                stop = j
                break
        region = lines[first:stop]
        ok = True
        want, got = asm_texts(region), c_texts(body)
        if want != got:
            ok = False
            for k in range(max(len(want), len(got))):
                a = want[k] if k < len(want) else None
                b = got[k] if k < len(got) else None
                if a != b:
                    errors.append('%s: text #%d differs\n    asm: %r\n    C:   %r' % (where, k + 1, a, b))
                    break
        have = c_callees(body)
        calls = asm_callees(region)
        missing = ['%s (%d, C has %d)' % (c, n, have[c]) for c, n in sorted(calls.items()) if have[c] < n]
        if missing:
            ok = False
            errors.append('%s: the assembly calls more often: %s' % (where, ', '.join(missing)))
        if ok:
            print('ok  %-34s %d texts, %d calls' % (name + ' @%04X' % addr, len(got), sum(calls.values())))
    # what has no C yet
    for mod, done in sorted(covered.items()):
        rs = routines(syms.read(mod))
        if rs is None:
            print('--  %s: odd number of rule lines, coverage not listed' % mod)
            continue
        todo = [r for r in rs if r.upper() not in done and ALIASES.get(r) is None]
        print('--  %s: %d of %d routines have C%s' % (mod, len(rs) - len(todo), len(rs),
              (' (missing: ' + ', '.join(todo) + ')') if todo else ''))


def compile_check(cc, path, errors):
    r = subprocess.run([cc, '-std=c99', '-Wall', '-Wextra', '-Wpedantic', '-fsyntax-only',
                        '-I', os.path.dirname(os.path.abspath(path)), path], capture_output=True, text=True)
    if r.returncode or r.stderr.strip():
        errors.append('%s: the compiler objects:\n%s' % (os.path.relpath(path, ROOT), (r.stderr or r.stdout).rstrip()))
    else:
        print('ok  %s compiles (%s -std=c99 -Wall -Wextra -Wpedantic)' % (os.path.relpath(path, ROOT), cc))


def main():
    args = sys.argv[1:]
    cc = None
    if '--cc' in args:
        k = args.index('--cc')
        cc = args[k + 1]
        del args[k:k + 2]
    files = args or sorted(glob.glob(os.path.join(ROOT, 'c', '*.c')))
    table = syms.table()
    errors = []
    for f in files:
        check(f, table, errors)
        if cc:
            compile_check(cc, f, errors)
    if errors:
        print()
        print('\n'.join(errors))
        sys.exit('ccheck: %d problem(s)' % len(errors))
    print('ccheck: OK')


if __name__ == '__main__':
    main()
