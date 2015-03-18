--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")

local util = require("json.decode.util")
local jsonutil = require("json.util")

local table_maxn = require("table").maxn

local unpack = unpack

module("json.decode.array")

-- Utility function to help manage slighly sparse arrays
local function processArray(array)
	local max_n = table_maxn(array)
	-- Only populate 'n' if it is necessary
	if #array ~= max_n then
		array.n = max_n
	end
	if jsonutil.InitArray then
		array = jsonutil.InitArray(array) or array
	end
	return array
end

local defaultOptions = {
	trailingComma = true
}

default = nil -- Let the buildCapture optimization take place
strict = {
	trailingComma = false
}

local function buildCapture(options, global_options, state)
	local ignored = global_options.ignored
	-- arrayItem == element
	local arrayItem = lpeg.V(util.types.VALUE)
	-- If match-time capture supported, use it to remove stack limit for JSON
	if lpeg.Cmt then
		arrayItem = lpeg.Cmt(lpeg.Cp(), function(str, i)
			-- Decode one value then return
			local END_MARKER = {}
			local pattern =
				-- Found empty segment
				#lpeg.P(']' * lpeg.Cc(END_MARKER) * lpeg.Cp())
				-- Found a value + captured, check for required , or ] + capture next pos
				+ state.VALUE_MATCH * #(lpeg.P(',') + lpeg.P(']')) * lpeg.Cp()
			local capture, i = pattern:match(str, i)
			if END_MARKER == capture then
				return i
			elseif (i == nil and capture == nil) then
				return false
			else
				return i, capture
			end
		end)
	end
	local arrayElements = lpeg.Ct(arrayItem * (ignored * lpeg.P(',') * ignored * arrayItem)^0 + 0) / processArray

	options = options and jsonutil.merge({}, defaultOptions, options) or defaultOptions
	local capture = lpeg.P("[")
	capture = capture * ignored
		* arrayElements * ignored
	if options.trailingComma then
		capture = capture * (lpeg.P(",") + 0) * ignored
	end
	capture = capture * lpeg.P("]")
	return capture
end

function register_types()
	util.register_type("ARRAY")
end

function load_types(options, global_options, grammar, state)
	local capture = buildCapture(options, global_options, state)
	local array_id = util.types.ARRAY
	grammar[array_id] = capture
	util.append_grammar_item(grammar, "VALUE", lpeg.V(array_id))
end
