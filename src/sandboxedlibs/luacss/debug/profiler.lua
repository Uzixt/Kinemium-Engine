--!nocheck
local RunService = game:GetService("RunService")

local Profiler = {}
Profiler.__index = Profiler

local function formatTime(seconds)
	if seconds < 0.001 then
		return string.format("%.2fµs", seconds * 1000000)
	elseif seconds < 1 then
		return string.format("%.2fms", seconds * 1000)
	else
		return string.format("%.2fs", seconds)
	end
end

local function formatBytes(bytes)
	if bytes < 1024 then
		return string.format("%d B", bytes)
	elseif bytes < 1024 * 1024 then
		return string.format("%.2f KB", bytes / 1024)
	else
		return string.format("%.2f MB", bytes / (1024 * 1024))
	end
end

function Profiler.new()
	local self = setmetatable({}, Profiler)

	self.metrics = {
		componentCreations = {},
		propertyUpdates = {},
		envValueChanges = {},
		stateChanges = {},
		renderTimes = {},
		memorySnapshots = {},
		activeObjects = 0,
		totalCreated = 0,
		totalDestroyed = 0,
	}

	self.startTime = tick()
	self.isRecording = false
	self.frameCounter = 0
	self.lastFrameTime = tick()

	return self
end

function Profiler:Start()
	self.isRecording = true
	self.startTime = tick()
	print("[Profiler] Recording started")
end

function Profiler:Stop()
	self.isRecording = false
	print("[Profiler] Recording stopped")
end

function Profiler:Clear()
	self.metrics = {
		componentCreations = {},
		propertyUpdates = {},
		envValueChanges = {},
		stateChanges = {},
		renderTimes = {},
		memorySnapshots = {},
		activeObjects = 0,
		totalCreated = 0,
		totalDestroyed = 0,
	}
	self.startTime = tick()
	self.frameCounter = 0
	print("[Profiler] Metrics cleared")
end

function Profiler:RecordComponentCreation(componentName, timeTaken)
	if not self.isRecording then
		return
	end

	if not self.metrics.componentCreations[componentName] then
		self.metrics.componentCreations[componentName] = {
			count = 0,
			totalTime = 0,
			avgTime = 0,
			minTime = math.huge,
			maxTime = 0,
			lastCreated = tick(),
		}
	end

	local entry = self.metrics.componentCreations[componentName]
	entry.count = entry.count + 1
	entry.totalTime = entry.totalTime + timeTaken
	entry.avgTime = entry.totalTime / entry.count
	entry.minTime = math.min(entry.minTime, timeTaken)
	entry.maxTime = math.max(entry.maxTime, timeTaken)
	entry.lastCreated = tick()

	self.metrics.totalCreated = self.metrics.totalCreated + 1
	self.metrics.activeObjects = self.metrics.activeObjects + 1
end

function Profiler:RecordObjectDestroyed()
	if not self.isRecording then
		return
	end

	self.metrics.totalDestroyed = self.metrics.totalDestroyed + 1
	self.metrics.activeObjects = math.max(0, self.metrics.activeObjects - 1)
end

function Profiler:RecordPropertyUpdate(propertyName, timeTaken)
	if not self.isRecording then
		return
	end

	if not self.metrics.propertyUpdates[propertyName] then
		self.metrics.propertyUpdates[propertyName] = {
			count = 0,
			totalTime = 0,
			avgTime = 0,
			frequency = 0,
			lastUpdate = tick(),
		}
	end

	local entry = self.metrics.propertyUpdates[propertyName]
	entry.count = entry.count + 1
	entry.totalTime = entry.totalTime + timeTaken
	entry.avgTime = entry.totalTime / entry.count
	entry.lastUpdate = tick()
end

function Profiler:RecordEnvValueChange(envName, oldValue, newValue)
	if not self.isRecording then
		return
	end

	if not self.metrics.envValueChanges[envName] then
		self.metrics.envValueChanges[envName] = {
			count = 0,
			lastValue = oldValue,
			history = {},
		}
	end

	local entry = self.metrics.envValueChanges[envName]
	entry.count = entry.count + 1
	entry.lastValue = newValue

	table.insert(entry.history, {
		timestamp = tick() - self.startTime,
		oldValue = oldValue,
		newValue = newValue,
	})

	-- Keep only last 50 changes
	if #entry.history > 50 then
		table.remove(entry.history, 1)
	end
end

function Profiler:RecordStateChange(objectName, stateName, timeTaken)
	if not self.isRecording then
		return
	end

	local key = objectName .. "." .. stateName
	if not self.metrics.stateChanges[key] then
		self.metrics.stateChanges[key] = {
			count = 0,
			totalTime = 0,
			avgTime = 0,
			lastChange = tick(),
		}
	end

	local entry = self.metrics.stateChanges[key]
	entry.count = entry.count + 1
	entry.totalTime = entry.totalTime + timeTaken
	entry.avgTime = entry.totalTime / entry.count
	entry.lastChange = tick()
