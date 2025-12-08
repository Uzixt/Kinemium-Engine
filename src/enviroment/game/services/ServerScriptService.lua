local Instance = require("@Instance")
local Vector3 = require("@Vector3")
local ServerScriptService = Instance.new("ServerScriptService")

local allowed_to_render = {
	["Part"] = "Part",
	["MeshPart"] = "MeshPart",
	["BasePart"] = "BasePart",
}

ServerScriptService:SetProperties({
	LoadStringEnabled = false,
})

ServerScriptService.InitRenderer = function(renderer, signal)
	signal:Connect(function(route, data)
		if route == "PlayTest" then
			for _, child in pairs(ServerScriptService:GetChildren()) do
				if child.ClassName == "Script" then
					-- TODO: add run function for Scripts
					child:Run()
				end
			end
		end
	end)
end

return ServerScriptService
