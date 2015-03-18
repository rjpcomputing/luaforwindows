local json = require("json")
local lunit = require("lunit")
local math = require("math")
local testutil = require("testutil")

local encode = json.encode
-- DECODE NOT 'local' due to requirement for testutil to access it
decode = json.decode.getDecoder(false)

module("lunit-calls", lunit.testcase, package.seeall)

function setup()
	-- Ensure that the decoder is reset
	_G["decode"] = json.decode.getDecoder(false)
end

local values = {
	0,
	1,
	0.2,
	"Hello",
	true,
	{hi=true},
	{1,2}
}

function test_identity()
	local function testFunction(capturedName, ...)
		assert_equal('call', capturedName)
		return (...)
	end
	local strict = {
		calls = { defs = {
			call = testFunction
		} }
	}
	local decode = json.decode.getDecoder(strict)
	for i, v in ipairs(values) do
		local str = "call(" .. encode(v) .. ")"
		local decoded = decode(str)
		if type(decoded) == 'table' then
			for k2, v2 in pairs(v) do
				assert_equal(v2, decoded[k2])
				decoded[k2] = nil
			end
			assert_nil(next(decoded))
		else
			assert_equal(v, decoded)
		end
	end
end

-- Test for a function that throws
function test_function_failure()
	local function testFunction(...)
		error("CANNOT CONTINUE")
	end
	local strict = {
		calls = { defs = {
			call = testFunction
		} }
	}
	local decode = json.decode.getDecoder(strict)
	for i, v in ipairs(values) do
		local str = "call(" .. encode(v) .. ")"
		assert_error(function()
			decode(str)
		end)
	end
end

-- Test for a function that is not a function
function test_not_a_function_fail()
	local notFunction = {
		0/0, 1/0, -1/0, 0, 1, "Hello", {}, coroutine.create(function() end)
	}
	for _, v in ipairs(notFunction) do
		assert_error(function()
			local strict = {
				calls = { defs = {
					call = v
				}, allowUndefined = false }
			}
			json.decode.getDecoder(strict)
		end)
	end
end

function test_not_permitted_fail()
	local strict = {
		calls = {
			defs = { call = false }
		}
	}
	local decoder = json.decode.getDecoder(strict)
	assert_error(function()
		decoder("call(1)")
	end)
end

function test_permitted()
	local strict = {
		calls = {
			defs = { call = true }
		}
	}
	local decoder = json.decode.getDecoder(strict)
	assert(decoder("call(1)").name == 'call')
end

function test_not_defined_fail()
	local decoder = json.decode.getDecoder({
		calls = {
			allowUndefined = false
		}
	})
	assert_error(function()
		decoder("call(1)")
	end)
end

function test_not_defined_succeed()
	local decoder = json.decode.getDecoder({
		calls = {
			allowUndefined = true
		}
	})
	assert(decoder("call(1)").name == 'call')
end

-- Test for a name that is not a string
function test_name_not_string()
	local notString = {
		true, false, 0/0, 1/0, -1/0, 0, 1, {}, function() end, coroutine.create(function() end)
	}
	for _, v in ipairs(notString) do
		assert_error(function()
			local defs = {
				[v] = function() end
			}
			local strict = {
				calls = { defs = defs }
			}
			json.decode.getDecoder(strict)
		end)
	end
end

-- Test for a name that is a string or a pattern
function test_name_matches_string_or_pattern()
	local matchedValues = {
		["mystring"] = "mystring",
		[lpeg.C(lpeg.P("m") * (lpeg.P("y") + lpeg.P("Y")) * "string")] = "mystring",
		[lpeg.C(lpeg.P("m") * (lpeg.P("y") + lpeg.P("Y")) * "string")] = "mYstring"
	}
	for pattern, value in pairs(matchedValues) do
		local matched = false
		local function mustBeCalled(capturedName, ...)
			assert_equal(value, capturedName)
			matched = true
		end
		matched = false
		local strict = {
			calls = { defs = {
				[pattern] = mustBeCalled
			} }
		}
		json.decode.getDecoder(strict)(value .. "(true)")
		assert_true(matched, "Value <" .. value .. "> did not match the given pattern")
	end
end
