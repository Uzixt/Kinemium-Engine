--[[

	AnimatedListLayout
	by ltsRealJr https://devforum.roblox.com/t/animatedlistlayout-a-custom-animated-uilistlayout/3557318
	
	Version: 0.0.1

	A dynamic and customizable UI layout system for Roblox. Supports Frames and ScrollingFrames,
	with smooth animations, UIScale integration, and automatic CanvasSize adjustment.
	
	API:
	
	--- Methods ---
	function AnimatedListLayout.new(Parent)
		Creates a new layout instance.

	function AnimatedListLayout:SetProperty(Property, Value)
		Sets a property of the layout.

	function AnimatedListLayout:GetProperty(Property)
		Returns the value of a property.

	function AnimatedListLayout:UpdateLayout(Animate)
		Updates the layout manually.

	function AnimatedListLayout:Destroy()
		Clears connections, stops animations, and destroys the layout.

	--- Properties ---
	property AnimatedListLayout.FillDirection
		> Horizontal, Vertical

	property AnimatedListLayout.HorizontalAlignment
		> Left, Center, Right

	property AnimatedListLayout.VerticalAlignment
		> Top, Center, Bottom

	property AnimatedListLayout.SortOrder
		> LayoutOrder, Name, ZIndex

	property AnimatedListLayout.AnimationEasingStyle
		> Linear, Sine, Back, Quad, Quart, Quint, Bounce, Elastic, Cubic, Exponential, Circular

	property AnimatedListLayout.AnimationEasingDirection
		> In, Out, InOut, OutIn

	property AnimatedListLayout.PaddingScale
		> number

	property AnimatedListLayout.PaddingOffset
		> number

	property AnimatedListLayout.StartXScale
		> number

	property AnimatedListLayout.StartXOffset
		> number

	property AnimatedListLayout.StartYScale
		> number

	property AnimatedListLayout.StartYOffset
		> number

	property AnimatedListLayout.AnimationEnabled
		> boolean

	property AnimatedListLayout.AnimationTime
		> number

	property AnimatedListLayout.AdaptiveAnimationSpeed
		> boolean

	property AnimatedListLayout.AutoCanvasSize
		> boolean

	property AnimatedListLayout.CanvasPaddingScale
		> number

	property AnimatedListLayout.CanvasPaddingOffset
		> number

	--- Events ---
	event AnimatedListLayout.PropertyChanged(Property)
		Fired when a property is changed.
		
	--- Usage ---
	MyLayout.FillDirection = "Vertical"
	MyLayout.HorizontalAlignment = "Center"
	MyLayout.VerticalAlignment = "Top"
	MyLayout.SortOrder = "LayoutOrder"
	MyLayout.PaddingScale = 0.1
	MyLayout.PaddingOffset = 20
	MyLayout.AnimationEnabled = true
	MyLayout.AnimationTime = 0.5
	MyLayout.AutoCanvasSize = true
--]]

-- [[ Services ]] --
local TweenService = game:GetService'TweenService'

-- [[ Variables ]] --
local AnimatedListLayout = {}
AnimatedListLayout.__index = AnimatedListLayout

local Properties = {
	FillDirection = true,
	HorizontalAlignment = true,
	VerticalAlignment = true,
	SortOrder = true,
	PaddingScale = true,
	PaddingOffset = true,
	StartXScale = true,
	StartXOffset = true,
	StartYScale = true,
	StartYOffset = true,
	AnimationEnabled = true,
	AnimationTime = true,
	AdaptiveAnimationSpeed = true,
	AnimationEasingStyle = true,
	AnimationEasingDirection = true,
	AutoCanvasSize = true,
	CanvasPaddingScale = true,
	CanvasPaddingOffset = true,
	AbsoluteContentSize = true,
	Padding = true,
	StartX = true,
	StartY = true,
	CanvasPadding = true,
	Name = 'AnimatedListLayout'
}

local OrigIndex = AnimatedListLayout.__index
AnimatedListLayout.__index = function(self, Key)
	if Properties[Key] then
		return self:GetProperty(Key)
	end
	return OrigIndex[Key]
