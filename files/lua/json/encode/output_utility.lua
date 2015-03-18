--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local setmetatable = setmetatable
local assert, loadstring = assert, loadstring

module("json.encode.output_utility")

-- Key == weak, if main key goes away, then cache cleared
local outputCache = setmetatable({}, {__mode = 'k'})
-- TODO: inner tables weak?

local function buildFunction(nextValues, innerValue, valueWriter, innerWriter)
	local putInner = ""
	if innerValue and innerWriter then
		-- Prepare the lua-string representation of the separator to put in between values
		local formattedInnerValue = ("%q"):format(innerValue)
		-- Fill in the condition %WRITE_INNER% and the %INNER_VALUE% to actually write
		putInner = innerWriter:gsub("%%WRITE_INNER%%", "%%1"):gsub("%%INNER_VALUE%%", formattedInnerValue)
	end
	-- Template-in the value writer (if present) and its conditional argument
	local functionCode = nextValues:gsub("PUTINNER(%b())", putInner)
	-- %VALUE% is to be filled in by the value-to-write
	valueWriter = valueWriter:gsub("%%VALUE%%", "%%1")
	-- Template-in the value writer with its argument
	functionCode = functionCode:gsub("PUTVALUE(%b())", valueWriter)
	functionCode = [[
		return function(composite, ret, encode, state)
	]] .. functionCode .. [[
		end
	]]
	return assert(loadstring(functionCode))()
end

function prepareEncoder(cacheKey, nextValues, innerValue, valueWriter, innerWriter)
	local cache = outputCache[cacheKey]
	if not cache then
		cache = {}
		outputCache[cacheKey] = cache
	end
	local fun = cache[nextValues]
	if not fun then
		fun = buildFunction(nextValues, innerValue, valueWriter, innerWriter)
		cache[nextValues] = fun
	end
	return fun
end
