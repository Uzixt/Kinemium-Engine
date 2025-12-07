_ = [[ 
Created By		: @ImSnox
Version			: 3.0.2
Original Post	: https://devforum.roblox.com/t/new-ui-blur-fully-automatic/2402850

Any official module script contains the original post within it.
If the original post creator is not @ImSnox, then it is considered a counterfeit version and most likely contains a virus.
																																																																																																																																												]]

local module = {}

local Creator = require(script.Creator)

function module:ModifyFrame(frame: Frame, State, Parent)
	if State == "Blur" then
		local Creator = require(script.Creator)

		local background = Instance.new("Frame")
		background.Name = "Blur"
		background.Size = frame.Size
		background.Position = frame.Position
		background.AnchorPoint = frame.AnchorPoint
		background.BackgroundTransparency = 1
		background.Parent = Parent or frame.Parent

		local new = Creator.new(background, {
			Material = Enum.Material.Glass,
			Transparency = 0.7,
			Color = Color3.fromRGB(18, 18, 18),
		})

		new:SetEnabled(true)

		frame.Changed:Connect(function()
			background.Size = UDim2.fromOffset(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
			background.Position = frame.Position
			background.AnchorPoint = frame.AnchorPoint
			background.BackgroundTransparency = 1
			background.Parent = Parent or frame.Parent

			if background:IsA("CanvasGroup") then
				if background.GroupTransparency == 1 then
					new:SetEnabled(false)
				else
					new:SetEnabled(true)
				end
			end

			if background.Visible == false then
				new:SetEnabled(false)
			else
				new:SetEnabled(true)
			end
		end)

		frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			background.Size = UDim2.fromOffset(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
		end)

		frame:GetPropertyChangedSignal("Position"):Connect(function()
			background.Position = frame.Position
		end)

		frame.Destroying:Connect(function()
			background:Destroy()
			new:Destroy()
		end)
	end
end

return module
