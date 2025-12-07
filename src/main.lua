_G.warn = function(...)
	print("[\x1b[33mWARN\x1b[0m]", ...)
end

local sandboxer = require("./modules/sandboxer")
local filesystem = require("./modules/filesystem")
local Kinemium_env = require("./enviroment/get")
local task = zune.task
local threads = {}
local Kinemium = {}

local renderer = require("@Kinemium.3d")

Kinemium_env = Kinemium_env(renderer)

--local raygui = require("@raygui")

sandboxer.enviroment = Kinemium_env

local function execute(path, entry)
	local code = filesystem.read(path)
	local thread = task.spawn(function()
		sandboxer.run(code, entry.name)
	end)
	threads[path] = thread
end

local function callback(entry, base)
	local base = base or "src/sandboxed"
	local path = base .. "/" .. entry.name

	if entry.kind == "directory" then
		filesystem.entryloop(path, function(e)
			callback(e, path)
		end)
	else
		execute(path, entry)
	end
end

filesystem.entryloop("src/sandboxed/internals", function(e)
	callback(e, "src/sandboxed/internals")
end)

function Kinemium:playtest()
	filesystem.entryloop("src/sandboxed", function(e)
		callback(e, "src/sandboxed")
	end)
end

renderer.Kinemium_camera.Parent = sandboxer.enviroment.workspace

Kinemium:playtest()
renderer.Run()
