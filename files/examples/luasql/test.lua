#!/usr/local/bin/lua5.1
-- See Copyright Notice in license.html

TOTAL_FIELDS = 40
TOTAL_ROWS = 40 --unused

DEFINITION_STRING_TYPE_NAME = "text"
QUERYING_STRING_TYPE_NAME = "text"

CREATE_TABLE_RETURN_VALUE = 0
DROP_TABLE_RETURN_VALUE = 0

---------------------------------------------------------------------
-- Produces a SQL statement which completely erases a table.
-- @param table_name String with the name of the table.
-- @return String with SQL statement.
---------------------------------------------------------------------
function sql_erase_table (table_name)
	return string.format ("delete from %s", table_name)
end

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
		msg.."wrong value ("..tostring(value).." instead of "..
		tostring(expected)..")")
end

---------------------------------------------------------------------
-- object test.
---------------------------------------------------------------------
function test_object (obj, objmethods)
	-- checking object type.
	assert2 (true, type(obj) == "userdata" or type(obj) == "table", "incorrect object type")
	-- trying to get metatable.
	assert2 ("LuaSQL: you're not allowed to get this metatable",
		getmetatable(obj), "error permitting access to object's metatable")
	-- trying to set metatable.
	assert2 (false, pcall (setmetatable, ENV, {}))
	-- checking existence of object's methods.
	for i = 1, table.getn (objmethods) do
		local method = obj[objmethods[i]]
		assert2 ("function", type(method))
		assert2 (false, pcall (method), "no 'self' parameter accepted")
	end
	return obj
end

ENV_METHODS = { "close", "connect", }
ENV_OK = function (obj)
	return test_object (obj, ENV_METHODS)
end
CONN_METHODS = { "close", "commit", "execute", "rollback", "setautocommit", }
CONN_OK = function (obj)
	return test_object (obj, CONN_METHODS)
end
CUR_METHODS = { "close", "fetch", "getcolnames", "getcoltypes", }
CUR_OK = function (obj)
	return test_object (obj, CUR_METHODS)
end

function checkUnknownDatabase(ENV)
	assert2 (nil, ENV:connect ("/unknown-data-base"), "this should be an error")
end

---------------------------------------------------------------------
-- basic checking test.
---------------------------------------------------------------------
function basic_test ()
	-- Check environment object.
	ENV = ENV_OK (luasql[driver] ())
	assert2 (true, ENV:close(), "couldn't close environment")
	-- trying to connect with a closed environment.
	assert2 (false, pcall (ENV.connect, ENV, datasource, username, password),
		"error connecting with a closed environment")
	-- it is ok to close a closed object, but false is returned instead of true.
	assert2 (false, ENV:close())
	-- Reopen the environment.
	ENV = ENV_OK (luasql[driver] ())
	-- Check connection object.
	local conn, err = ENV:connect (datasource, username, password)
	assert (conn, (err or '').." ("..datasource..")")
	CONN_OK (conn)
	assert2 (true, conn:close(), "couldn't close connection")
	-- trying to execute a statement with a closed connection.
	assert2 (false, pcall (conn.execute, conn, "create table x (c char)"),
		"error connecting with a closed environment")
	-- it is ok to close a closed object, but false is returned instead of true.
	assert2 (false, conn:close())
	-- Check error situation.
	checkUnknownDatabase(ENV)	

	-- force garbage collection
	local a = {}
	setmetatable(a, {__mode="v"})
	a.ENV = ENV_OK (luasql[driver] ())
	a.CONN = a.ENV:connect (datasource, username, password)
	collectgarbage ()
	collectgarbage ()
	assert2(nil, a.ENV, "environment not collected")
	assert2(nil, a.CONN, "connection not collected")
end

---------------------------------------------------------------------
-- Build SQL command to create the test table.
---------------------------------------------------------------------
function define_table (n)
	local t = {}
	for i = 1, n do
		table.insert (t, "f"..i.." "..DEFINITION_STRING_TYPE_NAME)
	end
	return "create table t ("..table.concat (t, ',')..")"
end


---------------------------------------------------------------------
-- Create a table with TOTAL_FIELDS character fields.
---------------------------------------------------------------------
function create_table ()
	-- Check SQL statements.
	CONN = CONN_OK (ENV:connect (datasource, username, password))
	-- Create t.
	local cmd = define_table(TOTAL_FIELDS)
	assert2 (CREATE_TABLE_RETURN_VALUE, CONN:execute (cmd))
end

