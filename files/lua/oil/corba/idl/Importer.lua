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
-- Title  : IDL Definition Repository                                         --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- importer:Facet
-- 	type:table register(definition:table)
-- 	type:table remove(definition:table)
-- 	[type:table] lookup(name:string)
-- 	[type:table] lookup_id(repid:string)
-- 
-- registry:Receptacle
-- 	type:table register(definition:table)
-- 	type:table remove(definition:table)
-- 	[type:table] lookup(name:string)
-- 	[type:table] lookup_id(repid:string)
-- 
-- delegated:Recetacle
-- 	[type:table] lookup(name:string)
-- 	[type:table] lookup_id(repid:string)
------------------------------------------------------------------------------ --

local error  = error
local ipairs = ipairs
local pairs  = pairs

local oo       = require "oil.oo"
local idl      = require "oil.corba.idl"
local iridl    = require "oil.corba.idl.ir"
local Registry = require "oil.corba.idl.Registry"                               --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.idl.Importer", oo.class)

resolve = Registry.resolve

function context(self, context)
	self.context = context
	local registry = context.registry
	registry:register(iridl)
	self.DefaultDefs = oo.class()
	for id, def in pairs(registry.definition_map) do
		self.DefaultDefs[id] = def
	end
end

function lookup(self, search_name)
	local context = self.context
	local definition = context.registry:lookup(search_name)
	if not definition then
		if context.delegated then
			definition = context.delegated:lookup(search_name)
			if definition then
				definition = self:register(definition)
			end
		end
	end
	return definition
end

function lookup_id(self, search_id)
	local context = self.context
	local definition = context.registry:lookup_id(search_id)
	if not definition then
		if context.delegated then
			definition = context.delegated:lookup_id(search_id)
			if definition then
				definition = self:register(definition)
			end
		end
	end
	return definition
end

local IDLTypes = {
	dk_Primitive = true,
	dk_String    = true,
	dk_Array     = true,
	dk_Sequence  = true,
}

local Contained = {
	dk_Typedef   = { const = idl.typedef,   iface = "IDL:omg.org/CORBA/TypedefDef:1.0"   },
	dk_Alias     = { const = idl.typedef,   iface = "IDL:omg.org/CORBA/AliasDef:1.0"     },
	dk_Enum      = { const = idl.enum,      iface = "IDL:omg.org/CORBA/EnumDef:1.0"      },
	dk_Struct    = { const = idl.struct,    iface = "IDL:omg.org/CORBA/StructDef:1.0"    },
	dk_Union     = { const = idl.union,     iface = "IDL:omg.org/CORBA/UnionDef:1.0"     },
	dk_Exception = { const = idl.except,    iface = "IDL:omg.org/CORBA/ExceptionDef:1.0" },
	dk_Module    = { const = idl.module,    iface = "IDL:omg.org/CORBA/ModuleDef:1.0"    },
	dk_Interface = { const = idl.interface, iface = "IDL:omg.org/CORBA/InterfaceDef:1.0" },
	dk_Attribute = { const = idl.attribute, iface = "IDL:omg.org/CORBA/AttributeDef:1.0" },
	dk_Operation = { const = idl.operation, iface = "IDL:omg.org/CORBA/OperationDef:1.0" },
}

function register(self, object, history)
	local result
	local registry = self.context.registry
	if object._get_def_kind then -- is a remote definition
		local kind = object:_get_def_kind()
		if kind == "dk_Repository" then
			result = registry
		elseif IDLTypes[kind] then
			local desc
			-- import definition specific information
			if kind == "dk_Array" then
				object = object:_narrow("IDL:omg.org/CORBA/ArrayDef:1.0")
				desc = object:_get_type()
				desc.elementtype = self:register(object:_get_element_type_def(), history)
			elseif kind == "dk_Sequence" then
				object = object:_narrow("IDL:omg.org/CORBA/SequenceDef:1.0")
				desc = object:_get_type()
				desc.elementtype = self:register(object:_get_element_type_def(), history)
			else
				object = object:_narrow("IDL:omg.org/CORBA/IDLType:1.0")
				desc = object:_get_type()
			end
			result = registry:register(desc)
		elseif Contained[kind] then
			object = object:_narrow(Contained[kind].iface)
			local desc = object:describe().value
			history = history or self.DefaultDefs()
			result = history[desc.id] 
			if not result then                                                        --[[VERBOSE]] verbose:repository(true, "importing definition ",desc.id)
				desc.repID = desc.id
				desc.defined_in = nil -- will be resolved later
				
				-- import definition specific information
				if kind == "dk_Typedef" then
					desc = object:_get_type()
				elseif kind == "dk_Alias" then
					desc.type = self:register(object:_get_original_type_def(), history)
				elseif kind == "dk_Enum" then
					desc.enumvalues = object:_get_members()
				elseif kind == "dk_Union" then
					desc.switch = self:register(object:_get_discriminator_type_def(), history)
				elseif kind == "dk_Interface" then
					for index, base in ipairs(object:_get_base_interfaces()) do
						desc.base_interfaces[index] = self:register(base, history)
					end
				elseif kind == "dk_Attribute" then
					desc.type = self:register(object:_get_type_def(), history)
				elseif kind == "dk_Operation" then
					desc.result = self:register(object:_get_result_def(), history)
					for _, param in ipairs(desc.parameters) do
						param.type = self:register(param.type_def, history)
					end
					for index, except in ipairs(object:_get_exceptions()) do
						desc.exceptions[index] = self:register(except, history)
					end
				end
				
				-- registration of the imported definition
				result = registry:register(Contained[kind].const(desc))
				history[result.repID] = result
				
				-- following references may be recursive
				if kind == "dk_Struct" or kind == "dk_Union" or kind == "dk_Exception" then
					local members = object:_get_members()
					for _, member in ipairs(members) do
						member.type = self:register(member.type_def, history)
						member.type_def = member.type
					end
					if result._set_members
						then result:_set_members(members)
						else result.members = members
					end
				end
				
				-- resolve contaiment
				result:move(
					self:register(object:_get_defined_in(), history),
					result.name,
					result.version
				)
				if object.contents then
					for _, contained in ipairs(object:contents("dk_all", true)) do
						self:register(contained, history)
					end
				end                                                                     --[[VERBOSE]] verbose:repository(false)
				
			end
		else
			error("unable to import definition of type "..object:_interface():_get_id())
		end
	else -- a local IDL description
		result = registry:register(object)
	end
	return result
end
