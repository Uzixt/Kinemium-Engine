local Instance = {}
local Signal = require("@Kinemium.signal")
local task = zune.task

-- Instance metatable
local instance_mt = {}

function instance_mt.__index(self, key)
	local props = rawget(self, "_props")
	if props and props[key] ~= nil then
		return props[key]
	end
	return Instance[key] -- fallback to class methods
end

function instance_mt.__newindex(self, key, value)
	local props = rawget(self, "_props")
	if not props then
		return
	end

	if key == "Parent" then
		local oldParent = props.Parent
		if oldParent then
			for i, child in ipairs(oldParent.Children) do
				if child == self then
					table.remove(oldParent.Children, i)
					break
				end
			end
		end
		props.Parent = value
		if value then
			table.insert(value.Children, self)

			if value.ChildAdded then
				value.ChildAdded:Fire(self)
			end

			local ancestor = value
			while ancestor do
				if ancestor.DescendantAdded then
					ancestor.DescendantAdded:Fire(self)
				end
				ancestor = ancestor.Parent
			end
		end
	else
		props[key] = value
	end

	if self.Changed then
		self.Changed:Fire(key, value)
	end
end

function Instance.new(className)
	local self = {}
	self.ClassName = className
	self.Name = className
	self.BaseClass = "Instance"
	self.Parent = nil
	self.UniqueId = math.random(1, 9999999)
	self.Children = {}
	self.ChildAdded = Signal.new()
	self.Changed = Signal.new()
	self.DescendantAdded = Signal.new()

	self._props = {
		ClassName = className,
		Name = className,
		Parent = nil,
		Children = {},
	}

	return setmetatable(self, instance_mt)
end

-- Utility methods
function Instance:GetProperties()
	return rawget(self, "_props")
end

function Instance:SetProperty(name, value)
	self[name] = value -- triggers __newindex
end

function Instance:FindFirstChild(name)
	for _, child in ipairs(self.Children) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

function Instance:FindFirstAncestor(className)
	local ancestor = self.Parent
	while ancestor do
		if ancestor.ClassName == className then
			return ancestor
		end
		ancestor = ancestor.Parent
	end
	return nil
end

function Instance:FindFirstChildOfClass(className)
	for _, child in ipairs(self.Children) do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end

function Instance:GetChildren()
	local copy = {}
	for i, child in ipairs(self.Children) do
		copy[i] = child
	end
	return copy
end

function Instance:GetDescendants()
	local result = {}

	local function scan(obj)
		for _, child in ipairs(obj.Children) do
			table.insert(result, child)
			scan(child)
		end
	end

	scan(self)
	return result
end

function Instance:IsA(className)
	return self.ClassName == className
end

function Instance:Clone()
	local copy = Instance.new(self.ClassName)

	for k, v in pairs(self._props) do
		if k ~= "Parent" and k ~= "Children" then
			copy[k] = v
		end
	end

	for _, child in ipairs(self.Children) do
		child:Clone().Parent = copy
	end

	return copy
end

function Instance:SetProperties(tbl)
	for k, v in pairs(tbl) do
		self:SetProperty(k, v)
	end
end

function Instance:ClearAllChildren()
	for _, child in ipairs(self.Children) do
		child.Parent = nil
	end
	self.Children = {}
end

function Instance:WaitForChild(name, timeout)
	timeout = timeout or 5
	local start = os.clock()

	local found = self:FindFirstChild(name)
	if found then
		return found
	end

	local connection
	local result = nil

	connection = self.ChildAdded:Connect(function(child)
		if child.Name == name then
			result = child
			connection:Disconnect()
		end
	end)

	while not result and os.clock() - start < timeout do
		task.wait(0)
	end

	if not result then
		error(("WaitForChild('%s') timed out"):format(name))
	end

	return result
end

function Instance:Destroy()
	if self.Parent then
		for i, child in ipairs(self.Parent.Children) do
			if child == self then
				table.remove(self.Parent.Children, i)
				break
			end
		end
	end

	self.Parent = nil
	self._props = nil
	self.Children = nil
	self.Destroyed = true
end

return Instance
