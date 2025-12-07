-- LuaCSS by devcell
-- Ported from roblox..
--!native
local luacss = {}
local functions = table.clone(require(script.assets.functions))
local spr = require(script.libs.spr)
local types = require(script.assets.Types)
local RegisteredComponents = {}
local Profiler = require(script.debug.profiler)
local colorModule = require(script.assets.color)
local guard = require(script.assets.guard)
local pages = require(script.assets.pages)
local sharedLib = require(script.assets.sharedlib)
local signal = require(script.signal)
local trove = require(script.libs.Trove)
local src = script.src
local value = require(src.value)
local profilerInstance = Profiler.new()
local enableLogs = false
local springSettings = { 2, 5 }

--> Printer
local printer = require(src.printer)
local log = printer.log
local error = printer.error
local warn = printer.warn

luacss.Enums = {}
luacss.Events = { Cache = {} }
luacss.methods = functions
luacss.Types = types
luacss.pages = pages
luacss._currentComputed = nil

luacss.value = function(v)
	return value.new(v, luacss)
end

local luacssShared = sharedLib.new("LuaCSS")
luacssShared:add("SignalEnv", signal())
luacssShared:add("Styles", {})
luacssShared:add("States", {})
luacssShared:add("OnClassCreatedEvents", {})
luacssShared:add("IdRegistry", {})
luacssShared:add("EnvValues", {})
luacssShared:add("EnvProperties", {})
luacssShared:add("EventStorage", {})
luacssShared:add("CustomClasses", {})
luacssShared:add("ErrorLogs", {})
luacssShared:add("EnvValueUsed", {})
luacssShared:add("Cleanup", {})
luacssShared:add("CreatedObjects", {})
luacssShared:add("ChangedEvents", {})
luacssShared:add("CreatedEnvs", {})
luacssShared:add("Themes", {})
luacssShared:add("Extensions", {})
luacss.extensions = luacssShared:get("Extensions")

--> Instances that are using Components..
-- they will get updated with the Component
luacssShared:add("ObjectsUsedComponents", {})

profilerInstance:StartAutoRecording()
luacssShared:add("Profiler", profilerInstance)

--> functions

local function runHook(eventName, ...)
	for _, ext in pairs(shared.LuaCSS.Extensions) do
		if ext.hooks and ext.hooks[eventName] then
			pcall(ext.hooks[eventName], luacss, ...)
		end
	end
end

local function setupComponentTracking(object, componentName, alreadymadeProps)
	shared.LuaCSS.ObjectsUsedComponents[object] = componentName

	local signalEnv = luacssShared:get("SignalEnv")
	local connection = signalEnv:Connect(function(receivedName, params: types.ComponentReplicateParams)
		if receivedName ~= componentName then
			return
		end
		if params.class ~= "Component" then
			return
		end

		luacss.edit(object, params.newProps)

		runHook("componentUpdate", componentName, params)

		if alreadymadeProps then
			alreadymadeProps.spawn = nil
			alreadymadeProps.class = nil

			luacss.edit(object, alreadymadeProps)
		end
	end)

	luacss.Events.Cache[object] = {
		compName = componentName,
		class = "Component",
		object = object,
		connection = connection,
	}

	runHook("afterSetupComponentTracking", object, componentName, luacss.Events.Cache[object])
end

local function resolveEnvValues(v)
	if type(v) == "table" then
		local newTable = {}
		for key, subValue in pairs(v) do
			newTable[key] = resolveEnvValues(subValue)
		end
		return newTable
	elseif luacss.EnvValueExists(v) then
		return luacss.getEnvValue(v)
	else
		return v
	end
end

local function processCustomFunction(object, property, value)
	if value == nil then
		return
	end

	local key = string.lower(property)
	local func = functions[key] or functions[property]

	local success, result = pcall(func, object, value)
	if not success then
		if enableLogs then
			if result == "attempt to call a nil value" then
				return
			end
			warn(`luacss: Error in custom function '{property}' → {result}`)
			warn("Debugging Data: " .. debug.traceback(result, 4))
		end
		table.insert(shared.LuaCSS.ErrorLogs, result)
		return nil
	end

	if typeof(result) == "RBXScriptConnection" then
		result = { result }
	elseif type(result) == "function" then
		result = { result() }
	elseif type(result) ~= "table" then
		result = { result }
	end

	for _, data in ipairs(shared.LuaCSS.EventStorage) do
		if data[1] == object and data[2] == property then
			data[3] = result
			return result
		end
	end

	runHook("ranCustomFunc", object, property, value)

	table.insert(shared.LuaCSS.EventStorage, { object, property, result })

	local cleanupConn
	cleanupConn = object.AncestryChanged:Connect(function(_, parent)
		if not parent then
			luacss:cleanevent(object, property)
			if cleanupConn then
				cleanupConn:Disconnect()
			end
		end
	end)

	return result
end

local function cleancache(data: any)
	local janitor = luacss:janitor()
	if type(data) == "table" then
		for i, v in pairs(data) do
			janitor:Add(v)
		end
	else
		janitor:Add(data)
	end
	janitor:Cleanup()
	janitor:Destroy()
end

