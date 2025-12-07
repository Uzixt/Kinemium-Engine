local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local CFrame = require("@CFrame")
local Enum = require("@EnumMap")
local signal = require("@Kinemium.signal")

local propTable = {
	Name = "Player",
	UserId = 0,
	Character = nil,
	Backpack = {},
	Team = nil,
	Health = 100,
	MaxHealth = 100,
	WalkSpeed = 16,
	JumpPower = 50,
}

return {
	class = "Player",
	non_creatable = true,
	callback = function(instance, starterGui)
		local CharacterAdded = signal.new()
		local CharacterRemoving = signal.new()

		propTable.CharacterAdded = CharacterAdded
		propTable.CharacterRemoving = CharacterRemoving

		instance:SetProperties(propTable)
		if starterGui and starterGui.ClassName == "StarterGui" then
			instance.PlayerGui = starterGui:Clone()
		end

		return instance
	end,
	inherit = function(tble)
		for prop, val in pairs(propTable) do
			tble[prop] = val
		end
	end,
}