end

AnimatedListLayout.__newindex = function(self, Key, Val)
	if Properties[Key] then
		self:SetProperty(Key, Val)
		return
	end
	rawset(self, Key, Val)
end

-- [[ Tables ]] --
local FillDirection = {
	Horizontal = 'Horizontal',
	Vertical = 'Vertical'
}

local HorizontalAlignment = {
	Left = 'Left',
	Center = 'Center',
	Right = 'Right'
}

local VerticalAlignment = {
	Top = 'Top',
	Center = 'Center',
	Bottom = 'Bottom'
}

local SortOrder = {
	LayoutOrder = 'LayoutOrder',
	Name = 'Name',
	ZIndex = 'ZIndex'
}

-- [[ Functions ]] --
function AnimatedListLayout.new(Parent)
	assert(Parent and Parent:IsA'GuiObject', 'AnimatedListLayout.new requires a GuiObject as parent')

	local self = setmetatable({}, AnimatedListLayout)

	self._Instance = Instance.new'Folder'
	self._Instance.Name = 'AnimatedListLayout'
	self._Instance.Parent = Parent

	self._Instance:SetAttribute('FillDirection', FillDirection.Vertical)
	self._Instance:SetAttribute('HorizontalAlignment', HorizontalAlignment.Left)
	self._Instance:SetAttribute('VerticalAlignment', VerticalAlignment.Top)
	self._Instance:SetAttribute('SortOrder', SortOrder.LayoutOrder)
	self._Instance:SetAttribute('PaddingScale', 0)
	self._Instance:SetAttribute('PaddingOffset', 0)
	self._Instance:SetAttribute('StartXScale', 0)
	self._Instance:SetAttribute('StartXOffset', 0)
	self._Instance:SetAttribute('StartYScale', 0)
	self._Instance:SetAttribute('StartYOffset', 0)
	self._Instance:SetAttribute('AnimationEnabled', true)
	self._Instance:SetAttribute('AnimationTime', 0.3)
	self._Instance:SetAttribute('AdaptiveAnimationSpeed', true)
	self._Instance:SetAttribute('AutoCanvasSize', true)
	self._Instance:SetAttribute('CanvasPaddingScale', 0)
	self._Instance:SetAttribute('CanvasPaddingOffset', 5)
	self._Instance:SetAttribute('AnimationEasingStyle', 'Quad')
	self._Instance:SetAttribute('AnimationEasingDirection', 'Out')
	self._Instance:SetAttribute('Name', 'AnimatedListLayout')

	self._AbsoluteContentSize = Vector2.new(0, 0)
	self._LastUpdateTime = tick()
	self._PrevScaleValues = {}
	self._ScaleChangeRates = {}
	self._PropertyChangedSignals = {}
	self._ChildPositions = {}
	self._ActiveTweens = {}
	self._Parent = Parent
	self._Connections = {}
	self._ScaleConnections = {}

	local Properties = {
		'FillDirection'; 'HorizontalAlignment'; 'VerticalAlignment'; 'SortOrder';
		'PaddingScale'; 'PaddingOffset'; 'StartXScale'; 'StartXOffset';
		'StartYScale'; 'StartYOffset'; 'AnimationEnabled'; 'AnimationTime';
		'AdaptiveAnimationSpeed'; 'AnimationEasingStyle'; 'AnimationEasingDirection';
		'AbsoluteContentSize'; 'AutoCanvasSize'; 'CanvasPaddingScale'; 'CanvasPaddingOffset'; 'Name'
	}

	for _, Property in Properties do
		self._PropertyChangedSignals[Property] = Instance.new'BindableEvent'
	end

	self._AttributeConnection = self._Instance.AttributeChanged:Connect(function(Attribute)
		if self._PropertyChangedSignals[Attribute] then
			self._PropertyChangedSignals[Attribute]:Fire(self._Instance:GetAttribute'Attribute')
			self:_UpdateLayout()
		end
	end)

	table.insert(self._Connections, Parent.ChildAdded:Connect(function(Child)
		self:_ConnectChild(Child)
		self:_UpdateLayout()
	end))

	table.insert(self._Connections, Parent.ChildRemoved:Connect(function(Child)
		if self._ActiveTweens[Child] then
			self._ActiveTweens[Child]:Cancel()
			self._ActiveTweens[Child] = nil
		end
		self._ChildPositions[Child] = nil
		self._PrevScaleValues[Child] = nil
		self._ScaleChangeRates[Child] = nil
		if self._ScaleConnections and self._ScaleConnections[Child] then
			for _, Conn in self._ScaleConnections[Child] do
				Conn:Disconnect()
			end
			self._ScaleConnections[Child] = nil
		end
		self:_UpdateLayout()
	end))

	table.insert(self._Connections, Parent:GetPropertyChangedSignal'AbsoluteSize':Connect(function()
		self:_UpdateLayout()
	end))

	for _, Child in Parent:GetChildren() do
		if Child:IsA'GuiObject' then
			self:_ConnectChild(Child)
		end
	end

	local SavedAnimState = self._Instance:GetAttribute'AnimationEnabled'
	self._Instance:SetAttribute('AnimationEnabled', false)
	self:_UpdateLayout()
	self._Instance:SetAttribute('AnimationEnabled', SavedAnimState)

	return self
