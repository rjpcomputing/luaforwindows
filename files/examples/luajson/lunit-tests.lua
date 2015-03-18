local json = require("json")
local lunit = require("lunit")
local testutil = require("testutil")
-- DECODE NOT 'local' due to requirement for testutil to access it
decode = json.decode.getDecoder(false)

module("lunit-tests", lunit.testcase, package.seeall)

function setup()
	_G["decode"] = json.decode.getDecoder(false)
end

function test_array_empty()
	local ret = assert_table(decode("[]"))
	assert_equal(0, #ret)
	assert_nil(next(ret))
end

function test_array_trailComma_nostrict()
	local ret = assert_table(decode("[true,]"))
	assert_equal(true, ret[1])
	assert_nil(next(ret, 1))
	assert_equal(1, #ret)
end

function test_array_innerComma()
	assert_error(function()
		decode("[true,,true]")
	end)
end

function test_preprocess()
	assert_equal('"Hello"', json.encode(1, {preProcess = function() return "Hello" end}))
	assert_equal('-1', json.encode(1, {preProcess = function(x) return -x end}))
	assert_equal('-Infinity', json.encode(1/0, {preProcess = function(x) return -x end}))
end

local strictDecoder = json.decode.getDecoder(true)

local function buildStrictDecoder(f)
	return testutil.buildPatchedDecoder(f, strictDecoder)
end
local function buildFailedStrictDecoder(f)
	return testutil.buildFailedPatchedDecoder(f, strictDecoder)
end
-- SETUP CHECKS FOR SEQUENCE OF DECODERS
for k, v in pairs(_M) do
	if k:match("^test_") and not k:match("_gen$") then
		if k:match("_nostrict") then
			_M[k .. "_strict_gen"] = buildFailedStrictDecoder(v)
		else
			_M[k .. "_strict_gen"] = buildStrictDecoder(v)
		end
	end
end
