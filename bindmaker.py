# Bindmaker v2 - by devcell
import re
import sys
from pathlib import Path

# Mapping C types to FFI runtime types
type_map = {
    'void': 'ffi.types.void',
    'bool': 'ffi.types.u8',
    'char': 'ffi.types.i8',
    'signed char': 'ffi.types.i8',
    'unsigned char': 'ffi.types.u8',
    'short': 'ffi.types.i16',
    'signed short': 'ffi.types.i16',
    'unsigned short': 'ffi.types.u16',
    'int': 'ffi.types.i32',
    'signed int': 'ffi.types.i32',
    'unsigned int': 'ffi.types.u32',
    'long': 'ffi.types.i64',
    'signed long': 'ffi.types.i64',
    'unsigned long': 'ffi.types.u64',
    'float': 'ffi.types.float',
    'double': 'ffi.types.double',
    'pointer': 'ffi.types.pointer',
    # JPH typedefs
    'JPH_Bool': 'ffi.types.u32',
    'JPH_BodyID': 'ffi.types.u32',
    'JPH_SubShapeID': 'ffi.types.u32',
    'JPH_ObjectLayer': 'ffi.types.u32',
    'JPH_BroadPhaseLayer': 'ffi.types.u8',
    'JPH_CollisionGroupID': 'ffi.types.u32',
    'JPH_CollisionSubGroupID': 'ffi.types.u32',
    'JPH_CharacterID': 'ffi.types.u32',
    'JPH_Color': 'ffi.types.u32',
    'size_t': 'ffi.types.pointer',
    'uint32_t': 'ffi.types.u32',
    'uint8_t': 'ffi.types.u8',
    'int32_t': 'ffi.types.i32',
    'int8_t': 'ffi.types.i8',
    'uint64_t': 'ffi.types.u64',
    'int64_t': 'ffi.types.i64',
}

lua_keywords = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return",
    "then", "true", "until", "while"
}

def sanitize_lua_name(name: str) -> str:
    name = re.sub(r'\[.*?\]', '', name)
    name = re.sub(r'[^\w_]', '', name)
    if re.match(r'^\d', name):
        name = '_' + name
    if name in lua_keywords:
        name = '_' + name
    # camelCase -> snake_case
    name = re.sub(r'([A-Z]+)', r'_\1', name).lower().strip('_')
    return name

def get_ffi_type(ctype: str) -> str:
    ctype = ctype.strip()
    ctype = re.sub(r'\b(const|volatile)\b', '', ctype).strip()
    if '*' in ctype:
        return 'ffi.types.pointer'
    return type_map.get(ctype, 'ffi.types.pointer')

def parse_structs(header):
    structs = {}
    nested_counter = 0
    pattern = re.compile(r'typedef struct\s+(\w+)?\s*{([^}]*)}\s*(\w+);', re.MULTILINE | re.DOTALL)
    for match in pattern.finditer(header):
        struct_name = sanitize_lua_name(match.group(3))
        body = match.group(2)
        fields = []
        seen_fields = set()

        for line in body.split(';'):
            line = line.strip()
            if not line:
                continue

            # Remove comments
            line = re.sub(r'/\*.*?\*/', '', line).strip()
            line = re.sub(r'//.*', '', line).strip()

            if not line:
                continue

            if re.search(r'\(\s*\*\s*\w+\s*\)\s*\(.*\)', line) or 'struct' in line:
                nested_counter += 1
                nested_name = f"{struct_name}_nested{nested_counter}"
                if nested_name not in seen_fields:
                    fields.append((nested_name, 'ffi.types.pointer'))
                    seen_fields.add(nested_name)
                continue

            # Parse field declaration
            # Handle arrays like: type field[SIZE]
            array_match = re.match(r'(.+?)\s+(\w+)\s*\[([^\]]+)\]', line)
            if array_match:
                ctype = array_match.group(1).strip()
                field_name = sanitize_lua_name(array_match.group(2))
                # For arrays, treat as pointer for now
                ffi_type = 'ffi.types.pointer'
            else:
                # Regular field: type field
                parts = line.split()
                if len(parts) < 2:
                    continue
                ctype = ' '.join(parts[:-1])
                field_name = sanitize_lua_name(parts[-1])

            if field_name in seen_fields:
                continue

            # Handle pointer types
            if '*' in ctype or ctype.startswith('const ') and '*' in ctype:
                ffi_type = 'ffi.types.pointer'
            else:
                ffi_type = get_ffi_type(ctype)

            fields.append((field_name, ffi_type))
            seen_fields.add(field_name)

        structs[struct_name] = fields
    return structs

