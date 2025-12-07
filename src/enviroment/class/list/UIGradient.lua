local UDim = require("@UDim")
local UDim2 = require("@UDim2")
local Vector2 = require("@Vector2")
local ColorSequence = require("@ColorSequence")
local ColorSequenceKeypoint = require("@ColorSequenceKeypoint")
local Color3 = require("@Color3")

local propTable = {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
	}),
	Rotation = 0,
	Name = "UIGradient",
	BaseClass = "Kinemium.uimodifier",
}

return {
	class = "UIGradient",
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
