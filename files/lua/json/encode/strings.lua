--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local string_char = require("string").char
local pairs = pairs

local util_merge = require("json.util").merge
module("json.encode.strings")

local normalEncodingMap = {
	['"'] = '\\"',
	['\\'] = '\\\\',
	['/'] = '\\/',
	['\b'] = '\\b',
	['\f'] = '\\f',
	['\n'] = '\\n',
	['\r'] = '\\r',
	['\t'] = '\\t',
	['\v'] = '\\v' -- not in official spec, on report, removing
}

local xEncodingMap = {}
for char, encoded in pairs(normalEncodingMap) do
	xEncodingMap[char] = encoded
end

-- Pre-encode the control characters to speed up encoding...
-- NOTE: UTF-8 may not work out right w/ JavaScript
-- JavaScript uses 2 bytes after a \u... yet UTF-8 is a
-- byte-stream encoding, not pairs of bytes (it does encode
-- some letters > 1 byte, but base case is 1)
for i = 0, 255 do
	local c = string_char(i)
	if c:match('[%z\1-\031\128-\255]') and not normalEncodingMap[c] then
		-- WARN: UTF8 specializes values >= 0x80 as parts of sequences...
		--       without \x encoding, do not allow encoding > 7F
		normalEncodingMap[c] = ('\\u%.4X'):format(i)
		xEncodingMap[c] = ('\\x%.2X'):format(i)
	end
end

local defaultOptions = {
	xEncode = false, -- Encode single-bytes as \xXX
	processor = nil, -- Simple processor for the string prior to quoting
	-- / is not required to be quoted but it helps with certain decoding
	-- Required encoded characters, " \, and 00-1F  (0 - 31)
	encodeSet = '\\"/%z\1-\031',
	encodeSetAppend = nil -- Chars to append to the default set
}

default = nil
strict = nil

function getEncoder(options)
	options = options and util_merge({}, defaultOptions, options) or defaultOptions
	local encodeSet = options.encodeSet
	if options.encodeSetAppend then
		encodeSet = encodeSet .. options.encodeSetAppend
	end
	local encodingMap = options.xEncode and xEncodingMap or normalEncodingMap
	local encodeString
	if options.processor then
		local processor = options.processor
		encodeString = function(s, state)
			return '"' .. processor(s:gsub('[' .. encodeSet .. ']', encodingMap)) .. '"'
		end
	else
		encodeString = function(s, state)
			return '"' .. s:gsub('[' .. encodeSet .. ']', encodingMap) .. '"'
		end
	end
	return {
		string = encodeString
	}
end
