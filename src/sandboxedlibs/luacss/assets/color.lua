local color3Cache = {}

export type ColorNames =
	"green"
	| "red"
	| "blue"
	| "black"
	| "white"
	| "yellow"
	| "orange"
	| "purple"
	| "pink"
	| "gray"
	| "cyan"
	| "teal"
	| "indigo"
	| "violet"
	| "lime"
	| "magenta"
	| "sky"
	-- Extra Shades
	| "darkred"
	| "maroon"
	| "crimson"
	| "rose"
	| "peach"
	| "coral"
	| "salmon"
	| "khaki"
	| "gold"
	| "bronze"
	| "brown"
	| "chocolate"
	| "olive"
	| "forest"
	| "seagreen"
	| "aqua"
	| "turquoise"
	| "navy"
	| "royalblue"
	| "midnight"
	| "steelblue"
	| "azure"
	| "ivory"
	| "beige"
	| "tan"
	| "sienna"
	| "silver"
	| "slate"
	| "charcoal"

export type ColorsMap = { [ColorNames]: Color3 }

return function(color)
	if typeof(color) == "Color3" then
		return color
	elseif type(color) == "string" then
		local main = {
			-- Basic
			green = Color3.fromRGB(0, 255, 0),
			red = Color3.fromRGB(255, 0, 0),
			blue = Color3.fromRGB(0, 0, 255),
			black = Color3.fromRGB(0, 0, 0),
			white = Color3.fromRGB(255, 255, 255),
			yellow = Color3.fromRGB(255, 255, 0),
			orange = Color3.fromRGB(255, 165, 0),
			purple = Color3.fromRGB(128, 0, 128),
			pink = Color3.fromRGB(255, 0, 255),
			gray = Color3.fromRGB(128, 128, 128),
			cyan = Color3.fromRGB(0, 170, 255),
			teal = Color3.fromRGB(0, 128, 128),
			indigo = Color3.fromRGB(75, 0, 130),
			violet = Color3.fromRGB(138, 43, 226),
			lime = Color3.fromRGB(50, 205, 50),
			magenta = Color3.fromRGB(255, 0, 170),
			sky = Color3.fromRGB(135, 206, 235),

			-- Extra Shades
			darkred = Color3.fromRGB(139, 0, 0),
			maroon = Color3.fromRGB(128, 0, 0),
			crimson = Color3.fromRGB(220, 20, 60),
			rose = Color3.fromRGB(255, 102, 204),
			peach = Color3.fromRGB(255, 218, 185),
			coral = Color3.fromRGB(255, 127, 80),
			salmon = Color3.fromRGB(250, 128, 114),
			khaki = Color3.fromRGB(240, 230, 140),
			gold = Color3.fromRGB(255, 215, 0),
			bronze = Color3.fromRGB(205, 127, 50),
			brown = Color3.fromRGB(139, 69, 19),
			chocolate = Color3.fromRGB(210, 105, 30),
			olive = Color3.fromRGB(128, 128, 0),
			forest = Color3.fromRGB(34, 139, 34),
			seagreen = Color3.fromRGB(46, 139, 87),
			aqua = Color3.fromRGB(0, 255, 255),
			turquoise = Color3.fromRGB(64, 224, 208),
			navy = Color3.fromRGB(0, 0, 128),
			royalblue = Color3.fromRGB(65, 105, 225),
			midnight = Color3.fromRGB(25, 25, 112),
			steelblue = Color3.fromRGB(70, 130, 180),
			azure = Color3.fromRGB(240, 255, 255),
			ivory = Color3.fromRGB(255, 255, 240),
			beige = Color3.fromRGB(245, 245, 220),
			tan = Color3.fromRGB(210, 180, 140),
			sienna = Color3.fromRGB(160, 82, 45),
			silver = Color3.fromRGB(192, 192, 192),
			slate = Color3.fromRGB(112, 128, 144),
			charcoal = Color3.fromRGB(54, 69, 79),
		}

		if string.find(color, "#") then
			return Color3.fromHex(color)
		else
			return main[string.lower(color)] or Color3.new(0, 0, 0)
		end
	end

	table.insert(color3Cache, color)

	return Color3.new(0, 0, 0)
end