end

function AnimatedListLayout:_ConnectChild(Child)
	if not Child:IsA'GuiObject' then return end

	self._PrevScaleValues[Child] = 1
	self._ScaleChangeRates[Child] = 0

	local Properties = {'Size', 'Visible', 'LayoutOrder', 'ZIndex'}
	for _, Property in ipairs(Properties) do
		local Connection = Child:GetPropertyChangedSignal(Property):Connect(function()
			self:_UpdateLayout()
		end)
		table.insert(self._Connections, Connection)
	end

	local AbsoluteSizeConnection = Child:GetPropertyChangedSignal'AbsoluteSize':Connect(function()
		self:_UpdateLayout()
	end)
	table.insert(self._Connections, AbsoluteSizeConnection)

	self._ScaleConnections[Child] = {}
	self:_ConnectUIScalesForChild(Child)

	local ChildAddedConnection = Child.ChildAdded:Connect(function(Descendant)
		if Descendant:IsA'UIScale' then
			self:_ConnectUIScale(Child, Descendant)
		end
	end)
	table.insert(self._ScaleConnections[Child], ChildAddedConnection)

	local ChildRemovedConnection = Child.ChildRemoved:Connect(function(Descendant)
		if Descendant:IsA'UIScale' then
			self:_UpdateLayout()
		end
	end)
	table.insert(self._ScaleConnections[Child], ChildRemovedConnection)
end

function AnimatedListLayout:_ConnectUIScalesForChild(Child)
	for _, Descendant in Child:GetDescendants() do
		if Descendant:IsA'UIScale' then
			self:_ConnectUIScale(Child, Descendant)
		end
	end

	local DescendantAddedConnection = Child.DescendantAdded:Connect(function(Descendant)
		if Descendant:IsA'UIScale' then
			self:_ConnectUIScale(Child, Descendant)
		end
	end)
	table.insert(self._ScaleConnections[Child], DescendantAddedConnection)

	local DescendantRemovedConnection = Child.DescendantRemoving:Connect(function(Descendant)
		if Descendant:IsA'UIScale' then
			self:_UpdateLayout()
		end
	end)
	table.insert(self._ScaleConnections[Child], DescendantRemovedConnection)
end

