local RunService = game:GetService("RunService")
local tooltip = {}
local luacss = require(script.Parent.Parent)
local spring = require(script.Parent.Parent.libs.spr)

local player = game.Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui

local mouse = player:GetMouse()

local tooltipGui, data = luacss.compileObject({
	class = "TextLabel",
	groundcolor = Color3.new(0, 0, 0),
	groundtransparency = 0.3,
	AutomaticSize = Enum.AutomaticSize.XY,
	text = "This is a cool tooltip!!",
	txtcolor = Color3.new(1, 1, 1),
	font = Enum.Font.BuilderSans,
	alignment = "center",
	txtsize = 17,
	size = { 0, 0, 0, 0 },
	padding = { 0, 10 },
	spawn = {
		Corner = {
			class = "UICorner",
			radius = { 1, 0 },
		},
	},
	parent = screenGui,
})

RunService.RenderStepped:Connect(function()
	spring.target(tooltipGui, 0.8, 5, {
		Position = UDim2.fromOffset(mouse.X, mouse.Y - 20),
	})
end)

local function hide()
	spring.target(tooltipGui, 2, 5, {
		TextTransparency = 1,
		BackgroundTransparency = 1,
	})
end

local function show()
	spring.target(tooltipGui, 2, 5, {
		TextTransparency = 0,
		BackgroundTransparency = 0.3,
	})
end

hide()

function tooltip:add(gui: GuiObject, text)
	gui.MouseEnter:Connect(function()
		tooltipGui.Text = text
		show()
	end)

	gui.MouseLeave:Connect(function()
		hide()
	end)
end

function tooltip:addPart(part: Part, callback)
	return RunService.RenderStepped:Connect(function()
		if mouse.Target == part then
			tooltipGui.Text = callback(part)
			show()
		else
			hide()
		end
	end)
end

return tooltip
