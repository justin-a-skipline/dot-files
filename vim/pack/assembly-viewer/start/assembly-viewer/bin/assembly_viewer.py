#!/usr/bin/env python3
"""Reads a .mylint object and writes the assembly of each source line as JSON.

Usage: assembly_viewer.py <source file> <output file>

The plugin runs this as a job, so the editor never waits. It finds the object
itself, from compile_commands.json, and writes

  {"lines": {"line number": ["instruction text", ...]},
   "object": path, "object_time": epoch, "source_time": epoch}

ready to draw. Any failure writes {"error": "..."} instead.
"""

import glob
import json
import os
import re
import subprocess
import sys

BRANCH_CONDITIONS = ['', 'eq', 'ne', 'cs', 'cc', 'mi', 'pl', 'vs', 'vc',
                     'hi', 'ls', 'ge', 'lt', 'gt', 'le', 'al']
BRANCHES = {base + condition
            for base in ('b', 'bl', 'blx', 'bx')
            for condition in BRANCH_CONDITIONS}
BRANCHES.update(('cbz', 'cbnz'))

# ARM writes its result to the first operand. These are the instructions that
# do not. Anything absent counts as a write, because a register held too long
# invents a wrong name, and one dropped too early loses a true one.
READS_ONLY = re.compile(r'^(str|stm|push|cmp|cmn|tst|teq|it)')

# AAPCS says the callee saves r4 to r11, which is why the compiler puts a
# pointer it needs after a call in one of them. Only these are lost.
CALL_CLOBBERS = ('r0', 'r1', 'r2', 'r3', 'r12', 'ip', 'lr')

FUNCTION_HEADER = re.compile(r'^[0-9a-f]+ <([^>]+)>:$')
RELOCATION = re.compile(r'^\s*([0-9a-f]+): R_\S+\s+(\S+)')
SOURCE_LINE = re.compile(r'^(/.*):(\d+)\s*(\(discriminator|$)')
INSTRUCTION = re.compile(r'^\s*([0-9a-fA-F]+):')
HEX_BYTES = re.compile(r'^[0-9a-fA-F]+(\s+[0-9a-fA-F]+)*\s*$')
POOL_ADDRESS = re.compile(r'; \(([0-9a-fA-F]+) <')
BRANCH_OPERAND = re.compile(r'<([A-Za-z_][A-Za-z0-9_]*)(?:\+0x([0-9a-fA-F]+))?>')
SYMBOL_TABLE = re.compile(r'^([0-9a-fA-F]+) .{7} (\S+)\t([0-9a-fA-F]+) (\S.*)$')
SECTION_PREFIX = re.compile(r'^\.(?:text|data|bss|rodata)\.(\S+)$')
PLAIN_NAME = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')
STATIC_SUFFIX = re.compile(r'\.\d+$')
MEMBER_OFFSET_COMMENT = re.compile(r'\s*; 0x[0-9a-fA-F]+$')
DWARF_HEADER = re.compile(r'^ <(\d+)><([0-9a-fA-F]+)>:.*\(DW_TAG_(\w+)\)')
DWARF_ATTRIBUTE = re.compile(r'DW_AT_\w+')
DWARF_NUMBER = re.compile(r':\s*(\d+)')
DWARF_MEMBER_LOCATION = re.compile(r'DW_OP_plus_uconst: (\d+)|:\s*(\d+)$')
DWARF_TYPE = re.compile(r': <0x([0-9a-fA-F]+)')
DWARF_NAME = re.compile(r':\s*([^:]*)$')

DWARF_WANTED = {'DW_AT_name', 'DW_AT_type', 'DW_AT_byte_size',
                'DW_AT_upper_bound', 'DW_AT_data_member_location'}

READ_THROUGH = ('typedef', 'const_type', 'volatile_type')
AGGREGATES = ('structure_type', 'union_type')


def base_mnemonic(mnemonic):
    return mnemonic.split('.', 1)[0]


