local Vector3 = require("@Vector3")
local Color3 = require("@Color3")
local CFrame = require("@CFrame")
local Enum = require("@EnumMap")
local signal = require("@Kinemium.signal")
local Vector2 = require("@Vector2")

local Button1Down = signal.new()
local Button1Up = signal.new()
local Button2Down = signal.new()
local Button2Up = signal.new()
local Move = signal.new()
local WheelForward = signal.new()
local WheelBackward = signal.new()

local propTable = {
	Icon = Enum.KinemiumMouseCursor.MOUSE_CURSOR_DEFAULT,
	Target = nil,
	Hit = nil,
	UnitRay = nil,
	TargetFilter = nil,

	IsMouseHidden = false,
	IsMouseOutOfBounds = false,

	X = 0,
	Y = 0,

	ViewSizeX = 0,
	ViewSizeY = 0,

	Button1Down = Button1Down,
	Button1Up = Button1Up,
	Button2Down = Button2Down,
	Button2Up = Button2Up,
	Move = Move,
	WheelForward = WheelForward,
	WheelBackward = WheelBackward,

	SetIcon = function(mouse, icon)
		mouse.Icon = icon
	end,

	GetScreenPosition = function(mouse)
		return mouse.X, mouse.Y
	end,

	Raycast = function(mouse, distance)
		return nil
	end,

	IsButtonDown = function(mouse, button)
		return false
	end,

	Name = "Mouse",
}

return {
	class = "Mouse",
	non_creatable = true,
	callback = function(instance, renderer)
		instance:SetProperties(propTable)

		local lib = renderer.lib

		instance.Changed:Connect(function(property, value)
			if property == "Icon" then
				lib.SetMouseCursor(value.Value)
			end
		end)

		renderer.Signal:Connect(function(route, data)
			if route == "MouseData" then
				--[[
                    			Button1Down = lib.IsMouseButtonDown(0) == 1,
                                Button1Pressed = lib.IsMouseButtonPressed(0) == 1,
                                Button1Released = lib.IsMouseButtonReleased(0) == 1,

                                Button2Down = lib.IsMouseButtonDown(1) == 1,
                                Button2Pressed = lib.IsMouseButtonPressed(1) == 1,
                                Button2Released = lib.IsMouseButtonReleased(1) == 1,

                                Button3Down = lib.IsMouseButtonDown(2) == 1,
                                Button3Pressed = lib.IsMouseButtonPressed(2) == 1,
                                Button3Released = lib.IsMouseButtonReleased(2) == 1,
                --]]
				local position = data.position
				local delta = data.delta
				local mouse_wheel_move = data.mouse_wheel_move
				local mouse_wheel_delta = data.mouse_wheel_delta

				instance.X = position.X
				instance.Y = position.Y
				instance.IsMouseHidden = data.is_cursor_hidden
				instance.IsMouseOutOfBounds = data.is_cursor_inbounds

				if mouse_wheel_move then
					Move:Fire()
				end

				if data.Button1Down then
					Button1Down:Fire()
				end

				if data.Button1Released then
					Button1Up:Fire()
				end

				if data.Button2Down then
					Button2Down:Fire()
				end

				if data.Button2Released then
					Button2Up:Fire()
				end
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
