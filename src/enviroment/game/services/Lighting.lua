local Instance = require("@Instance")
local Color3 = require("@Color3")
local Vector3 = require("@Vector3")

local Lighting = Instance.new("Lighting")

Lighting:SetProperties({
	Ambient = Color3.fromRGB(128, 128, 128), -- Now this will be 128/255 = 0.5
	Brightness = 2.0, -- Increase brightness multiplier
	ColorShift_Top = Color3.fromRGB(255, 255, 255),
	ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
	OutdoorAmbient = Color3.fromRGB(128, 128, 128),
	GlobalShadows = true,
	ClockTime = 14.0, -- Afternoon sun (higher in sky)
	GeographicLatitude = 0.0,
})

function Lighting:GetSunDirection()
	local time = self.ClockTime
	local latitude = math.rad(self.GeographicLatitude)
	local declination = math.rad(23.45 * math.sin(math.rad(360 * (284 + time * 15) / 365))) -- Approximate solar declination
	local hourAngle = math.rad(15 * (time - 12))

	local elevation = math.asin(
		math.sin(latitude) * math.sin(declination) + math.cos(latitude) * math.cos(declination) * math.cos(hourAngle)
	)
	local azimuth = math.atan2(
		math.sin(hourAngle),
		math.cos(hourAngle) * math.sin(latitude) - math.tan(declination) * math.cos(latitude)
	)

	return Vector3.new(
		math.cos(azimuth) * math.cos(elevation),
		math.sin(elevation),
		math.sin(azimuth) * math.cos(elevation)
	)
end

Lighting.InitRenderer = function(renderer, renderer_signal)
	renderer_signal:Connect(function(route, dt)
		if route == "RenderStepped" then
			local ambient = Lighting.Ambient
			local brightness = Lighting.Brightness
			renderer.SetShaderUniform(
				"Kinemium",
				"globalAmbient",
				{ ambient.R / 255, ambient.G / 255, ambient.B / 255 },
				4
			)
			renderer.SetShaderUniform("Kinemium", "brightness", brightness, 0)
		end
	end)
end

return Lighting