def is_branch(mnemonic):
    return base_mnemonic(mnemonic) in BRANCHES


def is_call(mnemonic):
    return mnemonic in ('bl', 'blx')


def symbol_name(relocation):
    """-ffunction-sections and -fdata-sections give every symbol a section of
    its own, named after it. A relocation against ".bss.currentDevice" means
    the variable currentDevice. A plain ".bss" names no variable."""
    match = SECTION_PREFIX.match(relocation)
    if match:
        return match.group(1)
    return relocation if PLAIN_NAME.match(relocation) else ''


def access_width(mnemonic):
    """ldr and str name the width they read: b is one byte, h is two, d is a
    pair of words, and a plain ldr is one word."""
    match = re.match(r'^(?:ldr|str)s?([bhd])', mnemonic)
    if not match:
        return 4
    return {'b': 1, 'h': 2, 'd': 8}[match.group(1)]


def split_instruction(line):
    """objdump writes <address>:\t<hex bytes>\t<mnemonic>\t<operands>. The hex
    bytes say nothing next to the source."""
    fields = line.split('\t')[1:]
    if fields and HEX_BYTES.match(fields[0]):
        fields = fields[1:]
    mnemonic = fields[0].strip() if fields else ''
    operands = ' '.join(field.strip() for field in fields[1:])
    return mnemonic, operands.strip()


