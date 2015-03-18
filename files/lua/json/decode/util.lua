--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local select = select
local pairs, ipairs = pairs, ipairs
local tonumber = tonumber
local string_char = require("string").char
local rawset = rawset

local error = error
local setmetatable = setmetatable

module("json.decode.util")

-- 09, 0A, 0B, 0C, 0D, 20
ascii_space = lpeg.S("\t\n\v\f\r ")
do
	local chr = string_char
	local u_space = ascii_space
	-- \u0085 \u00A0
	u_space = u_space + lpeg.P(chr(0xC2)) * lpeg.S(chr(0x85) .. chr(0xA0))
	-- \u1680 \u180E
	u_space = u_space + lpeg.P(chr(0xE1)) * (lpeg.P(chr(0x9A, 0x80)) + chr(0xA0, 0x8E))
	-- \u2000 - \u200A, also 200B
	local spacing_end = ""
	for i = 0x80,0x8b do
		spacing_end = spacing_end .. chr(i)
	end
	-- \u2028 \u2029 \u202F
	spacing_end = spacing_end .. chr(0xA8) .. chr(0xA9) .. chr(0xAF)
	u_space = u_space + lpeg.P(chr(0xE2, 0x80)) * lpeg.S(spacing_end)
	-- \u205F
	u_space = u_space + lpeg.P(chr(0xE2, 0x81, 0x9F))
	-- \u3000
	u_space = u_space + lpeg.P(chr(0xE3, 0x80, 0x80))
	-- BOM \uFEFF
	u_space = u_space + lpeg.P(chr(0xEF, 0xBB, 0xBF))
	_M.unicode_space = u_space
end

identifier = lpeg.R("AZ","az","__") * lpeg.R("AZ","az", "__", "09") ^0

hex = lpeg.R("09","AF","af")
hexpair = hex * hex

comments = {
	cpp = lpeg.P("//") * (1 - lpeg.P("\n"))^0 * lpeg.P("\n"),
	c = lpeg.P("/*") * (1 - lpeg.P("*/"))^0 * lpeg.P("*/")
}

comment = comments.cpp + comments.c

ascii_ignored = (ascii_space + comment)^0

unicode_ignored = (unicode_space + comment)^0

local types = setmetatable({false}, {
	__index = function(self, k)
		error("Unknown type: " .. k)
	end
})

function register_type(name)
	types[#types + 1] = name
	types[name] = #types
	return #types
end

_M.types = types

function append_grammar_item(grammar, name, capture)
	local id = types[name]
	local original = grammar[id]
	if original then
		grammar[id] = original + capture
	else
		grammar[id] = capture
	end
end

-- Parse the lpeg version skipping patch-values
-- LPEG <= 0.7 have no version value... so 0.7 is value
DecimalLpegVersion = lpeg.version and tonumber(lpeg.version():match("^(%d+%.%d+)")) or 0.7

function get_invalid_character_info(input, index)
	local parsed = input:sub(1, index)
	local bad_character = input:sub(index, index)
	local _, line_number = parsed:gsub('\n',{})
	local last_line = parsed:match("\n([^\n]+.)$") or parsed
	return line_number, #last_line, bad_character, last_line
end

function setObjectKeyForceNumber(t, key, value)
	key = tonumber(key) or key
	return rawset(t, key, value)
end