---------------------------------------------------------------------
-- Fetch 2 values.
---------------------------------------------------------------------
function fetch2 ()
	-- insert a record.
	assert2 (1, CONN:execute ("insert into t (f1, f2) values ('b', 'c')"))
	-- retrieve data.
	local cur = CUR_OK (CONN:execute ("select f1, f2, f3 from t"))
	-- check data.
	local f1, f2, f3 = cur:fetch()
	assert2 ('b', f1)
	assert2 ('c', f2)
	assert2 (nil, f3)
	assert2 (nil, cur:fetch())
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- insert a second record.
	assert2 (1, CONN:execute ("insert into t (f1, f2) values ('d', 'e')"))
	cur = CUR_OK (CONN:execute ("select f1, f2, f3 from t order by f1"))
	local f1, f2, f3 = cur:fetch()
	assert2 ('b', f1, f2)	-- f2 can be an error message
	assert2 ('c', f2)
	assert2 (nil, f3)
	f1, f2, f3 = cur:fetch()
	assert2 ('d', f1, f2)	-- f2 can be an error message
	assert2 ('e', f2)
	assert2 (nil, f3)
	assert2 (nil, cur:fetch())
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- remove records.
	assert2 (2, CONN:execute ("delete from t where f1 in ('b', 'd')"))
end

---------------------------------------------------------------------
-- Test fetch with a new table, reusing a table and with different
-- indexing.
---------------------------------------------------------------------
function fetch_new_table ()
	-- insert elements.
	assert2 (1, CONN:execute ("insert into t (f1, f2, f3, f4) values ('a', 'b', 'c', 'd')"))
	assert2 (1, CONN:execute ("insert into t (f1, f2, f3, f4) values ('f', 'g', 'h', 'i')"))
	-- retrieve data using a new table.
	local cur = CUR_OK (CONN:execute ("select f1, f2, f3, f4 from t order by f1"))
	local row, err = cur:fetch{}
	assert2 (type(row), "table", err)
	assert2 ('a', row[1])
	assert2 ('b', row[2])
	assert2 ('c', row[3])
	assert2 ('d', row[4])
	assert2 (nil, row.f1)
	assert2 (nil, row.f2)
	assert2 (nil, row.f3)
	assert2 (nil, row.f4)
	row, err = cur:fetch{}
	assert (type(row), "table", err)
	assert2 ('f', row[1])
	assert2 ('g', row[2])
	assert2 ('h', row[3])
	assert2 ('i', row[4])
	assert2 (nil, row.f1)
	assert2 (nil, row.f2)
	assert2 (nil, row.f3)
	assert2 (nil, row.f4)
	assert2 (nil, cur:fetch())
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())

	-- retrieve data reusing the same table.
	io.write ("reusing a table...")
	cur = CUR_OK (CONN:execute ("select f1, f2, f3, f4 from t order by f1"))
	local row, err = cur:fetch{}
	assert (type(row), "table", err)
	assert2 ('a', row[1])
	assert2 ('b', row[2])
	assert2 ('c', row[3])
	assert2 ('d', row[4])
	assert2 (nil, row.f1)
	assert2 (nil, row.f2)
	assert2 (nil, row.f3)
	assert2 (nil, row.f4)
	row, err = cur:fetch (row)
	assert (type(row), "table", err)
	assert2 ('f', row[1])
	assert2 ('g', row[2])
	assert2 ('h', row[3])
	assert2 ('i', row[4])
	assert2 (nil, row.f1)
	assert2 (nil, row.f2)
	assert2 (nil, row.f3)
	assert2 (nil, row.f4)
	assert2 (nil, cur:fetch{})
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())

	-- retrieve data reusing the same table with alphabetic indexes.
	io.write ("with alpha keys...")
	cur = CUR_OK (CONN:execute ("select f1, f2, f3, f4 from t order by f1"))
	local row, err = cur:fetch ({}, "a")
	assert (type(row), "table", err)
	assert2 (nil, row[1])
	assert2 (nil, row[2])
	assert2 (nil, row[3])
	assert2 (nil, row[4])
	assert2 ('a', row.f1)
	assert2 ('b', row.f2)
	assert2 ('c', row.f3)
	assert2 ('d', row.f4)
	row, err = cur:fetch (row, "a")
	assert2 (type(row), "table", err)
	assert2 (nil, row[1])
	assert2 (nil, row[2])
	assert2 (nil, row[3])
	assert2 (nil, row[4])
	assert2 ('f', row.f1)
	assert2 ('g', row.f2)
	assert2 ('h', row.f3)
	assert2 ('i', row.f4)
	assert2 (nil, cur:fetch(row, "a"))
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())

	-- retrieve data reusing the same table with both indexes.
	io.write ("with both keys...")
	cur = CUR_OK (CONN:execute ("select f1, f2, f3, f4 from t order by f1"))
	local row, err = cur:fetch ({}, "an")
	assert (type(row), "table", err)
	assert2 ('a', row[1])
	assert2 ('b', row[2])
	assert2 ('c', row[3])
	assert2 ('d', row[4])
	assert2 ('a', row.f1)
	assert2 ('b', row.f2)
	assert2 ('c', row.f3)
	assert2 ('d', row.f4)
	row, err = cur:fetch (row, "an")
	assert (type(row), "table", err)
	assert2 ('f', row[1])
	assert2 ('g', row[2])
	assert2 ('h', row[3])
	assert2 ('i', row[4])
	assert2 ('f', row.f1)
	assert2 ('g', row.f2)
	assert2 ('h', row.f3)
	assert2 ('i', row.f4)
	assert2 (nil, cur:fetch(row, "an"))
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- clean the table.
	assert2 (2, CONN:execute ("delete from t where f1 in ('a', 'f')"))
