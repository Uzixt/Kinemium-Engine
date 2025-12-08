--!nocheck
local RunService = game:GetService("RunService")

local animatedlist = require(script.Parent.Parent.libs.AnimatedListLayout)
local color = require(script.Parent.color)
local guard = require(script.Parent.Parent.assets.guard)
local logger = require(script.Parent.Parent.assets.logger)
local lucide = require(script.Parent.Parent.libs.Lucide)
local spr = require(script.Parent.Parent.libs.spr)

local maid = require(script.Parent.Parent.libs.maid)

local methods = {
	parent = function(object: GuiObject, parent: GuiObject)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		object.Parent = parent
	end,

	width = function(object: GuiObject, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end

		object.Size = UDim2.new(scale, offset, object.Size.Y.Scale, object.Size.Y.Offset)
	end,

	canvasEnabled = function(object: GuiObject, bool)
		local canvas = Instance.new("CanvasGroup")
		canvas.Name = object.Name
		canvas.BackgroundTransparency = 1
		canvas.Size = object.Size
		canvas.Transparency = 1
		canvas.Parent = object.Parent
		object.Parent = canvas
	end,

	autofill = function(object: GuiObject)
		local UIFlexItem = object:FindFirstChild("UIFlexItem") or Instance.new("UIFlexItem")
		UIFlexItem.FlexMode = Enum.UIFlexMode.Fill
		UIFlexItem.Parent = object
		return { UIFlexItem }
	end,

	squircle = function(gui: GuiObject, value)
		if value == true then
			if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
				gui.Image = "rbxassetid://95025174368716"
				gui.ResampleMode = Enum.ResamplerMode.Default
				gui.ScaleType = Enum.ScaleType.Slice
				gui.SliceCenter = Rect.new(25, 25, 25, 25)
				gui.Position = UDim2.new(0.5, 0, 0.5, 0)
				gui.ImageColor3 = gui.BackgroundColor3
				gui.AnchorPoint = Vector2.new(0.5, 0.5)
				gui.SliceScale = 0.5

				local highlight = Instance.new("ImageLabel")
				highlight.Size = UDim2.new(1, 0, 1, 0)
				highlight.Image = "rbxassetid://108824901287727"
				highlight.ResampleMode = Enum.ResamplerMode.Default
				highlight.ScaleType = Enum.ScaleType.Slice
				highlight.SliceCenter = Rect.new(25, 25, 25, 25)
				highlight.Position = UDim2.new(0.5, 0, 0.5, 0)
				highlight.BackgroundTransparency = 1
				highlight.AnchorPoint = Vector2.new(0.5, 0.5)
				highlight.SliceScale = 0.5
				highlight.Parent = gui

				gui.BackgroundTransparency = 0

				return {
					highlight,

					function()
						gui.Image = ""
					end,

					gui.Changed:Connect(function()
						gui.BackgroundTransparency = 0
						gui.ImageColor3 = gui.BackgroundColor3

						if gui:FindFirstAncestorWhichIsA("UICorner") then
							if not highlight:FindFirstAncestorWhichIsA("UICorner") then
								local clone = gui:FindFirstAncestorWhichIsA("UICorner"):Clone()
								clone.Parent = highlight
							end
						end
					end),
				}
			end
		end
	end,

	wrap = function(guiobject: GuiObject, data: { Instance })
		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.Position = UDim2.new(0.5, 0, 0.5, 0)
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Name = "GuiWrapper"
		frame.BackgroundTransparency = 1
		frame.Parent = guiobject

		for _, v in pairs(data) do
			v.Parent = frame
		end
	end,

	height = function(object: GuiObject, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end

		object.Size = UDim2.new(object.Size.X.Scale, object.Size.X.Offset, scale, offset)
	end,

	position = function(object: GuiObject, data)
		local x1, x2, y1, y2 = data[1], data[2], data[3], data[4]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(x1) then
			return "Value is not a number"
		end
		if not guard:isNumber(x2) then
			return "Value is not a number"
		end
		if not guard:isNumber(y1) then
			return "Value is not a number"
		end
		if not guard:isNumber(y2) then
			return "Value is not a number"
		end

		object.Position = UDim2.new(x1, x2, y1, y2)
	end,

	name = function(object: GuiObject, str)
		object.Name = str
	end,

	anchor = function(object: GuiObject, data)
		local x, y = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(x) then
			return "Value is not a number"
		end
		if not guard:isNumber(y) then
			return "Value is not a number"
		end
		object.AnchorPoint = Vector2.new(x, y)
	end,

	hovered = function(object: GuiObject, callback)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		object.MouseEnter:Connect(function()
			callback(object)
		end)
	end,

	clicked = function(object: GuiButton, callback)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		object.MouseButton1Click:Connect(function()
			callback(object)
		end)
	end,

	left = function(object: GuiObject, callback)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		object.MouseLeave:Connect(function()
			callback(object)
		end)
	end,

	size = function(object: GuiObject, data)
		local x1, x2, y1, y2 = data[1], data[2], data[3], data[4]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(x1) then
			return "Value is not a number"
		end
		if not guard:isNumber(x2) then
			return "Value is not a number"
		end
		if not guard:isNumber(y1) then
			return "Value is not a number"
		end
		if not guard:isNumber(y2) then
			return "Value is not a number"
		end

		if x1 and x2 and not y1 and not y2 then
			object.Size = UDim2.fromScale(x1, x2)
		else
			object.Size = UDim2.new(x1, x2, y1, y2)
		end
		return
	end,

	paddingtop = function(object: GuiObject, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end
		local padding: UIPadding
		if object:FindFirstChild("CSSPadding") then
			padding = object.CSSPadding
		else
			padding = Instance.new("UIPadding")
			padding.Name = "CSSPadding"
			padding.Parent = object
		end
		padding.PaddingTop = UDim.new(scale, offset)
		return { padding }
	end,

	paddingbottom = function(object: GuiObject, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end
		local padding: UIPadding
		if object:FindFirstChild("CSSPadding") then
			padding = object.CSSPadding
		else
			padding = Instance.new("UIPadding")
			padding.Name = "CSSPadding"
			padding.Parent = object
		end
		padding.PaddingBottom = UDim.new(scale, offset)
		return { padding }
	end,

	paddingleft = function(object: GuiObject, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end
		local padding: UIPadding
		if object:FindFirstChild("CSSPadding") then
			padding = object.CSSPadding
		else
			padding = Instance.new("UIPadding")
			padding.Name = "CSSPadding"
			padding.Parent = object
		end
		padding.PaddingLeft = UDim.new(scale, offset)
		return { padding }
	end,

	paddingright = function(object: GuiObject, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end
		local padding: UIPadding
		if object:FindFirstChild("CSSPadding") then
			padding = object.CSSPadding
		else
			padding = Instance.new("UIPadding")
			padding.Name = "CSSPadding"
			padding.Parent = object
		end
		padding.PaddingRight = UDim.new(scale, offset)
		return { padding }
	end,

	groundcolor = function(object: GuiObject, value: Color3 | string)
		object.BackgroundColor3 = color(value)
		return
	end,

	groundtransparency = function(object: GuiObject, transparency)
		object.BackgroundTransparency = transparency
		return
	end,

	borderColor = function(object: GuiObject, value)
		object.BorderColor3 = color(value)
		return
	end,

	border = function(object: GuiObject, bool)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		local events = {}

		if bool == true then
			if object:FindFirstChild("UIStroke") then
				return "Object already has a border"
			end
			local border = Instance.new("UIStroke")
			border.Name = "UIStroke"
			border.Parent = object
			border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			border.Color = Color3.new(1, 1, 1)
			border.Transparency = 0.9

			table.insert(
				events,
				object.Changed:Connect(function()
					if object:IsA("CanvasGroup") then
						if object.GroupTransparency == 1 then
							border.Transparency = 1
						elseif object.GroupTransparency == 0 then
							border.Transparency = 0.9
						end
					end
				end)
			)
		else
			if object:FindFirstChild("UIStroke") then
				object.UIStroke:Destroy()
			else
				return "Object does not have a border"
			end
		end
		return events
	end,

	rotation = function(object: GuiObject, rotation)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(rotation) then
			return "Value is not a number"
		end
		object.Rotation = rotation
		return
	end,

	visible = function(object: GuiObject, visible)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isBoolean(visible) then
			return "Value is not a boolean"
		end
		object.Visible = visible
		return
	end,

	layoutOrder = function(object: GuiObject, order)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(order) then
			return "Value is not a number"
		end
		object.LayoutOrder = order
		return
	end,

	allowClipping = function(object: GuiObject, bool)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isBoolean(bool) then
			return "Value is not a boolean"
		end
		object.ClipsDescendants = bool
		return
	end,

	text = function(object: GuiObject, text)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isString(text) then
			return "Value is not a string"
		end
		object.Text = text
		return
	end,

	stepped = function(object: GuiObject, callback)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		local stepped

		stepped = RunService.RenderStepped:Connect(function()
			callback(object, stepped)
		end)

		return { stepped }
	end,

	heartbeat = function(object: GuiObject, callback)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		local stepped

		stepped = RunService.Heartbeat:Connect(function()
			callback(object, stepped)
		end)

		return { stepped }
	end,

	target = function(object: GuiObject, data)
		local damping, frequency, properties = data[1], data[2], data[3]

		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(damping) then
			return "Damping is not a number"
		end
		if not guard:isNumber(frequency) then
			return "Frequency is not a number"
		end
		if not guard:isTable(properties) then
			return "Properties is not a table"
		end
		return { spr.target(object, damping, frequency, properties) }
	end,

	autosize = function(object: GuiObject, enum)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		object.AutomaticSize = enum
		return
	end,

	txtsize = function(object: GuiObject, size)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(size) then
			return "Size is not a number"
		end
		object.TextSize = size
		return
	end,

	txtcolor = function(object: GuiObject, value)
		object.TextColor3 = color(value)
		return
	end,

	font = function(object: GuiObject, font)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		object.Font = font
		return
	end,

	txtvisible = function(object: GuiObject, transparency: number)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(transparency) then
			return "Transparency is not a number"
		end
		object.TextTransparency = transparency
		return
	end,

	radius = function(object: UICorner, radius)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isTable(radius) then
			return "Radius is not a number"
		end
		object.CornerRadius = UDim.new(radius[1], radius[2])
		return
	end,

	padding = function(object: GuiObject, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end
		local padding: UIPadding
		if object:FindFirstChild("CSSPadding") then
			padding = object.CSSPadding
		else
			padding = Instance.new("UIPadding")
			padding.Name = "CSSPadding"
			padding.Parent = object
		end
		padding.PaddingRight = UDim.new(scale, offset)
		padding.PaddingLeft = UDim.new(scale, offset)
		padding.PaddingBottom = UDim.new(scale, offset)
		padding.PaddingTop = UDim.new(scale, offset)
	end,

	animlist = function(object: GuiObject, data)
		local vertical, horizontal, padding, filldirection = data[1], data[2], data[3], data[4]

		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		local layout = animatedlist.new(object)
		return { layout }
	end,

	drag = function(object: GuiObject, data)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		local drag: UIDragDetector = object:FindFirstChildOfClass("Drag")
		if not drag then
			drag = Instance.new("UIDragDetector")
			drag.Name = "Drag"
			drag.Parent = object
		end
		return { drag }
	end,

	gridmaxcells = function(object: GuiObject, data)
		if object:FindFirstChild("UIGridLayout") then
			object.UIGridLayout.FillDirectionMaxCells = Vector2.new(data[1], data[2])
		end
	end,

	gridpadding = function(object: GuiObject, data)
		if object:FindFirstChild("UIGridLayout") then
			object.UIGridLayout.CellPadding = UDim2.new(data[1], data[2], data[3], data[4])
		end
	end,

	grid = function(object: GuiObject, data)
		local vertical, horizontal, padding, size, filldirection = data[1], data[2], data[3], data[4], data[5]

		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isString(vertical) then
			return "Value is not a boolean"
		end
		if not guard:isString(horizontal) then
			return "Value is not a boolean"
		end

		local layout: UIGridLayout
		if object:FindFirstChild("UIGridLayout") then
			layout = object.UIGridLayout
		else
			layout = Instance.new("UIGridLayout")
		end
		layout.SortOrder = Enum.SortOrder.LayoutOrder

		if vertical == "top" then
			layout.VerticalAlignment = Enum.VerticalAlignment.Top
		elseif vertical == "bottom" then
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		elseif vertical == "center" then
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
		end

		if horizontal == "left" then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		elseif horizontal == "right" then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		elseif horizontal == "center" then
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		end

		if filldirection then
			layout.FillDirection = filldirection
		end

		layout.CellSize = UDim2.new(0, size[1], 0, size[2])
		layout.CellPadding = UDim2.new(0, padding[1], 0, padding[2])
		layout.Parent = object
		return layout
	end,

	cframe = function(object: GuiObject, cframe)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isCFrame(cframe) then
			return "Data is not CFrame"
		end
		object.CFrame = cframe
		return
	end,

	camera = function(object: GuiObject, callback)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		local returned = callback(object)
		if returned then
			object.CurrentCamera = returned
		end
		return { returned }
	end,

	alignment = function(object: GuiObject, pos)
		if not guard:isString(pos) then
			return "Passed argument is not a string"
		end

		local function setPosition(object, pos)
			local positions = {
				top = 0,
				center = 0.5,
				bottom = 1,
				left = 0,
				right = 1,
			}

			local vertical, horizontal = "center", "center"

			if pos:find(" ") then
				local parts = pos:split(" ")
				vertical, horizontal = parts[1], parts[2]
			else
				vertical = pos
				horizontal = pos
			end

			local x = positions[horizontal] or 0.5
			local y = positions[vertical] or 0.5

			object.Position = UDim2.fromScale(x, y)
			object.AnchorPoint = Vector2.new(x, y)
		end

		setPosition(object, pos)
		return
	end,

	getalignment = function(object: GuiObject, pos)
		if not guard:isString(pos) then
			return "Passed argument is not a string"
		end

		local function getPosition(object, pos)
			local positions = {
				top = 0,
				center = 0.5,
				bottom = 1,
				left = 0,
				right = 1,
			}

			local vertical, horizontal = "center", "center"

			if pos:find(" ") then
				local parts = pos:split(" ")
				vertical, horizontal = parts[1], parts[2]
			else
				vertical = pos
				horizontal = pos
			end

			local x = positions[horizontal] or 0.5
			local y = positions[vertical] or 0.5
			return UDim2.fromScale(x, y), Vector2.new(x, y)
		end

		return getPosition(pos)
	end,

	shadow = function(
		object: GuiObject,
		dataTable: {
			Image: string?,
			ImageTransparency: number?,
			Scale: number?,
			Color: Color3?,
			Parent: Instance?,
			ZIndex: number?,
		}
	)
		if object.Parent:FindFirstChild("Shadow") then
			return
		end
		local Shadow = Instance.new("Frame")
		Shadow.Name = "Shadow"
		Shadow.ZIndex = dataTable.ZIndex or 0
		Shadow.Size = UDim2.new(1, 0, 1, 0)
		Shadow.BackgroundTransparency = 1
		Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)

		object.Active = false

		local ShadowImage = Instance.new("ImageLabel")
		ShadowImage.Name = "ShadowImage"
		ShadowImage.ZIndex = 0
		ShadowImage.AnchorPoint = Vector2.new(0.5, 0.5)
		ShadowImage.Size = UDim2.new(dataTable.Scale or 1.5, 0, dataTable.Scale or 1.5, 0)
		ShadowImage.BackgroundTransparency = 1
		ShadowImage.Active = false
		ShadowImage.ImageTransparency = dataTable.ImageTransparency or 0
		ShadowImage.Position = UDim2.new(0.5, 0, 2, 0)
		ShadowImage.ImageColor3 = dataTable.Color or Color3.fromRGB(0, 0, 0)
		ShadowImage.Image = dataTable.Image or "rbxassetid://16389697796"
		ShadowImage.Parent = Shadow

		local changed
		local sync = task.spawn(function()
			changed = object.Changed:Connect(function()
				pcall(function()
					Shadow.Position = object.Position
					ShadowImage.Position = UDim2.new(0.5, 0, 0.5, 0)
					Shadow.AnchorPoint = object.AnchorPoint
					Shadow.Size =
						UDim2.new(object.Size.X.Scale, object.Size.X.Offset, object.Size.Y.Scale, object.Size.Y.Offset)
					ShadowImage.ImageTransparency = object.GroupTransparency or object.BackgroundTransparency
					ShadowImage.Visible = object.Visible
				end)
			end)
		end)

		local destroying = object.Destroying:Connect(function()
			task.cancel(sync)
			Shadow:Destroy()
		end)

		Shadow.Parent = dataTable.Parent or object.Parent

		maid:insert(Shadow)
		maid:insert(destroying)
		maid:insert(sync)
		maid:insert(changed)
		maid:insert(ShadowImage)
		return maid:get()
	end,

	maid = function(object: GuiObject, event: any)
		maid:insert(event)
		return event
	end,

	clean = function(object, tbl)
		maid:cleantable(tbl)
	end,

	cleanevents = function()
		maid:clean()
	end,

	rounded = function(guiobject: Instance, data)
		if guiobject:FindFirstChild("UICorner") then
			local corner = guiobject.UICorner
			if data[1] == 0 and data[2] == 0 then
				corner:Destroy()
			end
			corner.CornerRadius = UDim.new(data[1], data[2])
		else
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(data[1], data[2])
			corner.Parent = guiobject
		end
	end,

	hovercolor = function(guiobject: GuiObject, data)
		local value, animated, damping, frequency = data.Value, data.Animated, data.Damping, data.Frequency

		return {
			guiobject.MouseEnter:Connect(function()
				if animated then
					spr.target(guiobject, damping or 2, frequency or 5, {
						BackgroundColor3 = color(value),
					})
				else
					guiobject.BackgroundColor3 = color(value)
				end
			end),
		}
	end,

	hovertransparency = function(guiobject: GuiObject, data)
		local value, animated, damping, frequency = data.Value, data.Animated, data.Damping, data.Frequency

		return {
			guiobject.MouseEnter:Connect(function()
				if animated then
					spr.target(guiobject, damping or 2, frequency or 5, {
						BackgroundTransparency = value,
					})
				else
					guiobject.BackgroundTransparency = value
				end
			end),
		}
	end,

	leavetransparency = function(guiobject: GuiObject, data)
		local value, animated, damping, frequency = data.Value, data.Animated, data.Damping, data.Frequency

		return {
			guiobject.MouseLeave:Connect(function()
				if animated then
					spr.target(guiobject, damping or 2, frequency or 5, {
						BackgroundTransparency = value,
					})
				else
					guiobject.BackgroundTransparency = value
				end
			end),
		}
	end,

	leavecolor = function(guiobject: GuiObject, data)
		local value, animated, damping, frequency = data.Value, data.Animated, data.Damping, data.Frequency

		return {
			guiobject.MouseLeave:Connect(function()
				if animated then
					spr.target(guiobject, damping or 2, frequency or 5, {
						BackgroundColor3 = color(value),
					})
				else
					guiobject.BackgroundColor3 = color(value)
				end
			end),
		}
	end,

	animate = function(guiobject: GuiObject, data)
		local value, property, damping, frequency = data.Value, data.Property, data.Damping, data.Frequency

		local tbl = {}

		if type(value) == "string" then
			local function getPosition(pos)
				local positions = {
					top = 0,
					center = 0.5,
					bottom = 1,
					left = 0,
					right = 1,
				}

				local vertical, horizontal = "center", "center"

				if pos:find(" ") then
					local parts = pos:split(" ")
					vertical, horizontal = parts[1], parts[2]
				else
					vertical = pos
					horizontal = pos
				end

				local x = positions[horizontal] or 0.5
				local y = positions[vertical] or 0.5
				return UDim2.fromScale(x, y), Vector2.new(x, y)
			end

			local pos, anchor = getPosition(value)
			tbl.Position = pos
			tbl.AnchorPoint = anchor
		else
			tbl[property or "Position"] = value
		end

		return spr.target(guiobject, damping or 2, frequency or 5, tbl)
	end,

	image = function(guiObject: ImageLabel, str: string)
		local success, asset = pcall(function()
			return lucide.GetAsset(str, 28)
		end)

		if success and asset then
			guiObject.Image = asset.Url
			guiObject.ImageRectSize = asset.ImageRectSize
			guiObject.ImageRectOffset = asset.ImageRectOffset
		else
			guiObject.Image = str
		end
	end,

	inframe = function(guiobject: GuiObject)
		local Frame = Instance.new("Frame")
		Frame.Name = guiobject.Name
		Frame.BackgroundTransparency = 1
		Frame.Size = guiobject.Size
		Frame.Transparency = 1
		Frame.Parent = guiobject.Parent
		guiobject.Parent = Frame
		return { Frame }
	end,

	run = function(guiobject: GuiObject, func)
		return { func(guiobject) }
	end,

	runinsert = function(guiobject: GuiObject, func)
		local spawned = task.spawn(function()
			local returned = func(guiobject)

			if returned then
				maid:insert(returned)
			end
		end)
		maid:insert(spawned)
	end,

	zindex = function(guiobject: GuiObject, z)
		guiobject.ZIndex = z
	end,

	cornerRadius = function(guiobject: GuiObject, z)
		guiobject.CornerRadius = UDim.new(z[1], z[2])
	end,

	paddingsides = function(object, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end
		local padding: UIPadding
		if object:FindFirstChild("CSSPadding") then
			padding = object.CSSPadding
		else
			padding = Instance.new("UIPadding")
			padding.Name = "CSSPadding"
			padding.Parent = object
		end
		padding.PaddingLeft = UDim.new(scale, offset)
		padding.PaddingRight = UDim.new(scale, offset)
		return { padding }
	end,

	paddingvertical = function(object, data)
		local scale, offset = data[1], data[2]
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(scale) then
			return "Value is not a number"
		end
		if not guard:isNumber(offset) then
			return "Value is not a number"
		end
		local padding: UIPadding
		if object:FindFirstChild("CSSPadding") then
			padding = object.CSSPadding
		else
			padding = Instance.new("UIPadding")
			padding.Name = "CSSPadding"
			padding.Parent = object
		end
		padding.PaddingTop = UDim.new(scale, offset)
		padding.PaddingBottom = UDim.new(scale, offset)
		return { padding }
	end,

	gradient = function(guiobject: GuiObject, d)
		local color: ColorSequence = d.Color
		local transparency: NumberSequence = d.Transparency
		local rotation: number = d.Rotation
		local gradient: UIGradient
		if guiobject:FindFirstChild("Gradient") then
			gradient = guiobject.Gradient
		else
			gradient = Instance.new("UIGradient")
			gradient.Name = "Gradient"
			gradient.Parent = guiobject
		end
		if color then
			gradient.Color = color
		end
		if transparency then
			gradient.Transparency = transparency
		end
		if rotation then
			gradient.Rotation = rotation
		end
		return { gradient }
	end,

	center = function(guiobject)
		guiobject.AnchorPoint = Vector2.new(0.5, 0.5)
		guiobject.Position = UDim2.new(0.5, 0, 0.5, 0)
	end,

	offset = function(guiobject, offset: UDim2)
		guiobject.Position = guiobject.Position + offset
	end,

	borderwidth = function(guiobject, px)
		local border = guiobject:FindFirstChild("UIStroke") or Instance.new("UIStroke")
		border.Thickness = px
		border.Parent = guiobject
		return { border }
	end,

	opacity = function(guiobject, value)
		if guiobject:IsA("TextLabel") or guiobject:IsA("TextButton") then
			guiobject.TextTransparency = value
		end
		guiobject.BackgroundTransparency = value
	end,

	debugoutline = function(guiobject)
		local stroke = guiobject:FindFirstChild("UIStroke") or Instance.new("UIStroke")
		stroke.Color = Color3.new(1, 0, 0)
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = guiobject
		return { stroke }
	end,

	flexrow = function(gui, gap)
		local layout = gui:FindFirstChild("UIListLayout") or Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, gap or 0)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = gui
		return { layout }
	end,

	flexcolumn = function(gui, gap)
		local layout = gui:FindFirstChild("UIListLayout") or Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.Padding = UDim.new(0, gap or 0)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = gui
		return { layout }
	end,

	fit = function(guiobject: GuiObject, data)
		local aspectRatio = data.Ratio or 1.778 -- Default 16:9
		local dom = data.DominantAxis or Enum.DominantAxis.Width

		local constraint = guiobject:FindFirstChild("CSSAspect") or Instance.new("UIAspectRatioConstraint")
		constraint.Name = "CSSAspect"
		constraint.Parent = guiobject
		constraint.AspectRatio = aspectRatio
		constraint.DominantAxis = dom
		return { constraint }
	end,

	fitToDevice = function(guiobject: GuiObject, data)
		local UserInputService = game:GetService("UserInputService")

		local platform = UserInputService:GetPlatform()
		local viewportSize = workspace.CurrentCamera.ViewportSize
		local aspectRatio = viewportSize.X / viewportSize.Y

		local scale = 1
		local aspect = aspectRatio
		local dominantAxis = Enum.DominantAxis.Width

		if data.Scale then
			scale = data.Scale
		end
		if data.AspectRatio then
			aspect = data.AspectRatio
		end
		if data.DominantAxis then
			dominantAxis = data.DominantAxis
		end

		if platform == Enum.Platform.IOS or platform == Enum.Platform.Android then
			scale = 0.9 -- Slightly smaller for mobile
		elseif platform == Enum.Platform.XBoxOne then
			scale = 1.2 -- Larger for TV
		end

		local scaleInstance = guiobject:FindFirstChild("CSScale") or Instance.new("UIScale")
		scaleInstance.Name = "CSScale"
		scaleInstance.Scale = scale
		scaleInstance.Parent = guiobject

		if data.UseAspect ~= false then
			local aspectConstraint = guiobject:FindFirstChild("CSSAspect") or Instance.new("UIAspectRatioConstraint")
			aspectConstraint.Name = "CSSAspect"
			aspectConstraint.AspectRatio = aspect
			aspectConstraint.DominantAxis = dominantAxis
			aspectConstraint.Parent = guiobject
			return { aspectRatio, scaleInstance, aspectConstraint }
		end
		return { aspectRatio, scaleInstance }
	end,

	textStroke = function(object: GuiObject, data)
		local thickness, color = data.Thickness or 1, data.Color or Color3.new(0, 0, 0)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		local stroke = object:FindFirstChild("TextStroke") or Instance.new("UIStroke")
		stroke.Name = "TextStroke"
		stroke.Thickness = thickness
		stroke.Color = color
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = object
		return { stroke }
	end,

	textAlignment = function(object: GuiObject, alignment)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isString(alignment) then
			return "Alignment is not a string"
		end

		local alignments = {
			left = Enum.TextXAlignment.Left,
			center = Enum.TextXAlignment.Center,
			right = Enum.TextXAlignment.Right,
		}

		object.TextXAlignment = alignments[alignment] or Enum.TextXAlignment.Center
	end,

	textVerticalAlignment = function(object: GuiObject, alignment)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isString(alignment) then
			return "Alignment is not a string"
		end

		local alignments = {
			top = Enum.TextYAlignment.Top,
			center = Enum.TextYAlignment.Center,
			bottom = Enum.TextYAlignment.Bottom,
		}

		object.TextYAlignment = alignments[alignment] or Enum.TextYAlignment.Center
	end,

	-- Animation and Transitions
	fadeIn = function(object: GuiObject, data)
		local duration, delay = data.Duration or 0.5, data.Delay or 0
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		local originalTransparency = object.BackgroundTransparency
		object.BackgroundTransparency = 1

		task.wait(delay)
		return spr.target(object, 1, 1 / duration, {
			BackgroundTransparency = originalTransparency,
		})
	end,

	fadeOut = function(object: GuiObject, data)
		local duration, delay = data.Duration or 0.5, data.Delay or 0
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		task.wait(delay)
		return spr.target(object, 1, 1 / duration, {
			BackgroundTransparency = 1,
		})
	end,

	slideIn = function(object: GuiObject, data)
		local direction, duration, delay = data.Direction or "left", data.Duration or 0.5, data.Delay or 0
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end

		local originalPosition = object.Position
		local offsets = {
			left = UDim2.new(-1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset),
			right = UDim2.new(1, 0, originalPosition.Y.Scale, originalPosition.Y.Offset),
			top = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, -1, 0),
			bottom = UDim2.new(originalPosition.X.Scale, originalPosition.X.Offset, 1, 0),
		}

		object.Position = offsets[direction] or offsets.left
		task.wait(delay)

		return spr.target(object, 1, 1 / duration, {
			Position = originalPosition,
		})
	end,

	-- Layout and Responsive Design
	aspectRatio = function(object: GuiObject, ratio)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(ratio) then
			return "Ratio is not a number"
		end

		local constraint = object:FindFirstChild("CSSAspect") or Instance.new("UIAspectRatioConstraint")
		constraint.Name = "CSSAspect"
		constraint.AspectRatio = ratio
		constraint.Parent = object
		return { constraint }
	end,

	maxWidth = function(object: GuiObject, maxWidth)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(maxWidth) then
			return "MaxWidth is not a number"
		end

		local constraint = object:FindFirstChild("CSSMaxWidth") or Instance.new("UISizeConstraint")
		constraint.Name = "CSSMaxWidth"
		constraint.MaxSize = Vector2.new(maxWidth, math.huge)
		constraint.Parent = object
		return { constraint }
	end,

	minWidth = function(object: GuiObject, minWidth)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(minWidth) then
			return "MinWidth is not a number"
		end

		local constraint = object:FindFirstChild("CSSMinWidth") or Instance.new("UISizeConstraint")
		constraint.Name = "CSSMinWidth"
		constraint.MinSize = Vector2.new(minWidth, 0)
		constraint.Parent = object
		return { constraint }
	end,

	changedsignal = function(object: GuiObject, data)
		local property, callback = data.property, data.callback
		return {
			object:GetPropertyChangedSignal(property):Connect(function(...)
				if callback then
					callback(object, ...)
				end
			end),
		}
	end,

	-- Interactive States
	disabled = function(object: GuiObject, isDisabled)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isBoolean(isDisabled) then
			return "Value is not a boolean"
		end

		object.Active = not isDisabled
		if object:IsA("GuiButton") then
			object.Interactable = not isDisabled
		end

		-- Visual feedback for disabled state
		if isDisabled then
			object.BackgroundTransparency = math.min(object.BackgroundTransparency + 0.5, 1)
			if object:IsA("TextLabel") or object:IsA("TextButton") then
				object.TextTransparency = math.min(object.TextTransparency + 0.5, 1)
			end
		end
	end,

	hover = function(object: GuiObject, callbacks)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isTable(callbacks) then
			return "Callbacks is not a table"
		end

		local enter = callbacks.Enter or function() end
		local leave = callbacks.Leave or function() end

		return {
			object.MouseEnter:Connect(function()
				enter(object)
			end),
			object.MouseLeave:Connect(function()
				leave(object)
			end),
		}
	end,

	-- Utility Functions
	clone = function(object: GuiObject, parent)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		local cloned = object:Clone()
		if parent then
			cloned.Parent = parent
		end
		return { cloned }
	end,

	hide = function(object: GuiObject)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		object.Visible = false
	end,

	show = function(object: GuiObject)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		object.Visible = true
	end,

	toggle = function(object: GuiObject)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		object.Visible = not object.Visible
	end,

	flex = function(object: GuiObject, value)
		if not guard:isInstance(object) then
			return "Object is not an Instance"
		end
		if not guard:isNumber(value) then
			return "Value is not a number"
		end

		local flexItem = object:FindFirstChild("UIFlexItem") or Instance.new("UIFlexItem")
		flexItem.FlexMode = Enum.UIFlexMode.Custom
		flexItem.GrowRatio = value
		flexItem.Parent = object
		return { flexItem }
	end,

	textwrapped = function(object: GuiObject, bool)
		object.TextWrapped = bool
	end,

	richtext = function(object: GuiObject, bool)
		object.RichText = bool
	end,

	scrollable = function(object: GuiObject, data)
		local direction = data.Direction or "vertical"
		object.ClipsDescendants = true

		if direction == "vertical" then
			object.CanvasSize = UDim2.new(0, 0, 0, data.CanvasHeight or 1000)
			object.ScrollBarThickness = data.Thickness or 6
		elseif direction == "horizontal" then
			object.CanvasSize = UDim2.new(0, data.CanvasWidth or 1000, 0, 0)
			object.ScrollBarThickness = data.Thickness or 6
		end
	end,

	scale = function(object: GuiObject, value)
		local scaleObj = object:FindFirstChild("UIScale") or Instance.new("UIScale")
		scaleObj.Scale = value
		scaleObj.Parent = object
		return { scaleObj }
	end,

	display = function(object: GuiObject, value)
		if value == "none" then
			object.Visible = false
		elseif value == "block" or value == "flex" then
			object.Visible = true
		end
	end,

	overflow = function(object: ScrollingFrame, value)
		if value == "hidden" then
			object.ClipsDescendants = true
			object.ScrollingEnabled = false
		elseif value == "scroll" or value == "auto" then
			object.ClipsDescendants = true
			object.ScrollingEnabled = true
		elseif value == "visible" then
			object.ClipsDescendants = false
		end
	end,

	transform = function(object: GuiObject, data)
		if data.rotate then
			object.Rotation = data.rotate
		end
		if data.scale then
			local scale = object:FindFirstChild("UIScale") or Instance.new("UIScale")
			scale.Scale = data.scale
			scale.Parent = object
		end
	end,

	cursor = function(object: GuiButton, value)
		if value == "pointer" then
			object.AutoButtonColor = true
		elseif value == "default" or value == "not-allowed" then
			object.AutoButtonColor = false
		end
	end,

	pointerEvents = function(object: GuiObject, value)
		if value == "none" then
			object.Active = false
		elseif value == "auto" then
			object.Active = true
		end
	end,

	lineHeight = function(object: TextLabel, multiplier)
		object.LineHeight = multiplier
	end,

	textTransform = function(object: TextLabel, value)
		if value == "uppercase" then
			object.Text = string.upper(object.Text)
		elseif value == "lowercase" then
			object.Text = string.lower(object.Text)
		elseif value == "capitalize" then
			object.Text = string.gsub(object.Text, "(%a)([%w_']*)", function(first, rest)
				return first:upper() .. rest:lower()
			end)
		end
	end,

	textOverflow = function(object: TextLabel, value)
		if value == "ellipsis" then
			object.TextTruncate = Enum.TextTruncate.AtEnd
		elseif value == "clip" then
			object.TextTruncate = Enum.TextTruncate.None
		end
	end,

	whiteSpace = function(object: TextLabel, value)
		if value == "nowrap" then
			object.TextWrapped = false
		elseif value == "normal" or value == "wrap" then
			object.TextWrapped = true
		end
	end,

	filter = function(object: ImageLabel, data)
		if data.brightness then
			object.ImageColor3 = Color3.new(data.brightness, data.brightness, data.brightness)
		end
		if data.transparency then
			object.ImageTransparency = data.transparency
		end
	end,

	gap = function(object: GuiObject, value)
		local layout = object:FindFirstChildOfClass("UIListLayout") or object:FindFirstChildOfClass("UIGridLayout")
		if layout then
			layout.Padding = UDim.new(0, value)
		end
	end,

	justifyContent = function(object: GuiObject, value)
		local layout = object:FindFirstChildOfClass("UIListLayout")
		if not layout then
			return
		end

		if value == "flex-start" or value == "start" then
			if layout.FillDirection == Enum.FillDirection.Horizontal then
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			else
				layout.VerticalAlignment = Enum.VerticalAlignment.Top
			end
		elseif value == "center" then
			if layout.FillDirection == Enum.FillDirection.Horizontal then
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			else
				layout.VerticalAlignment = Enum.VerticalAlignment.Center
			end
		elseif value == "flex-end" or value == "end" then
			if layout.FillDirection == Enum.FillDirection.Horizontal then
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			else
				layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
			end
		elseif value == "space-between" then
			layout.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
		end
	end,

	alignItems = function(object: GuiObject, value)
		local layout = object:FindFirstChildOfClass("UIListLayout")
		if not layout then
			return
		end

		if layout.FillDirection == Enum.FillDirection.Horizontal then
			if value == "flex-start" then
				layout.VerticalAlignment = Enum.VerticalAlignment.Top
			elseif value == "center" then
				layout.VerticalAlignment = Enum.VerticalAlignment.Center
			elseif value == "flex-end" then
				layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
			end
		else
			if value == "flex-start" then
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			elseif value == "center" then
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			elseif value == "flex-end" then
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			end
		end
	end,

	objectFit = function(object: ImageLabel, value)
		if value == "cover" then
			object.ScaleType = Enum.ScaleType.Crop
		elseif value == "contain" then
			object.ScaleType = Enum.ScaleType.Fit
		elseif value == "fill" then
			object.ScaleType = Enum.ScaleType.Stretch
		elseif value == "none" then
			object.ScaleType = Enum.ScaleType.Tile
		end
	end,

	margin = function(object: GuiObject, data)
		local top, right, bottom, left = data[1], data[2], data[3], data[4]
		if not right then
			right = top
		end
		if not bottom then
			bottom = top
		end
		if not left then
			left = right
		end

		object.Position = object.Position + UDim2.new(0, left, 0, top)
	end,

	borderStyle = function(object: GuiObject, data)
		local width, style, colorv = data.width or 1, data.style or "solid", data.color

		local stroke = object:FindFirstChild("UIStroke") or Instance.new("UIStroke")
		stroke.Thickness = width
		if colorv then
			stroke.Color = color(colorv)
		end
		stroke.Parent = object
		return { stroke }
	end,

	placeholder = function(object: TextBox, text)
		object.PlaceholderText = text
	end,

	selectable = function(object: GuiObject, bool)
		object.Selectable = bool
	end,
}

methods.lowerzindex = function(guiobject: GuiObject)
	if guiobject.ZIndex > 0 then
		guiobject.ZIndex = guiobject.ZIndex - 1
	end
end

methods.background = function(object: GuiObject, data)
	if typeof(data) == "Color3" or type(data) == "string" then
		methods.groundcolor(object, data)
	elseif type(data) == "table" then
		if data.color then
			methods.groundcolor(object, data.color)
		end
		if data.transparency then
			object.BackgroundTransparency = data.transparency
		end
		if data.image then
			methods.image(object, data.image)
		end
	end
end

methods.raisezindex = function(guiobject: GuiObject)
	guiobject.ZIndex = guiobject.ZIndex + 1
end

methods.autoscalebased = function(guiobject: GuiObject, data)
	local padding, enum = data.Padding, data.Enum
	guiobject.Size = UDim2.fromScale(0, 0)
	guiobject.AutomaticSize = enum or Enum.AutomaticSize.XY
	methods.padding(guiobject, padding)
	return { padding }
end

methods.list = function(object: GuiObject, data)
	local vertical, horizontal, padding, filldirection, sortorder, horizontalflex, verticalflex

	if data == "horizontal" or data == "vertical" then
		vertical = "center"
		horizontal = "center"
		padding = { 0, 5 }
		filldirection = data == "horizontal" and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	else
		vertical, horizontal, padding, filldirection, sortorder, horizontalflex, verticalflex =
			data[1], data[2], data[3], data[4], data[5], data[6], data[7]
	end

	if not vertical then
		vertical = "center"
	end
	if not horizontal then
		horizontal = "center"
	end
	if not padding then
		padding = { 0, 5 }
	end
	if not filldirection then
		filldirection = Enum.FillDirection.Vertical
	end

	if not guard:isInstance(object) then
		return "Object is not an Instance"
	end
	if not guard:isString(vertical) then
		return "Value is not a boolean"
	end
	if not guard:isString(horizontal) then
		return "Value is not a boolean"
	end

	local layout: UIListLayout = object:FindFirstChild("UIListLayout") or Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	vertical = vertical:lower()
	horizontal = horizontal:lower()

	if vertical == "top" then
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
	elseif vertical == "bottom" then
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	elseif vertical == "center" then
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
	end
	if horizontal == "left" then
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	elseif horizontal == "right" then
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	elseif horizontal == "center" then
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	end
	if filldirection then
		layout.FillDirection = filldirection
	end

	layout.VerticalFlex = verticalflex or Enum.UIFlexAlignment.None
	layout.HorizontalFlex = horizontalflex or Enum.UIFlexAlignment.None
	layout.SortOrder = sortorder or Enum.SortOrder.LayoutOrder
	layout.Padding = padding and UDim.new(padding[1], padding[2]) or UDim.new()
	layout.Parent = object

	return { layout }
end

return methods
