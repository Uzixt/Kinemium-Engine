--!strict

local ffi = zune.ffi
local fs = zune.fs

local jolt = require("./jolt")

-- Load the joltc.dll
local lib_path = "./src/external/jolt/joltc.dll"
local lib = ffi.dlopen(lib_path, jolt.def)

local const = jolt -- constants and structs

local export = {
	lib = lib,
	const = const,
}

return export
