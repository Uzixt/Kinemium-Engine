local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(a0: InputObject, a1: boolean)
	print(a0)
end)
