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
-- Title  : Interface Definition Language (IDL) compiler                      --
-- Authors: Renato Maia   <maia@inf.puc-rio.br>                               --
--          Ricardo Cosme <rcosme@tecgraf.puc-rio.br>                         --
--------------------------------------------------------------------------------
-- compiler:Facet
-- 	success:boolean, [except:table] load(idl:string)
-- 	success:boolean, [except:table] loadfile(filepath:string)
-- 
-- registry:Receptacle
-- 	types:table register(definition:table)
--------------------------------------------------------------------------------

local pairs  = pairs
local select = select
local unpack = unpack

local luaidl = require "luaidl"

local oo  = require "oil.oo"
local idl = require "oil.corba.idl"                                             --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.idl.Compiler", oo.class)

context = false

--------------------------------------------------------------------------------
Options = {
	callbacks = {
		VOID      = idl.void,
		SHORT     = idl.short,
		LONG      = idl.long,
		LLONG     = idl.longlong,
		USHORT    = idl.ushort,
		ULONG     = idl.ulong,
		ULLONG    = idl.ulonglong,
		FLOAT     = idl.float,
		DOUBLE    = idl.double,
		LDOUBLE   = idl.longdouble,
		BOOLEAN   = idl.boolean,
		CHAR      = idl.char,
		OCTET     = idl.octet,
		ANY       = idl.any,
		TYPECODE  = idl.TypeCode,
		STRING    = idl.string,
		OBJECT    = idl.object,
		operation = idl.operation,
		attribute = idl.attribute,
		except    = idl.except,
		union     = idl.union,
		struct    = idl.struct,
		enum      = idl.enum,
		typedef   = idl.typedef,
		array     = idl.array,
		sequence  = idl.sequence,
	},
}
function Options.callbacks.interface(def)
	if def.definitions then -- not forward declarations
		return idl.interface(def)
	end
	return def
end

local Modules
function Options.callbacks.module(def)
	Modules[def] = true
	return def
end

function Options.callbacks.start()
	Modules = {}
end

function Options.callbacks.finish()
	for module in pairs(Modules) do idl.module(module) end
end

--------------------------------------------------------------------------------

function doresults(self, ...)
	if ... then
		return self.context.registry:register(...)
	end
	return ...
end

function loadfile(self, filepath)
	return self:doresults(luaidl.parsefile(filepath, self.Options))
end

function load(self, idlspec)
	return self:doresults(luaidl.parse(idlspec, self.Options))
end
