local pairs = pairs

local idl  = require "oil.corba.idl"
local giop = require "oil.corba.giop"                                           --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.corba.idl.sysex"

--------------------------------------------------------------------------------

name = "CORBA"
repID = "IDL:omg.org/CORBA:1.0"
idl.module(_M)

--------------------------------------------------------------------------------

for name, repID in pairs(giop.SystemExceptionIDs) do
	definitions[name] = idl.except{
		{name = "minor_code_value" , type = idl.ulong },
		{name = "completion_status", type = idl.ulong },
	}
end
