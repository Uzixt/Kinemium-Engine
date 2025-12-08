return function(item: TextButton, mouse: Mouse, color: Color3)
	local frame = Instance.new("Frame")
	local spring = require(script.Parent.spr)
	
	local ASX,ASY = item.AbsoluteSize.X, item.AbsoluteSize.Y
	local APX,APY = item.AbsolutePosition.X, item.AbsolutePosition.Y
	local MX,MY = mouse.X,mouse.Y
	local Pos = UDim2.new(0,MX-APX,0,MY-APY)
	
	item.ClipsDescendants = true
	
	frame.Name = "Ripple"
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.7
	frame.Position = Pos
	frame.Parent = item
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	
	spring.target(frame, 3, 5, {
		Size = UDim2.new(0, 200 + item.Size.X.Offset, 0, 200 + item.Size.X.Offset)
	})
	
	spring.target(frame, 3, 5, {
		BackgroundTransparency = 1
	})
	
	task.spawn(function() 
        repeat task.wait() until frame.BackgroundTransparency == 1
        frame:Destroy()
    end)
end