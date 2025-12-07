--!nocheck
local LuaCSS = require(script.Parent.Parent)

local prefix = "$luacss.debugging.window:"
local APIService = require(script.Parent.Parent.libs.APIService)
local blurController = require(script.Parent.Parent.libs.BlurController)
local highlighter = require(script.Parent.highlighter)
local repr = require(script.Parent.repr)
local types = require(script.Parent.Parent.assets.Types)
local RunService = game:GetService("RunService")

local function getInstanceFromFullName(fullName)
	local parts = fullName:split(".")
	local current = game

	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then
			return nil
		end
	end

	return current
end

local things_that_are_considered_guis = {
	"CanvasGroup",
	"Frame",
	"TextButton",
	"TextLabel",
	"ImageButton",
	"ImageLabel,",
}

local function create_with_prefix(v)
	return prefix .. v
end

local function gwp(v)
	return prefix .. v
end

local selected = nil
local state = "enviroment"
local window
local highlightJobs = {}
local references = {}

local mainTheme = LuaCSS.theme("luacss:debugging_window", {
	[create_with_prefix("BackgroundColor")] = Color3.fromRGB(0, 0, 0),
	[create_with_prefix("TitleBackgroundColor")] = Color3.fromRGB(40, 40, 40),
	[create_with_prefix("TitleTextColor")] = Color3.fromRGB(255, 255, 255),
	[create_with_prefix("TextColor")] = Color3.fromRGB(200, 200, 200),
	[create_with_prefix("ScrollBarColor")] = Color3.fromRGB(80, 80, 80),
	[create_with_prefix("ScrollBarHoverColor")] = Color3.fromRGB(120, 120, 120),
	[create_with_prefix("BorderColor")] = Color3.fromRGB(60, 60, 60),
	[create_with_prefix("BorderThickness")] = 1,
	[create_with_prefix("Padding")] = 5,
	[create_with_prefix("TitlePadding")] = 15,
	[create_with_prefix("Font")] = Enum.Font.BuilderSans,
	[create_with_prefix("CodelineFont")] = Enum.Font.Code,
	[create_with_prefix("Roundness")] = { 0, 5 },
	[create_with_prefix("ItemHeight")] = 20,
	[create_with_prefix("SelectedColor")] = Color3.new(0.023529, 0.505882, 0.713725),
	[create_with_prefix("InspectorLineColor")] = Color3.fromRGB(30, 30, 30),
	[create_with_prefix("TextboxBackgroundColor")] = Color3.fromRGB(0, 0, 0),
	[create_with_prefix("ReadOnlyColor")] = Color3.fromRGB(40, 40, 40),
	[create_with_prefix("ReloadButtonColor")] = Color3.fromRGB(0, 100, 200),
	[create_with_prefix("SearchBoxColor")] = Color3.fromRGB(0, 0, 0),
	[create_with_prefix("HoverTransparency")] = 0.4,
	[create_with_prefix("RibbonButtonHeight")] = { 2.5, 0 },
	[create_with_prefix("WindowSize")] = { 0, 900, 0, 500 },
	[create_with_prefix("BlurEnabled")] = false,
	[create_with_prefix("TitleHeight")] = { 0, 50 },
	[create_with_prefix("BackgroundTransparency")] = 0,
	[create_with_prefix("TitleFontSize")] = 15,
	[create_with_prefix("DefaultTextSize")] = 18,
})

local templateEditor = [[
	local style = {}
	-- You have globals such as CSS and the entire shared library.
	-- Good luck.....................

	style = css.theme({
		["BackgroundColor"] = Color3.new(0, 0, 0),
		["TextColor"] = Color3.new(1, 1, 1),
		["Font"] = Enum.Font.Code,
	})

	return style
]]

local function parsePropertyValue(valueStr: string, propertyType: string)
	valueStr = valueStr:gsub("^%s*(.-)%s*$", "%1")

	if propertyType == "number" then
		return tonumber(valueStr)
	elseif propertyType == "boolean" then
		return valueStr:lower() == "true"
	elseif propertyType == "string" then
		return valueStr
	elseif propertyType == "Color3" then
		local r, g, b = valueStr:match("rgb%(?(%d+),%s*(%d+),%s*(%d+)%)?")
		if not r then
			r, g, b = valueStr:match("(%d+),%s*(%d+),%s*(%d+)")
		end
		if r and g and b then
			return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
		end
	elseif propertyType == "UDim2" then
		local scaleX, offsetX, scaleY, offsetY = valueStr:match("{?([%d%.]+),%s*([%d%.]+),%s*([%d%.]+),%s*([%d%.]+)}?")
		if scaleX then
			return UDim2.new(tonumber(scaleX), tonumber(offsetX), tonumber(scaleY), tonumber(offsetY))
		end
	elseif propertyType == "UDim" then
		local scale, offset = valueStr:match("{?([%d%.]+),%s*([%d%.]+)}?")
		if scale then
			return UDim.new(tonumber(scale), tonumber(offset))
		end
	elseif propertyType == "Vector2" then
		local x, y = valueStr:match("(%d+),%s*(%d+)")
		if x and y then
			return Vector2.new(tonumber(x), tonumber(y))
		end
	elseif propertyType == "Vector3" then
		local x, y, z = valueStr:match("([%d%.]+),%s*([%d%.]+),%s*([%d%.]+)")
		if x and y and z then
			return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
		end
	elseif propertyType == "EnumItem" then
		local enumType, enumValue = valueStr:match("Enum%.([%w_]+)%.([%w_]+)")
		if enumType and enumValue then
			return Enum[enumType][enumValue]
		end
	end

	return nil
