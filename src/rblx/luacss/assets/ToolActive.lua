local ToolManager = {}
ToolManager.__index = ToolManager

function ToolManager.new()
	local self = setmetatable({}, ToolManager)
	self.Tools = {}
	self.ActiveTool = nil
	return self
end

function ToolManager:RegisterTool(toolName, onActivate, onDeactivate)
	self.Tools[toolName] = {
		OnActivate = onActivate,
		OnDeactivate = onDeactivate,
	}
end

function ToolManager:SetActive(toolName)
	if self.ActiveTool == toolName then
		local tool = self.Tools[self.ActiveTool]
		if tool and tool.OnDeactivate then
			tool.OnDeactivate()
		end
		self.ActiveTool = nil
		return
	end

	if self.ActiveTool and self.Tools[self.ActiveTool] then
		local tool = self.Tools[self.ActiveTool]
		if tool.OnDeactivate then
			tool.OnDeactivate()
		end
	end

	self.ActiveTool = toolName

	local tool = self.Tools[toolName]
	if tool and tool.OnActivate then
		tool.OnActivate()
	end
end

function ToolManager:GetActive()
	return self.ActiveTool
end

return ToolManager