local function cleanCustomFunctionEvent(object, property)
	local janitor = luacss:janitor()
	for i, data in pairs(shared.LuaCSS.EventStorage) do
		if data[1] == object and data[2] == property then
			local connections = data[3]

			for _, v in pairs(connections) do
				if typeof(v) == "RBXScriptConnection" and v.Disconnect then
					pcall(function()
						v:Disconnect()
					end)
				elseif typeof(v) == "Instance" and v.Destroy then
					pcall(function()
						v:Destroy()
					end)
				elseif type(v) == "function" then
					pcall(v)
				end
			end

			shared.LuaCSS.EventStorage[i] = nil
			break
		end
	end
	janitor:Cleanup()
	janitor:Destroy()
end

luacss.Enums.anchors = {
	TopLeft = { 0, 0 },
	TopCenter = { 0.5, 0 },
	TopRight = { 1, 0 },

	MiddleLeft = { 0, 0.5 },
	MiddleCenter = { 0.5, 0.5 },
	MiddleRight = { 1, 0.5 },

	BottomLeft = { 0, 1 },
	BottomCenter = { 0.5, 1 },
	BottomRight = { 1, 1 },
}

local function deprecate(name, replacement)
	warn(`LuaCSS: {name} is deprecated. Use {replacement} instead.`)
end
luacss.Events.getpos = function(anchorPoint: {})
	return UDim2.new(anchorPoint[1], 0, anchorPoint[2], 0)
end

local function ApplyProperties(object: Instance, properties: types.Object, logs: boolean?)
	local _spawnedChildren = {}

	if properties["spawn"] then
		local data = properties["spawn"]

		if type(data) == "table" then
			for i, v in pairs(data) do
				if type(v) == "table" then
					local child = luacss.compileObject(v)
					if child then
						child.Name = i
						child.Parent = object
						table.insert(_spawnedChildren, child)
					end
				elseif typeof(v) == "Instance" then
					v.Name = i
					v.Parent = object
				end
			end
		else
			warn(`LUACSS: Did you mean to put the instance inside a table? Property: spawn\nValue: {data}`)
		end
	end

	local function isPropertyKey(key, value)
		return type(value) ~= "function" and type(value) ~= "table" or key == "style"
	end

	if properties["style"] then
		local value: string | {} = properties["style"]
		local name
		local args

		if type(value) == "string" then
			name = value

			local result
			if RegisteredComponents[name] then
				if shared.LuaCSS.RegisteredComponents[name] then
					result = table.clone(shared.LuaCSS.RegisteredComponents[name])
					shared.LuaCSS.ObjectsUsedComponents[object] = value
				else
					result = table.clone(RegisteredComponents[name])
					shared.LuaCSS.ObjectsUsedComponents[object] = value
				end
			else
				result = shared.LuaCSS.Styles[name]
			end

			ApplyProperties(object, result)
		elseif type(value) == "table" then
			name = value[1]
			args = value[2]

			local result = {}

			if shared.LuaCSS.Styles[name] then
				result = table.clone(shared.LuaCSS.Styles[name])
			elseif shared.LuaCSS.RegisteredComponents[name] then
				if RegisteredComponents[name] then
					result = table.clone(RegisteredComponents[name])
					shared.LuaCSS.ObjectsUsedComponents[object] = name
				else
					result = table.clone(shared.LuaCSS.RegisteredComponents[name])
					shared.LuaCSS.ObjectsUsedComponents[object] = name
				end
			end

			if args then
				for property, v in pairs(args) do
					result[property] = v
				end
			end

			ApplyProperties(object, result)
		elseif typeof(value) == "Instance" then
			luacss.edit(object, luacss.fromInstance(value))
		end
	end

	if properties["id"] then
		shared.LuaCSS.IdRegistry[properties["id"]] = object
	end

	if properties["multistyle"] then
		local styles = properties["multistyle"]

		assert(typeof(styles) == "table", "multistyle must be a table of style names")

		for _, styleName in ipairs(styles) do
			local result
			if shared.LuaCSS.Styles[styleName] then
				result = table.clone(shared.LuaCSS.Styles[styleName])
			elseif shared.LuaCSS.RegisteredComponents[styleName] then
				result = table.clone(shared.LuaCSS.RegisteredComponents[styleName])
				shared.LuaCSS.ObjectsUsedComponents[object] = styleName
			elseif RegisteredComponents[styleName] then
				result = table.clone(RegisteredComponents[styleName])
				shared.LuaCSS.ObjectsUsedComponents[object] = styleName
			end

			if result then
				ApplyProperties(object, result)
			else
				warn(`[luacss] multistyle: style '{styleName}' not found`)
			end
		end
	end

	if properties["editChildren"] then
		for name: string, tble in pairs(properties["editChildren"]) do
			luacss.edit(object[name], tble)
		end
	end

	for property, value in pairs(properties) do
		luacss.ProcessPropertyValue(property, value, object, properties)
	end

	if properties["states"] then
		shared.LuaCSS.States[object] = properties["states"]
	end

	if properties["state"] then
		local state = properties["state"]

		local firstName
		local args

		if type(state) == "table" then
			firstName = state[1]
			args = table.unpack(state[2])
			shared.LuaCSS.States[object][firstName](object, args)
		elseif type(state) == "string" then
			shared.LuaCSS.States[object][state](object)
		end
	end

	if properties["_applytoall"] or properties["pta"] then
		local data = properties["_applytoall"] or properties["pta"]
		if type(data) == "table" then
			local descendants = object:GetDescendants()
			if #descendants > 100 then
				warn(`[luacss] _applytoall on {#descendants} objects may cause lag`)
			end
			for i, child in pairs(descendants) do
				luacss.edit(child, data)
			end
		end
	end

	if properties["editbody"] then
		for _, child in pairs(object:GetDescendants()) do
			if
				string.lower(object.Name) == "content"
				or string.lower(object.Name) == "body"
				or object.Name == "Body"
			then
				luacss.edit(child, properties["editbody"])
			end
		end
	end

	local ancestryConn
	ancestryConn = object.AncestryChanged:Connect(function(_, parent)
		if not parent then
			pcall(function()
				shared.LuaCSS.IdRegistry[properties["id"]] = nil
			end)
			pcall(function()
				shared.LuaCSS.States[object] = nil
			end)
			pcall(function()
				shared.LuaCSS.EnvValueUsed[object] = nil
			end)
			pcall(function()
				if luacss.Events.Cache[object] then
					luacss.ClearObjectComponentUpdates(object)
				end
			end)

			ancestryConn:Disconnect()
		end
	end)

	if shared.LuaCSS.ObjectsUsedComponents[object] then
		if not luacss.Events.Cache[object] then
			setupComponentTracking(object, shared.LuaCSS.ObjectsUsedComponents[object])
		end
	end

	return _spawnedChildren
