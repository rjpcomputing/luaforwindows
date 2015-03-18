--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local type = type
local assert, error = assert, error
local getmetatable, setmetatable = getmetatable, setmetatable
local util = require("json.util")

local ipairs, pairs = ipairs, pairs
local require = require

local output = require("json.encode.output")

local util = require("json.util")
local util_merge, isCall = util.merge, util.isCall

module("json.encode")

--[[
	List of encoding modules to load.
	Loaded in sequence such that earlier encoders get priority when
	duplicate type-handlers exist.
]]
local modulesToLoad = {
	"strings",
	"number",
	"calls",
	"others",
	"array",
	"object"
}
-- Modules that have been loaded
local loadedModules = {}

-- Default configuration options to apply
local defaultOptions = {}
-- Configuration bases for client apps
default = nil
strict = {
	initialObject = true -- Require an object at the root
}

-- For each module, load it and its defaults
for _,name in ipairs(modulesToLoad) do
	local mod = require("json.encode." .. name)
	defaultOptions[name] = mod.default
	strict[name] = mod.strict
	loadedModules[name] = mod
end

-- Merges values, assumes all tables are arrays, inner values flattened, optionally constructing output
local function flattenOutput(out, values)
	out = not out and {} or type(out) == 'table' and out or {out}
	if type(values) == 'table' then
		for _, v in ipairs(values) do
			out[#out + 1] = v
		end
	else
		out[#out + 1] = values
	end
	return out
end

-- Prepares the encoding map from the already provided modules and new config
local function prepareEncodeMap(options)
	local map = {}
	for _, name in ipairs(modulesToLoad) do
		local encodermap = loadedModules[name].getEncoder(options[name])
		for valueType, encoderSet in pairs(encodermap) do
			map[valueType] = flattenOutput(map[valueType], encoderSet)
		end
	end
	return map
end

--[[
	Encode a value with a given encoding map and state
]]
local function encodeWithMap(value, map, state, isObjectKey)
	local t = type(value)
	local encoderList = assert(map[t], "Failed to encode value, unhandled type: " .. t)
	for _, encoder in ipairs(encoderList) do
		local ret = encoder(value, state, isObjectKey)
		if false ~= ret then
			return ret
		end
	end
	error("Failed to encode value, encoders for " .. t .. " deny encoding")
end


local function getBaseEncoder(options)
	local encoderMap = prepareEncodeMap(options)
	if options.preProcess then
		local preProcess = options.preProcess
		return function(value, state, isObjectKey)
			local ret = preProcess(value, isObjectKey or false)
			if nil ~= ret then
				value = ret
			end
			return encodeWithMap(value, encoderMap, state)
		end
	end
	return function(value, state, isObjectKey)
		return encodeWithMap(value, encoderMap, state)
	end
end
--[[
	Retreive an initial encoder instance based on provided options
	the initial encoder is responsible for initializing state
		State has at least these values configured: encode, check_unique, already_encoded
]]
function getEncoder(options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	local encode = getBaseEncoder(options)

	local function initialEncode(value)
		if options.initialObject then
			local errorMessage = "Invalid arguments: expects a JSON Object or Array at the root"
			assert(type(value) == 'table' and not isCall(value, options), errorMessage)
		end

		local alreadyEncoded = {}
		local function check_unique(value)
			assert(not alreadyEncoded[value], "Recursive encoding of value")
			alreadyEncoded[value] = true
		end

		local outputEncoder = options.output and options.output() or output.getDefault()
		local state = {
			encode = encode,
			check_unique = check_unique,
			already_encoded = alreadyEncoded, -- To unmark encoding when moving up stack
			outputEncoder = outputEncoder
		}
		local ret = encode(value, state)
		if nil ~= ret then
			return outputEncoder.simple and outputEncoder.simple(ret) or ret
		end
	end
	return initialEncode
end

-- CONSTRUCT STATE WITH FOLLOWING (at least)
--[[
	encoder
	check_unique -- used by inner encoders to make sure value is unique
	already_encoded -- used to unmark a value as unique
]]
function encode(data, options)
	return getEncoder(options)(data)
end

local mt = getmetatable(_M) or {}
mt.__call = function(self, ...)
	return encode(...)
end
setmetatable(_M, mt)
