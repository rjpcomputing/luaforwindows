local lunit = require("lunit")
local json = require("json")

module("lunit-depth", lunit.testcase, package.seeall)

local SAFE_DEPTH = 23
local SAFE_CALL_DEPTH = 31

function test_object_current_max_depth()
	local root = {}
	for i = 1, SAFE_DEPTH do
		root = { x = root }
	end
	local encoded = json.encode(root)
	json.decode(encoded)
end

function test_array_current_max_depth()
	local root = {}
	for i = 1, SAFE_DEPTH do
		root = { root }
	end
	local encoded = json.encode(root)
	json.decode(encoded)
end

function test_function_current_max_depth()
	local root = json.util.buildCall("deep")
	for i = 1, SAFE_CALL_DEPTH do
		root = json.util.buildCall("deep", root)
	end
	local encoded = json.encode(root)
	json.decode(encoded, { calls = { allowUndefined = true }})
end

if os.getenv("TEST_UNSAFE") then
	local UNSAFE_DEPTH = 194
	local UNSAFE_CALL_DEPTH = UNSAFE_DEPTH
	function test_object_unsafe_max_depth()
		local root = {}
		for i = 1, UNSAFE_DEPTH do
			root = { x = root }
		end
		local encoded = json.encode(root)
		json.decode(encoded)
	end

	function test_array_unsafe_max_depth()
		local root = {}
		for i = 1, UNSAFE_DEPTH do
			root = { root }
		end
		local encoded = json.encode(root)
		json.decode(encoded)
	end

	function test_function_unsafe_max_depth()
		local root = json.util.buildCall("deep")
		for i = 1, UNSAFE_CALL_DEPTH do
			root = json.util.buildCall("deep", root)
		end
		local encoded = json.encode(root)
		json.decode(encoded, { calls = { allowUndefined = true }})
	end

end