end

--> Deprecated
luacss.anchors = setmetatable({}, {
	__index = function(_, key)
		deprecate("luacss.anchors", "the alignment property")
		return luacss.Enums.anchors[key]
	end,
})

luacss.getpos = function(anchorPoint: {})
	deprecate("luacss.anchors", "the alignment property")
	return luacss.Events.getpos(anchorPoint)
end

--> methods

--- Executes a callback with LuaCSS logging temporarily enabled.
---@param callback function The function to run while logs are enabled.
---@return any ... The return value(s) from the callback.
function luacss.withLogs(callback)
	local previousState = enableLogs
	enableLogs = true

	local success, result = pcall(callback)

	enableLogs = previousState

	if not success then
		error(result)
	end

	return result
end

function luacss.extension(extension: types.LuaCSSExtension)
	local result
	if type(extension) == "string" then
		if script.extensions[extension] then
			extension = script.extensions[extension]
		end
	end
	if extension.init then
		extension.init(luacss, extension)
	end
	if extension.name and shared.LuaCSS[extension.name] then
		return shared.LuaCSS[extension.name]
	end
	if typeof(extension) == "Instance" then
		if extension:IsA("ModuleScript") then
			local success, pcallResult = pcall(function(...)
				return require(extension)
			end)

			if not success then
				warn("Extension", "Tried to require extension; got result: " .. pcallResult)
				return
			end
			result = table.clone(pcallResult)
			extension = pcallResult
		end
	else
		result = table.clone(extension)
	end
	if not result then
		return
	end
	if extension.env then
		for property, value in pairs(extension.env) do
			local get = luacss.getEnvValueObject(property)
			if get then
				get.Set(value)
			else
				local new = luacss.addEnvValue(property, value)
				result.env[property] = new
			end
		end
	end

	if extension.handlers then
		for property, value in pairs(extension.handlers) do
			functions[property] = value
			result[property] = value
		end
	end

	if extension.components then
		for component, styleProperties in pairs(extension.components) do
			local newComponent = luacss.component(component, styleProperties)
			newComponent.makeGlobal()
			if newComponent then
				result.components[component] = newComponent
			end
		end
	end

	if extension.name then
		shared.LuaCSS.Extensions[extension.name] = result
	end
	return result
end

--- Clears any live updates from a component applied to an object
---
--- When an object is using a component, LuaCSS may connect signals to automatically
--- update that object whenever the component changes. This function disconnects
--- those signals and removes the object's cache entry, effectively "detaching" it
--- from the component.
---
--- @param object Instance The Roblox instance whose component updates should be cleared.
function luacss.ClearObjectComponentUpdates(object: Instance)
	-- Retrieve cached component data for this object
	local cacheProperties = luacss.Events.Cache[object]

	-- If there is no cache or it's not a table, nothing to do
	if type(cacheProperties) ~= "table" then
		return
	end

	-- Only clear if this cache belongs to a Component
	if cacheProperties and cacheProperties.class == "Component" then
		-- Disconnect the component's update signal
		if cacheProperties.connection then
			cacheProperties.connection:Disconnect()
		end

		-- Remove the cached entry to fully detach the object
		luacss.Events.Cache[object] = nil
	end
end

--- Registers a callback that runs whenever a class of the specified type is created.
---@param class string The class name to listen for.
---@param callback function The function to call when the class is created. Receives the new instance.
---@return function disconnect A function to call to remove this listener.
function luacss.onClassCreate(class: string, callback: () -> Instance)
	if not shared.LuaCSS.OnClassCreatedEvents[class] then
		shared.LuaCSS.OnClassCreatedEvents[class] = {}
	end

	table.insert(shared.LuaCSS.OnClassCreatedEvents[class], callback)

	return function()
		local events = shared.LuaCSS.OnClassCreatedEvents[class]
		if events then
			for i, cb in ipairs(events) do
				if cb == callback then
					table.remove(events, i)
					break
				end
			end
		end
	end
end

--- Enables LuaCSS debug logs globally.
function luacss.enableLogs()
	enableLogs = true
end

