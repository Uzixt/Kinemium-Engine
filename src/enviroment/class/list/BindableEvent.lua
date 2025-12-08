local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local CFrame = require("@CFrame")
local Enum = require("@EnumMap")
local Instance = require("@Instance")

local signal = require("@Kinemium.signal")

local propTable = {}

return {
	class = "BindableEvent",
	callback = function(object)
		local bindableSignal = signal.new()

		propTable = {
			Fire = bindableSignal.Fire,
			Connect = bindableSignal.Connect,
			Name = "BindableEvent",
		}
		object.SetProperties(propTable)

		return object
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
