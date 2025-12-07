local KinemiumShaderService = game:GetService("KinemiumShaderService")

-- Create terrain base (large flat island)
local function createTerrain()
	-- Main island platform
	local island = Instance.new("Part")
	island.Size = Vector3.new(100, 3, 100)
	island.Position = Vector3.new(0, -1.5, 0)
	island.Material = Enum.Material.Grass
	island.Color = Color3.fromRGB(76, 143, 68)
	island.Anchored = true
	island.Parent = workspace

	-- Sandy beach around the edges
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local beach = Instance.new("Part")
		beach.Size = Vector3.new(20, 1, 15)
		beach.Position = Vector3.new(math.cos(angle) * 45, -2.5, math.sin(angle) * 45)
		beach.Rotation = Vector3.new(0, math.deg(angle), 0)
		beach.Material = Enum.Material.Sand
		beach.Color = Color3.fromRGB(227, 207, 159)
		beach.Anchored = true
		beach.Parent = workspace
	end
end

-- Create hills and elevation
local function createHills()
	local hills = {
		{ pos = Vector3.new(20, 3, 20), size = Vector3.new(25, 10, 25) },
		{ pos = Vector3.new(-25, 2, -15), size = Vector3.new(20, 8, 20) },
		{ pos = Vector3.new(15, 4, -30), size = Vector3.new(18, 12, 18) },
	}

	for _, hill in ipairs(hills) do
		local part = Instance.new("Part")
		part.Size = hill.size
		part.Position = hill.pos
		part.Material = Enum.Material.Grass
		part.Color = Color3.fromRGB(67, 120, 55)
		part.Anchored = true
		part.Parent = workspace
	end
end

-- Create rocky cliffs
local function createCliffs()
	local cliffs = {
		{ pos = Vector3.new(-40, 5, 10), size = Vector3.new(8, 15, 20) },
		{ pos = Vector3.new(35, 6, -20), size = Vector3.new(10, 18, 15) },
	}

	for _, cliff in ipairs(cliffs) do
		local part = Instance.new("Part")
		part.Size = cliff.size
		part.Position = cliff.pos
		part.Material = Enum.Material.Slate
		part.Color = Color3.fromRGB(90, 90, 95)
		part.Anchored = true
		part.Parent = workspace
	end
end

-- Create trees
local function createTree(position)
	-- Trunk
	local trunk = Instance.new("Part")
	trunk.Size = Vector3.new(2, 8, 2)
	trunk.Position = position + Vector3.new(0, 4, 0)
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(120, 80, 50)
	trunk.Anchored = true
	trunk.Parent = workspace

	-- Leaves (canopy)
	local leaves = Instance.new("Part")
	leaves.Size = Vector3.new(10, 8, 10)
	leaves.Position = position + Vector3.new(0, 10, 0)
	leaves.Material = Enum.Material.Grass
	leaves.Color = Color3.fromRGB(40, 120, 30)
	leaves.Anchored = true
	leaves.Parent = workspace
end

local function createForest()
	local treePositions = {
		Vector3.new(10, 0, 15),
		Vector3.new(15, 0, 20),
		Vector3.new(5, 0, 25),
		Vector3.new(-10, 0, 10),
		Vector3.new(-15, 0, 15),
		Vector3.new(-20, 0, 5),
		Vector3.new(25, 3, -10),
		Vector3.new(20, 3, -15),
	}

	for _, pos in ipairs(treePositions) do
		createTree(pos)
	end
end

-- Create water around the island
local function createWater()
	local water = Instance.new("Part")
	water.Size = Vector3.new(200, 1, 200)
	water.Position = Vector3.new(0, -4, 0)
	water.Color = Color3.fromRGB(30, 80, 150)
	water.Transparency = 0.3
	water.Anchored = true
	water.Parent = workspace
end

-- Create some rocks scattered around
local function createRocks()
	local rocks = {
		{ pos = Vector3.new(30, 0, 5), size = Vector3.new(3, 2, 3) },
		{ pos = Vector3.new(-25, 0, 20), size = Vector3.new(4, 3, 4) },
		{ pos = Vector3.new(0, 0, -35), size = Vector3.new(2.5, 2, 2.5) },
		{ pos = Vector3.new(12, 0, -10), size = Vector3.new(3, 2.5, 3) },
	}

	for _, rock in ipairs(rocks) do
		local part = Instance.new("Part")
		part.Size = rock.size
		part.Position = rock.pos
		part.Material = Enum.Material.Concrete
		part.Color = Color3.fromRGB(100, 100, 105)
		part.Rotation = Vector3.new(math.random(-15, 15), math.random(0, 360), math.random(-15, 15))
		part.Anchored = true
		part.Parent = workspace
	end
end

-- Create a small wooden dock
local function createDock()
	-- Main dock platform
	local dock = Instance.new("Part")
	dock.Size = Vector3.new(15, 1, 6)
	dock.Position = Vector3.new(0, -3, 48)
	dock.Material = Enum.Material.Wood
	dock.Color = Color3.fromRGB(140, 100, 60)
	dock.Anchored = true
	dock.Parent = workspace

	-- Dock posts
	for i = -1, 1 do
		local post = Instance.new("Part")
		post.Size = Vector3.new(1, 6, 1)
		post.Position = Vector3.new(i * 5, -5, 48)
		post.Material = Enum.Material.Wood
		post.Color = Color3.fromRGB(100, 70, 40)
		post.Anchored = true
		post.Parent = workspace
	end
end

-- Add point lights for testing
local function createLights()
	-- Campfire light
	local campfireLight = Instance.new("PointLight")
	campfireLight.Position = Vector3.new(-5, 2, -5)
	campfireLight.Color = Color3.fromRGB(255, 120, 40)
	campfireLight.Range = 25
	campfireLight.Parent = workspace

	-- Lantern on dock
	local lanternLight = Instance.new("PointLight")
	lanternLight.Position = Vector3.new(0, 0, 48)
	lanternLight.Color = Color3.fromRGB(255, 200, 100)
	lanternLight.Range = 20
	lanternLight.Parent = workspace

	-- Moon-like light
	local moonLight = Instance.new("PointLight")
	moonLight.Position = Vector3.new(30, 40, -30)
	moonLight.Color = Color3.fromRGB(150, 160, 200)
	moonLight.Range = 80
	moonLight.Parent = workspace
end

-- Build the island
print("Building island scene...")
createWater()
createTerrain()
createHills()
createCliffs()
createForest()
createRocks()
createDock()
createLights()

print("Island scene complete! Move around to test the shader lighting.")