--- Processes a style or property value for a UI object, resolving dynamic values, functions, and environment links.
---@param property string The property name being processed.
---@param value any The value assigned to the property.
---@param object Instance The Roblox object to apply the value to.
---@param properties table The full property table being applied.
function luacss.ProcessPropertyValue(property, value, object, properties)
	local envValue = luacss.EnvValueExists(value)
	local mapped = resolveEnvValues(value)

	if envValue then
		pcall(function()
			processCustomFunction(object, property, mapped)
		end)

		pcall(function()
			object[property] = mapped
		end)

		pcall(function()
			if object[property] then
				if type(mapped) == "function" then
					object[property]:Connect(function()
						mapped(object)
					end)
				end
			end
		end)

		pcall(function()
			shared.LuaCSS.EnvProperties[property](object, mapped)
		end)

		local signalEnv = luacssShared:get("SignalEnv")
		if not shared.LuaCSS.CreatedEnvs[object] then
			shared.LuaCSS.CreatedEnvs[object] = {}
		end
		pcall(function()
			if shared.LuaCSS.CreatedEnvs[object][property] then
				shared.LuaCSS.CreatedEnvs[object][property]:Disconnect()
			end
		end)
		if object then
			shared.LuaCSS.CreatedEnvs[object][property] = signalEnv:Connect(
				function(name, newValue, params: types.PropertyReplicateParams?)
					if name ~= value then
						return
					end
					if name == "ComponentUpdate" then
						return
					end
					if enableLogs then
						log("INFO", "Enviroment Signal", `Got signal event: {name} -> {value}`, nil, enableLogs)
					end

					pcall(function()
						if shared.LuaCSS.Cleanup[property] then
							cleanCustomFunctionEvent(object, property)
						end
						local remains = processCustomFunction(object, property, newValue)
						shared.LuaCSS.Cleanup[property] = remains
					end)

					pcall(function()
						if object[property] then
							if type(value) == "function" then
								if shared.LuaCSS.Cleanup[property] then
									shared.LuaCSS.Cleanup[property]:Disconnect()
								end
								shared.LuaCSS.Cleanup[property] = object[property]:Connect(function()
									value(object)
								end)
							end
						end
					end)

					pcall(function()
						if params and params.UseSpring then
							luacss.spring(object, {
								[property] = newValue,
							})
						else
							object[property] = newValue
						end
					end)

					pcall(function()
						shared.LuaCSS.EnvProperties[property](object, newValue)
					end)

					runHook("propertyUpdate", object, property, newValue)
				end
			)
		end

		if not shared.LuaCSS.EnvValueUsed[object] then
			shared.LuaCSS.EnvValueUsed[object] = {}
		end
		shared.LuaCSS.EnvValueUsed[object][property] = value
	end

	if not envValue then
		local s, e = pcall(function()
			processCustomFunction(object, property, mapped)
		end)
		if not s then
			if enableLogs then
				if not string.find(e, "attempt to call a nil value") then
					local traceback = debug.traceback(e, 2)
					warn(
						"error_traceback",
						`Got error while trying to run custom method:\n{traceback}\nError: {e}\nProperty: {property}\nValue: {value}`
					)
				end
			end
		end

		pcall(function()
			if mapped then
				local result = mapped
				object[property] = result
			end
		end)

		pcall(function()
			if object[property] then
				if typeof(object[property]) == "RBXScriptSignal" and type(mapped) == "function" then
					object[property]:Connect(function(...)
						mapped(object, ...)
					end)
				end
			end
		end)

		pcall(function()
			shared.LuaCSS.EnvProperties[property](object, mapped)
		end)
	end
end

--- Runs a named state function on a given UI object, if defined.
---@param object Instance The target object.
---@param state string The name of the state to execute.
function luacss.state(object, state)
	return shared.LuaCSS.States[object][state](object)
end

--- Creates a wrapper around a registered object by its ID, providing convenient methods to edit, change, or destroy it.
---@param idName string The string ID of the object in `LuaCSS.IdRegistry`.
---@return table IdObject A table containing methods to manipulate the object:
---   `.Edit(properties)` → Applies properties to the object.
---   `.Change(newId)` → Changes the ID associated with the object.
---   `.Destroy()` → Destroys the object and removes it from the registry.
function luacss.IdObject(idName: string): types.IdObject
	assert(type(idName) == "string", "IdObject requires a string id")

	local methods = {}
	methods.Value = idName

	function methods:Edit(properties: types.Object): Instance
		local instance = shared.LuaCSS.IdRegistry[methods.Value]
		if not instance then
			warn(`[luacss] No instance found for id '{methods.Value}'`)
			return nil
		end
		return luacss.edit(instance, properties)
	end

	function methods:Change(newId: string)
		assert(type(newId) == "string", "Id must be a string")
		local instance = shared.LuaCSS.IdRegistry[methods.Value]
		if instance then
			shared.LuaCSS.IdRegistry[newId] = instance
			shared.LuaCSS.IdRegistry[methods.Value] = nil
			methods.Value = newId
		else
			warn(`[luacss] Cannot change id '{methods.Value}' → instance not found`)
		end
	end

	function methods:Destroy()
		local instance = shared.LuaCSS.IdRegistry[methods.Value]
		if instance then
			pcall(function()
				instance:Destroy()
			end)
			shared.LuaCSS.IdRegistry[self.Value] = nil
		end
	end

	return methods
end

--- Cleans up a specific custom function event for an object.
---@param object Instance The target object.
---@param customfunctionName string The property/custom function name to clean.
function luacss:cleanevent(object, customfunctionName: string)
	cleanCustomFunctionEvent(object, customfunctionName)
end

--- Cleans up cached resources and destroys a UI object.
---@param object Instance The object to clean and destroy.
function luacss.CleanupObject(object: Instance)
	cleancache(shared.LuaCSS.Cleanup[object])
	object:Destroy()
