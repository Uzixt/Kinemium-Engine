local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local Enum = require("@EnumMap")
local CFrame = require("@CFrame")

local propTable = {
	Position = Vector3.new(0, 0, 0),
	Color = Color3.new(1, 1, 1),
	Brightness = 1, -- intensity of the light
	Range = 10, -- how far the light reaches
	Shadows = true, -- casts shadows or not
	Enabled = true, -- whether the light is active
	Name = "PointLight",
	BaseClass = "Kinemium.light",
	CFrame = CFrame.new(0, 0, 0),
}

return {
	class = "PointLight",
	callback = function(instance)
		instance:SetProperties(propTable)
		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