end

local function cloneForPreview(instance: Instance, parent: Instance)
	if not instance or not instance:IsA("GuiObject") then
		return
	end

	local clone = instance:Clone()
	clone.Size = UDim2.new(1, 0, 1, 0)
	clone.Parent = parent

	return clone
end

local function clearText(object: Instance)
	for _, child in pairs(object:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
			if child.Name == "Title" then
				continue
			end
			if child.Name == "SearchTextbox" then
				continue
			end
			child:Destroy()
		end
	end
end

local function populateInspector(inspector: Instance, instance: Instance)
	clearText(inspector.Scroller)

	local toloop
	local isEnvValueObject = false
	local envObjectName = nil

	if type(instance) == "table" then
		if instance.class == "EnvValueObject" then
			isEnvValueObject = true
			envObjectName = instance.name
			toloop = {
				Name = envObjectName,
				Value = instance:Get(),
				Type = typeof(instance:Get()),
			}
		else
			toloop = instance
		end
	elseif typeof(instance) == "Instance" then
		toloop = APIService:GetProperties(instance, false)
	end

	for key, value in pairs(toloop) do
		local originalValue = value
		local originalValueType = typeof(value)

		local displayValue
		if type(value) == "table" then
			displayValue = repr(value, { pretty = true })
		elseif type(value) == "boolean" then
			displayValue = value and "true" or "false"
		elseif type(value) == "function" then
			continue
		else
			displayValue = tostring(value)
		end

		local label = LuaCSS.compileObject({
			class = "TextLabel",
			style = gwp("CodeLine"),
			groundcolor = gwp("InspectorLineColor"),
			text = `{key}`,
			spawn = {
				ChangeableItem = {
					class = "TextBox",
					alignment = "center right",
					height = { 1.5, 0 },
					rounded = gwp("Roundness"),
					width = { 0.5, 0 },
					Text = displayValue,
					groundtransparency = 0,
					txtsize = 15,
					ClearTextOnFocus = false,
					textAlignment = "center",
					ClipsDescendants = true,
					groundcolor = gwp("TextboxBackgroundColor"),
					txtcolor = gwp("TextColor"),
					font = gwp("Font"),
				},
			},
		})

		local textbox: TextBox = label.ChangeableItem

		if isEnvValueObject and (key == "Name" or key == "Type") then
			textbox.TextEditable = false
			textbox.BackgroundColor3 = LuaCSS.getEnvValue(gwp("ReadOnlyColor"))
		end

		textbox.FocusLost:Connect(function(enterPressed)
			if not enterPressed then
				return
			end

			local newval = parsePropertyValue(textbox.Text, originalValueType)

			if newval == nil then
				warn(`[LuaCSS Inspector] Failed to parse value: "{textbox.Text}" as {originalValueType}`)
				textbox.Text = displayValue
				return
			end

			if isEnvValueObject and key == "Value" then
				local envObj = LuaCSS.getEnvValueObject(envObjectName)
				if envObj then
					envObj.Set(newval)
					print(`[LuaCSS Inspector] Set ENV value '{envObjectName}' -> {tostring(newval)}`)

					textbox.Text = tostring(newval)

					for _, child in pairs(inspector.Scroller:GetChildren()) do
						if child:IsA("TextLabel") and child.Text == "Type" then
							local typeBox = child:FindFirstChild("ChangeableItem")
							if typeBox and typeBox:IsA("TextBox") then
								typeBox.Text = typeof(newval)
							end
							break
						end
					end
				else
					warn(`[LuaCSS Inspector] Could not find ENV value object: {envObjectName}`)
				end
			else
				local success, err = pcall(function()
					instance[key] = newval
				end)

				if success then
					print(`[LuaCSS Inspector] Set {key} -> {tostring(newval)}`)
					textbox.Text = tostring(newval)
				else
					warn(`[LuaCSS Inspector] Failed to set {key}: {err}`)
					textbox.Text = displayValue
				end
			end
		end)

		label.RichText = true
		label.Parent = inspector.Scroller
		RunService.RenderStepped:Wait()
	end

	if isEnvValueObject then
		local reloadButton = LuaCSS.compileObject({
			class = "TextButton",
			style = gwp("CodeLine"),
			groundcolor = gwp("ReloadButtonColor"),
			txtcolor = gwp("TitleTextColor"),
			text = "🔄 Reload ENV Value",
			font = gwp("Font"),
			clicked = function()
				local envObj = LuaCSS.getEnvValueObject(envObjectName)
				if envObj then
					envObj.Reload()
					print(`[LuaCSS Inspector] Reloaded ENV value '{envObjectName}'`)
					task.defer(function()
						populateInspector(inspector, instance)
					end)
				end
			end,
		})
		reloadButton.Parent = inspector.Scroller
	end
end

local function populateErrors(object)
	clearText(object)

	if #shared.LuaCSS.ErrorLogs == 0 then
		local noErrors = LuaCSS.compileObject({
			class = "TextLabel",
			style = gwp("CodeLine"),
			groundcolor = Color3.fromRGB(0, 100, 0),
			txtcolor = Color3.fromRGB(200, 255, 200),
			text = "✓ No errors logged",
			txtsize = 16,
		})
		noErrors.Parent = object
		return
	end

	local count = 0
	for i, error in ipairs(shared.LuaCSS.ErrorLogs) do
		count += 1
		if count >= 100 then
			warn("Too many errors to display")
			break
		end

		local label = LuaCSS.compileObject({
			class = "TextLabel",
			style = gwp("CodeLine"),
			groundcolor = Color3.fromRGB(100, 0, 0),
			txtcolor = Color3.fromRGB(255, 200, 200),
			text = `[{i}] {tostring(error):sub(1, 100)}...`,
			layoutOrder = count,
			textwrapped = true,
		})

		label.RichText = true
		label.Parent = object
		RunService.RenderStepped:Wait()
	end
end

LuaCSS.springSettings(2, 5)

LuaCSS.component(
	create_with_prefix("RibbonButton"),
	{
		autoscalebased = { Enum.AutomaticSize.XY, { 0, 0 } },
		groundcolor = gwp("TitleBackgroundColor"),
		groundtransparency = 1,
		paddingsides = { 0, 10 },
		height = gwp("RibbonButtonHeight"),
		TextSize = 20,
		txtcolor = gwp("TextColor"),
		BorderSizePixel = 0,
		text = "Button",
		AutoButtonColor = false,
		font = gwp("Font"),
		MouseEnter = function(Button)
			LuaCSS.spring(Button, {
				BackgroundTransparency = LuaCSS.getEnvValue(gwp("HoverTransparency")),
			})
		end,
		MouseLeave = function(Button)
			LuaCSS.spring(Button, {
				BackgroundTransparency = 1,
			})
		end,
		spawn = {
			Underline = {
				class = "Frame",
				height = { 0, 2 },
				width = { 1, 0 },
				alignment = "bottom center",
				groundcolor = gwp("TextColor"),
			},
		},
	} :: types.Object
).makeGlobal()

LuaCSS.component(
	create_with_prefix("Page"),
	{
		size = { 1, 0, 1, 0 },
	} :: types.Object
).makeGlobal()

LuaCSS.component(
	create_with_prefix("CodeLine"),
	{
		txtsize = 14,
		width = { 1, 0 },
		txtcolor = gwp("TitleTextColor"),
		groundtransparency = 1,
		groundcolor = gwp("InspectorLineColor"),
		textAlignment = "left",
		font = gwp("CodelineFont"),
		borderwidth = 0,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		textwrapped = true,
		AutoButtonColor = false,
		richtext = true,
		padding = { 0, 5 },
		MouseEnter = function(Button)
			if selected ~= Button then
				LuaCSS.spring(Button, {
					BackgroundTransparency = LuaCSS.getEnvValue(gwp("HoverTransparency")),
				})
			end
		end,
		MouseLeave = function(Button)
			if selected ~= Button then
				LuaCSS.spring(Button, {
					BackgroundTransparency = 1,
				})
			end
		end,
		autoscalebased = { Enum.AutomaticSize.XY, { 0, 0 } },
		text = "Some important code..",
		layoutOrder = 1,
	} :: types.Object
).makeGlobal()

LuaCSS.component(
	create_with_prefix("CodeInput"),
	{
		txtsize = 14,
		width = { 1, 0 },
		txtcolor = gwp("TitleTextColor"),
		groundtransparency = 1,
		groundcolor = gwp("InspectorLineColor"),
		font = gwp("CodelineFont"),
		borderwidth = 0,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		textwrapped = true,
		AutoButtonColor = false,
		richtext = true,
		MouseEnter = function(Button)
			if selected ~= Button then
				LuaCSS.spring(Button, {
					BackgroundTransparency = LuaCSS.getEnvValue(gwp("HoverTransparency")),
				})
			end
		end,
		MouseLeave = function(Button)
			if selected ~= Button then
				LuaCSS.spring(Button, {
					BackgroundTransparency = 1,
				})
			end
		end,
		autoscalebased = { Enum.AutomaticSize.XY, { 0, 0 } },
		layoutOrder = 1,
		height = { 1, 0 },
		textAlignment = "left",
		textVerticalAlignment = "top",
		padding = { 0, 5 },
		text = templateEditor,
	} :: types.Object
).makeGlobal()

LuaCSS.component(
	create_with_prefix("window"),
	{
		border = true,
		size = { 0, 280, 0, 200 },
		groundcolor = gwp("BackgroundColor"),
		list = { "top", "center", { 0, 0 }, Enum.FillDirection.Vertical },
		MouseEnter = function(Button)
			LuaCSS.spring(Button, {
				BackgroundTransparency = 0.4,
			})
		end,
		MouseLeave = function(Button)
			LuaCSS.spring(Button, {
				BackgroundTransparency = 0,
			})
		end,
		spawn = {
			Title = {
				class = "TextLabel",
				alignment = "top center",
				width = { 1, 0 },
				autoscalebased = { Enum.AutomaticSize.Y, {} },
				txtsize = 21,
				groundtransparency = 1,
				paddingvertical = 5,
				font = gwp("Font"),
				txtcolor = gwp("TextColor"),
				border = false,
			},

			Scroller = {
				class = "ScrollingFrame",
				size = { 1, 0, 1, 0 },
				groundtransparency = 1,
				ScrollBarThickness = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				autofill = true,
				list = { "top", "center", { 0, 0 }, Enum.FillDirection.Vertical },
			},
		},
	} :: types.Object
).makeGlobal()

local function newGuiTree(key, value, count, parent)
	local visual
	if typeof(value) == "Instance" then
		visual = value:GetFullName()
	else
		visual = value
	end

	local line = repr({ [key] = visual }, { pretty = true }):gsub("\n$", "")

	local label = LuaCSS.compileObject({
		class = "TextButton",
		style = gwp("CodeLine"),
		groundcolor = Color3.fromRGB(30, 30, 30),
		layoutOrder = count,
		text = line,
		clicked = function(Button)
			if selected then
				LuaCSS.spring(selected, {
					BackgroundColor3 = LuaCSS.getEnvValue(gwp("InspectorLineColor")),
				})
				selected = nil
			end

			LuaCSS.spring(Button, {
				BackgroundColor3 = LuaCSS.getEnvValue(gwp("SelectedColor")),
			})
			selected = Button

			local inspector = window.Content.VerticalList.Inspector
			local previewContainer = window.Content.VerticalList.Preview.Scroller

			task.spawn(function()
				populateInspector(inspector, references[Button])
			end)

			task.spawn(function()
				if typeof(references[Button]) == "Instance" then
					if
						references[Button]:IsA("Frame")
						or references[Button]:IsA("CanvasGroup")
						or references[Button]:IsA("TextLabel")
						or references[Button]:IsA("TextButton")
					then
						for _, child in pairs(previewContainer:GetChildren()) do
							if
								child:IsA("Frame")
								or child:IsA("CanvasGroup")
								or child:IsA("TextLabel")
								or child:IsA("TextButton")
							then
								child:Destroy()
							end
						end

						for _, child in pairs(previewContainer:GetChildren()) do
							if child:IsA("GuiObject") then
								child:Destroy()
							end
						end

						cloneForPreview(references[Button], previewContainer)
					end
				end
			end)
		end,
	})
	label.RichText = true
	label.Parent = parent

	if typeof(value) == "Instance" then
		references[label] = value
	elseif typeof(key) == "Instance" then
		references[label] = key
	elseif typeof(value) == "table" then
		references[label] = value
	elseif typeof(value) == "string" then
		references[label] = value
	end

	task.spawn(function()
		table.insert(
			highlightJobs,
			highlighter.highlight({
				textObject = label,
				src = line,
			})
		)
	end)
	RunService.RenderStepped:Wait()
end

local function populate(object, data)
	local str = repr(data, { pretty = true })
	local lines = str:split("\n")
	local children = object:GetChildren()

	local dataIndex = 1
	local currentIndex = 0
	for i, child in ipairs(children) do
		if child.Name ~= "titleLabel" then
			local line = lines[dataIndex]
			if not line then
				child:Destroy()
			else
				if child:IsA("TextLabel") then
					child.Text = line
					child.BackgroundColor3 = (dataIndex % 2 == 0) and Color3.fromRGB(30, 30, 30)
						or Color3.fromRGB(25, 25, 25)
					task.spawn(function()
						table.insert(
							highlightJobs,
							highlighter.highlight({
								textObject = child,
								src = line,
							})
						)
					end)
					references[child] = data[dataIndex]
					print(references)
				end
				dataIndex += 1
			end
		end
	end

	local count = 0
	for key, value in pairs(data) do
		count += 1
		if count >= 400 then
			print("Item count more than 100, Stopping.")
			break
		end

		newGuiTree(key, value, count, object)
	end
end

local function populateEvents(object)
	clearText(object)

	local count = 0
	for i, eventData in ipairs(shared.LuaCSS.EventStorage) do
		count += 1
		if count >= 400 then
			warn("Item count more than 400, stopping.")
			break
		end

		local obj, property, connections = unpack(eventData)
		local connectionCount = #connections

		local label = LuaCSS.compileObject({
			class = "TextButton",
			style = gwp("CodeLine"),
			groundcolor = gwp("InspectorLineColor"),
			layoutOrder = count,
			text = `[{i}] {obj.Name or "Unknown"}.{property} ({connectionCount} connections)`,
			clicked = function(Button)
				if selected then
					LuaCSS.spring(selected, {
						BackgroundColor3 = LuaCSS.getEnvValue(gwp("InspectorLineColor")),
					})
				end

				LuaCSS.spring(Button, {
					BackgroundColor3 = LuaCSS.getEnvValue(gwp("SelectedColor")),
				})
				selected = Button

				local inspector = window.Content.VerticalList.Inspector
				populateInspector(inspector, {
					Object = obj,
					Property = property,
					Connections = connectionCount,
					EventIndex = i,
				})
			end,
		})

		label.RichText = true
		label.Parent = object
		references[label] = obj

		RunService.RenderStepped:Wait()
	end
end

local function populateOverview(object, addManagementActions)
	clearText(object)

	local stats = {
		{ name = "Environment Values", count = 0, color = Color3.fromRGB(100, 150, 255) },
		{ name = "Registered Components", count = 0, color = Color3.fromRGB(150, 100, 255) },
		{ name = "Created Objects", count = 0, color = Color3.fromRGB(100, 255, 150) },
		{ name = "ID Registry", count = 0, color = Color3.fromRGB(255, 200, 100) },
		{ name = "Active States", count = 0, color = Color3.fromRGB(255, 100, 150) },
		{ name = "Event Connections", count = 0, color = Color3.fromRGB(200, 200, 100) },
		{ name = "Styles", count = 0, color = Color3.fromRGB(150, 255, 200) },
		{ name = "Error Logs", count = 0, color = Color3.fromRGB(255, 100, 100) },
		{ name = "LuaCSS Shared", count = 0, color = Color3.fromRGB(0, 50, 178) },
	}

	-- Count everything
	for _ in pairs(shared.LuaCSS.EnvValues) do
		stats[1].count += 1
	end
	for _ in pairs(shared.LuaCSS.RegisteredComponents) do
		stats[2].count += 1
	end
	for _ in pairs(shared.LuaCSS.CreatedObjects) do
		task.spawn(function()
			stats[3].count += 1
		end)
	end
	for _ in pairs(shared.LuaCSS.IdRegistry) do
		stats[4].count += 1
	end
	for _ in pairs(shared.LuaCSS.States) do
		stats[5].count += 1
	end
	stats[6].count = #shared.LuaCSS.EventStorage
	for _ in pairs(shared.LuaCSS.Styles) do
		stats[7].count += 1
	end
	stats[8].count = #shared.LuaCSS.ErrorLogs

	for _ in pairs(shared.LuaCSS) do
		stats[9].count += 1
	end

	for i, stat in ipairs(stats) do
		local card = LuaCSS.compileObject({
			class = "TextButton",
			style = gwp("CodeLine"),
			groundcolor = stat.color,
			txtcolor = Color3.fromRGB(255, 255, 255),
			txtsize = 16,
			layoutOrder = i,
			padding = { 0, 10 },
			clicked = function()
				if stat.name == "Environment Values" then
					clearText(window.Content.Scroller)
					populate(window.Content.Scroller, shared.LuaCSS.EnvValues)
				elseif stat.name == "Registered Components" then
					clearText(window.Content.Scroller)
					populate(window.Content.Scroller, shared.LuaCSS.RegisteredComponents)
				elseif stat.name == "Created Objects" then
					clearText(window.Content.Scroller)
					populate(window.Content.Scroller, shared.LuaCSS.CreatedObjects)
				elseif stat.name == "ID Registry" then
					clearText(window.Content.Scroller)
					populate(window.Content.Scroller, shared.LuaCSS.IdRegistry)
				elseif stat.name == "Active States" then
					clearText(window.Content.Scroller)
					populate(window.Content.Scroller, shared.LuaCSS.States)
				elseif stat.name == "Event Connections" then
					clearText(window.Content.Scroller)
					populateEvents(window.Content.Scroller)
				elseif stat.name == "Styles" then
					clearText(window.Content.Scroller)
					populate(window.Content.Scroller, shared.LuaCSS.Styles)
				elseif stat.name == "Error Logs" then
					clearText(window.Content.Scroller)
					populateErrors(window.Content.Scroller)
				elseif stat.name == "LuaCSS Shared" then
					clearText(window.Content.Scroller)
					populate(window.Content.Scroller, shared.LuaCSS)
				end
			end,
		})
		card.Parent = object

		local conn = RunService.RenderStepped:Connect(function()
			card.Text = `{stat.name}: {stat.count}`
		end)
		card.AncestryChanged:Connect(function()
			conn:Disconnect()
		end)
	end

	local memoryLabel = LuaCSS.compileObject({
		class = "TextLabel",
		style = gwp("CodeLine"),
		groundcolor = gwp("InspectorLineColor"),
		txtcolor = gwp("TextColor"),
		text = `Total tracked objects: {stats[3].count + stats[4].count}`,
		txtsize = 14,
		layoutOrder = 999,
	})
	memoryLabel.Parent = object

	addManagementActions(object)
end

local function addManagementActions(object)
	local actions = LuaCSS.compileObject({
		class = "Frame",
		groundtransparency = 1,
		width = { 1, 0 },
		autoscalebased = { Enum.AutomaticSize.Y, {} },
		layoutOrder = 1000,
		list = { "top", "center", { 0, 5 }, Enum.FillDirection.Vertical },
		spawn = {
			ClearErrors = {
				class = "TextButton",
				style = gwp("CodeLine"),
				groundcolor = Color3.fromRGB(200, 50, 50),
				text = "🗑️ Clear Error Logs",
				clicked = function()
					table.clear(shared.LuaCSS.ErrorLogs)
					print("[DevTools] Cleared error logs")
					populateOverview(window.Content.Scroller)
				end,
			},

			ReloadAll = {
				class = "TextButton",
				style = gwp("CodeLine"),
				groundcolor = Color3.fromRGB(50, 150, 200),
				text = "🔄 Reload All Styles",
				clicked = function()
					LuaCSS.reloadAll()
					print("[DevTools] Reloaded all styles and components")
				end,
			},

			EnableLogs = {
				class = "TextButton",
				style = gwp("CodeLine"),
				groundcolor = Color3.fromRGB(200, 150, 50),
				text = "📝 Toggle Logging",
				clicked = function(btn)
					LuaCSS.enableLogs()
					btn.Text = "📝 Logging Enabled"
					print("[DevTools] Enabled LuaCSS logging")
				end,
			},
		},
	})

	actions.Parent = object
end

local function populateTree(object)
	clearText(object)

	local inputBox = LuaCSS.compileObject({
		class = "TextBox",
		style = gwp("CodeLine"),
		groundcolor = gwp("TextboxBackgroundColor"),
		txtcolor = gwp("TextColor"),
		text = "Enter path (e.g., game.Workspace.Part)",
		txtsize = 14,
		height = { 0, 30 },
		layoutOrder = 0,
		ClearTextOnFocus = true,
		textAlignment = "left",
		padding = { 0, 5 },
	})
	inputBox.Parent = object

	local treeContainer = LuaCSS.compileObject({
		class = "Frame",
		groundtransparency = 1,
		width = { 1, 0 },
		autoscalebased = { Enum.AutomaticSize.Y, {} },
		layoutOrder = 1,
		list = { "top", "center", { 0, 0 }, Enum.FillDirection.Vertical },
	})
	treeContainer.Parent = object

	local expandedNodes = {}

	local function createTreeNode(instance, depth, parent, index)
		local hasChildren = #instance:GetChildren() > 0
		local isExpanded = expandedNodes[instance]

		local icon = hasChildren and (isExpanded and "▼ " or "► ") or "  "
		local indent = string.rep("    ", depth)

		local nodeButton = LuaCSS.compileObject({
			class = "TextButton",
			style = gwp("CodeLine"),
			groundcolor = depth % 2 == 0 and Color3.fromRGB(25, 25, 25) or Color3.fromRGB(30, 30, 30),
			text = indent .. icon .. instance.Name .. " (" .. instance.ClassName .. ")",
			txtsize = 13,
			layoutOrder = index,
			textAlignment = "left",
			clicked = function(btn)
				if hasChildren then
					expandedNodes[instance] = not expandedNodes[instance]
					populateTree(window.Content.Scroller)
				else
					-- Select the instance
					if selected then
						LuaCSS.spring(selected, {
							BackgroundColor3 = LuaCSS.getEnvValue(gwp("InspectorLineColor")),
						})
					end
					LuaCSS.spring(btn, {
						BackgroundColor3 = LuaCSS.getEnvValue(gwp("SelectedColor")),
					})
					selected = btn

					local inspector = window.Content.VerticalList.Inspector
					populateInspector(inspector, instance)

					-- Preview if it's a GuiObject
					if instance:IsA("GuiObject") then
						local previewContainer = window.Content.VerticalList.Preview.Scroller
						for _, child in pairs(previewContainer:GetChildren()) do
							if child:IsA("GuiObject") then
								child:Destroy()
							end
						end
						cloneForPreview(instance, previewContainer)
					end
				end
			end,
		})
		nodeButton.Parent = parent
		RunService.RenderStepped:Wait()

		if hasChildren and isExpanded then
			local children = instance:GetChildren()
			for i, child in ipairs(children) do
				createTreeNode(child, depth + 1, parent, index + i)
			end
		end
	end

	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local result = getInstanceFromFullName(inputBox.Text)
			if typeof(result) == "Instance" then
				clearText(treeContainer)
				expandedNodes = {}
				expandedNodes[result] = true
				createTreeNode(result, 0, treeContainer, 0)
			else
				warn("[Tree] Invalid path or instance not found")
				inputBox.Text = "Invalid path! Try again..."
			end
		end
	end)