end

--- Creates a new Janitor for cleaning resources automatically.
---@return table janitor A new janitor instance.
function luacss:janitor()
	local janitor = require(script.libs.Janitor)
	return janitor.new()
end

--- Creates a scoped LuaCSS environment that auto-cleans applied changes.
---@return table scope A scoped object with methods:
---   `.compileObject(properties, logs)` → Creates a new object within the scope.
---   `.edit(obj, properties)` → Edits an object within the scope.
---   `.Cleanup()` → Cleans all resources in the scope.
---   `.Destroy()` → Cleans and destroys the scope.
function luacss.scope()
	local janitor = luacss:janitor()
	local scope = {}

	--- Creates a new UI element with the specified properties
	--- @param properties Object The properties to apply
	--- @param logs boolean? Whether to enable logging
	--- @return Instance, VirtualGuiObject, Object
	function scope.compileObject(properties: types.Object, logs: boolean?)
		local new, vobj, props = luacss.compileObject(properties, logs)
		janitor:Add(new)
		return new, vobj, props
	end

	--- Edits a UI element with the specified properties
	--- @param object Instance The instance to apply the properties to
	--- @param properties Object The properties to apply
	--- @return Instance
	function scope.edit(obj: Instance, properties: types.Object)
		local edited = luacss.edit(obj, properties)
		janitor:Add(edited)
		return edited
	end

	--- Cleans the scope
	--- @return nil
	function scope:Cleanup()
		janitor:Cleanup()
	end

	--- Destroys the scope
	--- @return nil
	function scope:Destroy()
		janitor:Destroy()
	end

	return scope
end
luacss.cleaner = luacss.scope

--- Reloads the styles, states, and the env properties.
--- @return nil
function luacss.reloadAll()
	for id, obj in pairs(shared.LuaCSS.IdRegistry) do
		local style = shared.LuaCSS.Styles[id] or shared.LuaCSS.RegisteredComponents[id]
		if style then
			luacss.edit(obj, style)
		end
	end

	for obj, states in pairs(shared.LuaCSS.States) do
		if obj.Parent then -- only valid objects
			luacss.edit(obj, { states = states })
		end
	end

	for key, callback in pairs(shared.LuaCSS.EnvProperties) do
		local envValue = shared.LuaCSS.EnvValues[key]
		if envValue and type(callback) == "function" then
			pcall(callback, shared.LuaCSS.LuaCSS.IdRegistry[key] or nil, envValue)
		end
	end
end

--- Sets the global spring animation settings for LuaCSS.
---@param damping number The spring damping value.
---@param frequency number The spring frequency value.
---@return table self Returns LuaCSS for method chaining.
function luacss.springSettings(damping, frequency)
	springSettings = { damping, frequency }
	return luacss
end

--- Returns the set Damping
--- @return number
function luacss.getDamping()
	return springSettings[1]
end

--- Returns the set Frequency
--- @return number
function luacss.getFrequency()
	return springSettings[2]
end

--- Applies spring animation to an object with current spring settings.
---@param obj Instance The target object.
---@param properties table A table of properties to animate.
function luacss.spring(obj, properties)
	spr.target(obj, luacss.getDamping(), luacss.getFrequency(), properties)
end

--- Converts different types (UDim2, Vector2, Vector3, CFrame, Color3, number, string) to a numeric table.
---@param any any The value to translate.
---@return table tble The numeric representation of the value.
function luacss.translate(any)
	local tble = {}

	if typeof(any) == "UDim2" then
		tble = { any.X.Scale, any.X.Offset, any.Y.Scale, any.Y.Offset }
	elseif typeof(any) == "table" then
		tble = any
	elseif typeof(any) == "Vector3" then
		tble = { any.X, any.Y, any.Z }
	elseif typeof(any) == "CFrame" then
		tble = { any:GetComponents() }
	elseif typeof(any) == "Color3" then
		tble = { any.R, any.G, any.B }
	elseif typeof(any) == "Vector2" then
		tble = { any.X, any.Y }
	elseif typeof(any) == "number" then
		tble = { any, 0, 0, 0 }
	elseif typeof(any) == "string" then
		tble = { any, 0, 0, 0 }
	else
		tble = { any, 0, 0, 0 }
	end
	return tble
end

--- Registers a new style under a given name.
---@param name string The style name.
---@param properties table A table of property-value pairs for the style.
---@return table The stored style table.
function luacss.style(name, properties: types.Object)
	if not guard:isTable(properties) then
		log("WARN", "Style", `Properties is not a table`, nil, enableLogs)
		return
	end
	shared.LuaCSS.Styles[name] = properties
	return shared.LuaCSS.Styles[name]
end

--- Retrieves the current value of an environment variable.
---@param name string The name of the environment value.
---@return any value The current value.
function luacss.getEnvValue(name)
	return shared.LuaCSS.EnvValues[name].Get()
end

--- Retrieves all environment values.
---@return table envValues A table mapping env names to their EnvValueObjects.
function luacss.getEnvValues()
	return shared.LuaCSS.EnvValues
end

--- Retrieves the full EnvValueObject for a given name.
---@param name string The environment value name.
---@return EnvValueObject? envObject The EnvValueObject or nil if not found.
function luacss.getEnvValueObject(name): types.EnvValueObject?
	local value = shared.LuaCSS.EnvValues[name]
	if value then
		return value
	else
		log("INFO", "EnvValueObject", `{name} not found`, nil, enableLogs)
	end
	return
