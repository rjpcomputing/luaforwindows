--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local tostring = tostring
local assert = assert
local util = require("json.util")
local huge = require("math").huge

module("json.encode.number")

local defaultOptions = {
	nan = true,
	inf = true
}

default = nil -- Let the buildCapture optimization take place
strict = {
	nan = false,
	inf = false
}

local function encodeNumber(number, options)
	if number ~= number then
		assert(options.nan, "Invalid number: NaN not enabled")
		return "NaN"
	end
	if number == huge then
		assert(options.inf, "Invalid number: Infinity not enabled")
		return "Infinity"
	end
	if number == -huge then
		assert(options.inf, "Invalid number: Infinity not enabled")
		return "-Infinity"
	end
	return tostring(number)
end

function getEncoder(options)
	options = options and util.merge({}, defaultOptions, options) or defaultOptions
	return {
		number = function(number, state)
			return encodeNumber(number, options)
		end
	}
end