end

local function populateProfiler(object)
	clearText(object)

	local profilerInstance = shared.LuaCSS.Profiler
	local summary = profilerInstance:GetSummary()

	-- Summary Cards
	local summaryCards = {
		{
			name = "Runtime",
			value = string.format("%.1fs", summary.runtime),
			color = Color3.fromRGB(100, 150, 255),
		},
		{
			name = "Average FPS",
			value = string.format("%.1f", summary.averageFPS),
			color = summary.averageFPS > 50 and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 150, 100),
		},
		{
			name = "Active Objects",
			value = string.format("%d", summary.activeObjects),
			color = Color3.fromRGB(150, 100, 255),
		},
		{
			name = "Memory (Current)",
			value = string.format("%.2f MB", summary.memCurrent / (1024 * 1024)),
			color = Color3.fromRGB(255, 200, 100),
		},
		{
			name = "Memory (Peak)",
			value = string.format("%.2f MB", summary.memPeak / (1024 * 1024)),
			color = Color3.fromRGB(255, 100, 100),
		},
		{
			name = "Created",
			value = string.format("%d", summary.totalCreated),
			color = Color3.fromRGB(100, 255, 200),
		},
		{
			name = "Destroyed",
			value = string.format("%d", summary.totalDestroyed),
			color = Color3.fromRGB(255, 100, 150),
		},
		{
			name = "Frames",
			value = string.format("%d", summary.frameCount),
			color = Color3.fromRGB(200, 200, 255),
		},
	}

	for i, card in ipairs(summaryCards) do
		local cardFrame = LuaCSS.compileObject({
			class = "TextLabel",
			style = gwp("CodeLine"),
			groundcolor = card.color,
			txtcolor = Color3.fromRGB(255, 255, 255),
			text = string.format("%s: %s", card.name, card.value),
			txtsize = 15,
			layoutOrder = i,
			padding = { 0, 10 },
		})
		cardFrame.Parent = object
		RunService.RenderStepped:Wait()
	end

	-- Section: Slowest Components
	local slowestHeader = LuaCSS.compileObject({
		class = "TextLabel",
		style = gwp("CodeLine"),
		groundcolor = Color3.fromRGB(50, 50, 50),
		txtcolor = Color3.fromRGB(255, 255, 100),
		text = "🐌 Slowest Components (Avg Time)",
		txtsize = 16,
		layoutOrder = 101,
		font = Enum.Font.BuilderSansBold,
	})
	slowestHeader.Parent = object

	local slowest = profilerInstance:GetSlowestComponents(10)
	for i, comp in ipairs(slowest) do
		local timeStr = comp.avgTime < 0.001 and string.format("%.2fµs", comp.avgTime * 1000000)
			or string.format("%.2fms", comp.avgTime * 1000)

		local label = LuaCSS.compileObject({
			class = "TextLabel",
			style = gwp("CodeLine"),
			groundcolor = Color3.fromRGB(40, 30, 30),
			txtcolor = Color3.fromRGB(255, 200, 200),
			text = string.format(
				"[%d] %s - %s (×%d, max: %.2fms)",
				i,
				comp.name,
				timeStr,
				comp.count,
				comp.maxTime * 1000
			),
			txtsize = 13,
			layoutOrder = 101 + i,
		})
		label.Parent = object
		RunService.RenderStepped:Wait()
	end

	local frequentHeader = LuaCSS.compileObject({
		class = "TextLabel",
		style = gwp("CodeLine"),
		groundcolor = Color3.fromRGB(50, 50, 50),
		txtcolor = Color3.fromRGB(255, 255, 100),
		text = "Most Frequent Property Updates",
		txtsize = 16,
		layoutOrder = 201,
		font = Enum.Font.BuilderSansBold,
	})
	frequentHeader.Parent = object

	local frequent = profilerInstance:GetMostFrequentUpdates(10)
	for i, prop in ipairs(frequent) do
		local label = LuaCSS.compileObject({
			class = "TextLabel",
			style = gwp("CodeLine"),
			groundcolor = Color3.fromRGB(40, 30, 30),
			txtcolor = Color3.fromRGB(255, 200, 200),
			text = string.format("[%d] %s - %d updates (%.1f/s)", i, prop.name, prop.count, prop.frequency),
			txtsize = 13,
			layoutOrder = 201 + i,
		})
		label.Parent = object
		RunService.RenderStepped:Wait()
	end

	-- Section: EnvValue Changes
	local envHeader = LuaCSS.compileObject({
		class = "TextLabel",
		style = gwp("CodeLine"),
		groundcolor = Color3.fromRGB(50, 50, 50),
		txtcolor = Color3.fromRGB(255, 255, 100),
		text = "🔄 Environment Value Changes",
		txtsize = 16,
		layoutOrder = 301,
		font = Enum.Font.BuilderSansBold,
	})
	envHeader.Parent = object

	local envCount = 0
	for envName, data in pairs(profilerInstance.metrics.envValueChanges) do
		envCount = envCount + 1
		if envCount > 15 then
			break
		end

		local label = LuaCSS.compileObject({
			class = "TextLabel",
			style = gwp("CodeLine"),
			groundcolor = Color3.fromRGB(30, 40, 30),
			txtcolor = Color3.fromRGB(200, 255, 200),
			text = string.format("%s - %d changes (last: %s)", envName, data.count, tostring(data.lastValue)),
			txtsize = 13,
			layoutOrder = 301 + envCount,
		})
		label.Parent = object
		RunService.RenderStepped:Wait()
	end

	if envCount == 0 then
		local noEnv = LuaCSS.compileObject({
			class = "TextLabel",
			style = gwp("CodeLine"),
			groundcolor = Color3.fromRGB(30, 30, 30),
			txtcolor = gwp("TextColor"),
			text = "No environment value changes recorded",
			txtsize = 13,
			layoutOrder = 302,
		})
		noEnv.Parent = object
	end

	local controls = LuaCSS.compileObject({
		class = "Frame",
		groundtransparency = 1,
		width = { 1, 0 },
		autoscalebased = { Enum.AutomaticSize.Y, {} },
		layoutOrder = 901,
		list = { "top", "center", { 0, 5 }, Enum.FillDirection.Vertical },
		spawn = {
			RefreshBtn = {
				class = "TextButton",
				style = gwp("CodeLine"),
				groundcolor = Color3.fromRGB(50, 150, 200),
				txtcolor = Color3.fromRGB(255, 255, 255),
				text = summary.isRecording and "⏸️ Pause Recording" or "▶️ Resume Recording",
				clicked = function(btn)
					if profilerInstance.isRecording then
						profilerInstance:StopAutoRecording()
						btn.Text = "▶️ Resume Recording"
					else
						profilerInstance:StartAutoRecording()
						btn.Text = "⏸️ Pause Recording"
					end
				end,
			},
			ClearBtn = {
				class = "TextButton",
				style = gwp("CodeLine"),
				groundcolor = Color3.fromRGB(200, 50, 50),
				txtcolor = Color3.fromRGB(255, 255, 255),
				text = "🗑️ Clear Metrics",
				clicked = function()
					profilerInstance:Clear()
					populateProfiler(window.Content.Scroller)
				end,
			},
			ExportBtn = {
				class = "TextButton",
				style = gwp("CodeLine"),
				groundcolor = Color3.fromRGB(100, 200, 100),
				txtcolor = Color3.fromRGB(255, 255, 255),
				text = "📤 Export to Console",
				clicked = function()
					local exported = profilerInstance:Export()
					print("=== LuaCSS Profiler Export ===")
					print(exported)
					print("==============================")
				end,
			},
			AutoRefreshBtn = {
				class = "TextButton",
				style = gwp("CodeLine"),
				groundcolor = Color3.fromRGB(150, 100, 200),
				txtcolor = Color3.fromRGB(255, 255, 255),
				text = "🔄 Auto-Refresh (OFF)",
				clicked = function(btn)
					if not btn.autoRefreshConnection then
						btn.autoRefreshConnection = RunService.Heartbeat:Connect(function()
							if profilerInstance.frameCounter % 30 == 0 then -- Every 30 frames
								task.spawn(function()
									populateProfiler(window.Content.Scroller)
								end)
							end
						end)
						btn.Text = "🔄 Auto-Refresh (ON)"
						btn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
					else
						btn.autoRefreshConnection:Disconnect()
						btn.autoRefreshConnection = nil
						btn.Text = "🔄 Auto-Refresh (OFF)"
						btn.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
					end
				end,
			},
		},
	})
	controls.Parent = object