end

--- Creates a theme object for managing multiple environment values.
---@param data table A dictionary of env names and initial values.
---@return ThemeObject theme The theme object with methods `.Set()`, `.SetProperty()`, `.Get()`, `.Remove()`, `.Reload()`.
function luacss.theme(name: string, data: { [string]: any })
	local themeObject = {}
	local created = {}
	local envNames = {}

	local isGlobal = false

	local changedEvent = shared.LuaCSS.ChangedEvents[name] or signal()
	if not shared.LuaCSS.ChangedEvents[name] then
		shared.LuaCSS.ChangedEvents[name] = signal()
	end

	for env_value_name, env_value_data in pairs(data) do
		local new = luacss.addEnvValue(env_value_name, env_value_data)
		new.Set(env_value_data)
		created[env_value_name] = new
		envNames[env_value_name] = env_value_data
	end

	function themeObject:Set(newData: { [string]: any })
		for name, envValue in pairs(created) do
			if newData[name] ~= nil then
				envValue.Set(newData[name])
				envNames[name] = newData[name]
			end
		end
		if isGlobal then
			shared.LuaCSS.Themes[name] = themeObject
		end
		changedEvent:Fire(newData)
	end

	function themeObject:Store(propName: string, newValue: any)
		envNames[propName] = newValue
		if isGlobal then
			shared.LuaCSS.Themes[name] = themeObject
		end
		changedEvent:Fire({ [propName] = newValue })
	end

	function themeObject:Get()
		local result = {}
		for name, _ in pairs(envNames) do
			result[name] = envNames[name]
		end
		return result
	end

	function themeObject:Remove()
		for name, envValue in pairs(created) do
			if envValue and envValue.Remove then
				envValue.Remove()
			end
			created[name] = nil
		end
		table.clear(envNames)
	end

	function themeObject:Evaluate()
		for env_value_name, env_value_data in pairs(envNames) do
			local existingEnv = luacss.getEnvValueObject(env_value_name)

			if existingEnv then
				print("buh!!!!!! " .. name)
				existingEnv.Set(env_value_data)
				created[env_value_name] = existingEnv
			else
				local new = luacss.addEnvValue(env_value_name, env_value_data)
				new.Set(env_value_data)
				created[env_value_name] = new
			end
		end
	end

	function themeObject:Reload()
		-- Reload all env values with this theme's stored values
		for name, storedValue in pairs(envNames) do
			local envValue = shared.LuaCSS.EnvValues[name]
			if envValue then
				envValue.Set(storedValue)
			end
		end
		changedEvent:Fire(self:Get())
	end

	function themeObject:SetGlobal()
		isGlobal = true
		shared.LuaCSS.Themes[name] = themeObject
	end

	themeObject.Data = data
	themeObject.Changed = changedEvent.Event
	themeObject.class = "LuaCSSTheme"

	return themeObject
end

--- Returns a theme.
---@param name string The theme name.
---@return boolean exists True if it exists, false otherwise.
function luacss.getTheme(name): types.ThemeObject
	return shared.LuaCSS.Themes[name]
end

--- Checks if an environment value exists.
---@param name string The environment value name.
---@return boolean exists True if it exists, false otherwise.
function luacss.EnvValueExists(name)
	local success, result = pcall(function()
		return shared.LuaCSS.EnvValues[name] ~= nil
	end)
	if success then
		return result
	else
		return false
	end
end

--- Returns performance metrics for LuaCSS operations.
---@return table metrics A table containing timing and count data.
function luacss.getPerformanceMetrics()
	return {
		compiledObjects = #shared.LuaCSS.CreatedObjects,
		activeEnvValues = #shared.LuaCSS.EnvValues,
		registeredComponents = #RegisteredComponents,
		eventConnections = #shared.LuaCSS.EventStorage,
		profilerData = profilerInstance:GetSummary(),
	}
end

--- Adds a new environment value to LuaCSS.
---@param name string The name of the environment value.
---@param value any The initial value.
---@return EnvValueObject env The created EnvValueObject.
function luacss.addEnvValue(name, value): types.EnvValueObject
	runHook("beforeEnvValueCreate", name, value)

	if enableLogs then
		log("INFO", "EnvValueObject", `Adding EnvValue '{name}' with initial data {tostring(value)}`, nil, enableLogs)
	end
	local changedEvent = shared.LuaCSS.ChangedEvents[name] or signal()
	if not shared.LuaCSS.ChangedEvents[name] then
		shared.LuaCSS.ChangedEvents[name] = signal()
	end

	local methods
	methods = {
		class = "EnvValueObject",
		name = name,

		ReplicateParams = {
			UseSpring = false,
		},

		Enabled = true,

		Set = function(new)
			if not shared.LuaCSS.EnvValues[name] then
				return
			end
			if shared.LuaCSS.EnvValues[name].Data ~= new then
				shared.LuaCSS.EnvValues[name].Data = new
				changedEvent:Fire(new)
				shared.LuaCSS.SignalEnv:Fire(name, new, methods.ReplicateParams)
				if enableLogs then
					log("INFO", "EnvValueObject", `Sent Signal to SignalENV: {name} -> {value}`, nil, enableLogs)
				end
			end
		end,

		Data = value,

		Changed = changedEvent,

		Get = function()
			return shared.LuaCSS.EnvValues[name].Data
		end,

		Remove = function()
			shared.LuaCSS.EnvValues[name] = nil
		end,
	}

	if name and value then
		methods.Set(value)
	end

	methods.Enable = function()
		shared.LuaCSS.EnvValues[name].Enabled = true
	end

	methods.Disable = function()
		shared.LuaCSS.EnvValues[name].Enabled = false
	end

	methods.Reload = function()
		shared.LuaCSS.SignalEnv:Fire(name, methods.Get())
	end

	if not shared.LuaCSS.EnvValues[name] then
		shared.LuaCSS.EnvValues[name] = methods
	end

	runHook("afterEnvValueCreate", shared.LuaCSS.EnvValues[name] or methods)

	return shared.LuaCSS.EnvValues[name] or methods
