#!/usr/local/bin/lua5.1

---------------------------------------------------------------------
-- checks for a value and throw an error if it is invalid.
---------------------------------------------------------------------
function assert2 (expected, value, msg)
	if not msg then
		msg = ''
	else
		msg = msg..'\n'
	end
	return assert (value == expected,
		msg.."wrong value (["..tostring(value).."] instead of "..
		tostring(expected)..")")
end

---------------------------------------------------------------------
-- object test.
---------------------------------------------------------------------
local objmethods = { "close", "dostring", }
function test_object (obj)
	-- checking object type.
	assert2 (true, type(obj) == "userdata" or type(obj) == "table", "incorrect object type")
	-- trying to get metatable.
	assert2 ("You're not allowed to get the metatable of a Lua State",
		getmetatable(obj), "error permitting access to object's metatable")
	-- trying to set metatable.
	assert2 (false, pcall (setmetatable, S, {}))
	-- checking existence of object's methods.
	for i = 1, table.getn (objmethods) do
		local method = obj[objmethods[i]]
		assert2 ("function", type(method))
		assert2 (false, pcall (method), "no 'self' parameter accepted")
	end
	return obj
end

---------------------------------------------------------------------
---------------------------------------------------------------------
require"rings"

print(rings._VERSION)

S = test_object (rings.new())
S:dostring([[pcall(require, "luarocks.require")]])

-- How to handle errors on another Lua State?

assert2 (false, S:dostring"bla()")
assert2 (false, S:dostring"bla(")
assert2 (true, S:dostring"print'Hello World!'")
-- Checking returning value
io.write(".")
local ok, _x = S:dostring"return x"
assert2 (true, ok, "Error while returning a value ("..tostring(_x)..")")
assert2 (nil, _x, "Unexpected initialized variable (x = "..tostring(_x)..")")
-- setting a value
io.write(".")
assert2 (nil, x, "I need an unitialized varible to do the test!")
S:dostring"x = 1"
assert2 (nil, x, "Changing original Lua State instead of the new one!")
-- obtaining a value from the new state
io.write(".")
local ok, _x = S:dostring"return x"
assert2 (true, ok, "Error while returning a value ("..tostring(_x)..")")
assert2 (1, _x, "Unexpected initialized variable (x = "..tostring(_x)..")")

-- executing code in the master state from the new state
io.write(".")
global = 2
local ok, _x = S:dostring[[
	local ok, _x = remotedostring"return global"
	if not ok then
		error(_x)
	else
		return _x
	end
]]
assert2 (true, ok, "Unexpected error: "..tostring(_x).." (status == "..tostring(ok)..")")
assert2 (global, _x, "Unexpected error: "..tostring(_x).." (status == "..tostring(ok)..")")

-- new state obtaining data from the master state by using remotedostring
io.write(".")
f1 = function () return "funcao 1" end
f2 = function () return "funcao 2" end
f3 = function () return "funcao 3" end
data = {
	key1 = { f1, f2, f3, },
	key2 = { f3, f1, f2, },
}
local ok, k, i, f = S:dostring ([[
	require"math"
	require"os"
	math.randomseed(os.time())
	local key = "key"..math.random(2)
	local i = math.random(3)
	local ok, f = remotedostring("return data."..key.."["..i.."]()")
	return key, i, f
]], package.path)
assert2 (true, ok, "Unexpected error: "..k)
assert2 ("string", type(k), string.format ("Wrong #1 return value (expected string, got "..type(k)..")"))
assert2 ("number", type(i), string.format ("Wrong #2 return value (expected number, got "..type(i)..")"))
assert2 ("string", type(f), string.format ("Wrong #3 return value (expected string, got "..type(f)..")"))
assert2 (f, data[k][i](), "Wrong #3 return value")

-- Passing arguments and returning values
io.write(".")
local data = { 12, 13, 14, 15, }
local cmd = string.format ([[
local arg = { ... }
assert (type(arg) == "table")
assert (arg[1] == %d)
assert (arg[2] == %d)
assert (arg[3] == %d)
assert (arg[4] == %d)
assert (arg[5] == nil)
return unpack (arg)]], unpack (data))
local _data = { S:dostring(cmd, data[1], data[2], data[3], data[4]) }
assert2 (true, table.remove (_data, 1), "Unexpected error: "..tostring(_data[2]))
for i, v in ipairs (data) do
	assert2 (v, _data[i])
end

-- Transfering userdata
io.write(".")
local ok, f1, f2, f3 = S:dostring([[ return ..., io.stdout ]], io.stdout)
assert ((not f1) and (not f2), "Same file objects (io.stdout) in different states (user data objects were supposed not to be copyable")

-- Checking cache
io.write(".")
local chunk = [[return tostring(debug.getinfo(1,'f').func)]]
local ok, f1 = S:dostring(chunk)
local ok, f2 = S:dostring(chunk)
local ok, f3 = S:dostring([[return tostring (debug.getinfo(1,'f').func)]])
assert (f1 == f2, "Cache is not working")
assert (f1 ~= f3, "Function `dostring' is producing the same function for different strings")
assert (S:dostring"collectgarbage(); collectgarbage()")
local ok, f4 = S:dostring(chunk)
assert (f4 ~= f1, "Cache is not being collected")
local ok, f5 = S:dostring(chunk)
assert (f4 == f5, "Cache is not working")

-- Checking Stable
io.write(".")
assert (S:dostring[[require"stable"]])
assert (type(_state_persistent_table_) == "table", "Stable could not create persistent table")
assert (S:dostring[[stable.set("key", "value")]])
assert (_state_persistent_table_.key == "value", "Stable could not store a value")
assert (S:dostring[[assert(stable.get"key" == "value")]])

-- Closing new state
io.write(".")
S:close ()
assert2 (false, pcall (S.dostring, S, "print[[This won't work!]]"))
collectgarbage()
collectgarbage()

-- Checking Stable's persistent table
io.write(".")
local NS = test_object (rings.new())
assert (NS:dostring ([[
pcall(require, "luarocks.require")
package.path = ...
]], package.path))
assert (NS:dostring[[require"stable"]])
assert (type(_state_persistent_table_) == "table", "Stable persistent table was removed")
assert (_state_persistent_table_.key == "value", "Stable key vanished")
assert (NS:dostring[[assert(stable.get"key" == "value")]])

-- Checking remotedostring environment
S = rings.new({ a = 2, b = 3, assert = assert })
S:dostring([[pcall(require, "luarocks.require")]])

assert (S:dostring[[remotedostring[=[assert(a == 2)]=] ]])
assert (S:dostring[[remotedostring[=[assert(b == 3)]=] ]])
assert (S:dostring[[remotedostring[=[assert(print == nil)]=] ]])

-- Checking inherited environment

local env = { msg = "Hi!"}
local r = rings.new(env)
r:dostring([[pcall(require, "luarocks.require")]])
r:dostring([==[remotedostring([[assert(msg == "Hi!", "Environment failure")]])]==])

print"Ok!"
