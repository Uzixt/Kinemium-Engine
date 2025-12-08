local sharedtble = {}

function sharedtble.new(category)
	local methods = {}
	shared[category] = shared[category] or {}

	function methods:add(key, value)
		if shared[category][key] then
			return
		end
		shared[category][key] = value
		return methods
	end

	function methods:get(key)
		return shared[category][key]
	end

	function methods:remove(key)
		shared[category][key] = nil
		return self
	end

	function methods:has(key)
		return shared[category][key] ~= nil
	end

	function methods:update(key, value)
		if shared[category][key] then
			shared[category][key] = value
		end
		return self
	end

	function methods:getAll()
		return shared[category]
	end

	function methods:Destroy()
		shared[category] = nil
		table.clear(methods)
		return self
	end

	function methods:addToTable(key, value)
		if not shared[category][key] then
			shared[category][key] = {}
		end
		table.insert(shared[category][key], value)
		return self
	end

	return methods
end

return sharedtble