end

--- Returns all globally registered components.
---@return table components The registered global components.
function luacss.getGlobalComponents()
	return shared.LuaCSS.RegisteredComponents
end

--- Inverts a color.
---@param c Color3|string The color to invert or an environment key.
---@return Color3 inverted The inverted color.
function luacss.invertColor(c: Color3 | string)
	runHook("beforeInvert", c)

	if typeof(c) == "Color3" then
		runHook("afterInvert", c)

		return Color3.new(1 - c.R, 1 - c.G, 1 - c.B)
	elseif typeof(c) == "string" then
		local result = shared.LuaCSS.EnvValues[c]
		if result then
			runHook("afterInvert", c)

			return Color3.new(1 - result.R, 1 - result.G, 1 - result.B)
		end
	end
end

--- Adds a custom environment property key with optional callback.
---@param propertyName string The property name.
---@param prefix string A prefix to prepend to the key.
---@return table envKey The object with `.setCalled(callback)` and `.EditKey(newName)`.
function luacss.addEnvKey(propertyName: string, prefix: string)
	runHook("beforeEnvKeyCreate", propertyName, prefix)

	local key = `{prefix}{propertyName}`
	local result = {}
	local str = ""

	if shared.LuaCSS.EnvProperties[key] then
		shared.LuaCSS.EnvProperties[`{prefix}{key}`] = {}
		str = `{prefix}{key}`
	else
		shared.LuaCSS.EnvProperties[key] = {}
		str = key
	end

	function result:setCalled(callback: (any) -> ())
		shared.LuaCSS.EnvProperties[str] = callback
	end

	function result:EditKey(newName)
		shared.LuaCSS.EnvProperties[newName] = shared.LuaCSS.EnvProperties[str]
		shared.LuaCSS.EnvProperties[str] = nil
	end

	runHook("afterEnvKeyCreate", result)

	return result
end

--- Registers a new component or updates an existing one.
---@param name string The component name.
---@param data table|Instance The component properties table or instance to register.
---@return table componentObject The component wrapper with `.makeGlobal()`, `.Destroy()`, `.Reload()`, `.Inspect()`, `.Update()`, `.UpdatedEvent`, `.Value`.
function luacss.component(name, data: types.Object)
	runHook("beforeComponentCreate", name, data)

	if enableLogs then
		log("INFO", "Component", `Registering component {name}`, nil, enableLogs)
	end
	local result = {}

	if type(data) == "table" then
		RegisteredComponents[name] = data
		result = data
	elseif typeof(data) == "Instance" then
		if data:IsA("ModuleScript") then
			RegisteredComponents[name] = data
			result = data
		else
			local APIService = require(script.libs.APIService)
			local properties = APIService:GetProperties(data, true)

			properties.class = data.ClassName
			RegisteredComponents[name] = properties

			result = properties
		end
	end

	local componentUpdated = shared.LuaCSS.ChangedEvents[name] or signal()
	if not shared.LuaCSS.ChangedEvents[name] then
		shared.LuaCSS.ChangedEvents[name] = signal()
	end

	local componentObject
	componentObject = {
		class = "Component",
		makeGlobal = function()
			if not shared.LuaCSS.RegisteredComponents then
				shared.LuaCSS.RegisteredComponents = {}
			end
			shared.LuaCSS.RegisteredComponents[name] = result
		end,
		Destroy = function()
			if shared.LuaCSS.RegisteredComponents then
				shared.LuaCSS.RegisteredComponents[name] = nil
			end
			componentUpdated:Destroy()
			RegisteredComponents[name] = nil
			return nil
		end,
		Reload = function()
			if typeof(data) == "ModuleScript" then
				local newData = require(data)
				return componentObject.Update(newData)
			end
			printer.error("Component", `Update failed: invalid type for '{name}'`, nil, enableLogs)
			return
		end,
		Inspect = function()
			log("INFO", "Component", `Component '{name}':`, nil, enableLogs)
			print(RegisteredComponents[name])
			return RegisteredComponents[name]
		end,
		Update = function(newData)
			if typeof(newData) == "ModuleScript" then
				newData = require(newData)
			end

			if typeof(newData) == "Instance" then
				newData = luacss.fromInstance(newData)
			end

			if type(newData) ~= "table" then
				printer.error("Component", `Update failed: invalid type for '{name}'`, nil, enableLogs)
			end

			RegisteredComponents[name] = newData
			result = newData

			if shared.LuaCSS.RegisteredComponents then
				shared.LuaCSS.RegisteredComponents[name] = newData
			end

			local replicateParams: types.ComponentReplicateParams = {
				class = "Component",
				newProps = newData,
			}

			componentUpdated:Fire(result)
			shared.LuaCSS.SignalEnv:Fire(name, replicateParams)
		end,
		UpdatedEvent = componentUpdated.Event,
		Value = RegisteredComponents[name],
	}

	runHook("afterComponentCreate", componentObject)

	return componentObject
