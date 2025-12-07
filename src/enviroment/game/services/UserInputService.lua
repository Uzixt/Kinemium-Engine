local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local UserInputService = Instance.new("UserInputService")

local InputBegan = signal.new()
local InputEnded = signal.new()
local MouseMoved = signal.new()
local MouseWheel = signal.new()

UserInputService.InitRenderer = function(renderer, renderer_signal)
	local Enum = require("@EnumMap")

	local lib = renderer.lib
	local const = renderer.const

	UserInputService:SetProperties({
		IsKeyDown = false,
		InputBegan = InputBegan,
		MouseMoved = MouseMoved,
		MouseWheel = MouseWheel,
		InputEnded = InputEnded,
		GetCharPressed = lib.GetCharPressed,
		TouchEnabled = false,
		GamepadEnabled = false,
	})

	function UserInputService:GetKeysDown()
		local keysDown = {}
		for name, code in pairs(const.KeyboardKey) do
			if lib.IsKeyDown(code) == 1 then
				table.insert(keysDown, name)
			end
		end
		return keysDown
	end

	function UserInputService:GetStringPressed()
		local code = lib.GetCharPressed()
		if code ~= 0 then
			return string.char(code)
		end
		return nil
	end

	function UserInputService:IsKeyDown(key)
		return lib.IsKeyDown(const.KeyboardKey[key]) == 1
	end

	function UserInputService:IsKeyPressed(key)
		return lib.IsKeyPressed(const.KeyboardKey[key]) == 1
	end

	function UserInputService:IsKeyReleased(key)
		return lib.IsKeyReleased(const.KeyboardKey[key]) == 1
	end

	local function findSuitable(value: number)
		for _, enumItem in pairs(Enum._numberIndex) do
			if enumItem.Value == value then
				return enumItem
			end
		end
	end

	renderer_signal:Connect(function(route, data)
		if route == "IsKeyDown" then
			local key = findSuitable(data)
			if key then
				InputBegan:Fire({
					KeyCode = key,
					UserInputType = Enum.UserInputType.Keyboard,
					UserInputState = Enum.UserInputState.Begin,
				})
			end
		end

		if route == "IsKeyReleased" then
			local key = findSuitable(data)
			if key then
				InputEnded:Fire({
					KeyCode = key,
					UserInputType = Enum.UserInputType.Keyboard,
					UserInputState = Enum.UserInputState.End,
				})
			end
		end

		if route == "MouseMoved" then
			MouseMoved:Fire({
				UserInputType = Enum.UserInputType.MouseMovement,
				Delta = data,
			})
		end

		if route == "MouseWheel" then
			MouseWheel:Fire({
				UserInputType = Enum.UserInputType.MouseWheel,
				Delta = data,
			})
		end
	end)
end

return UserInputService
