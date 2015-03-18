--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local tostring = tostring
local pairs, ipairs = pairs, ipairs
local next, type = next, type
local error = error

local util = require("json.decode.util")

local buildCall = require("json.util").buildCall

local getmetatable = getmetatable

module("json.decode.calls")

local defaultOptions = {
	defs = nil,
	-- By default, do not allow undefined calls to be de-serialized as call objects
	allowUndefined = false
}

-- No real default-option handling needed...
default = nil
strict = nil

local isPattern
if lpeg.type then
	function isPattern(value)
		return lpeg.type(value) == 'pattern'
	end
else
	local metaAdd = getmetatable(lpeg.P("")).__add
	function isPattern(value)
		return getmetatable(value).__add == metaAdd
	end
end

local function buildDefinedCaptures(argumentCapture, defs)
	local callCapture
	if not defs then return end
	for name, func in pairs(defs) do
		if type(name) ~= 'string' and not isPattern(name) then
			error("Invalid functionCalls name: " .. tostring(name) .. " not a string or LPEG pattern")
		end
		-- Allow boolean or function to match up w/ encoding permissions
		if type(func) ~= 'boolean' and type(func) ~= 'function' then
			error("Invalid functionCalls item: " .. name .. " not a function")
		end
		local nameCallCapture
		if type(name) == 'string' then
			nameCallCapture = lpeg.P(name .. "(") * lpeg.Cc(name)
		else
			-- Name matcher expected to produce a capture
			nameCallCapture = name * "("
		end
		-- Call func over nameCallCapture and value to permit function receiving name

		-- Process 'func' if it is not a function
		if type(func) == 'boolean' then
			local allowed = func
			func = function(name, ...)
				if not allowed then
					error("Function call on '" .. name .. "' not permitted")
				end
				return buildCall(name, ...)
			end
		else
			local inner_func = func
			func = function(...)
				return (inner_func(...))
			end
		end
		local newCapture = (nameCallCapture * argumentCapture) / func * ")"
		if not callCapture then
			callCapture = newCapture
		else
			callCapture = callCapture + newCapture
		end
	end
	return callCapture
end

local function buildCapture(options, global_options, state)
	if not options  -- No ops, don't bother to parse
		or not (options.defs and (nil ~= next(options.defs)) or options.allowUndefined) then
		return nil
	end
	-- Allow zero or more arguments separated by commas
	local value = lpeg.V(util.types.VALUE)
	if lpeg.Cmt then
		value = lpeg.Cmt(lpeg.Cp(), function(str, i)
			-- Decode one value then return
			local END_MARKER = {}
			local pattern =
				-- Found empty segment
				#lpeg.P(')' * lpeg.Cc(END_MARKER) * lpeg.Cp())
				-- Found a value + captured, check for required , or ) + capture next pos
				+ state.VALUE_MATCH * #(lpeg.P(',') + lpeg.P(')')) * lpeg.Cp()
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
	local argumentCapture = (value * (lpeg.P(",") *  value)^0) + 0
	local callCapture = buildDefinedCaptures(argumentCapture, options.defs)
	if options.allowUndefined then
		local function func(name, ...)
			return buildCall(name, ...)
		end
		-- Identifier-type-match
		local nameCallCapture = lpeg.C(util.identifier) * "("
		local newCapture = (nameCallCapture * argumentCapture) / func * ")"
		if not callCapture then
			callCapture = newCapture
		else
			callCapture = callCapture + newCapture
		end
	end
	return callCapture
end

function load_types(options, global_options, grammar, state)
	local capture = buildCapture(options, global_options, state)
	if capture then
		util.append_grammar_item(grammar, "VALUE", capture)
	end
end
