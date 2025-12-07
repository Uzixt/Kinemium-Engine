local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local Vector3 = require("@Vector3")

local StarterGui = Instance.new("StarterGui")

StarterGui:SetProperties({
	Enabled = true,
	ResetOnSpawn = true,
	ZIndexBehavior = "Sibling",
	CoreGuiEnabled = true,
})

StarterGui.InitRenderer = function(renderer, signal)
	-- we dont need to do anything here since the engine
	-- copies the children of starter gui to the player's gui
	signal:Connect(function(route, data) end)
end

return StarterGui
