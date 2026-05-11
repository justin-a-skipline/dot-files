#!/usr/bin/env python3
"""Move opening braces for C control-flow statements onto their own line.

Handles if, else if, else, for, while, do, switch — including
multi-line conditions — by counting parentheses.

Usage: python3 split_braces.py <file> [--in-place]
"""
import re
import sys

# Each pattern: (regex to match start of stripped line, has_parens, has_close_brace)
PATTERNS = [
    (r'\}\s*else\s+if\b',  True,  True),
    (r'\}\s*else\b',        False, True),
    (r'else\s+if\b',        True,  False),
    (r'if\b',               True,  False),
    (r'for\b',              True,  False),
    (r'while\b',            True,  False),
    (r'switch\b',           True,  False),
    (r'else\b',             False, False),
    (r'do\b',               False, False),
]


def get_indent(line):
    return line[:len(line) - len(line.lstrip())]


def find_closing_paren(lines, start):
    """Count parens starting from line `start` until balanced.
    Returns the line index where the closing ) lands, or None."""
    depth = 0
    j = start
    while j < len(lines):
        for ch in lines[j]:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    return j
        j += 1
    return None


def process(text):
    lines = text.split('\n')
    i = 0
    while i < len(lines):
        stripped = lines[i].lstrip()
        indent = get_indent(lines[i])

        matched = None
        for regex, has_parens, has_close_brace in PATTERNS:
            m = re.match(regex, stripped)
            if m:
                matched = (has_parens, has_close_brace)
                break

        if not matched:
            i += 1
            continue

        has_parens, has_close_brace = matched
        inserted = 0

        # Step 1: Split leading } off onto its own line
        if has_close_brace:
            after_brace = stripped[1:].lstrip()
            lines[i] = indent + '}'
            lines.insert(i + 1, indent + after_brace)
            inserted += 1
            i += 1
            stripped = lines[i].lstrip()
            indent = get_indent(lines[i])

        # Step 2: Handle the keyword
        if has_parens:
            end = find_closing_paren(lines, i)
            if end is None:
                i += 1 + inserted
                continue
            tail = lines[end].rstrip()
            if tail.endswith('{'):
                lines[end] = tail[:-1].rstrip()
                lines.insert(end + 1, indent + '{')
                inserted += 1
        else:
            tail = lines[i].rstrip()
            if tail.endswith('{'):
                lines[i] = tail[:-1].rstrip()
                lines.insert(i + 1, indent + '{')
                inserted += 1

        i += 1 + inserted

    return '\n'.join(lines)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file> [--in-place]", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    in_place = '--in-place' in sys.argv

    with open(path) as f:
        text = f.read()

    result = process(text)

    if in_place:
        with open(path, 'w') as f:
            f.write(result)
            if not result.endswith('\n'):
                f.write('\n')
    else:
        sys.stdout.write(result)
