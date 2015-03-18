--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local pairs = pairs
local assert = assert

local type = type
local tostring = tostring

local table_concat = require("table").concat
local util_merge = require("json.util").merge

module("json.encode.object")

local defaultOptions = {
}

default = nil
strict = nil

--[[
	Cleanup function to unmark a value as in the encoding process and return
	trailing results
]]
local function unmarkAfterEncode(tab, state, ...)
	state.already_encoded[tab] = nil
	return ...
end
--[[
	Encode a table as a JSON Object ( keys = strings, values = anything else )
]]
local function encodeTable(tab, options, state)
	-- Make sure this value hasn't been encoded yet
	state.check_unique(tab)
	local encode = state.encode
	local compositeEncoder = state.outputEncoder.composite
	local valueEncoder = [[
	local first = true
	for k, v in pairs(composite) do
		local ti = type(k)
		assert(ti == 'string' or ti == 'number' or ti == 'boolean', "Invalid object index type: " .. ti)
		local name = encode(tostring(k), state, true)
		if first then
			first = false
		else
			name = ',' .. name
		end
		PUTVALUE(name .. ':')
		local val = encode(v, state)
		val = val or ''
		if val then
			PUTVALUE(val)
		end
	end
	]]
	return unmarkAfterEncode(tab, state, compositeEncoder(valueEncoder, '{', '}', nil, tab, encode, state))
end

function getEncoder(options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	return {
		table = function(tab, state)
			return encodeTable(tab, options, state)
		end
	}
end
