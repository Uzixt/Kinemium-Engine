local sandboxer = {}

local luau = zune.luau
local fs = zune.fs

sandboxer.enviroment = {}
sandboxer.native_code_gen = true

local function gsub(code)
	-- transform into kinemium compatible code
	code = string.gsub(code, "require", "krequire")
	code = string.gsub(code, "typeof", "ktypeof")
	return code
end

local function merge(v1, v2)
	for k, v in pairs(v2) do
		v1[k] = v
	end
	return v1
end

function sandboxer.run(code, chunk, env)
	local options = {
		env = env or sandboxer.enviroment,
		chunk_name = chunk,
		native_code_gen = sandboxer.native_code_gen,
	}

	local bytecode = luau.compile(code)
	local thread = luau.load(bytecode, options)

	return thread()
end

function sandboxer.rblxrequire(path: string, callbackScript)
	local file = fs.readFile(path)
	local result
	if file then
		print("Got file")
		local code = gsub(file)
		if code then
			print("Got code")
			print("Running")
			-- require implementation already added in enviroment, skip
			local object = callbackScript(code, path)

			print(sandboxer.enviroment.krequire)
			result = sandboxer.run(
				code,
				path,
				merge(sandboxer.enviroment, {
					script = object,
					kinemium = {
						import = sandboxer.enviroment.krequire,
						typeof = sandboxer.enviroment.ktypeof,
					},
				})
			)
		end
	end
	if result then
		return result
	end
	return
end

return sandboxer
