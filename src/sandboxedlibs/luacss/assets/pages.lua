local toolActive = require(script.Parent.ToolActive)

export type Pages = {
	OnPageVisible: (page: CanvasGroup) -> (),
	OnPageDisappear: (page: CanvasGroup) -> (),
	TabContent: Instance,
	Connections: { RBXScriptConnection },
	Run: () -> (),
	TogglePage: (page: string) -> (),
}

export type Module = {
	Init: (parent: Instance, Content: Instance) -> Pages,
}

local pages: Module = {}

function pages.Init(parent: Instance, Content: Instance)
	local toolManager = toolActive.new()

	local methods = {}

	methods.OnPageVisible = function(page: CanvasGroup)
		page.Visible = true
	end

	methods.OnPageDisappear = function(page: CanvasGroup)
		page.Visible = false
	end

	methods.TabContent = parent
	methods.Connections = {}
	methods.Run = function()
		for _, v in pairs(parent:GetChildren()) do
			if v:IsA("GuiButton") then
				local page: CanvasGroup = Content[v.Name]
				if page then
					toolManager:RegisterTool(v.Name, function()
						task.spawn(function()
							methods.OnPageVisible(page)
						end)
					end, function()
						task.spawn(function()
							methods.OnPageDisappear(page)
						end)
					end)

					table.insert(
						methods.Connections,
						v.MouseButton1Click:Connect(function()
							toolManager:SetActive(v.Name)
						end)
					)
				end
			end
		end
	end
	methods.TogglePage = function(page)
		toolManager:SetActive(page)
	end

	return methods
end

return pages
