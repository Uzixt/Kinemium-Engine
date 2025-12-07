-- script/src/printer.lua
local Printer = {}

--- Formats the current time as HH:MM:SS
---@return string
local function formatTime()
	local t = os.date("*t")
	return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

--- Logs a message with a specific level
---@param level string "INFO" | "WARN" | "ERROR"
---@param context string Context of the log
---@param message string The log message
---@param data any? Optional debug data
---@param enableLogs boolean? Whether to print the log (default true)
function Printer.log(level: string, context: string, message: string, data: any?, enableLogs: boolean?)
	enableLogs = enableLogs ~= false
	local timestamp = formatTime()
	local formatted = string.format("[%s][%s][%s] %s", timestamp, level, context, message)

	if enableLogs then
		if level == "ERROR" then
			warn(formatted)
		else
			print(formatted)
		end
		if data ~= nil then
			print("Debug data:", data)
		end
	end

	if level == "ERROR" then
		shared.LuaCSS.ErrorLogs = shared.LuaCSS.ErrorLogs or {}
		table.insert(shared.LuaCSS.ErrorLogs, {
			context = context,
			error = message,
			timestamp = os.clock(),
			data = data,
		})
	end
end

--- Logs an info message
---@param context string
---@param message string
---@param data any?
---@param enableLogs boolean?
function Printer.info(context: string, message: string, data: any?, enableLogs: boolean?)
	Printer.log("INFO", context, message, data, enableLogs)
end

--- Logs a warning message
---@param context string
---@param message string
---@param data any?
---@param enableLogs boolean?
function Printer.warn(context: string, message: string, data: any?, enableLogs: boolean?)
	Printer.log("WARN", context, message, data, enableLogs)
end

--- Logs an error message and stores it in shared.LuaCSS.ErrorLogs
---@param context string
---@param message string
---@param data any?
---@param enableLogs boolean?
function Printer.error(context: string, message: string, data: any?, enableLogs: boolean?)
	Printer.log("ERROR", context, message, data, enableLogs)
end

return Printer
