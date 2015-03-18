--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local tostring = tostring

local assert = assert
local jsonutil = require("json.util")
local util_merge = require("json.util").merge
local type = type

module("json.encode.others")

-- Shortcut that works
encodeBoolean = tostring

local defaultOptions = {
	allowUndefined = true,
	null = jsonutil.null,
	undefined = jsonutil.undefined
}

default = nil -- Let the buildCapture optimization take place
strict = {
	allowUndefined = false
}

function getEncoder(options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	local function encodeOthers(value, state)
		if value == options.null then
			return 'null'
		elseif value == options.undefined then
			assert(options.allowUndefined, "Invalid value: Unsupported 'Undefined' parameter")
			return 'undefined'
		else
			return false
		end
	end
	local function encodeBoolean(value, state)
		return value and 'true' or 'false'
	end
	local nullType = type(options.null)
	local undefinedType = options.undefined and type(options.undefined)
	-- Make sure that all of the types handled here are handled
	local ret = {
		boolean = encodeBoolean,
		['nil'] = function() return 'null' end,
		[nullType] = encodeOthers
	}
	if undefinedType then
		ret[undefinedType] = encodeOthers
	end
	return ret
end