end

---------------------------------------------------------------------
-- Fetch many values
---------------------------------------------------------------------
function fetch_many ()
	-- insert values.
	local fields, values = "f1", "'v1'"
	for i = 2, TOTAL_FIELDS do
		fields = string.format ("%s,f%d", fields, i)
		values = string.format ("%s,'v%d'", values, i)
	end
	local cmd = string.format ("insert into t (%s) values (%s)",
		fields, values)
	assert2 (1, CONN:execute (cmd))
	-- fetch values (without a table).
	local cur = CUR_OK (CONN:execute ("select * from t where f1 = 'v1'"))
	local row = { cur:fetch () }
	assert2 ("string", type(row[1]), "error while trying to fetch many values (without a table)")
	for i = 1, TOTAL_FIELDS do
		assert2 ('v'..i, row[i])
	end
	assert2 (nil, cur:fetch (row))
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- fetch values (with a table and default indexing).
	io.write ("with a table...")
	local cur = CUR_OK (CONN:execute ("select * from t where f1 = 'v1'"))
	local row = cur:fetch {}
	assert2 ("string", type(row[1]), "error while trying to fetch many values (default indexing)")
	for i = 1, TOTAL_FIELDS do
		assert2 ('v'..i, row[i])
	end
	assert2 (nil, cur:fetch (row))
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- fetch values (with numbered indexes on a table).
	io.write ("with numbered keys...")
	local cur = CUR_OK (CONN:execute ("select * from t where f1 = 'v1'"))
	local row = cur:fetch ({}, "n")
	assert2 ("string", type(row[1]), "error while trying to fetch many values (numbered indexes)")
	for i = 1, TOTAL_FIELDS do
		assert2 ('v'..i, row[i])
	end
	assert2 (nil, cur:fetch (row))
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- fetch values (with alphanumeric indexes on a table).
	io.write ("with alpha keys...")
	local cur = CUR_OK (CONN:execute ("select * from t where f1 = 'v1'"))
	local row = cur:fetch ({}, "a")
	assert2 ("string", type(row.f1), "error while trying to fetch many values (alphanumeric indexes)")
	for i = 1, TOTAL_FIELDS do
		assert2 ('v'..i, row['f'..i])
	end
	assert2 (nil, cur:fetch (row))
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- fetch values (with both indexes on a table).
	io.write ("with both keys...")
	local cur = CUR_OK (CONN:execute ("select * from t where f1 = 'v1'"))
	local row = cur:fetch ({}, "na")
	assert2 ("string", type(row[1]), "error while trying to fetch many values (both indexes)")
	assert2 ("string", type(row.f1), "error while trying to fetch many values (both indexes)")
	for i = 1, TOTAL_FIELDS do
		assert2 ('v'..i, row[i])
		assert2 ('v'..i, row['f'..i])
	end
	assert2 (nil, cur:fetch (row))
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- clean the table.
	assert2 (1, CONN:execute ("delete from t where f1 = 'v1'"))
end

