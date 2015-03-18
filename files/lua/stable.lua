----------------------------------------------------------------------------
-- Stable: State persistent table for Rings.
--
-- Copyright (c) 2006-2007 Kepler Project
-- $Id: stable.lua,v 1.7 2008/06/30 17:52:31 carregal Exp $
----------------------------------------------------------------------------

local remotedostring = assert (remotedostring, "There is no `remotedostring'.  Probably not in a slave state")
-- creating persistent table at master state.
assert (remotedostring[[_state_persistent_table_ = _state_persistent_table_ or {}]])

module"stable"

----------------------------------------------------------------------------
_COPYRIGHT = "Copyright (C) 2006 Kepler Project"
_DESCRIPTION = "State persistent table"
_VERSION = "Stable 1.0"

----------------------------------------------------------------------------
function get (i)
	local ok, value = remotedostring ("return _state_persistent_table_[...]", i)
	return value
end

----------------------------------------------------------------------------
function set (i, v)
	remotedostring ("_state_persistent_table_[select(1,...)] = select(2,...)", i, v)
end
