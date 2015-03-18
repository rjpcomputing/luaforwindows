---------------------------------------------------------------------
-- SQLite specific tests and configurations.
-- $Id: sqlite.lua,v 1.2 2006/05/31 21:43:33 carregal Exp $
---------------------------------------------------------------------

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