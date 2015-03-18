---------------------------------------------------------------------
-- MySQL specific tests and configurations.
-- $Id: mysql.lua,v 1.4 2006/01/25 20:28:30 tomas Exp $
---------------------------------------------------------------------

QUERYING_STRING_TYPE_NAME = "binary(65535)"

table.insert (CUR_METHODS, "numrows")
table.insert (EXTENSIONS, numrows)

---------------------------------------------------------------------
-- Build SQL command to create the test table.
---------------------------------------------------------------------
local _define_table = define_table
function define_table (n)
	return _define_table(n) .. " TYPE = InnoDB;"
end

---------------------------------------------------------------------
-- MySQL versions 4.0.x do not implement rollback.
---------------------------------------------------------------------
local _rollback = rollback
function rollback ()
	if luasql._MYSQLVERSION and string.sub(luasql._MYSQLVERSION, 1, 3) == "4.0" then
		io.write("skipping rollback test (mysql version 4.0.x)")
		return
	else
		_rollback ()
	end
end