---------------------------------------------------------------------
---------------------------------------------------------------------
function rollback ()
	-- begin transaction
	assert2 (true, CONN:setautocommit (false), "couldn't disable autocommit")
	-- insert a record and commit the operation.
	assert2 (1, CONN:execute ("insert into t (f1) values ('a')"))
	local cur = CUR_OK (CONN:execute ("select count(*) from t"))
	assert2 (1, tonumber (cur:fetch ()), "Insert failed")
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	assert2 (true, CONN:commit(), "couldn't commit transaction")
	-- insert a record and roll back the operation.
	assert2 (1, CONN:execute ("insert into t (f1) values ('b')"))
	local cur = CUR_OK (CONN:execute ("select count(*) from t"))
	assert2 (2, tonumber (cur:fetch ()), "Insert failed")
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	assert2 (true, CONN:rollback (), "couldn't roolback transaction")
	-- check resulting table with one record.
	cur = CUR_OK (CONN:execute ("select count(*) from t"))
	assert2 (1, tonumber(cur:fetch()), "Rollback failed")
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- delete a record and roll back the operation.
	assert2 (1, CONN:execute ("delete from t where f1 = 'a'"))
	cur = CUR_OK (CONN:execute ("select count(*) from t"))
	assert2 (0, tonumber(cur:fetch()))
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	assert2 (true, CONN:rollback (), "couldn't roolback transaction")
	-- check resulting table with one record.
	cur = CUR_OK (CONN:execute ("select count(*) from t"))
	assert2 (1, tonumber(cur:fetch()), "Rollback failed")
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
--[[
	-- insert a second record and turn on the auto-commit mode.
	-- this will produce a rollback on PostgreSQL and a commit on ODBC.
	-- what to do?
	assert2 (1, CONN:execute ("insert into t (f1) values ('b')"))
	cur = CUR_OK (CONN:execute ("select count(*) from t"))
	assert2 (2, tonumber (cur:fetch ()), "Insert failed")
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	assert2 (true, CONN:setautocommit (true), "couldn't enable autocommit")
	-- check resulting table with one record.
	cur = CUR_OK (CONN:execute ("select count(*) from t"))
	assert2 (1, tonumber(cur:fetch()), "Rollback failed")
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
--]]
	-- clean the table.
	assert2 (1, CONN:execute (sql_erase_table"t"))
	assert2 (true, CONN:commit (), "couldn't commit transaction")
	assert2 (true, CONN:setautocommit (true), "couldn't enable autocommit")
	-- check resulting table with no records.
	cur = CUR_OK (CONN:execute ("select count(*) from t"))
	assert2 (0, tonumber(cur:fetch()), "Rollback failed")
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
end

---------------------------------------------------------------------
-- Get column names and types.
---------------------------------------------------------------------
function column_info ()
	-- insert elements.
	assert2 (1, CONN:execute ("insert into t (f1, f2, f3, f4) values ('a', 'b', 'c', 'd')"))
	local cur = CUR_OK (CONN:execute ("select f1,f2,f3,f4 from t"))
	-- get column information.
	local names, types = cur:getcolnames(), cur:getcoltypes()
	assert2 ("table", type(names), "getcolnames failed")
	assert2 ("table", type(types), "getcoltypes failed")
	assert2 (4, table.getn(names), "incorrect column names table")
	assert2 (4, table.getn(types), "incorrect column types table")
	for i = 1, table.getn(names) do
		assert2 ("f"..i, names[i], "incorrect column names table")
		local type_i = types[i]
		assert (type_i == QUERYING_STRING_TYPE_NAME, "incorrect column types table")
	end
	-- check if the tables are being reused.
	local n2, t2 = cur:getcolnames(), cur:getcoltypes()
	assert2 (names, n2, "getcolnames is rebuilding the table")
	assert2 (types, t2, "getcoltypes is rebuilding the table")
	assert2 (true, cur:close(), "couldn't close cursor")
	assert2 (false, cur:close())
	-- clean the table.
	assert2 (1, CONN:execute ("delete from t where f1 = 'a'"))
end

---------------------------------------------------------------------
-- Escaping strings
---------------------------------------------------------------------
function escape ()
	assert2 ("a''b''c''d", CONN:escape"a'b'c'd")
end

