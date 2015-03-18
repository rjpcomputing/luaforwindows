---------------------------------------------------------------------
-- SQLite specific tests and configurations.
-- $Id: sqlite3.lua,v 1.2 2007/10/16 15:42:50 carregal Exp $
---------------------------------------------------------------------

DROP_TABLE_RETURN_VALUE = 1

---------------------------------------------------------------------
-- Produces a SQL statement which completely erases a table.
-- @param table_name String with the name of the table.
-- @return String with SQL statement.
---------------------------------------------------------------------
function sql_erase_table (table_name)
	return string.format ("delete from %s where 1", table_name)
end

function checkUnknownDatabase(ENV)
	-- skip this test
end