end

--- Returns the environment values used by LuaCSS objects.
---@return table stats A table of object->property->envValue mappings.
function luacss.GetStats()
	return luacssShared:get("EnvValueUsed")
end

--- Serializes a Roblox instance into a LuaCSS-compatible property table.
---@param object Instance The instance to serialize.
---@return table serialized The property table.
function luacss.fromInstance(object: Instance)
	local APIService = require(script.libs.APIService)
	local new = APIService:GetProperties(object, true)

	new.class = object.ClassName
	new.spawn = {}

	for _, child in pairs(object:GetChildren()) do
		local serialized = luacss.fromInstance(child)
		if serialized then
			new.spawn[child.Name] = serialized
		end
	end

	return new
end

--- Disconnects all cached signal connections in LuaCSS.
function luacss.Events.Cleanup()
	for _, conn in ipairs(luacss.Events.Cache) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(luacss.Events.Cache)
end

--- Applies a set of properties to a Roblox object.
---@param object Instance The target object.
---@param properties table The properties to apply.
---@return Instance object The same object for chaining.
function luacss.edit(object: Instance, properties: types.Object)
	runHook("beforeEdit", object, properties)

	ApplyProperties(object, properties)

	runHook("afterEdit", object, properties)

	return object :: GuiObject
end

--- Converts a color or string into a LuaCSS Color object.
---@param c Color3|string The color to convert.
---@return table colorObj The resulting Color object.
function luacss.color(c)
	runHook("getColorEvent", c)

	return colorModule(c)
end

--- Creates a new Roblox instance from a properties table and applies LuaCSS styles.
---@param properties table The properties including `.class`.
---@param logs boolean? Optional debug logging.
---@return Instance new The created instance.
---@return table virtualGuiObject A wrapper object with edit/utility methods.
---@return table properties The applied properties table.
function luacss.compileObject(properties: types.Object, logs: boolean?)
	if type(properties) ~= "table" then
		return
	end
	assert(properties.class, "Inputted data does not has class value")

	runHook("beforeCompile", properties)

	local new = Instance.new(properties.class)
	if properties["name"] then
		new.Name = properties["name"]
	end
	if properties["parent"] then
		new.Parent = properties.parent
	end

	for _, data in pairs(shared.LuaCSS.OnClassCreatedEvents) do
		if data.class == properties.class then
			data.callback(new)
		end
	end

	ApplyProperties(new, properties, logs)

	local virtualGuiObject = {}

	function virtualGuiObject:Edit(newProps: types.Object)
		return luacss.edit(new, newProps)
	end

	function virtualGuiObject:OverlapComponent(name)
		if RegisteredComponents[name] then
			ApplyProperties(new, RegisteredComponents[name])
		end

		if shared.LuaCSS.RegisteredComponents[name] then
			ApplyProperties(new, shared.LuaCSS.RegisteredComponents[name])
		end
	end

	function virtualGuiObject:SetAsComponent()
		return luacss.component(new.Name, new)
	end

	function virtualGuiObject.spawn(properties: types.Object)
		for i, v in pairs(properties) do
			local child = luacss.compileObject(v)
			if child then
				child.Name = i
				child.Parent = new
			end
		end
	end

	function virtualGuiObject:IsA(className)
		return new:IsA(className)
	end

	setmetatable(virtualGuiObject, {
		__index = function(_, key)
			local custom = rawget(virtualGuiObject, key)
			if custom ~= nil then
				return custom
			end
			return new[key]
		end,
		__newindex = function(_, key, value)
			new[key] = value
		end,
		__tostring = function()
			return tostring(new)
		end,
		__call = function(_, ...)
			return virtualGuiObject:Edit(...)
		end,
		__eq = function(_, other)
			return new == other or virtualGuiObject == other
		end,
	})

	runHook("afterCompile", new, virtualGuiObject)

	return new, virtualGuiObject, properties
end

--- Compiles a table of named LuaCSS objects, applying styles or creating new instances.
---@param data table<string, types.Object> A dictionary mapping names or conditions to property tables.
---@return table created A list of newly created instances.
function luacss.compile(data: { [string]: types.Object })
	runHook("beforeBatchCompile", data)

	local created = {}
	for name, properties: types.Object in pairs(data) do
		if string.find(name, " --> ") then
			local tble = string.split(name, " --> ")
			local property = tble[1]:gsub("^%s*(.-)%s*$", "%1") -- trim
			local valueStr = tble[2]:gsub("^%s*(.-)%s*$", "%1") -- trim

			local v
			if tonumber(valueStr) then
				v = tonumber(valueStr)
			elseif valueStr == "true" then
				v = true
			elseif valueStr == "false" then
				v = false
			else
				v = valueStr
			end

			for _, obj in pairs(game:GetDescendants()) do
				if obj:IsA("GuiObject") then
					if obj[property] == v then
						ApplyProperties(obj, properties)
					end
				end
			end
			continue
		end
		if shared.LuaCSS.IdRegistry[name] then
			local object = shared.LuaCSS.IdRegistry[name]
			ApplyProperties(object, properties)
			continue
		end
		local new = luacss.compileObject(properties)
		if new then
			new.Name = name
			table.insert(created, new)
		else
			continue
		end
	end

	runHook("afterBatchCompile", created)

	return created
end

export type LuaCSS = typeof(luacss)
return table.freeze(luacss)
