local Vector2 = require("@Vector2")
local Color3 = require("@Color3")
local UDim2 = require("@UDim2")
local Enum = require("@EnumMap")
local Frame = require("@Frame")
local ImageLabel = require("@ImageLabel")
local logic = require("@Kinemium.2dbutton")

local propTable = {
	AutoButtonColor = true,
	ChangeCursorOnHover = true,
	Visible = true,
}

ImageLabel.inherit(propTable)

propTable.render = function(lib, object, dt, structs, renderer)
	local framePos, frameSize, texture = ImageLabel.render(lib, object, dt, structs, renderer)

	logic:Step(object, lib)
end

return {
	class = "ImageButton",
	callback = function(instance, renderer)
		-- includes lib
		logic:SetupSignals(propTable)
		instance:SetProperties(propTable)

		instance.Changed:Connect(function(property)
			if property == "Image" then
				renderer.gbSet(instance.Image, renderer.lib.LoadTexture(instance.Image))
			end
		end)

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