function AnimatedListLayout:_ConnectUIScale(Child, UIScale)
	local Connection

	Connection = UIScale:GetPropertyChangedSignal'Scale':Connect(function()
		self:_CalculateLayout()

		for C, NewPos in self._ChildPositions do
			if self._ActiveTweens[C] then
				self._ActiveTweens[C]:Cancel()
				self._ActiveTweens[C] = nil
				self:_AnimateToPosition(C, NewPos)
			else
				C.Position = NewPos
			end
		end

		local CurrentTime = tick()
		local DeltaTime = CurrentTime - self._LastUpdateTime
		if DeltaTime > 0 then
			local CurrentScale = UIScale.Scale
			local PrevScale = self._PrevScaleValues[Child] or CurrentScale
			local ChangeRate = math.abs(CurrentScale - PrevScale) / DeltaTime
			self._ScaleChangeRates[Child] = ChangeRate
			self._PrevScaleValues[Child] = CurrentScale
			self._LastUpdateTime = CurrentTime
		end
	end)

	table.insert(self._ScaleConnections[Child], Connection)
end

function AnimatedListLayout:_GetAdaptiveAnimationTime(Child)
	return self:GetProperty'AnimationTime'
end

function AnimatedListLayout:_UpdateCanvasSize()
	local Parent = self._Parent
	if not Parent:IsA'ScrollingFrame' or not self:GetProperty'AutoCanvasSize' then return end

	local ContentSize = self._AbsoluteContentSize
	if ContentSize.X <= 0 or ContentSize.Y <= 0 then return end

	local StartX = self:GetProperty'StartX'
	local StartY = self:GetProperty'StartY'
	local StartXAbsolute = StartX.Scale * Parent.AbsoluteSize.X + StartX.Offset
	local StartYAbsolute = StartY.Scale * Parent.AbsoluteSize.Y + StartY.Offset

	local CanvasPadding = UDim.new(self:GetProperty'CanvasPaddingScale', self:GetProperty'CanvasPaddingOffset')
	local PaddingXAbsolute = CanvasPadding.Scale * Parent.AbsoluteSize.X + CanvasPadding.Offset
	local PaddingYAbsolute = CanvasPadding.Scale * Parent.AbsoluteSize.Y + CanvasPadding.Offset

	local FillDir = self:GetProperty'FillDirection'
	local CanvasSize = Parent.CanvasSize

	if FillDir == FillDirection.Vertical then
		local TotalHeight = ContentSize.Y + StartYAbsolute + (PaddingYAbsolute * 2)
		CanvasSize = UDim2.new(CanvasSize.X.Scale, CanvasSize.X.Offset, CanvasPadding.Scale, TotalHeight)
	else
		local TotalWidth = ContentSize.X + StartXAbsolute + (PaddingXAbsolute * 2)
		CanvasSize = UDim2.new(CanvasPadding.Scale, TotalWidth, CanvasSize.Y.Scale, CanvasSize.Y.Offset)
	end

	Parent.CanvasSize = CanvasSize
end

function AnimatedListLayout:GetProperty(Property)
	if Property == 'AbsoluteContentSize' then
		return self._AbsoluteContentSize
	elseif Property == 'Name' then
		return self._Instance:GetAttribute'Name'
	elseif Property == 'Padding' then
		return UDim.new(self._Instance:GetAttribute'PaddingScale', self._Instance:GetAttribute'PaddingOffset')
	elseif Property == 'StartX' then
		return UDim.new(self._Instance:GetAttribute'StartXScale', self._Instance:GetAttribute'StartXOffset')
	elseif Property == 'StartY' then
		return UDim.new(self._Instance:GetAttribute'StartYScale', self._Instance:GetAttribute'StartYOffset')
	elseif Property == 'CanvasPadding' then
		return UDim.new(self._Instance:GetAttribute'CanvasPaddingScale', self._Instance:GetAttribute'CanvasPaddingOffset')
	elseif Property == 'AnimationEasingStyle' then
		local StyleName = self._Instance:GetAttribute'AnimationEasingStyle'
		return Enum.EasingStyle[StyleName]
	elseif Property == 'AnimationEasingDirection' then
		local DirName = self._Instance:GetAttribute'AnimationEasingDirection'
		return Enum.EasingDirection[DirName]
	else
		local Value = self._Instance:GetAttribute(Property)
		if Value == nil then
			error('Invalid property: ' .. Property)
		end
		return Value
	end
end

