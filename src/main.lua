_G.warn = function(...)
	print("[\x1b[33mWARN\x1b[0m]", ...)
end

local sandboxer = require("./modules/sandboxer")
local filesystem = require("./modules/filesystem")
local Instance = require("@Instance")
local ModuleScript = require("@ModuleScript")
local Kinemium_env = require("./enviroment/get")
local task = zune.task
local threads = {}
local Kinemium = {}
local luacss = "./src/rblx/luacss/init.luau"

local renderer = require("@Kinemium.3d")

Kinemium_env = Kinemium_env(renderer)

--local raygui = require("@raygui")

sandboxer.enviroment = Kinemium_env

--[[
sandboxer.rblxrequire(luacss, function(code, path)
	local scriptInstance = Instance.new("ModuleScript")
	ModuleScript.callback(scriptInstance)
	scriptInstance.Source = code

	local function processDirectory(dirPath, parentInstance)
		local entries = zune.fs.entries(dirPath)
		for _, entry in pairs(entries) do
			if entry.kind == "directory" then
				local folder = Instance.new("Folder")
				folder.Name = entry.name
				folder.Parent = parentInstance
				processDirectory(dirPath .. "/" .. entry.name, folder) -- recursive call
			elseif entry.kind == "file" and entry.name:match("%.lu[au]$") then
				local childModule = Instance.new("ModuleScript")
				childModule.Name = entry.name:gsub("%.lu[au]$", "")
				childModule.Source = zune.fs.readFile(dirPath .. "/" .. entry.name)
				childModule.Parent = parentInstance
				if not scriptInstance[parentInstance.Name] then
					scriptInstance[parentInstance.Name] = parentInstance
				end
				scriptInstance[parentInstance.Name][childModule.Name] = childModule
			end
		end
	end

	processDirectory("./src/rblx/luacss", scriptInstance)

	return scriptInstance
end)
--]]

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
