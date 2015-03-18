--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local jsonutil = require("json.util")

local type = type
local pairs = pairs
local assert = assert

local table = require("table")
local math = require("math")
local table_concat = table.concat
local math_floor, math_modf = math.floor, math.modf

local util_merge = require("json.util").merge
local util_IsArray = require("json.util").IsArray

module("json.encode.array")

local defaultOptions = {
	isArray = util_IsArray
}

default = nil
strict = nil

--[[
	Utility function to determine whether a table is an array or not.
	Criteria for it being an array:
		* ExternalIsArray returns true (or false directly reports not-array)
		* If the table has an 'n' value that is an integer >= 1 then it
		  is an array... may result in false positives (should check some values
		  before it)
		* It is a contiguous list of values with zero string-based keys
]]
function isArray(val, options)
	local externalIsArray = options and options.isArray

	if externalIsArray then
		local ret = externalIsArray(val)
		if ret == true or ret == false then
			return ret
		end
	end
	-- Use the 'n' element if it's a number
	if type(val.n) == 'number' and math_floor(val.n) == val.n and val.n >= 1 then
		return true
	end
	local len = #val
	for k,v in pairs(val) do
		if type(k) ~= 'number' then
			return false
		end
		local _, decim = math_modf(k)
		if not (decim == 0 and 1<=k) then
			return false
		end
		if k > len then -- Use Lua's length as absolute determiner
			return false
		end
	end

	return true
end

--[[
	Cleanup function to unmark a value as in the encoding process and return
	trailing results
]]
local function unmarkAfterEncode(tab, state, ...)
	state.already_encoded[tab] = nil
	return ...
end
function getEncoder(options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	local function encodeArray(tab,  state)
		if not isArray(tab, options) then
			return false
		end
		-- Make sure this value hasn't been encoded yet
		state.check_unique(tab)
		local encode = state.encode
		local compositeEncoder = state.outputEncoder.composite
		local valueEncoder = [[
		for i = 1, (composite.n or #composite) do
			local val = composite[i]
			PUTINNER(i ~= 1)
			val = encode(val, state)
			val = val or ''
			if val then
				PUTVALUE(val)
			end
		end
		]]
		return unmarkAfterEncode(tab, state, compositeEncoder(valueEncoder, '[', ']', ',', tab, encode, state))
	end
	return { table = encodeArray }
end
