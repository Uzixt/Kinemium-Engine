local value = {}

--- Creates a reactive value object bound to LuaCSS for dynamic UI updates.
---@param v any The initial value.
---@return table valueObject The reactive value wrapper with `.get()` and `.set()` methods.
function value.new(initial: any, luacss)
	local self = {}
	local value = initial
	local subscribers = {}

	local function notify()
		for _, callback in ipairs(subscribers) do
			callback(value)
		end
	end

	function self:get()
		if luacss._currentComputed then
			luacss._currentComputed:dependOn(self)
		end
		return value
	end

	function self:set(new: any)
		if value ~= new then
			value = new
			notify()
		end
	end

	function self:subscribe(callback: (any) -> ())
		table.insert(subscribers, callback)
		callback(value) -- call immediately
		return function()
			for i, cb in ipairs(subscribers) do
				if cb == callback then
					table.remove(subscribers, i)
					break
				end
			end
		end
	end

	function self:map(transform: (any) -> any)
		local derived = luacss.value(transform(value))
		self:subscribe(function(v)
			derived:set(transform(v))
		end)
		return derived
	end

	function self:filter(predicate: (any) -> boolean)
		local filtered = luacss.value(value)
		self:subscribe(function(v)
			if predicate(v) then
				filtered:set(v)
			end
		end)
		return filtered
	end

	function self:computed(fn: () -> any)
		local derived = luacss.value(fn())
		local computed = { dependencies = {} }

		function computed:dependOn(dep)
			table.insert(self.dependencies, dep)
			dep:subscribe(function()
				derived:set(fn())
			end)
		end

		luacss._currentComputed = computed
		derived:set(fn())
		luacss._currentComputed = nil

		return derived
	end

	function self:bind(propertySetter: (any) -> ())
		self:subscribe(propertySetter)
		return function(newValue)
			self:set(newValue)
		end
	end

	return self
end

return value
