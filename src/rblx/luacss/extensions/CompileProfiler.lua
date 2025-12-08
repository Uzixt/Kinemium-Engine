--!strict
-- LuaCSS Profiler Extension
-- Performance monitoring and memory tracking for GUI objects

local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Profiler = {
	name = "profiler",
	_version = 1,

	-- Tracked objects and their metrics
	trackedObjects = {},

	-- Performance snapshots
	snapshots = {},
	maxSnapshots = 100,

	-- Settings
	enabled = true,
	trackInterval = 0.5, -- seconds between measurements

	-- Real-time stats
	totalObjects = 0,
	totalMemory = 0,
	highestMemoryObject = nil,
	highestMemoryValue = 0,
}

type ObjectMetrics = {
	object: Instance,
	name: string,
	className: string,
	createdAt: number,

	-- Memory tracking
	estimatedMemory: number,
	childCount: number,
	descendantCount: number,

	-- Performance tracking
	renderTime: number?,
	updateCount: number,
	lastUpdate: number,

	-- Custom properties
	properties: { [string]: any },
	connections: number,
}

type PerformanceSnapshot = {
	timestamp: number,
	totalObjects: number,
	totalMemory: number,
	fps: number,
	memoryUsage: number,
	topObjects: { ObjectMetrics },
}

--- Estimate memory usage of a GUI object
function Profiler.estimateMemory(object: Instance): number
	local memory = 0

	-- Base object overhead (~100 bytes)
	memory += 100

	-- Property memory
	local properties = {
		"Text",
		"Image",
		"BackgroundColor3",
		"BorderColor3",
		"TextColor3",
		"Position",
		"Size",
		"AnchorPoint",
	}

	for _, prop in ipairs(properties) do
		local success, value = pcall(function()
			return object[prop]
		end)

		if success and value then
			if type(value) == "string" then
				memory += #value * 2 -- Unicode characters
			elseif typeof(value) == "Color3" then
				memory += 12 -- 3 floats
			elseif typeof(value) == "UDim2" then
				memory += 16 -- 4 floats
			elseif typeof(value) == "Vector2" then
				memory += 8
			end
		end
	end

	-- Image memory (rough estimate)
	if object:IsA("ImageLabel") or object:IsA("ImageButton") then
		local success, image = pcall(function()
			return object.Image
		end)
		if success and image ~= "" then
			-- Assume average texture size
			memory += 50000 -- ~50KB per image
		end
	end

	-- Children overhead
	memory += #object:GetChildren() * 50

	return memory
end

--- Track a new object
function Profiler.track(object: Instance, metadata: { [string]: any }?): ObjectMetrics
	if not Profiler.enabled then
		return
	end

	local metrics: ObjectMetrics = {
		object = object,
		name = object.Name,
		className = object.ClassName,
		createdAt = os.clock(),
		estimatedMemory = Profiler.estimateMemory(object),
		childCount = #object:GetChildren(),
		descendantCount = #object:GetDescendants(),
		updateCount = 0,
		lastUpdate = os.clock(),
		properties = metadata or {},
		connections = 0,
	}

	Profiler.trackedObjects[object] = metrics
	Profiler.totalObjects += 1
	Profiler.totalMemory += metrics.estimatedMemory

	-- Track if this is the highest memory object
	if metrics.estimatedMemory > Profiler.highestMemoryValue then
		Profiler.highestMemoryObject = object
		Profiler.highestMemoryValue = metrics.estimatedMemory
	end

	-- Update metrics on property changes
	local propertyConn = object.Changed:Connect(function()
		metrics.updateCount += 1
		metrics.lastUpdate = os.clock()

		-- Recalculate memory
		local oldMemory = metrics.estimatedMemory
		metrics.estimatedMemory = Profiler.estimateMemory(object)
		Profiler.totalMemory += (metrics.estimatedMemory - oldMemory)
	end)

	-- Track children changes
	local childConn = object.ChildAdded:Connect(function()
		metrics.childCount = #object:GetChildren()
		metrics.descendantCount = #object:GetDescendants()
	end)

	metrics.connections = 2

	-- Cleanup on destroy
	local destroyConn
	destroyConn = object.AncestryChanged:Connect(function(_, parent)
		if not parent then
			Profiler.untrack(object)
			propertyConn:Disconnect()
			childConn:Disconnect()
			if destroyConn then
				destroyConn:Disconnect()
			end
		end
	end)

	return metrics
end

