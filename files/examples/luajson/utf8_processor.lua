local lpeg = require("lpeg")

local string = string

module("utf8_processor")

local function encode_utf(codepoint)
	if codepoint > 0x10FFFF then
		error("Codepoint > 10FFFF cannot be encoded")
	elseif codepoint > 0xFFFF then
		-- Surrogate pair needed
		codepoint = codepoint - 0x10000
		local first, second = codepoint / 0x0400 + 0xD800, codepoint % 0x0400 + 0xDC00
		return ("\\u%.4X\\u%.4X"):format(first, second)
	else
		return ("\\u%.4X"):format(codepoint)
	end
end

-- decode a two-byte UTF-8 sequence
local function f2 (s)
	local c1, c2 = string.byte(s, 1, 2)
	return encode_utf(c1 * 64 + c2 - 12416)
end

-- decode a three-byte UTF-8 sequence
local function f3 (s)
	local c1, c2, c3 = string.byte(s, 1, 3)
	return encode_utf((c1 * 64 + c2) * 64 + c3 - 925824)
end

-- decode a four-byte UTF-8 sequence
local function f4 (s)
	local c1, c2, c3, c4 = string.byte(s, 1, 4)
	return encode_utf(((c1 * 64 + c2) * 64 + c3) * 64 + c4 - 63447168)
end

local cont = lpeg.R("\128\191")   -- continuation byte

local utf8 = lpeg.R("\0\127") -- Do nothing here
	+ lpeg.R("\194\223") * cont / f2
	+ lpeg.R("\224\239") * cont * cont / f3
	+ lpeg.R("\240\244") * cont * cont * cont / f4

local utf8_decode_pattern = lpeg.Cs(utf8^0) * -1


function process(s)
	return utf8_decode_pattern:match(s)
end