class Types:
    """DWARF describes every type as an entry with an offset that other entries
    point at. A member of a structure carries the offset it sits at, which is
    what turns "+0x35" into ".curPage"."""

    def __init__(self, output):
        self.dies = {}
        self.variables = {}
        open_dies = {}
        die = None

        for line in output.splitlines():
            if 'DW_AT_' in line:
                if die is None:
                    continue
                attribute = DWARF_ATTRIBUTE.search(line).group(0)
                if attribute in DWARF_WANTED:
                    self._attribute(die, attribute, line)
                continue

            if 'DW_TAG_' not in line:
                continue
            match = DWARF_HEADER.match(line)
            if not match:
                continue

            level, offset, tag = match.groups()
            parent = open_dies.get(int(level) - 1)
            die = {'tag': tag, 'name': '', 'type': '', 'size': 0, 'count': 0,
                   'location': -1, 'members': [], 'parent': parent}
            self.dies[offset] = die
            open_dies[int(level)] = die
            if parent is not None and tag == 'member':
                parent['members'].append(die)

    def _attribute(self, die, attribute, line):
        if attribute == 'DW_AT_name':
            match = DWARF_NAME.search(line)
            die['name'] = match.group(1).strip() if match else ''
        elif attribute == 'DW_AT_type':
            match = DWARF_TYPE.search(line)
            die['type'] = match.group(1) if match else ''
        elif attribute == 'DW_AT_byte_size':
            match = DWARF_NUMBER.search(line)
            die['size'] = int(match.group(1)) if match else 0
        elif attribute == 'DW_AT_data_member_location':
            match = DWARF_MEMBER_LOCATION.search(line)
            if match:
                die['location'] = int(match.group(1) or match.group(2))
        elif die['parent'] is not None:
            # The count belongs to the array above the subrange that holds it.
            match = DWARF_NUMBER.search(line)
            if match:
                die['parent']['count'] = int(match.group(1)) + 1

        if die['tag'] == 'variable' and die['name'] and die['type']:
            self.variables[die['name']] = die['type']

    def real_type(self, type_offset):
        """A typedef, a const and a volatile all name the same layout as the
        type below them."""
        for _ in range(16):
            die = self.dies.get(type_offset)
            if die is None:
                return None
            if die['tag'] not in READ_THROUGH:
                return die
            type_offset = die['type']
        return None

    def type_size(self, type_offset):
        die = self.real_type(type_offset)
        if die is None:
            return 0
        if die['tag'] == 'pointer_type':
            return 4
        if die['size'] > 0:
            return die['size']
        if die['tag'] == 'array_type':
            return die['count'] * self.type_size(die['type'])
        return 0

    def member_path(self, type_offset, offset):
        """Walks into a structure or an array until the offset lands on
        something that holds no more members, and writes the way there the way
        C does: ".curPage", "[3].nodeID". Offset 0 of a structure is its first
        member, so the walk goes on."""
        die = self.real_type(type_offset)
        if die is None:
            return '+0x%x' % offset if offset else ''

        if die['tag'] == 'array_type':
            element = self.type_size(die['type'])
            if element <= 0:
                return '+0x%x' % offset if offset else ''
            return '[%d]' % (offset // element) \
                + self.member_path(die['type'], offset % element)

        if die['tag'] not in AGGREGATES:
            return '+0x%x' % offset if offset else ''

        found = None
        for member in die['members']:
            if member['location'] < 0 or member['location'] > offset:
                continue
            size = self.type_size(member['type'])
            if size > 0 and offset >= member['location'] + size:
                continue
            if found is None or member['location'] > found['location']:
                found = member

        if found is None or not found['name']:
            return '+0x%x' % offset if offset else ''

        return '.' + found['name'] \
            + self.member_path(found['type'], offset - found['location'])


def member_base(path):
    return re.sub(r'\+0x[0-9a-fA-F]+$', '', path)


def member_range(first, last):
    """A word read that covers two halfwords touches both, and the code that
    follows masks off the one it wants. Name both, and cut the second one back
    to where the two paths part, so "a.low..high" reads as one range."""
    if member_base(first) == member_base(last):
        return first

    last = member_base(last)
    common = 0
    while common < len(first) and common < len(last) \
            and first[common] == last[common]:
        common += 1
    while common > 0 and last[common - 1] != '.':
        common -= 1
    return first + '..' + last[common:]


class Symbols:
    def __init__(self, output):
        self.sections = {}
        self.by_name = {}

        for line in output.splitlines():
            if line.startswith('Disassembly of section'):
                break
            match = SYMBOL_TABLE.match(line)
            if not match:
                continue
            value, section, size, name = match.groups()
            symbol = {'section': section, 'value': int(value, 16),
                      'size': int(size, 16), 'name': name}
            self.sections.setdefault(section, []).append(symbol)
            self.by_name[name] = symbol

    def at(self, types, section, offset, width):
        for symbol in self.sections.get(section, []):
            if symbol['size'] <= 0 or offset < symbol['value']:
                continue
            if offset >= symbol['value'] + symbol['size']:
                continue

            # gcc names a static inside a function "funcToSend.12741", to keep
            # it apart from a static of the same name in another function. The
            # number means nothing here, and DWARF holds the plain name.
            name = STATIC_SUFFIX.sub('', symbol['name'])
            into = offset - symbol['value']

            if name in types.variables:
                type_offset = types.variables[name]
                end = min(into + width, symbol['size']) - 1
                path = member_range(types.member_path(type_offset, into),
                                    types.member_path(type_offset, end))
                if path:
                    return name + path

            return name if into == 0 else name + '+0x%x' % into

        return ''


def branch_target(instruction):
    """A call has no address until the linker gives it one, so objdump writes 0
    and labels it with whatever symbol sits at 0 of the current section. That
    label is the caller itself and it is wrong."""
    if not is_branch(instruction['mnemonic']):
        return None
    if instruction['symbol']:
        return (instruction['symbol'], '0')
    match = BRANCH_OPERAND.search(instruction['operands'])
    if not match:
        return None
    return (match.group(1), match.group(2) or '0')


def parse_disassembly(output, source_file):
    mapping = {}
    relocations = {}
    constants = {}
    last_line_of = {}
    pool_words = []
    current_function = ''
    current_line = 0

    for line in output.splitlines():
        header = FUNCTION_HEADER.match(line)
        if header:
            current_function = header.group(1)
            continue

        # A relocation names the symbol that objdump could not, and it sits at
        # the address of the field it corrects. Test it before the instruction,
        # because it also starts with an address and a colon. The relocation
        # type marks the line; the name cannot, because a relocation against a
        # section reads ".bss.thing".
        relocation = RELOCATION.match(line)
        if relocation:
            address, symbol = relocation.groups()
            relocations[(current_function, address)] = \
                re.sub(r'\+0x[0-9a-fA-F]+$', '', symbol)
            continue

        if line.startswith('/'):
            source = SOURCE_LINE.match(line)
            if source:
                # Code inlined from a header keeps the line of the call site in
                # this file. Its own line number belongs to a different file.
                if source.group(1) == source_file:
                    current_line = int(source.group(2))
                    last_line_of[current_function] = max(
                        last_line_of.get(current_function, 0), current_line)
                continue

        match = INSTRUCTION.match(line)
        if not match:
            continue

        address = match.group(1)
        mnemonic, operands = split_instruction(line)
        instruction = {'address': address, 'mnemonic': mnemonic,
                       'operands': operands, 'function': current_function,
                       'symbol': '', 'relocation': '', 'loaded': '',
                       'member': ''}

        # A .word is a value from the literal pool, not code. It has no line of
        # its own, so it goes under the end of the function that reads it.
        if mnemonic == '.word':
            constants[(current_function, address)] = operands
            pool_words.append(instruction)
            continue

        if not mnemonic or mnemonic.startswith('.') or current_line <= 0:
            continue

        mapping.setdefault(current_line, []).append(instruction)

    for word in pool_words:
        line_number = last_line_of.get(word['function'], 0)
        if line_number in mapping:
            mapping[line_number].append(word)

    return mapping, relocations, constants


def resolve_addresses(mapping, relocations, constants, is_arm):
    """Names two things objdump leaves as an address: what a call goes to, and
    what a load from the literal pool reads."""
    for instructions in mapping.values():
        for instruction in instructions:
            key = (instruction['function'], instruction['address'])
            instruction['symbol'] = symbol_name(relocations.get(key, ''))

            if not is_arm:
                continue
            pool = POOL_ADDRESS.search(instruction['operands'])
            if not pool:
                continue

            key = (instruction['function'], pool.group(1))
            instruction['relocation'] = relocations.get(key, '')
            instruction['loaded'] = symbol_name(instruction['relocation']) \
                if instruction['relocation'] else constants.get(key, '')


def has_unknown_jump(instructions):
    """A table jump reads its target out of a table, and bx reads it out of a
    register, so the disassembly does not say where either one goes. Any
    instruction after one may be the target, and would run with registers this
    pass never saw."""
    for instruction in instructions:
        mnemonic = base_mnemonic(instruction['mnemonic'])
        if mnemonic in ('tbb', 'tbh'):
            return True
        if mnemonic == 'bx' and instruction['operands'] != 'lr':
            return True
    return False


def track_registers(mapping, symbols, types):
    """A pointer to a section reaches a variable in it, and objdump prints only
    the offset. So follow the register that holds the pointer.

    The register is followed along a run of instructions with one way in. A
    call keeps the registers the callee must save. Everything else that writes
    the register, and every address a branch can land on, drops it."""
    by_function = {}
    for instructions in mapping.values():
        for instruction in instructions:
            by_function.setdefault(instruction['function'], []).append(
                instruction)

    for function, instructions in by_function.items():
        instructions.sort(key=lambda i: int(i['address'], 16))
        if has_unknown_jump(instructions):
            continue

        targets = set()
        for instruction in instructions:
            target = branch_target(instruction)
            if target and target[0] == function:
                targets.add(target[1])

        pointers = {}
        for instruction in instructions:
            if instruction['address'] in targets:
                pointers = {}

            mnemonic = base_mnemonic(instruction['mnemonic'])
            operands = instruction['operands']

            match = re.search(r'\[([A-Za-z]\w*)[,\]]', operands)
            register = match.group(1) if match else ''
            if register in pointers:
                offset = re.search(r'\[' + register + r', #(-?\d+)\]', operands)
                if offset:
                    into = int(offset.group(1))
                elif re.search(r'\[' + register + r'\]', operands):
                    into = 0
                else:
                    into = None
                if into is not None:
                    pointer = pointers[register]
                    instruction['member'] = symbols.at(
                        types, pointer['section'], pointer['value'] + into,
                        access_width(mnemonic))

            if is_call(mnemonic):
                for clobbered in CALL_CLOBBERS:
                    pointers.pop(clobbered, None)
                continue

            # ldm and pop write a list of registers, not the first operand.
            if mnemonic.startswith('ldm') or mnemonic.startswith('pop'):
                pointers = {}
                continue

            if is_branch(mnemonic):
                continue

            match = re.match(r'^([A-Za-z]\w*),', operands)
            if not match or READS_ONLY.match(mnemonic):
                continue

            destination = match.group(1)
            pointers.pop(destination, None)

            # A conditional load may not happen, and then the register still
            # holds what it held before. Only a plain ldr is certain.
            if mnemonic == 'ldr' and instruction['relocation'] in symbols.by_name:
                pointers[destination] = symbols.by_name[instruction['relocation']]


def instruction_text(instruction, index):
    target = branch_target(instruction)
    operands = instruction['operands']

    # Show the name from the relocation, never the wrong one objdump printed.
    if instruction['symbol'] and target:
        operands = '<%s>' % target[0]

    # A pool word that the linker fills in reads 0. Its name is the value.
    if instruction['mnemonic'] == '.word' and instruction['symbol']:
        operands = instruction['symbol']

    # Put what the pool holds where its address was. The rest of the comment
    # stays, so the load still reads as a load from the pool.
    if instruction['loaded']:
        operands = POOL_ADDRESS.sub('; (%s <' % instruction['loaded'].replace(
            '\\', '\\\\'), operands, count=1)

    # objdump comments an offset with the same number in hex, which says
    # nothing. The name of what sits there says everything. Brackets mark it as
    # the memory at that name, the same way the operand does.
    if instruction['member']:
        operands = MEMBER_OFFSET_COMMENT.sub('', operands) \
            + ' ; [%s]' % instruction['member']

    text = '%5s  %-7s %s' % (instruction['address'],
                             instruction['mnemonic'], operands)

    if target:
        line = index.get((target[0], target[1]), 0)
        if line:
            text += '  → Line %d' % line

    return text


def find_compile_commands(source_file):
    """The newest compile_commands.json at or just below the nearest directory
    above this file that holds one.

    Walking up from the file is the only reliable way there. The working
    directory is no help: :lcd makes it a property of the window, so a job
    started from a timer, or from an autocommand while another window is
    current, runs somewhere else entirely. A hidden directory holds another
    tool's build, such as the one qt writes."""
    directory = os.path.dirname(source_file)

    while True:
        found = [path
                 for pattern in ('compile_commands.json',
                                 os.path.join('*', 'compile_commands.json'))
                 for path in glob.glob(os.path.join(directory, pattern))
                 if not os.path.basename(os.path.dirname(path)).startswith('.')]
        if found:
            return max(found, key=os.path.getmtime)

        parent = os.path.dirname(directory)
        if parent == directory:
            return ''
        directory = parent


def compile_command(entry):
    if 'command' in entry:
        return entry['command'].split()
    return list(entry.get('arguments', []))


def output_file(words):
    for index, word in enumerate(words):
        if word == '-o' and index + 1 < len(words):
            return words[index + 1]
        if word.startswith('-o') and len(word) > 2:
            return word[2:]
    return ''


def objdump_version(objdump):
    try:
        first = subprocess.run([objdump, '--version'], capture_output=True,
                               text=True, check=True).stdout.splitlines()[0]
    except (OSError, subprocess.SubprocessError, IndexError):
        return ()
    match = re.search(r'[0-9]+(?:\.[0-9]+)*$', first)
    return tuple(int(part) for part in match.group(0).split('.')) \
        if match else ()


def find_objdump(compiler):
    """A cross toolchain names its tools <prefix>-gcc and <prefix>-objdump. The
    native objdump cannot disassemble another architecture.

    More than one copy is usually installed. An old objdump decodes less: the
    2011 CodeSourcery one reads the first 4 bytes of a Thumb function as one
    ARM word and loses two instructions. So run every one that is installed and
    keep the newest. They all share the target prefix, so they all read the
    same architecture and only the version differs."""
    name = re.sub(r'-(?:gcc|g\+\+)$', '-objdump', os.path.basename(compiler))
    if name == os.path.basename(compiler):
        return 'objdump'

    best, best_version = '', ()
    seen = set()
    for directory in os.environ.get('PATH', '').split(os.pathsep) \
            + [os.path.dirname(compiler)]:
        path = os.path.join(directory, name)
        if not os.access(path, os.X_OK) or os.path.realpath(path) in seen:
            continue
        seen.add(os.path.realpath(path))

        version = objdump_version(path)
        if version > best_version:
            best, best_version = path, version

    return best or 'objdump'


def find_object(source_file):
    """Reads the compile_commands entry for this file and takes its -o, which
    is what mylint.vim adds .mylint to."""
    commands = find_compile_commands(source_file)
    if not commands:
        raise LookupError('No compile_commands.json above ' + source_file)

    with open(commands, encoding='utf-8') as handle:
        entries = json.load(handle)

    for entry in entries:
        if os.path.realpath(os.path.join(entry['directory'], entry['file'])) \
                != source_file:
            continue

        words = compile_command(entry)
        target = output_file(words)
        if not target:
            raise LookupError('No -o in the compile command for this file')

        binary = os.path.join(entry['directory'], target) + '.mylint'
        if not os.path.exists(binary):
            raise LookupError('mylint.vim has not built ' + binary)

        return binary, find_objdump(words[0] if words else '')

    raise LookupError('No entry for this file in ' + commands)


def assembly(source_file):
    binary, objdump = find_object(source_file)

    disassembly = subprocess.run(
        [objdump, '-f', '-t', '-d', '-z', '-l', '-r', '--demangle', binary],
        capture_output=True, text=True, check=True).stdout

    architecture = re.search(r'architecture: ([a-z0-9_]+)', disassembly)
    # objdump reports the family alone as "arm", and the exact machine as
    # "armv7" once it has read the code. aarch64 reads an address another way.
    is_arm = bool(architecture) and architecture.group(1).startswith('arm')

    mapping, relocations, constants = parse_disassembly(disassembly,
                                                        source_file)
    resolve_addresses(mapping, relocations, constants, is_arm)

    if is_arm:
        types = Types(subprocess.run(
            [objdump, '--dwarf=info', binary],
            capture_output=True, text=True, check=True).stdout)
        track_registers(mapping, Symbols(disassembly), types)

    index = {}
    for line, instructions in mapping.items():
        for instruction in instructions:
            index[(instruction['function'], instruction['address'])] = line

    return {'lines': {str(line): [instruction_text(instruction, index)
                                  for instruction in instructions]
                      for line, instructions in mapping.items()},
            'object': binary,
            'object_time': int(os.path.getmtime(binary)),
            'source_time': int(os.path.getmtime(source_file))}


def main():
    source_file = os.path.realpath(sys.argv[1])
    destination = sys.argv[2] if len(sys.argv) > 2 else ''

    try:
        result = assembly(source_file)
    except LookupError as failure:
        result = {'error': str(failure)}
    except subprocess.CalledProcessError as failure:
        result = {'error': ' '.join(failure.cmd) + ' failed: '
                  + (failure.stderr or '').strip()}
    except OSError as failure:
        result = {'error': str(failure)}

    if destination:
        with open(destination, 'w', encoding='utf-8') as handle:
            json.dump(result, handle)
    else:
        json.dump(result, sys.stdout)


if __name__ == '__main__':
    main()