function AnimatedListLayout:SetProperty(Property, Value)

	assert(Property ~= 'AbsoluteContentSize', 'AbsoluteContentSize is a read-only property')

	if Property == 'Padding' then
		assert(typeof(Value) == 'UDim', 'Padding must be a UDim value')
		self._Instance:SetAttribute('PaddingScale', Value.Scale)
		self._Instance:SetAttribute('PaddingOffset', Value.Offset)
		
	elseif Property == 'Name' then
		assert(typeof(Value) == 'string', 'Name must be a string')
		self._Instance:SetAttribute('Name', Value)
		self._Instance.Name = Value

	elseif Property == 'StartX' then
		assert(typeof(Value) == 'UDim', 'StartX must be a UDim value')
		self._Instance:SetAttribute('StartXScale', Value.Scale)
		self._Instance:SetAttribute('StartXOffset', Value.Offset)

	elseif Property == 'StartY' then
		assert(typeof(Value) == 'UDim', 'StartY must be a UDim value')
		self._Instance:SetAttribute('StartYScale', Value.Scale)
		self._Instance:SetAttribute('StartYOffset', Value.Offset)

	elseif Property == 'CanvasPadding' then
		assert(typeof(Value) == 'UDim', 'CanvasPadding must be a UDim value')
		self._Instance:SetAttribute('CanvasPaddingScale', Value.Scale)
		self._Instance:SetAttribute('CanvasPaddingOffset', Value.Offset)

	elseif Property == 'AnimationEasingStyle' then
		assert(typeof(Value) == 'EnumItem' and Value.EnumType == Enum.EasingStyle, 'AnimationEasingStyle must be an Enum.EasingStyle value')
		self._Instance:SetAttribute('AnimationEasingStyle', Value.Name)

	elseif Property == 'AnimationEasingDirection' then
		assert(typeof(Value) == 'EnumItem' and Value.EnumType == Enum.EasingDirection, 'AnimationEasingDirection must be an Enum.EasingDirection value')
		self._Instance:SetAttribute('AnimationEasingDirection', Value.Name)

	else
		if Property == 'FillDirection' then
			assert(FillDirection[Value] ~= nil, 'Invalid FillDirection value')

		elseif Property == 'HorizontalAlignment' then
			assert(HorizontalAlignment[Value] ~= nil, 'Invalid HorizontalAlignment value')

		elseif Property == 'VerticalAlignment' then
			assert(VerticalAlignment[Value] ~= nil, 'Invalid VerticalAlignment value')

		elseif Property == 'SortOrder' then
			assert(SortOrder[Value] ~= nil, 'Invalid SortOrder value')

		elseif Property == 'AnimationTime' then
			assert(typeof(Value) == 'number' and Value >= 0, 'AnimationTime must be a non-negative number')

		elseif Property == 'AnimationEnabled' or Property == 'AdaptiveAnimationSpeed' or Property == 'AutoCanvasSize' then
			assert(typeof(Value) == 'boolean', Property .. ' must be a boolean value')

		elseif Property == 'PaddingScale' or Property == 'PaddingOffset' or Property == 'StartXScale' or Property == 'StartXOffset' or Property == 'StartYScale' or Property == 'StartYOffset' or Property == 'CanvasPaddingScale' or Property == 'CanvasPaddingOffset' then
			assert(typeof(Value) == 'number', Property .. ' must be a number')

		end
		self._Instance:SetAttribute(Property, Value)
	end

end

function AnimatedListLayout:GetPropertyChangedSignal(Property)
	assert(self._PropertyChangedSignals[Property], 'Invalid property: ' .. Property)
	return self._PropertyChangedSignals[Property].Event
end

function AnimatedListLayout:_SortChildren(Children)
	local SortOrd = self:GetProperty'SortOrder'
	table.sort(Children, function(A, B)
		if SortOrd == SortOrder.LayoutOrder then
			return A.LayoutOrder < B.LayoutOrder
		elseif SortOrd == SortOrder.Name then
			return A.Name < B.Name
		elseif SortOrd == SortOrder.ZIndex then
			return A.ZIndex < B.ZIndex
		end
		return false
	end)
	return Children
