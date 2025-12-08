-- BlurOverlay.lua
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local BlurOverlay = {}
BlurOverlay.__index = BlurOverlay

local singularStep = require(game.ReplicatedStorage.Shared.Libraries.SingularStep)
local stepped = singularStep.new()

-- Utility: Unique IDs
local uidCounter = 0
local function genUid()
	uidCounter += 1
	return "blurOverlay::" .. tostring(uidCounter)
end

-- Utility: Check camera readiness
local function waitForCamera()
	local function isValid(x)
		return x == x
	end
	while not isValid(Camera:ScreenPointToRay(0, 0).Origin.X) do
		stepped:Wait()
	end
end
waitForCamera()

-- Geometry helpers
local acos, max, pi, sqrt = math.acos, math.max, math.pi, math.sqrt
local wedgeSize = 0.2

local function drawTriangle(v1, v2, v3, part0, part1, material)
	local s1 = (v1 - v2).Magnitude
	local s2 = (v2 - v3).Magnitude
	local s3 = (v3 - v1).Magnitude
	local smax = max(s1, s2, s3)
	local A, B, C
	if s1 == smax then
		A, B, C = v1, v2, v3
	elseif s2 == smax then
		A, B, C = v2, v3, v1
	else
		A, B, C = v3, v1, v2
	end

	local para = ((B - A).X * (C - A).X + (B - A).Y * (C - A).Y + (B - A).Z * (C - A).Z) / (A - B).Magnitude
	local perp = sqrt((C - A).Magnitude ^ 2 - para * para)
	local dif_para = (A - B).Magnitude - para

	local st = CFrame.new(B, A)
	local za = CFrame.Angles(pi / 2, 0, 0)

	local cf0 = st
	local topLook = (cf0 * za).LookVector
	local midPoint = A + CFrame.new(A, B).LookVector * para
	local neededLook = CFrame.new(midPoint, C).LookVector
	local dot = topLook:Dot(neededLook)

	local ac = CFrame.Angles(0, 0, acos(dot))
	cf0 = cf0 * ac
	if ((cf0 * za).LookVector - neededLook).Magnitude > 0.01 then
		cf0 *= CFrame.Angles(0, 0, -2 * acos(dot))
	end
	cf0 *= CFrame.new(0, perp / 2, -(dif_para + para / 2))

	local cf1 = st * ac * CFrame.Angles(0, pi, 0)
	if ((cf1 * za).LookVector - neededLook).Magnitude > 0.01 then
		cf1 *= CFrame.Angles(0, 0, 2 * acos(dot))
	end
	cf1 *= CFrame.new(0, perp / 2, dif_para / 2)

	if not part0 then
		part0 = Instance.new("Part")
		part0.Anchored = true
		part0.CanCollide = false
		part0.CastShadow = false
		part0.Material = material
		part0.Size = Vector3.new(wedgeSize, wedgeSize, wedgeSize)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Wedge
		mesh.Name = "WedgeMesh"
		mesh.Parent = part0
	end
	part0.WedgeMesh.Scale = Vector3.new(0, perp / wedgeSize, para / wedgeSize)
	part0.CFrame = cf0

	if not part1 then
		part1 = part0:Clone()
	end
	part1.WedgeMesh.Scale = Vector3.new(0, perp / wedgeSize, dif_para / wedgeSize)
	part1.CFrame = cf1

	return part0, part1
end

local function drawQuad(v1, v2, v3, v4, parts, material)
	parts[1], parts[2] = drawTriangle(v1, v2, v3, parts[1], parts[2], material)
	parts[3], parts[4] = drawTriangle(v3, v2, v4, parts[3], parts[4], material)
end

-- Constructor
function BlurOverlay.new(frame, opts)
	local self = setmetatable({}, BlurOverlay)

	self.Frame = frame
	self.Options = opts or {}
	self.Options.Material = self.Options.Material or Enum.Material.Glass
	self.Options.Transparency = self.Options.Transparency or 0.5
	self.Options.Color = self.Options.Color or Color3.new(1, 1, 1)

	-- Depth of Field effect
	self.DepthOfField = Instance.new("DepthOfFieldEffect")
	self.DepthOfField.FarIntensity = 0
	self.DepthOfField.FocusDistance = 51.6
	self.DepthOfField.InFocusRadius = 50
	self.DepthOfField.NearIntensity = 1
	self.DepthOfField.Enabled = false
	self.DepthOfField.Parent = Lighting

	-- Storage
	self.Parts = {}
	self.Folder = Instance.new("Folder")
	self.Folder.Name = frame.Name .. "_BlurParts"
	self.Folder.Parent = Camera

	self.Parents = {}
	do
		local function collect(gui)
			if gui:IsA("GuiObject") then
				table.insert(self.Parents, gui)
				if gui.Parent then
					collect(gui.Parent)
				end
			end
		end
		collect(frame)
	end

	self._uid = genUid()
	RunService:BindToRenderStep(self._uid, 2000, function()
		self:_update()
	end)

	return self
end

function BlurOverlay:_update()
	if not self.Enabled then
		self.DepthOfField.Enabled = false
		for _, part in ipairs(self.Parts) do
			part:Destroy()
		end
		self.Parts = {}
		return
	end

	self.DepthOfField.Enabled = true

	local zIndex = 1 - 0.05 * self.Frame.ZIndex
	local tl = self.Frame.AbsolutePosition
	local br = tl + self.Frame.AbsoluteSize
	local tr = Vector2.new(br.X, tl.Y)
	local bl = Vector2.new(tl.X, br.Y)

	local rot = 0
	for _, gui in ipairs(self.Parents) do
		rot += gui.Rotation
	end
	if rot ~= 0 and rot % 180 ~= 0 then
		local mid = tl:Lerp(br, 0.5)
		local s, c = math.sin(math.rad(rot)), math.cos(math.rad(rot))
		local function rotateVec(v)
			return Vector2.new(c * (v.X - mid.X) - s * (v.Y - mid.Y), s * (v.X - mid.X) + c * (v.Y - mid.Y)) + mid
		end
		tl, tr, bl, br = rotateVec(tl), rotateVec(tr), rotateVec(bl), rotateVec(br)
	end

	drawQuad(
		Camera:ScreenPointToRay(tl.X, tl.Y, zIndex).Origin,
		Camera:ScreenPointToRay(tr.X, tr.Y, zIndex).Origin,
		Camera:ScreenPointToRay(bl.X, bl.Y, zIndex).Origin,
		Camera:ScreenPointToRay(br.X, br.Y, zIndex).Origin,
		self.Parts,
		self.Options.Material
	)

	for _, pt in ipairs(self.Parts) do
		pt.Parent = self.Folder
		pt.Transparency = self.Options.Transparency
		pt.Color = self.Options.Color
	end
end

function BlurOverlay:SetEnabled(state)
	self.Enabled = state
end

function BlurOverlay:Destroy()
	RunService:UnbindFromRenderStep(self._uid)
	self.DepthOfField:Destroy()
	for _, part in ipairs(self.Parts) do
		part:Destroy()
	end
	self.Folder:Destroy()
end

return BlurOverlay
