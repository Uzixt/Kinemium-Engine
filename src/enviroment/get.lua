local datatypes = require("@Kinemium.datatypes.get")
local Registry = require("@Kinemium.registry")
local DataModel = require("@DataModel")
local EnumMap = require("@EnumMap")
local PlayerGui = require("@PlayerGui")

return function(renderer)
	local mainDatamodel = DataModel.new(renderer, { "StarterGui" })
	local data = datatypes

	local shared = {}

	data.Instance = {
		new = function(class)
			return Registry.new(class, renderer)
		end,
	}
	data.Enum = EnumMap
	data.task = {
		cancel = zune.task.cancel,
		defer = zune.task.defer,
		delay = zune.task.delay,
		spawn = zune.task.spawn,
		wait = zune.task.wait,
	}
	data.game = mainDatamodel
	data.workspace = mainDatamodel:GetService("Workspace")
	data.shared = shared
	data.wait = zune.task.wait
	data.Kinemium = {
		version = 1.0,
		window = require("@Kinemium.window")(renderer.lib),
		--jolt = require("@Kinemium.jolt"),
	}
	data.krequire = function(Instance)
		local sandboxer = require("@sandboxer")

		if type(Instance) == "table" then
			if Instance.ClassName == "ModuleScript" then
				local source = Instance.Source
				local returned = sandboxer.run(source, Instance.Name, data)
				if returned then
					return returned
				end
			end
		elseif type(Instance) == "string" then
			error("Cannot require string")
			return
		else
			error("krequire: cannot require this table; expected ModuleScript")
		end
	end
	data.ktypeof = function(v)
		if type(v) == "table" then
			if v.type then
				return v.type
			else
				return "table"
			end
		else
			return type(v)
		end
	end
	local players = mainDatamodel:GetService("Players")
	players.LocalPlayer.PlayerGui = PlayerGui.InitRenderer(renderer, renderer.Signal)
	players.LocalPlayer.Parent = players

	renderer.SetLightingService(mainDatamodel:GetService("Lighting"))
	return data
end
