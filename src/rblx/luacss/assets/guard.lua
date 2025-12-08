-- @guard.lua

local guard = {}

function guard:isString(value)
	return typeof(value) == "string"
end
function guard:isInstance(value)
	return typeof(value) == "Instance"
end
function guard:isTable(value)
	return typeof(value) == "table"
end
function guard:isNumber(value)
	return typeof(value) == "number"
end
function guard:isVector3(value)
	return typeof(value) == "Vector3"
end
function guard:isCFrame(value)
	return typeof(value) == "CFrame"
end
function guard:isRay(value)
	return typeof(value) == "Ray"
end
function guard:isVector2(value)
	return typeof(value) == "Vector2"
end
function guard:isUDim2(value)
	return typeof(value) == "UDim2"
end
function guard:isUDim(value)
	return typeof(value) == "UDim"
end
function guard:isColor3(value)
	return typeof(value) == "Color3"
end
function guard:isBrickColor(value)
	return typeof(value) == "BrickColor"
end
function guard:isBoolean(value)
	return typeof(value) == "BrickColor"
end
function guard:isColorSequence(value)
	return typeof(value) == "ColorSequence"
end
function guard:isNumberSequence(value)
	return typeof(value) == "NumberSequence"
end
function guard:isPhysicalProperties(value)
	return typeof(value) == "PhysicalProperties"
end
function guard:isRect(value)
	return typeof(value) == "Rect"
end
function guard:isRegion3(value)
	return typeof(value) == "Region3"
end
function guard:isRegion3int16(value)
	return typeof(value) == "Region3int16"
end

return guard
