local Instance = require("@Instance")
local signal = require("@Kinemium.signal")

local TweenService = Instance.new("TweenService")

local TweenCompleted = signal.new()

local activeTweens = {}

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function lerpVector3(a, b, t)
	return a:Lerp(b, t)
end

local defaultEasing = function(x)
	return x -- linear
end

local function newTween(object, info)
	local duration = info.Time or 1
	local props = info.Properties or {}
	local easing = info.Easing or defaultEasing

	local starts = {}
	for prop, target in pairs(props) do
		starts[prop] = object[prop]
	end

	local tween = {
		Object = object,
		Duration = duration,
		Elapsed = 0,
		Properties = props,
		Starts = starts,
		Easing = easing,
		Completed = signal.new(),
		Playing = false,
	}

	function tween:Play()
		if self.Playing then
			return
		end
		self.Playing = true
		activeTweens[self] = true
	end

	function tween:Cancel()
		if not self.Playing then
			return
		end
		self.Playing = false
		activeTweens[self] = nil
	end

	return tween
end

function TweenService:Create(object, info)
	return newTween(object, info)
end

TweenService.InitRenderer = function(renderer, renderer_signal)
	TweenService:SetProperties({
		Create = TweenService.Create,
		Completed = TweenCompleted,
	})

	renderer_signal:Connect(function(route, dt)
		if route ~= "Heartbeat" then
			return
		end

		for tween in pairs(activeTweens) do
			tween.Elapsed += dt

			local alpha = tween.Elapsed / tween.Duration
			if alpha > 1 then
				alpha = 1
			end

			alpha = tween.Easing(alpha)

			for prop, target in pairs(tween.Properties) do
				local start = tween.Starts[prop]

				if type(start) == "number" then
					tween.Object[prop] = lerp(start, target, alpha)
				else
					tween.Object[prop] = lerpVector3(start, target, alpha)
				end
			end

			if alpha >= 1 then
				activeTweens[tween] = nil
				tween.Playing = false
				tween.Completed:Fire()
				TweenCompleted:Fire(tween)
			end
		end
	end)
end

return TweenService
