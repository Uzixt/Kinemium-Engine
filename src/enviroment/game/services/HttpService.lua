local Instance = require("@Instance")
local signal = require("@Kinemium.signal")
local net = zune.net

local HttpService = Instance.new("HttpService")

HttpService.RequestStarted = signal.new()
HttpService.RequestFinished = signal.new()
HttpService.RequestFailed = signal.new()

local JSON = zune.serde.json

local function request(method, url, body, headers, opts)
	opts = opts or {}
	headers = headers or {}

	HttpService.RequestStarted:Fire({ Method = method, URL = url })

	local success, response = pcall(function()
		return net.http.request(url, {
			method = method,
			headers = headers,
			body = body,
			timeout = opts.Timeout,
			allow_redirects = opts.AllowRedirects,
		})
	end)

	if not success then
		HttpService.RequestFailed:Fire({ Method = method, URL = url, Error = response })
		print("HttpService Request Error: " .. tostring(response))
	end

	local res = {
		Body = response.body,
		StatusCode = response.status_code,
		StatusReason = response.status_reason,
		Headers = response.headers,
		Ok = response.ok,
	}

	HttpService.RequestFinished:Fire(res)
	return res
end

function HttpService:GetAsync(url, headers, opts)
	local res = request("GET", url, nil, headers, opts)
	return res.Body, res
end

function HttpService:PostAsync(url, body, headers, opts)
	local res = request("POST", url, body, headers, opts)
	return res.Body, res
end

function HttpService:JSONEncode(tbl)
	return JSON.encode(tbl)
end

function HttpService:JSONDecode(str)
	return JSON.decode(str)
end

return HttpService
