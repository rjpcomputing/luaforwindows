-- we need to test all the different formats, at minimum
-- this means bimPpsuxz for now
-- Copyright � 2008 Ben "ToxicFrog" Kelly; see COPYING

-- test cases
-- simple: read and write of each format, seeks, endianness controls
-- complex: naming, tables, repetition, combinations of all of these,
--		nested tables, multi formats per string
-- non-obvious: seek past end of file
-- error handling: seek past start, read past end, invalid widths,
--		non-isomorphic input tables

local c = string.char
local require,math,ipairs,string,tostring,print,os,pairs
	= require,math,ipairs,string,tostring,print,os,pairs

module((...))
local struct = require(_NAME:match("^[^%.]+"))
local name = (...):gsub('%.[^%.]+$', '')

local function check_bm(m)
	m = m.m
	return m[8] and m[7] and m[6] and m[5]
	and m[4] and not m[3] and m[2] and not m[1]
end

local tests = {
	-- booleans
	{ raw = "\0\0\0\0\0\0\0\1"; format = "b8"; val = true; },
	{ raw = "\1\0\0\0\0\0\0\0"; format = "(b8)*1"; val = true; },
	{ raw = "\0\0\0\0\0\0\0\0"; format = "1*(b8)"; val = false; },
	-- signed integers
	{ raw = "\254\255\255"; format = "< i3"; val = -2; },
	-- unsigned integers
	{ raw = "\254\255\255"; format = "< u3"; val = 2^24-2; },
	-- bitmasks
	{ raw = "\250"; format = "{m:m1}"; test = check_bm; },
	-- fixed point
	{ raw = "\1\128"; format = "> P8.8"; val = 1.5; },
	{ raw = "\2\192"; format = "> p1.1"; val = 2.75; },
	-- plain strings
	{ raw = "foobar"; format = "s4"; val = "foob"; },
	-- counted strings
	{ raw = "\006\000\000\000foobar"; format = "< c4"; val = "foobar"; },
	-- null terminated strings
	{ raw = "foobar\0baz"; format = "z"; val = "foobar"; },
	{ raw = "foobar\0baz"; format = "z10"; val = "foobar"; },
	-- floats
	{ raw = c(0x00, 0x00, 0x00, 0x00); format = "< f4"; val = 0.0; },
	{ raw = c(0x3f, 0x80, 0x00, 0x00); format = "> f4"; val = 1.0; },
	{ raw = c(0x00, 0x00, 0x80, 0x3f); format = "< f4"; val = 1.0; },
	{ raw = c(0x00, 0x00, 0x80, 0xbf); format = "< f4"; val = -1.0; },
	{ raw = c(0x00, 0x00, 0x80, 0x7f); format = "< f4"; val = math.huge; },
	{ raw = c(0x00, 0x00, 0x80, 0xff); format = "< f4"; val = -math.huge; },
	{ raw = c(0x00, 0x00, 0xc0, 0x7f); format = "< f4"; val = 0/0; test = function(v) return v ~= v end },
	{ raw = c(0x00, 0x00, 0xc0, 0xff); format = "< f4"; val = 0/0; test = function(v) return v ~= v end },
	-- doubles
	{ raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00); format = "< f8"; val = 0.0; },
	{ raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x3f); format = "< f8"; val = 1.0; },
	{ raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xbf); format = "< f8"; val = -1.0; },
	{ raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0x7f); format = "< f8"; val = math.huge; },
	{ raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xff); format = "< f8"; val = -math.huge; },
	{ raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f); format = "< f8"; val = 0/0; test = function(v) return v ~= v end },
	{ raw = c(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0xff); format = "< f8"; val = 0/0; test = function(v) return v ~= v end },
}

function od(str)
	return str:gsub('.', function(c) return string.format("%02X ", c:byte()) end)
end

function check(test)
	local val, pass, raw
	local fmt = "%7.7s %42.42s%2.2s %17.17s %4.4s %3.3s"

	val = struct.unpack(test.format, test.raw)[1]
	pass = test.test
		and test.test(val)
		or val == test.val
	print(fmt:format(test.format, od(test.raw), "=>", tostring(val), pass and "PASS" or "FAIL", pass and "" or "!!!"):sub(1,79))
	if not pass then return end

	raw = struct.pack(test.format, {val})
	pass = raw == test.raw
	-- if we have a failure, it might be because there are multiple valid on-disk forms
	-- for example, a boolean can be any non-zero value, but we always write it back out as 1
	-- so, re-read it using the same format and see if it matches
	if not pass then
		local new_val = struct.unpack(test.format, raw)[1]
		pass = test.test and test.test(val) or new_val == test.val
	end
	print(fmt:format(test.format, od(raw), "<=", tostring(val), pass and "PASS" or "FAIL", pass and "" or " !!!"):sub(1,79))
end

for i,test in ipairs(tests) do
	check(test)
end

os.exit(0)