end

function Profiler:RecordFrameTime()
	if not self.isRecording then
		return
	end

	local currentTime = tick()
	local frameTime = currentTime - self.lastFrameTime
	self.lastFrameTime = currentTime

	table.insert(self.metrics.renderTimes, frameTime)

	-- Keep only last 100 frames
	if #self.metrics.renderTimes > 100 then
		table.remove(self.metrics.renderTimes, 1)
	end

	self.frameCounter = self.frameCounter + 1
end

function Profiler:RecordMemorySnapshot()
	if not self.isRecording then
		return
	end

	local memUsed = collectgarbage("count") * 1024 -- Convert KB to bytes

	table.insert(self.metrics.memorySnapshots, {
		timestamp = tick() - self.startTime,
		memory = memUsed,
		activeObjects = self.metrics.activeObjects,
	})

	-- Keep only last 100 snapshots
	if #self.metrics.memorySnapshots > 100 then
		table.remove(self.metrics.memorySnapshots, 1)
	end
end

function Profiler:GetSlowestComponents(limit)
	limit = limit or 10
	local sorted = {}

	for name, data in pairs(self.metrics.componentCreations) do
		table.insert(sorted, {
			name = name,
			avgTime = data.avgTime,
			count = data.count,
			maxTime = data.maxTime,
		})
	end

	table.sort(sorted, function(a, b)
		return a.avgTime > b.avgTime
	end)

	local result = {}
	for i = 1, math.min(limit, #sorted) do
		table.insert(result, sorted[i])
	end

	return result
end

function Profiler:GetMostFrequentUpdates(limit)
	limit = limit or 10
	local sorted = {}

	for name, data in pairs(self.metrics.propertyUpdates) do
		table.insert(sorted, {
			name = name,
			count = data.count,
			avgTime = data.avgTime,
			frequency = data.count / math.max(1, tick() - self.startTime),
		})
	end

	table.sort(sorted, function(a, b)
		return a.count > b.count
	end)

	local result = {}
	for i = 1, math.min(limit, #sorted) do
		table.insert(result, sorted[i])
	end

	return result
end

function Profiler:GetAverageFPS()
	if #self.metrics.renderTimes == 0 then
		return 0
	end

	local sum = 0
	for _, time in ipairs(self.metrics.renderTimes) do
		sum = sum + time
	end

	local avgFrameTime = sum / #self.metrics.renderTimes
	return 1 / math.max(0.001, avgFrameTime)
end

function Profiler:GetMemoryUsage()
	if #self.metrics.memorySnapshots == 0 then
		return {
			current = collectgarbage("count") * 1024,
			peak = 0,
			average = 0,
		}
	end

	local current = self.metrics.memorySnapshots[#self.metrics.memorySnapshots].memory
	local peak = 0
	local sum = 0

	for _, snapshot in ipairs(self.metrics.memorySnapshots) do
		peak = math.max(peak, snapshot.memory)
		sum = sum + snapshot.memory
	end

	return {
		current = current,
		peak = peak,
		average = sum / #self.metrics.memorySnapshots,
	}
end

function Profiler:GetSummary()
	local runtime = tick() - self.startTime
	local memUsage = self:GetMemoryUsage()

	return {
		runtime = runtime,
		isRecording = self.isRecording,
		totalCreated = self.metrics.totalCreated,
		totalDestroyed = self.metrics.totalDestroyed,
		activeObjects = self.metrics.activeObjects,
		averageFPS = self:GetAverageFPS(),
		frameCount = self.frameCounter,
		memCurrent = memUsage.current,
		memPeak = memUsage.peak,
		memAverage = memUsage.average,
		componentTypes = 0,
		propertyTypes = 0,
		envValueCount = 0,
		stateChangeCount = 0,
	}
end

function Profiler:StartAutoRecording()
	if self.autoRecordConnection then
		self.autoRecordConnection:Disconnect()
	end

	self:Start()

	self.autoRecordConnection = RunService.Heartbeat:Connect(function()
		self:RecordFrameTime()

		-- Record memory every second
		if self.frameCounter % 60 == 0 then
			self:RecordMemorySnapshot()
		end
	end)
end

function Profiler:StopAutoRecording()
	if self.autoRecordConnection then
		self.autoRecordConnection:Disconnect()
		self.autoRecordConnection = nil
	end

	self:Stop()
end

function Profiler:Export()
	return {
		summary = self:GetSummary(),
		slowestComponents = self:GetSlowestComponents(20),
		frequentUpdates = self:GetMostFrequentUpdates(20),
		componentCreations = self.metrics.componentCreations,
		propertyUpdates = self.metrics.propertyUpdates,
		envValueChanges = self.metrics.envValueChanges,
		stateChanges = self.metrics.stateChanges,
		renderTimes = self.metrics.renderTimes,
		memorySnapshots = self.metrics.memorySnapshots,
	}
end

return Profiler
