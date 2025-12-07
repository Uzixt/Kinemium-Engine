-- KinemiumSignal.lua
local Signal = {}
Signal.__index = Signal

-- connection object
local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	local self = setmetatable({}, Connection)
	self._signal = signal
	self._fn = fn
	self.Connected = true
	return self
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false
	local sig = self._signal
	if sig and sig._connections then
		for i = #sig._connections, 1, -1 do
			if sig._connections[i] == self then
				table.remove(sig._connections, i)
				break
			end
		end
	end
	self._signal = nil
	self._fn = nil
end

function Connection:Fire(...)
	if self.Connected and self._fn then
		local ok, err = pcall(self._fn, ...)
		if not ok then
			print(err)
		end
	end
end

-- signal container
function Signal.new()
	local self = setmetatable({}, Signal)
	self._connections = {}
	self._prevState = {}
	return self
end

function Signal:Connect(fn)
	local conn = Connection.new(self, fn)
	table.insert(self._connections, conn)
	return conn
end

function Signal:Fire(...)
	for _, conn in ipairs(self._connections) do
		conn:Fire(...)
	end
end

function Signal:FireOncePerPress(id, currentState, ...)
	if not self._prevState[id] then
		self._prevState[id] = 0
	end

	local state = 0
	if type(currentState) == "boolean" then
		state = currentState and 1 or 0
	elseif type(currentState) == "number" then
		state = (currentState ~= 0) and 1 or 0
	else
		error("FireOncePerPress: currentState must be boolean or number")
	end

	if state == 1 and self._prevState[id] == 0 then
		self:Fire(...)
	end

	self._prevState[id] = state
end

function Signal:__tostring()
	return ("Signal(%d listeners)"):format(#self._connections)
end

return Signal
