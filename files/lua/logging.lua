-------------------------------------------------------------------------------
-- includes a new tostring function that handles tables recursively
--
-- @author Danilo Tuler (tuler@ideais.com.br)
-- @author Andre Carregal (info@keplerproject.org)
-- @author Thiago Costa Ponte (thiago@ideais.com.br)
--
-- @copyright 2004-2011 Kepler Project
-------------------------------------------------------------------------------

local type, table, string, _tostring, tonumber = type, table, string, tostring, tonumber
local select = select
local error = error
local format = string.format

module("logging")

-- Meta information
_COPYRIGHT = "Copyright (C) 2004-2011 Kepler Project"
_DESCRIPTION = "A simple API to use logging features in Lua"
_VERSION = "LuaLogging 1.2.0"

-- The DEBUG Level designates fine-grained instring.formational events that are most
-- useful to debug an application
DEBUG = "DEBUG"

-- The INFO level designates instring.formational messages that highlight the
-- progress of the application at coarse-grained level
INFO = "INFO"

-- The WARN level designates potentially harmful situations
WARN = "WARN"

-- The ERROR level designates error events that might still allow the
-- application to continue running
ERROR = "ERROR"

-- The FATAL level designates very severe error events that will presumably
-- lead the application to abort
FATAL = "FATAL"

local LEVEL = {"DEBUG", "INFO", "WARN", "ERROR", "FATAL"}
local MAX_LEVELS = #LEVEL
-- make level names to order
for i=1,MAX_LEVELS do
	LEVEL[LEVEL[i]] = i
end

-- private log function, with support for formating a complex log message.
local function LOG_MSG(self, level, fmt, ...)
	local f_type = type(fmt)
	if f_type == 'string' then
		if select('#', ...) > 0 then
			return self:append(level, format(fmt, ...))
		else
			-- only a single string, no formating needed.
			return self:append(level, fmt)
		end
	elseif f_type == 'function' then
		-- fmt should be a callable function which returns the message to log
		return self:append(level, fmt(...))
	end
	-- fmt is not a string and not a function, just call tostring() on it.
	return self:append(level, tostring(fmt))
end

-- create the proxy functions for each log level.
local LEVEL_FUNCS = {}
for i=1,MAX_LEVELS do
	local level = LEVEL[i]
	LEVEL_FUNCS[i] = function(self, ...)
		-- no level checking needed here, this function will only be called if it's level is active.
		return LOG_MSG(self, level, ...)
	end
end

-- do nothing function for disabled levels.
local function disable_level() end

-- improved assertion funciton.
local function assert(exp, ...)
	-- if exp is true, we are finished so don't do any processing of the parameters
	if exp then return exp, ... end
	-- assertion failed, raise error
	error(format(...), 2)
end

-------------------------------------------------------------------------------
-- Creates a new logger object
-- @param append Function used by the logger to append a message with a
--	log-level to the log stream.
-- @return Table representing the new logger object.
-------------------------------------------------------------------------------
function new(append)

	if type(append) ~= "function" then
		return nil, "Appender must be a function."
	end

	local logger = {}
	logger.append = append

	logger.setLevel = function (self, level)
		local order = LEVEL[level]
		assert(order, "undefined level `%s'", _tostring(level))
		self.level = level
		self.level_order = order
		-- enable/disable levels
		for i=1,MAX_LEVELS do
			local name = LEVEL[i]:lower()
			if i >= order then
				self[name] = LEVEL_FUNCS[i]
			else
				self[name] = disable_level
			end
		end
	end

	-- generic log function.
	logger.log = function (self, level, ...)
		local order = LEVEL[level]
		assert(order, "undefined level `%s'", _tostring(level))
		if order < self.level_order then
			return
		end
		return LOG_MSG(self, level, ...)
	end

	-- initialize log level.
	logger:setLevel(DEBUG)
	return logger
end


-------------------------------------------------------------------------------
-- Prepares the log message
-------------------------------------------------------------------------------
function prepareLogMsg(pattern, dt, level, message)

    local logMsg = pattern or "%date %level %message\n"
    message = string.gsub(message, "%%", "%%%%")
    logMsg = string.gsub(logMsg, "%%date", dt)
    logMsg = string.gsub(logMsg, "%%level", level)
    logMsg = string.gsub(logMsg, "%%message", message)
    return logMsg
end


-------------------------------------------------------------------------------
-- Converts a Lua value to a string
--
-- Converts Table fields in alphabetical order
-------------------------------------------------------------------------------
function tostring(value)
  local str = ''

  if (type(value) ~= 'table') then
    if (type(value) == 'string') then
      str = string.format("%q", value)
    else
      str = _tostring(value)
    end
  else
    local auxTable = {}
    table.foreach(value, function(i, v)
      if (tonumber(i) ~= i) then
        table.insert(auxTable, i)
      else
        table.insert(auxTable, tostring(i))
      end
    end)
    table.sort(auxTable)

    str = str..'{'
    local separator = ""
    local entry = ""
    table.foreachi (auxTable, function (i, fieldName)
      if ((tonumber(fieldName)) and (tonumber(fieldName) > 0)) then
        entry = tostring(value[tonumber(fieldName)])
      else
        entry = fieldName.." = "..tostring(value[fieldName])
      end
      str = str..separator..entry
      separator = ", "
    end)
    str = str..'}'
  end
  return str
end