--- Stop tracking an object
function Profiler.untrack(object: Instance)
	local metrics = Profiler.trackedObjects[object]
	if metrics then
		Profiler.totalObjects -= 1
		Profiler.totalMemory -= metrics.estimatedMemory
		Profiler.trackedObjects[object] = nil
	end
end

--- Get metrics for a specific object
function Profiler.getMetrics(object: Instance): ObjectMetrics?
	return Profiler.trackedObjects[object]
end

--- Get all tracked objects
function Profiler.getAllMetrics(): { ObjectMetrics }
	local metrics = {}
	for _, m in pairs(Profiler.trackedObjects) do
		table.insert(metrics, m)
	end
	return metrics
end

--- Get top memory consumers
function Profiler.getTopMemoryConsumers(limit: number?): { ObjectMetrics }
	limit = limit or 10

	local metrics = Profiler.getAllMetrics()
	table.sort(metrics, function(a, b)
		return a.estimatedMemory > b.estimatedMemory
	end)

	local top = {}
	for i = 1, math.min(limit, #metrics) do
		table.insert(top, metrics[i])
	end

	return top
end

--- Get most frequently updated objects
function Profiler.getMostUpdatedObjects(limit: number?): { ObjectMetrics }
	limit = limit or 10

	local metrics = Profiler.getAllMetrics()
	table.sort(metrics, function(a, b)
		return a.updateCount > b.updateCount
	end)

	local top = {}
	for i = 1, math.min(limit, #metrics) do
		table.insert(top, metrics[i])
	end

	return top
end

--- Format bytes to human-readable
function Profiler.formatBytes(bytes: number): string
	if bytes < 1024 then
		return string.format("%.0f B", bytes)
	elseif bytes < 1024 * 1024 then
		return string.format("%.2f KB", bytes / 1024)
	else
		return string.format("%.2f MB", bytes / (1024 * 1024))
	end
end

--- Take a performance snapshot
function Profiler.snapshot(): PerformanceSnapshot
	local snapshot: PerformanceSnapshot = {
		timestamp = os.clock(),
		totalObjects = Profiler.totalObjects,
		totalMemory = Profiler.totalMemory,
		fps = 1 / RunService.Heartbeat:Wait(),
		memoryUsage = Stats:GetTotalMemoryUsageMb(),
		topObjects = Profiler.getTopMemoryConsumers(5),
	}

	table.insert(Profiler.snapshots, snapshot)

	-- Limit snapshots
	if #Profiler.snapshots > Profiler.maxSnapshots then
		table.remove(Profiler.snapshots, 1)
	end

	return snapshot
end

--- Get performance report
function Profiler.getReport(): string
	local report = {
		"═══════════════════════════════════════",
		"       LuaCSS Performance Report",
		"═══════════════════════════════════════",
		"",
		string.format("Total Objects Tracked: %d", Profiler.totalObjects),
		string.format("Total Memory Usage: %s", Profiler.formatBytes(Profiler.totalMemory)),
		string.format(
			"Average per Object: %s",
			Profiler.formatBytes(Profiler.totalObjects > 0 and Profiler.totalMemory / Profiler.totalObjects or 0)
		),
		"",
		"Top Memory Consumers:",
		"───────────────────────────────────────",
	}

	local topMemory = Profiler.getTopMemoryConsumers(5)
	for i, metrics in ipairs(topMemory) do
		table.insert(
			report,
			string.format(
				"%d. %s (%s) - %s",
				i,
				metrics.name,
				metrics.className,
				Profiler.formatBytes(metrics.estimatedMemory)
			)
		)
	end

	table.insert(report, "")
	table.insert(report, "Most Updated Objects:")
	table.insert(
		report,
		"───────────────────────────────────────"
	)

	local mostUpdated = Profiler.getMostUpdatedObjects(5)
	for i, metrics in ipairs(mostUpdated) do
		table.insert(
			report,
			string.format("%d. %s (%s) - %d updates", i, metrics.name, metrics.className, metrics.updateCount)
		)
	end

	table.insert(report, "")
	table.insert(
		report,
		"═══════════════════════════════════════"
	)

	return table.concat(report, "\n")
end

--- Print report to console
function Profiler.printReport()
	print(Profiler.getReport())
end

--- Create a visual profiler UI
function Profiler.createUI(parent: Instance?): Frame
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	parent = parent or PlayerGui

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LuaCSSProfiler"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Name = "ProfilerFrame"
	frame.Size = UDim2.new(0, 400, 0, 500)
	frame.Position = UDim2.new(1, -420, 0, 20)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	title.BorderSizePixel = 0
	title.Text = "LuaCSS Profiler"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.Parent = frame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = title

	-- Stats container
	local statsScroll = Instance.new("ScrollingFrame")
	statsScroll.Name = "StatsScroll"
	statsScroll.Size = UDim2.new(1, -20, 1, -60)
	statsScroll.Position = UDim2.new(0, 10, 0, 50)
	statsScroll.BackgroundTransparency = 1
	statsScroll.BorderSizePixel = 0
	statsScroll.ScrollBarThickness = 6
	statsScroll.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = statsScroll

	-- Update function
	local function updateUI()
		-- Clear existing
		for _, child in ipairs(statsScroll:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end

		-- Overall stats
		local function createLabel(text: string): TextLabel
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0, 25)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Font = Enum.Font.Code
			label.TextSize = 12
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = statsScroll
			return label
		end

		createLabel(string.format("Objects: %d", Profiler.totalObjects))
		createLabel(string.format("Memory: %s", Profiler.formatBytes(Profiler.totalMemory)))
		createLabel("")
		createLabel("Top Memory Users:")

		local top = Profiler.getTopMemoryConsumers(5)
		for i, metrics in ipairs(top) do
			createLabel(string.format("  %d. %s: %s", i, metrics.name, Profiler.formatBytes(metrics.estimatedMemory)))
		end

		createLabel("")
		createLabel("Most Updated:")

		local updated = Profiler.getMostUpdatedObjects(5)
		for i, metrics in ipairs(updated) do
			createLabel(string.format("  %d. %s: %d updates", i, metrics.name, metrics.updateCount))
		end

		-- Update canvas size
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Wait()
		statsScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end

	-- Update every second
	task.spawn(function()
		while screenGui.Parent do
			updateUI()
			task.wait(1)
		end
	end)

	return frame
end

-- LuaCSS Extension Definition
local ProfilerExtension = {
	name = "profiler",
	_version = 1,

	handlers = {
		-- Enable profiling for an object
		profile = function(object: Instance, enabled: boolean | { [string]: any })
			if type(enabled) == "table" then
				Profiler.track(object, enabled)
			elseif enabled then
				Profiler.track(object)
			end
		end,

		-- Add metadata to profiling
		profileMetadata = function(object: Instance, metadata: { [string]: any })
			local metrics = Profiler.getMetrics(object)
			if metrics then
				for key, value in pairs(metadata) do
					metrics.properties[key] = value
				end
			end
		end,
	},

	env = {},

	init = function(luacss, ext)
		print("[LuaCSS Profiler Extension] Loaded successfully")

		-- Expose profiler functions
		ext.enable = function()
			Profiler.enabled = true
		end
		ext.disable = function()
			Profiler.enabled = false
		end
		ext.track = Profiler.track
		ext.untrack = Profiler.untrack
		ext.getMetrics = Profiler.getMetrics
		ext.getAllMetrics = Profiler.getAllMetrics
		ext.getTopMemoryConsumers = Profiler.getTopMemoryConsumers
		ext.getMostUpdatedObjects = Profiler.getMostUpdatedObjects
		ext.snapshot = Profiler.snapshot
		ext.getReport = Profiler.getReport
		ext.printReport = Profiler.printReport
		ext.createUI = Profiler.createUI
		ext.formatBytes = Profiler.formatBytes

		-- Auto-track all LuaCSS objects if desired
		ext.autoTrackAll = function()
			luacss.onClassCreate("GuiObject", function(object)
				Profiler.track(object)
			end)
		end

		-- Example
		ext.example = function()
			print([[
Example usage:

-- Auto-track object
luacss.compileObject({
	class = "Frame",
	profile = true -- Automatically tracked
})

-- Track with metadata
luacss.compileObject({
	class = "TextLabel",
	profile = {
		purpose = "Title",
		screen = "MainMenu"
	}
})

-- Get report
ext.printReport()

-- Create visual UI
ext.createUI()

-- Auto-track all objects
ext.autoTrackAll()

-- Get specific metrics
local metrics = ext.getMetrics(myFrame)
print("Memory:", ext.formatBytes(metrics.estimatedMemory))
			]])
		end
	end,

	hooks = {
		afterCompile = function(luacss, instance, virtualObject)
			Profiler.track(instance)
		end,
	},
}

return ProfilerExtension
