-- @maid.lua

local maid = {}

local storage = {}

function maid:insert(any)
	table.insert(storage, any)
end

function maid:clean()
	for i, v in pairs(storage) do
		if typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
		elseif typeof(v) == "table" then
			table.clear(v)
		elseif typeof(v) == "Instance" then
			v:Destroy()
		elseif typeof(v) == "function" then
			v()
		elseif type(v) == "thread" then
			pcall(function()
				task.cancel(v)
			end)
			pcall(function()
				coroutine.close(v)
			end)
		end
	end
	table.clear(storage)
	storage = {}
end

function maid:get()
	return storage
end

function maid:cleantable(tbl)
	for i, v in pairs(tbl) do
		if typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
		elseif typeof(v) == "table" then
			table.clear(v)
		elseif typeof(v) == "Instance" then
			v:Destroy()
		elseif typeof(v) == "function" then
			v()
		elseif type(v) == "thread" then
			pcall(function()
				task.cancel(v)
			end)
			pcall(function()
				coroutine.close(v)
			end)
		end
	end
	table.clear(tbl)
	tbl = {}
end

return maid