---------------------------------------------------------------------
---------------------------------------------------------------------
function check_close()
	-- an object with references to it can't be closed
	local cmd = "select * from t"
	local cur = CUR_OK(CONN:execute (cmd))
	assert2 (true, cur:close(), "couldn't close cursor")

	-- force garbage collection
	local a = {}
	setmetatable(a, {__mode="v"})
	a.CONN = ENV:connect (datasource, username, password)
	cur = CUR_OK(a.CONN:execute (cmd))

	collectgarbage ()
	collectgarbage ()
	CONN_OK (a.CONN)
	a.cur = cur
	a.cur:close()
	a.CONN:close()
	cur = nil
	collectgarbage ()
	assert2(nil, a.cur, "cursor not collected")
	collectgarbage ()
	assert2(nil, a.CONN, "connection not collected")

	-- check cursor integrity after trying to close a connection
	local conn = CONN_OK (ENV:connect (datasource, username, password))
	assert2 (1, conn:execute"insert into t (f1) values (1)", "could not insert a new record")
	local cur = CUR_OK (conn:execute (cmd))
	local ok, err = pcall (conn.close, conn)
	CUR_OK (cur)
	assert (cur:fetch(), "corrupted cursor")
	cur:close ()
	conn:close ()
end

---------------------------------------------------------------------
---------------------------------------------------------------------
function drop_table ()
	assert2 (true, CONN:setautocommit(true), "couldn't enable autocommit")
	-- Postgres retorns 0, ODBC retorns -1, sqlite returns 1
	assert2 (DROP_TABLE_RETURN_VALUE, CONN:execute ("drop table t"))
end

---------------------------------------------------------------------
---------------------------------------------------------------------
function close_conn ()
	assert (true, CONN:close())
	assert (true, ENV:close())
end

---------------------------------------------------------------------
-- Testing Extensions
---------------------------------------------------------------------
EXTENSIONS = {
}
function extensions_test ()
	for i, f in ipairs (EXTENSIONS) do
		f ()
	end
end

---------------------------------------------------------------------
-- Testing numrows method.
-- This is not a default test, it must be added to the extensions
-- table to be executed.
---------------------------------------------------------------------
function numrows()
    local cur = CUR_OK(CONN:execute"select * from t")
    assert2(0,cur:numrows())
    cur:close()

    -- Inserts one row.
    assert2 (1, CONN:execute"insert into t (f1) values ('a')", "could not insert a new record")
    cur = CUR_OK(CONN:execute"select * from t")
    assert2(1,cur:numrows())
    cur:close()

    -- Inserts three more rows (total = 4).
    assert2 (1, CONN:execute"insert into t (f1) values ('b')", "could not insert a new record")
    assert2 (1, CONN:execute"insert into t (f1) values ('c')", "could not insert a new record")
    assert2 (1, CONN:execute"insert into t (f1) values ('d')", "could not insert a new record")
    cur = CUR_OK(CONN:execute"select * from t")
    assert2(4,cur:numrows())
	cur:close()

    -- Deletes one row
    assert2(1, CONN:execute"delete from t where f1 = 'a'", "could not delete the specified row")
    cur = CUR_OK(CONN:execute"select * from t")
    assert2(3,cur:numrows())
    cur:close()

    -- Deletes all rows
    assert2 (3, CONN:execute (sql_erase_table"t"))
    cur = CUR_OK(CONN:execute"select * from t")
    assert2(0,cur:numrows())
    cur:close()

	io.write (" numrows")
end


---------------------------------------------------------------------
-- Main
---------------------------------------------------------------------

if type(arg[1]) ~= "string" then
	print (string.format ("Usage %s <driver> [<data source> [, <user> [, <password>]]]", arg[0]))
	os.exit()
end

driver = arg[1]
datasource = arg[2] or "luasql-test"
username = arg[3] or nil
password = arg[4] or nil

-- Loading driver specific functions
if arg[0] then
	local path = string.gsub (arg[0], "^([^/]*%/).*$", "%1")
	if path == "test.lua" then
		path = ""
	end
	local file = path..driver..".lua"
	local f, err = loadfile (file)
	if not f then
		print ("LuaSQL test: couldn't find driver-specific test file ("..
			file..").\nProceeding with general test")
	else
		f ()
	end
end

-- Complete set of tests
tests = {
	{ "basic checking", basic_test },
	{ "create table", create_table },
	{ "fetch two values", fetch2 },
	{ "fetch new table", fetch_new_table },
	{ "fetch many", fetch_many },
	{ "rollback", rollback },
	{ "get column information", column_info },
	{ "escape", escape },
	{ "extensions", extensions_test },
	{ "close objects", check_close },
	{ "drop table", drop_table },
	{ "close connection", close_conn },
}

require ("luasql."..driver)
assert (luasql, "no luasql table")

for i = 1, table.getn (tests) do
	local t = tests[i]
	io.write (t[1].." ...")
	t[2] ()
	io.write (" OK !\n")
end