end

return function()
	window = LuaCSS.compileObject({
		class = "CanvasGroup",
		drag = true,
		size = { 0, 900, 0, 500 },
		groundcolor = gwp("BackgroundColor"),
		rounded = gwp("Roundness"),
		alignment = "center",
		list = { "top", "center", { 0, 0 }, Enum.FillDirection.Vertical },
		border = true,
		groundtransparency = gwp("BackgroundTransparency"),
		spawn = {
			Content = {
				class = "CanvasGroup",
				size = { 1, 0, 1, 0 },
				groundtransparency = 1,
				list = { "center", "center", { 0, 0 }, Enum.FillDirection.Horizontal },
				spawn = {
					Scroller = {
						class = "ScrollingFrame",
						size = { 1, 0, 1, 0 },
						groundtransparency = 1,
						ScrollBarThickness = 0,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						autofill = true,
						list = { "top", "center", { 0, 0 }, Enum.FillDirection.Vertical },
						spawn = {
							SearchTextbox = {
								class = "TextBox",
								alignment = "center",
								height = { 0, 25 },
								width = { 1, 0 },
								Text = "Search..",
								paddingleft = { 0, 10 },
								border = true,
								textAlignment = "left",
								txtsize = gwp("DefaultTextSize"),
								groundcolor = gwp("SearchBoxColor"),
								txtcolor = gwp("TextColor"),
								font = gwp("Font"),
							},
						},
					},
					VerticalList = {
						class = "CanvasGroup",
						layoutOrder = 999,
						width = { 0, 0 },
						autosize = Enum.AutomaticSize.X,
						groundtransparency = 1,
						list = { "top", "center", { 0, 0 }, Enum.FillDirection.Vertical },
						border = true,
						height = { 1, 0 },
						spawn = {
							Inspector = {
								class = "Frame",
								style = gwp("window"),
								height = { 1, 0 },
								autofill = true,
								editChildren = {
									Title = {
										text = "Inspector",
									},
								},
							},

							Preview = {
								class = "Frame",
								style = gwp("window"),
								height = { 1, 0 },
								autofill = true,
								editChildren = {
									Title = {
										text = "Preview",
									},
								},
							},
						},
					},
				},
			},

			Title = {
				class = "TextLabel",
				border = true,
				width = { 1, 0 },
				font = Enum.Font.BuilderSansBold,
				text = "          LuaCSS DevTools (v6)",
				layoutOrder = -999,
				alignment = "top center",
				groundtransparency = 1,
				txtsize = gwp("TitleFontSize"),
				padding = { 0, gwp("TitlePadding") },
				groundcolor = gwp("TitleBackgroundColor"),
				txtcolor = gwp("TitleTextColor"),
				textAlignment = "left",
				height = gwp("TitleHeight"),
				spawn = {
					Logo = {
						class = "ImageLabel",
						Image = "rbxassetid://131767945927134",
						size = { 0, 35, 0, 35 },
						alignment = "center left",
						MouseEnter = function(Button)
							LuaCSS.spring(Button, {
								Size = UDim2.new(0, 45, 0, 45),
							})
						end,
						MouseLeave = function(Button)
							LuaCSS.spring(Button, {
								Size = UDim2.new(0, 35, 0, 35),
							})
						end,
						groundtransparency = 1,
						ScaleType = Enum.ScaleType.Fit,
					},

					Buttons = {
						class = "Frame",
						width = { 1, 0 },
						height = { 1, 0 },
						groundtransparency = 1,
						paddingright = { 0, 5 },
						list = { "center", "right", { 0, 5 }, Enum.FillDirection.Horizontal },
						spawn = {
							Overview = {
								class = "TextButton",
								style = gwp("RibbonButton"),
								text = "Overview",
								clicked = function()
									clearText(window.Content.Scroller)
									populateOverview(window.Content.Scroller, addManagementActions)
								end,
							},

							Profiler = {
								class = "TextButton",
								style = gwp("RibbonButton"),
								text = "Profiler",
								clicked = function()
									clearText(window.Content.Scroller)
									populateProfiler(window.Content.Scroller)
								end,
							},

							Tree = {
								class = "TextButton",
								style = gwp("RibbonButton"),
								text = "Tree",
								clicked = function()
									clearText(window.Content.Scroller)
									populateTree(window.Content.Scroller)
								end,
							},
						},
					},
				},
			},
		},
	})

	local searchBox: TextBox = window.Content.Scroller.SearchTextbox

	local blurValue = LuaCSS.getEnvValueObject(gwp("BlurEnabled"))
	blurValue.Changed:Connect(function(new)
		if new == true then
			task.spawn(function()
				blurController:ModifyFrame(window, "Blur")
			end)
		end
	end)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchBox.Text:lower()

		for _, item in pairs(window.Content.Scroller:GetChildren()) do
			if item:IsA("TextButton") then
				local text = (item.Text or ""):lower()
				item.Visible = text:find(query) ~= nil
			end
		end
	end)

	searchBox.FocusLost:Connect(function(ent)
		if ent then
			local result = getInstanceFromFullName(searchBox.Text)
			if result then
				clearText(window.Content.Scroller)
				newGuiTree(result, shared.LuaCSS.CreatedObjects[result], 0, window.Content.Scroller)
			end
		end
	end)

	return window
end
