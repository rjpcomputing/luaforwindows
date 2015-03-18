#!/usr/local/bin/lua
-- See Copyright Notice in license.html

TOTAL_ROWS = 200

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
function test_object (obj, objmethods)
	-- checking object type.
	assert2 ("userdata", type(obj), "incorrect object type")
	-- trying to get metatable.
	assert2 ("LuaSQL: you're not allowed to get this metatable",
		getmetatable(obj), "error permitting access to object's metatable")
	-- trying to set metatable.
	assert2 (false, pcall (setmetatable, ENV, {}))
	-- checking existence of object's methods.
	for i = 1, table.getn (objmethods) do
		local method = objmethods[i]
		assert2 ("function", type(obj[method]))
	end
	return obj
end

ENV_OK = function (obj)
	return test_object (obj, { "close", "connect", })
end
CONN_OK = function (obj)
	return test_object (obj, { "close", "commit", "execute", "rollback", "setautocommit", })
end
CUR_OK = function (obj)
	return test_object (obj, { "close", "fetch", "getcolnames", "getcoltypes", })
end

---------------------------------------------------------------------
-- Main
---------------------------------------------------------------------

if type(arg[1]) ~= "string" then
	print (string.format ("Usage %s <driver> [<data source> [, <user> [, <password>]]]", arg[0]))
	os.exit()
end

local driver = arg[1]
local datasource = arg[2] or "luasql-test"
local username = arg[3] or nil
local password = arg[4] or nil

require (arg[1])
assert (luasql, "no luasql table")

local env, err = luasql[driver] ()
assert (env, err)
conn, err = env:connect (datasource, username, password)
assert (conn, err)
conn:execute ("drop table fetch_test")
-- Create test table
local n, err = conn:execute ([[
	create table fetch_test (
		f1	varchar(30),
		f2	varchar(30),
		f3	varchar(30),
		f4	varchar(30),
		f5	varchar(30),
		f6	varchar(30),
		f7	varchar(30),
		f8	varchar(30)
	)]])
assert (n, err)
assert (type(n) == "number", "couldn't create fetch_test table")
-- Insert rows
for i = 1, TOTAL_ROWS do
	local n, err = conn:execute (
		"insert into fetch_test values ('f1','f2','f3','f4','f5','f6','f7','f8')")
	assert (n, err)
	assert (type (n) == "number", "couldn't insert rows")
end
print ("table created; rows inserted")

-- default
local cur, err = conn:execute ("select * from fetch_test")
assert (cur, err)
--assert (cur:numrows() == TOTAL_ROWS, "wrong number of rows")
local t1 = os.clock()
--for i = 1, cur:numrows() do
	--local f1,f2,f3,f4,f5,f6,f7,f8 = cur:fetch()
--end
local f1,f2,f3,f4,f5,f6,f7,f8 = cur:fetch()
while f1 do
	f1,f2,f3,f4,f5,f6,f7,f8 = cur:fetch()
end
print ("default: ", os.clock() - t1)
assert (cur:close () == 1, "couldn't close cursor object")

-- using the same table
local cur, err = conn:execute ("select * from fetch_test")
assert (cur, err)
--assert (cur:numrows() == TOTAL_ROWS, "wrong number of rows")
t1 = os.clock()
local t = {}
--for i = 1, cur:numrows() do
	--t = cur:fetch (t)
--end
t = cur:fetch(t)
while t do
	t = cur:fetch(t)
end
print ("same table: ", os.clock() - t1)
assert (cur:close () == 1, "couldn't close cursor object")

-- using the same table with alphanumeric keys
local cur, err = conn:execute ("select * from fetch_test")
assert (cur, err)
--assert (cur:numrows() == TOTAL_ROWS, "wrong number of rows")
t1 = os.clock()
local t = {}
--for i = 1, cur:numrows() do
	--t = cur:fetch (t,"a")
--end
t = cur:fetch (t, "a")
while t do
	t = cur:fetch (t, "a")
end
print ("alpha keys: ", os.clock() - t1)
assert (cur:close () == 1, "couldn't close cursor object")

-- using the same table with numeric and alphanumeric keys
local cur, err = conn:execute ("select * from fetch_test")
assert (cur, err)
--assert (cur:numrows() == TOTAL_ROWS, "wrong number of rows")
t1 = os.clock()
local t = {}
--for i = 1, cur:numrows() do
	--t = cur:fetch (t,"an")
--end
t = cur:fetch (t, "an")
while t do
	t = cur:fetch (t, "an")
end
print ("all keys: ", os.clock() - t1)
assert (cur:close () == 1, "couldn't close cursor object")

-- creating a table
local cur, err = conn:execute ("select * from fetch_test")
assert (cur, err)
--assert (cur:numrows() == TOTAL_ROWS, "wrong number of rows")
t1 = os.clock()
--for i = 1, cur:numrows() do
	--local t = cur:fetch{}
--end
while cur:fetch{} do
end
print ("new table: ", os.clock() - t1)
assert (cur:close () == 1, "couldn't close cursor object")

assert (conn:close () == 1, "couldn't close connection object")
assert (env:close () == 1, "couldn't close environment object")
