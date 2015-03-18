--------------------------------------------------------------------------------
------------------------------  #####      ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------ ##   ## ##  ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------  #####  ### ###### ------------------------------
--------------------------------                --------------------------------
----------------------- An Object Request Broker in Lua ------------------------
--------------------------------------------------------------------------------
-- Project: OiL - ORB in Lua: An Object Request Broker in Lua                 --
-- Release: 0.4                                                               --
-- Title  : IDL Interface Indexer                                             --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- indexer:Facet
-- 	[interface:table] typeof(name:string)
-- 	member:table valueof(interface:table, name:string)
-- 
-- registry:Receptacle
-- 	[interface:table] lookup_id(repid:string)
-- 	[interface:table] lookup(name:string)
--------------------------------------------------------------------------------

local ipairs = ipairs

local oo     = require "oil.oo"
local idl    = require "oil.corba.idl"                                          --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.idl.Indexer", oo.class)

context = false

--------------------------------------------------------------------------------
-- Internal Functions ----------------------------------------------------------

function findmember(self, interface, name)
	for interface in interface:hierarchy() do
		local contained = interface.definitions[name]
		if
			contained and
			(contained._type == "operation" or contained._type == "attribute")
		then
			return contained, interface
		end
	end
end

patterns = { "^_([gs]et)_(.+)$" }

builders = {}
function builders:get(attribute, opname, attribop)
	if attribute._type == "attribute" then
		return idl.operation{ attribute = attribute, attribop = attribop,
			name = opname,
			result = attribute.type,
		}
	end
end
function builders:set(attribute, opname, attribop)
	if attribute._type == "attribute" then
		return idl.operation{ attribute = attribute, attribop = attribop,
			name = opname,
			parameters = { {type = attribute.type, name = "value"} },
		}
	end
end

--------------------------------------------------------------------------------
-- Interface Operations --------------------------------------------------------

function typeof(self, name)
	return self.context.registry:resolve(name)
end

function valueof(self, interface, name)
	local member = self:findmember(interface, name)
	if not member then
		local action
		for _, pattern in ipairs(self.patterns) do
			action, member = name:match(pattern)
			if action then
				member, interface = self:findmember(interface, member)
				if member then
					member = self.builders[action](self, member, name, action)
				end
			end
		end
	end
	return member
end
