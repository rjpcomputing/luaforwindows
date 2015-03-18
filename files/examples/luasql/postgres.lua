---------------------------------------------------------------------
-- PostgreSQL specific tests and configurations.
-- $Id: postgres.lua,v 1.2 2006/01/25 19:15:21 tomas Exp $
---------------------------------------------------------------------

table.insert (CUR_METHODS, "numrows")
table.insert (EXTENSIONS, numrows)