end

function AnimatedListLayout:_GetChildSize(Child)
	if not Child.Visible then return Vector2.new(0, 0) end
	return Child.AbsoluteSize
end

function AnimatedListLayout:_AnimateToPosition(Child, TargetPosition)
	if self._ActiveTweens[Child] then
		self._ActiveTweens[Child]:Cancel()
		self._ActiveTweens[Child] = nil
	end

	local AnimTime = self:_GetAdaptiveAnimationTime(Child)
	local EasingStyle = self:GetProperty'AnimationEasingStyle'
	local EasingDirection = self:GetProperty'AnimationEasingDirection'

	local TweenInfo = TweenInfo.new(AnimTime, EasingStyle, EasingDirection)
	local Tween = TweenService:Create(Child, TweenInfo, {Position = TargetPosition})
	self._ActiveTweens[Child] = Tween
	Tween:Play()

	Tween.Completed:Connect(function()
		if self._ActiveTweens[Child] == Tween then
			self._ActiveTweens[Child] = nil
		end
	end)
end

function AnimatedListLayout:_UpdateLayout()
	self:_CalculateLayout()

	local AnimEnabled = self:GetProperty'AnimationEnabled'

	for Child, FinalPos in self._ChildPositions do
		if AnimEnabled and Child.Position ~= FinalPos then
			self:_AnimateToPosition(Child, FinalPos)
		else
			Child.Position = FinalPos
		end
	end

	self:_UpdateCanvasSize()
end

function AnimatedListLayout:UpdateLayout(Animate)
	local SavedAnimState = self._Instance:GetAttribute'AnimationEnabled'
	if Animate ~= nil then
		self._Instance:SetAttribute('AnimationEnabled', Animate)
	end
	self:_UpdateLayout()
	self._Instance:SetAttribute('AnimationEnabled', SavedAnimState)
end

