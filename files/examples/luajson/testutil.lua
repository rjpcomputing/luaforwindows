local pcall, error = pcall, error

local lunit = require("lunit")
local assert_error = lunit.assert_error

-- Allow module to alter decoder
local function setDecoder(d)
	decode = d
end
module("testutil", package.seeall)
function buildPatchedDecoder(f, newDecoder)
	return function()
		setDecoder(newDecoder)
		f()
	end
end
function buildFailedPatchedDecoder(f, newDecoder)
	return function()
		setDecoder(newDecoder)
		assert_error(f)
	end
end
