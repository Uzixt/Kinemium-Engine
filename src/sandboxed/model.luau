--[[
local RunService = game:GetService("RunService")
local model = Instance.new("Model")

local WhitePart = Instance.new("Part")
WhitePart.Position = Vector3.new(0, 9, 0)
WhitePart.Size = Vector3.new(8, 8, 8)
WhitePart.Shader = "Kinemium"
WhitePart.Transparency = 0.5
WhitePart.Color = Color3.new(0.47451, 0.47451, 0.47451)
WhitePart.Parent = model

model.Parent = workspace

print(workspace:GetChildren())

-- add new part

local newPart = Instance.new("MeshPart")
newPart.Position = Vector3.new(0, 9, 9)
newPart.Size = Vector3.new(5, 5, 5)
newPart.Shader = "Kinemium"
newPart.Transparency = 0
newPart.MeshId = "./src/template/meshes/other.obj"
newPart.Color = Color3.new(0.466667, 0, 1)
newPart.Parent = model

local t = 0
RunService.RenderStepped:Connect(function(delta: number)
	t += delta

	-- pulse transparency
	newPart.Transparency = 0.2 + math.abs(math.sin(t * 3)) * 0.5

	-- pulse scale
	local s = 5 + math.sin(t * 3) * 0.3
	newPart.Size = Vector3.new(s, s, s)

	-- rotate using Orientation (degrees)
	newPart.Orientation += Vector3.new(
		math.rad(math.random(1, 360)),
		math.rad(math.random(1, 360)),
		math.rad(math.random(1, 360))
	)
end)
--]]