function AnimatedListLayout:_CalculateLayout()
	local Parent = self._Parent
	if not Parent then self:Destroy(); return end

	local Children = {}
	for _, Child in Parent:GetChildren() do
		if Child:IsA('GuiObject') and Child ~= self._Instance then
			table.insert(Children, Child)
		end
	end

	Children = self:_SortChildren(Children)

	local FillDir = self:GetProperty('FillDirection')
	local HAlign = self:GetProperty('HorizontalAlignment')
	local VAlign = self:GetProperty('VerticalAlignment')
	local Padding = self:GetProperty('Padding')
	local StartX = self:GetProperty('StartX')
	local StartY = self:GetProperty('StartY')

	local PaddingAbsolute = Padding.Scale * Parent.AbsoluteSize.Y + Padding.Offset
	local StartXAbsolute = StartX.Scale * Parent.AbsoluteSize.X + StartX.Offset
	local StartYAbsolute = StartY.Scale * Parent.AbsoluteSize.Y + StartY.Offset

	local PositionX = StartXAbsolute
	local PositionY = StartYAbsolute
	local MaxCrossSize = 0
	local ContentSizeX, ContentSizeY = 0, 0

	self._ChildPositions = {}

	for _, Child in Children do
		if not Child.Visible then
			continue
		end

		local ChildSize = self:_GetChildSize(Child)
		local ChildPos = UDim2.new(0, 0, 0, 0)

		if FillDir == FillDirection.Vertical then
			ChildPos = UDim2.new(StartX.Scale, StartXAbsolute, 0, PositionY)
			PositionY = PositionY + ChildSize.Y + PaddingAbsolute
			MaxCrossSize = math.max(MaxCrossSize, ChildSize.X)
			ContentSizeY = PositionY - PaddingAbsolute - StartYAbsolute
			ContentSizeX = MaxCrossSize
		else
			ChildPos = UDim2.new(0, PositionX, StartY.Scale, StartYAbsolute)
			PositionX = PositionX + ChildSize.X + PaddingAbsolute
			MaxCrossSize = math.max(MaxCrossSize, ChildSize.Y)
			ContentSizeX = PositionX - PaddingAbsolute - StartXAbsolute
			ContentSizeY = MaxCrossSize
		end

		self._ChildPositions[Child] = ChildPos
	end

	local ContentSize = Vector2.new(ContentSizeX, ContentSizeY)
	self._AbsoluteContentSize = ContentSize
	self._PropertyChangedSignals.AbsoluteContentSize:Fire(ContentSize)

	for _, Child in Children do
		if not Child.Visible then
			continue
		end

		local ChildPos = self._ChildPositions[Child]
		if not ChildPos then continue end

		local ChildSize = self:_GetChildSize(Child)
		local FinalPos = UDim2.new(0, 0, 0, 0)

		if HAlign == HorizontalAlignment.Left then
			if FillDir == FillDirection.Vertical then
				FinalPos = UDim2.new(StartX.Scale, StartXAbsolute, ChildPos.Y.Scale, ChildPos.Y.Offset)
			else
				FinalPos = ChildPos
			end
		elseif HAlign == HorizontalAlignment.Center then
			if FillDir == FillDirection.Vertical then
				local Offset = StartXAbsolute + (Parent.AbsoluteSize.X - ChildSize.X - StartXAbsolute) / 2
				FinalPos = UDim2.new(0, Offset, ChildPos.Y.Scale, ChildPos.Y.Offset)
			else
				FinalPos = ChildPos
			end
		elseif HAlign == HorizontalAlignment.Right then
			if FillDir == FillDirection.Vertical then
				local Offset = Parent.AbsoluteSize.X - ChildSize.X
				FinalPos = UDim2.new(0, Offset, ChildPos.Y.Scale, ChildPos.Y.Offset)
			else
				FinalPos = ChildPos
			end
		end

		if FillDir == FillDirection.Vertical then
			FinalPos = UDim2.new(FinalPos.X.Scale, FinalPos.X.Offset, ChildPos.Y.Scale, ChildPos.Y.Offset)
		else
			if VAlign == VerticalAlignment.Top then
				FinalPos = UDim2.new(ChildPos.X.Scale, ChildPos.X.Offset, StartY.Scale, StartYAbsolute)
			elseif VAlign == VerticalAlignment.Center then
				local Offset = StartYAbsolute + (Parent.AbsoluteSize.Y - ChildSize.Y - StartYAbsolute) / 2
				FinalPos = UDim2.new(ChildPos.X.Scale, ChildPos.X.Offset, 0, Offset)
			elseif VAlign == VerticalAlignment.Bottom then
				local Offset = Parent.AbsoluteSize.Y - ChildSize.Y
				FinalPos = UDim2.new(ChildPos.X.Scale, ChildPos.X.Offset, 0, Offset)
			end
		end

		self._ChildPositions[Child] = FinalPos
	end
end

function AnimatedListLayout:GetInstance()
	return self._Instance
end

function AnimatedListLayout:CancelAnimations()
	for Child, Tween in self._ActiveTweens do
		Tween:Cancel()
	end
	self._ActiveTweens = {}
end

function AnimatedListLayout:Destroy()
	self:CancelAnimations()

	for _, Connection in self._Connections do
		Connection:Disconnect()
	end

	self._Connections = {}

	if self._AttributeConnection then
		self._AttributeConnection:Disconnect()
		self._AttributeConnection = nil
	end

	if self._ScaleConnections then
		for _, Connections in self._ScaleConnections do
			for _, Conn in Connections do
				Conn:Disconnect()
			end
		end
		self._ScaleConnections = {}
	end

	for _, Signal in self._PropertyChangedSignals do
		Signal:Destroy()
	end

	self._PropertyChangedSignals = {}
	self._ChildPositions = {}
	self._PrevScaleValues = {}
	self._ScaleChangeRates = {}

	if self._Instance then
		self._Instance:Destroy()
		self._Instance = nil
	end

	self._Parent = nil
end

return AnimatedListLayout