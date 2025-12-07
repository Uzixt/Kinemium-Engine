local UDim = require("@UDim")
local UDim2 = require("@UDim2")
local Vector2 = require("@Vector2")

local propTable = {
	CornerRadius = UDim.new(0, 15),
	Name = "UICorner",
	BaseClass = "Kinemium.uimodifier",
}

return {
	class = "UICorner",
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
