local json = require("json")
local lunit = require("lunit")
local math = require("math")
local testutil = require("testutil")
local string = require("string")

local encode = json.encode
-- DECODE NOT 'local' due to requirement for testutil to access it
decode = json.decode.getDecoder(false)

module("lunit-numbers", lunit.testcase, package.seeall)

function setup()
	-- Ensure that the decoder is reset
	_G["decode"] = json.decode.getDecoder(false)
end

local function assert_near(expect, received)
	local pctDiff
	if expect == received then
		pctDiff = 0
	else
		pctDiff = math.abs(1 - expect / received)
	end
	local msg = ("expected '%s' but was '%s' .. '%s'%% apart"):format(expect, received, pctDiff * 100)
	assert(pctDiff < 0.000001, msg)
end
local function test_simple(num)
	assert_near(num, decode(tostring(num)))
end
local function test_simple_w_encode(num)
	assert_near(num, decode(encode(num)))
end
local function test_scientific(num)
	assert_near(num, decode(string.format('%e', num)))
	assert_near(num, decode(string.format('%E', num)))
end
local numbers = {
	0, 1, -1, math.pi, -math.pi
}
math.randomseed(0xDEADBEEF)
-- Add sequence of numbers at low/high end of value-set
for i = -300,300,60 do
	numbers[#numbers + 1] = math.random() * math.pow(10, i)
	numbers[#numbers + 1] = -math.random() * math.pow(10, i)
end

local function get_number_tester(f)
	return function ()
		for _, v in ipairs(numbers) do
			f(v)
		end
	end
end

test_simple_numbers = get_number_tester(test_simple)
test_simple_numbers_w_encode = get_number_tester(test_simple_w_encode)
test_simple_numbers_scientific = get_number_tester(test_scientific)

function test_infinite_nostrict()
	assert_equal(math.huge, decode("Infinity"))
	assert_equal(math.huge, decode("infinity"))
	assert_equal(-math.huge, decode("-Infinity"))
	assert_equal(-math.huge, decode("-infinity"))
end

function test_nan_nostrict()
	local value = decode("nan")
	assert_true(value ~= value)
	local value = decode("NaN")
	assert_true(value ~= value)
end

function test_expression()
	assert_error(function()
		decode("1 + 2")
	end)
end

-- For strict tests, small concession must be made to allow non-array/objects as root
local strict = json.util.merge({}, json.decode.strict, {initialObject = false})
local strictDecoder = json.decode.getDecoder(strict)

local numberValue = {hex = true}

local hex = {number = numberValue}
local hexDecoder = json.decode.getDecoder(hex)

function test_hex()
	if decode == hexDecoder then -- MUST SKIP FAIL UNTIL BETTER METHOD SETUP
		return
	end
	assert_error(function()
		decode("0x20")
	end)
end

local hexNumbers = {
	0xDEADBEEF,
	0xCAFEBABE,
	0x00000000,
	0xFFFFFFFF,
	0xCE,
	0x01
}

function test_hex_only()
	_G["decode"] = hexDecoder
	for _, v in ipairs(hexNumbers) do
		assert_equal(v, decode(("0x%x"):format(v)))
		assert_equal(v, decode(("0X%X"):format(v)))
		assert_equal(v, decode(("0x%X"):format(v)))
		assert_equal(v, decode(("0X%x"):format(v)))
	end
end

local decimal_hexes = {
	"0x0.1",
	"0x.1",
	"0x0e+1",
	"0x0E-1"
}
function test_no_decimal_hex_only()
	for _, str in ipairs(decimal_hexes) do
		assert_error(function()
			hexDecoder(str)
		end)
	end
end

function test_nearly_scientific_hex_only()
	assert_equal(0x00E1, hexDecoder("0x00e1"))
end

local function buildStrictDecoder(f)
	return testutil.buildPatchedDecoder(f, strictDecoder)
end
local function buildFailedStrictDecoder(f)
	return testutil.buildFailedPatchedDecoder(f, strictDecoder)
end
-- SETUP CHECKS FOR SEQUENCE OF DECODERS
for k, v in pairs(_M) do
	if k:match("^test_") and not k:match("_gen$") and not k:match("_only$") then
		if k:match("_nostrict") then
			_M[k .. "_strict_gen"] = buildFailedStrictDecoder(v)
		else
			_M[k .. "_strict_gen"] = buildStrictDecoder(v)
		end
		_M[k .. "_hex_gen"] = testutil.buildPatchedDecoder(v, hexDecoder)
	end
end