def parse_constants(header):
    consts = {}

    for m in re.finditer(r'#define\s+(\w+)\s+(.+)', header):
        const_name = sanitize_lua_name(m.group(1))
        const_value = m.group(2).strip()

        # Skip preprocessor directives and non-constants
        if any(skip in const_value for skip in ['#endif', '#ifdef', '#ifndef', '#else', '#elif', 'extern', '_JPH_', '__']):
            continue

        # Clean up C-style numeric literals
        const_value = re.sub(r'\b(\d+(?:\.\d+)?)f\b', r'\1', const_value)  # Remove 'f' suffix
        const_value = re.sub(r'\(([^)]+)\)', r'\1', const_value)  # Remove parentheses

        try:
            # Try to evaluate as a number
            val = eval(const_value, {"__builtins__": None})
            if isinstance(val, (int, float)):
                consts[const_name] = val
        except:
            # Skip constants that can't be evaluated as numbers
            continue

    return consts


def parse_functions(header):
    funcs = {}
    pattern = re.compile(r'([\w\s\*\d]+)\s+(\w+)\s*\(([^)]*)\);', re.MULTILINE)
    for match in pattern.finditer(header):
        ret_type = get_ffi_type(match.group(1))
        args = []
        params = match.group(3).strip()
        if params and params != 'void':
            for arg in params.split(','):
                arg = arg.strip()
                if arg == '...':
                    args.append('ffi.types.pointer')  # variadic, fallback to pointer
                    continue
                parts = arg.split()
                if len(parts) < 1:
                    continue
                ctype = ' '.join(parts[:-1]) if len(parts) > 1 else parts[0]
                ffi_type = get_ffi_type(ctype)
                args.append(ffi_type)
        funcs[match.group(2)] = (ret_type, args)
    return funcs

def generate_lua(structs, funcs, consts):
    lines = [
        "-- Generated with Zune Bindmaker (v2, devcell)",
        "local ffi = zune.ffi",
        "local fs = zune.fs",
        "local structs = {}",
        "local const = {}",
        "",
        "-- Primitive type aliases",
        "local void = ffi.types.void",
        "local int = ffi.types.i32",
        "local uint = ffi.types.u32",
        "local bool = ffi.types.u8",
        "local float = ffi.types.float",
        "local cstring = ffi.types.pointer",
        "local long = ffi.types.i64",
        "type int = number",
        "type uint = number",
        "type bool = number",
        "type float = number",
        "type long = buffer",
        "type double = number",
        "type cstring = string | buffer | FFIPointer",
        "type FFIPointer = string | buffer | FFIPointer",
        ""
    ]

    # structs
    for name, fields in structs.items():
        lines.append(f"structs.{name} = ffi.struct({{")
        for field_name, field_type in fields:
            lines.append(f"    {{ {field_name} = {field_type} }},")
        lines.append("})")
        lines.append(f"type {name} = typeof(structs.{name}:new({{}}))\n")

    # constants
    for k, v in consts.items():
        lines.append(f"const.{k} = {v}")

    lines.append("""
local function fn(returns: any, args: { any })
    return { returns = returns, args = args }
end
""")

    # export types
    lines.append("export type Fns = {")
    for fname, (ret, args) in funcs.items():
        args_str = ", ".join(["FFIPointer" if a == "ffi.types.pointer" else a for a in args])
        ret_type = "FFIPointer" if ret == "ffi.types.pointer" else ret
        lines.append(f"\t{fname}: ({args_str}) -> {ret_type},")
    lines.append("}\n")

    # runtime defs
    lines.append("return {")
    lines.append("\tdef = {")
    for fname, (ret, args) in funcs.items():
        args_list = ", ".join(args)
        lines.append(f"\t\t{fname} = fn({ret}, {{ {args_list} }}),")
    lines.append("\t},")
    lines.append("\tstructs = structs,")
    lines.append("\tconst = const,")
    lines.append("}")
    return "\n".join(lines)

def main():
    if len(sys.argv) < 2:
        print("Usage: python bindmaker.py <header.h>")
        return

    header_file = Path(sys.argv[1])
    output_file = header_file.with_name(header_file.stem + "_bindings.luau")

    with open(header_file) as f:
        header = f.read()

    structs = parse_structs(header)
    funcs = parse_functions(header)
    consts = parse_constants(header)
    lua_code = generate_lua(structs, funcs, consts)

    with open(output_file, "w") as f:
        f.write(lua_code)

    print(f"Bindings generated: {output_file}")

if __name__ == "__main__":
    main()
