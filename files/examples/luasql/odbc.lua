---------------------------------------------------------------------
-- ODBC specific tests and configurations.
-- $Id: odbc.lua,v 1.2 2006/01/25 19:54:21 tomas Exp $
---------------------------------------------------------------------

QUERYING_STRING_TYPE_NAME = "string"
-- The CREATE_TABLE_RETURN_VALUE and DROP_TABLE_RETURN_VALUE works
-- with -1 on MS Acess Driver, and 0 on SQL Server Driver
CREATE_TABLE_RETURN_VALUE = -1
DROP_TABLE_RETURN_VALUE = -1

---------------------------------------------------------------------
-- Test of data types managed by ODBC driver.
---------------------------------------------------------------------
table.insert (EXTENSIONS, function ()
	assert2 (CREATE_TABLE_RETURN_VALUE, CONN:execute"create table test_dt (f1 integer, f2 varchar(30), f3 bit )")
	-- Inserts a number, a string value and a "bit" value.
	assert2 (1, CONN:execute"insert into test_dt values (10, 'ABCDE', 1)")

	-- Checks the results with the inserted values.
	local cur = CUR_OK (CONN:execute"select * from test_dt")
	local row, err = cur:fetch ({}, "a")
	assert2 ("table", type(row), err)

	assert2 (10, row.f1, "Wrong number representation")
	assert2 ("ABCDE", row.f2, "Wrong string representation")
	assert2 (true, row.f3, "Wrong bit representation")

	-- Drops the table
    assert2 (DROP_TABLE_RETURN_VALUE0, CONN:execute("drop table test_dt") )
end)
