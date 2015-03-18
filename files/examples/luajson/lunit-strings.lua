local json = require("json")
local lunit = require("lunit")
local testutil = require("testutil")
local string= require("string")

local encode = json.encode
-- DECODE NOT 'local' due to requirement for testutil to access it
decode = json.decode.getDecoder(false)

local error = error

module("lunit-strings", lunit.testcase, package.seeall)

local function assert_table_equal(expect, t)
	if type(expect) ~= 'table' then
		return assert_equal(expect, t)
	end
	for k,v in pairs(expect) do
		if type(k) ~= 'string' and type(k) ~= 'number' and type(k) ~= 'boolean' then
			error("INVALID expected table key")
		end
		local found = t[k]
		if found == nil then
			fail(tostring(k) .. " not found but expected")
		end
		assert_table_equal(v, t[k])
	end
	for k,v in pairs(t) do
		if nil == expect[k] then
			fail(tostring(k) .. " found but not expected")
		end
	end
end

function setup()
	-- Ensure that the decoder is reset
	_G["decode"] = json.decode.getDecoder(false)
end

function test_strict_quotes()
	local opts = {
		strings = {
			strict_quotes = true
		}
	}
	assert_error(function()
		local decoder = json.decode.getDecoder(opts)
		decoder("'hello'")
	end)
	opts.strings.strict_quotes = false
	assert_equal("hello", json.decode.getDecoder(opts)("'hello'"))
	-- Quote test
	assert_equal("he'\"llo'", json.decode.getDecoder(opts)("'he\\'\"llo\\''"))

end

local utf16_matches = {
	-- 1-byte
	{ '"\\u0000"', string.char(0x00) },
	{ '"\\u007F"', string.char(0x7F) },
	-- 2-byte
	{ '"\\u0080"', string.char(0xC2, 0x80) },
	{ '"\\u00A2"', string.char(0xC2, 0xA2) },
	{ '"\\u07FF"', string.char(0xDF, 0xBF) },
	-- 3-byte
	{ '"\\u0800"', string.char(0xE0, 0xA0, 0x80) },
	{ '"\\u20AC"', string.char(0xE2, 0x82, 0xAC) },
	{ '"\\uFEFF"', string.char(0xEF, 0xBB, 0xBF) },
	{ '"\\uFFFF"', string.char(0xEF, 0xBF, 0xBF) },
	-- 4-byte - currently not handled
	--{ '"\\uD800\\uDC00"', string.char(0xF0, 0x90, 0x80, 0x80) },
	--{ '"\\uDBFF\\uDFFF"', string.char(0xF4, 0x8F, 0xBF, 0xBF) }

}

function test_utf16_decode()
	for i, v in ipairs(utf16_matches) do
		-- Test that the default \u decoder outputs UTF8
		local num = tostring(i) .. ' '
		assert_equal(num .. v[2], num .. json.decode(v[1]))
	end
end

local BOM = string.char(0xEF, 0xBB, 0xBF)
-- BOM skipping tests - here due to relation to UTF8/16
local BOM_skip_tests = {
	{ BOM .. '"x"', "x" },
	{ BOM .. '["\\uFFFF",true]', { string.char(0xEF, 0xBF, 0xBF), true } },
	-- Other uses of unicode spaces
}

function test_bom_skip()
	for i,v in ipairs(BOM_skip_tests) do
		assert_table_equal(v[2], json.decode(v[1]))
	end
end

-- Unicode whitespace codepoints gleaned from unicode.org
local WHITESPACES = {
	"\\u0009", -- \t
	"\\u000A", -- \n
	"\\u000B", -- \v
	"\\u000C", -- \f
	"\\u000D", -- \r
	"\\u0020", -- space
	"\\u0085",
	"\\u00A0",
	"\\u1680",
	"\\u180E",
	"\\u2000",
	"\\u2001",
	"\\u2002",
	"\\u2003",
	"\\u2004",
	"\\u2005",
	"\\u2006",
	"\\u2007",
	"\\u2008",
	"\\u2009",
	"\\u200A",
	"\\u200B", -- addition, zero-width space
	"\\u2028",
	"\\u2029",
	"\\u202F",
	"\\u205F",
	"\\u3000",
	"\\uFEFF" -- Zero-width non-breaking space (BOM)
}

local inject_ws_values = {
	"%WS%true",
	" %WS%'the%WS blob'  %WS%",
	"%WS%{ key: %WS%\"valueMan\",%WS% key2:%WS%4.4}",
	"%WS%false%WS%"
}
function test_whitespace_ignore()
	for _, ws in ipairs(WHITESPACES) do
		ws = json.decode('"' .. ws .. '"')
		for _, v in ipairs(inject_ws_values) do
			v = v:gsub("%%WS%%", ws)
			assert_true(nil ~= json.decode(v))
		end
	end
end

function test_u_encoding()
	local encoder = json.encode.getEncoder()
	local decoder = json.decode.getDecoder()
	for i = 0, 255 do
		local char = string.char(i)
		assert_equal(char, decoder(encoder(char)))
	end
end

function test_x_encoding()
	local encoder = json.encode.getEncoder({ strings = { xEncode = true } })
	local decoder = json.decode.getDecoder()
	for i = 0, 255 do
		local char = string.char(i)
		assert_equal(char, decoder(encoder(char)))
	end
end

local multibyte_encoding_values = {
	-- 2-byte
	{ '"\\u0080"', string.char(0xC2, 0x80) },
	{ '"\\u00A2"', string.char(0xC2, 0xA2) },
	{ '"\\u07FF"', string.char(0xDF, 0xBF) },
	-- 3-byte
	{ '"\\u0800"', string.char(0xE0, 0xA0, 0x80) },
	{ '"\\u20AC"', string.char(0xE2, 0x82, 0xAC) },
	{ '"\\uFEFF"', string.char(0xEF, 0xBB, 0xBF) },
	{ '"\\uFFFF"', string.char(0xEF, 0xBF, 0xBF) },
	-- 4-byte (surrogate pairs)
	{ '"\\uD800\\uDC00"', string.char(0xF0, 0x90, 0x80, 0x80) },
	{ '"\\uDBFF\\uDFFF"', string.char(0xF4, 0x8F, 0xBF, 0xBF) }
}

function test_custom_encoding()
	local function processor(s)
		return require("utf8_processor").process(s)
	end
	local encoder = json.encode.getEncoder({
		strings = {
			processor = processor
		}
	})
	for i, v in ipairs(multibyte_encoding_values) do
		local encoded = encoder(v[2])
		assert_equal(v[1], encoded, "Failed to encode value using custom encoder")
	end
end

function test_strict_decoding()
	local encoder = json.encode.getEncoder(json.encode.strict)
	local decoder = json.decode.getDecoder(json.decode.strict)
	for i = 0, 255 do
		local char = string.char(i)
		-- Must wrap character in array due to decoder strict-ness
		assert_equal(char, decoder(encoder({char}))[1])
	end
end
