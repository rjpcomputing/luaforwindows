---------------------------------------------------------------------
-- Oracle specific tests and configurations.
-- $Id: oci8.lua,v 1.3 2006/05/31 21:43:15 carregal Exp $
---------------------------------------------------------------------

table.insert (CUR_METHODS, "numrows")
table.insert (EXTENSIONS, numrows)

DEFINITION_STRING_TYPE_NAME = "varchar(60)"
QUERYING_STRING_TYPE_NAME = "string"