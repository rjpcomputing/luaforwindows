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
-- Title  : Interface Definition Language (IDL) specifications in Lua         --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Interface:                                                                 --
--   istype(object)        Checks whether object is an IDL type               --
--   isspec(object)        Checks whether object is an IDL specification      --
--                                                                            --
--   null                  IDL null type                                      --
--   void                  IDL void type                                      --
--   short                 IDL integer type short                             --
--   long                  IDL integer type long                              --
--   ushort                IDL integer type unsigned short                    --
--   ulong                 IDL integer type unsigned long                     --
--   float                 IDL floating-point numeric type                    --
--   double                IDL double-precision floating-point numeric type   --
--   boolean               IDL boolean type                                   --
--   char                  IDL character type                                 --
--   octet                 IDL raw byte type                                  --
--   any                   IDL generic type                                   --
--   TypeCode              IDL meta-type                                      --
--   string                IDL string type                                    --
--                                                                            --
--   Object(definition)    IDL Object type construtor                         --
--   struct(definition)    IDL struct type construtor                         --
--   union(definition)     IDL union type construtor                          --
--   enum(definition)      IDL enumeration type construtor                    --
--   sequence(definition)  IDL sequence type construtor                       --
--   array(definition)     IDL array type construtor                          --
--   typedef(definition)   IDL type definition construtor                     --
--   except(definition)    IDL expection construtor                           --
--                                                                            --
--   attribute(definition) IDL attribute construtor                           --
--   operation(definition) IDL operation construtor                           --
--   module(definition)    IDL module structure constructor                   --
--   interface(definition) IDL object interface structure constructor         --
--                                                                            --
--   OctetSequence         IDL type used in OiL implementation                --
--   Version               IDL type used in OiL implementation                --
--                                                                            --
--   ScopeMemberList       Class that defines behavior of interface member list-
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   The syntax used for description of IDL specifications is strongly based  --
--   on the work provided by Letícia Nogeira (i.e. LuaRep), which was mainly  --
--   inteded to provide an user-friendly syntax. This approach may change to  --
--   allow better fitting into CORBA model, since the use of LuaIDL parsing   --
--   facilities already provides an user-friendly way to define IDL           --
--   specifications. However backward compatibility may be provided whenever  --
--   possible.                                                                --
--------------------------------------------------------------------------------

local type     = type
local newproxy = newproxy
local pairs    = pairs
local ipairs   = ipairs
local rawset   = rawset
local require  = require
local rawget   = rawget

-- backup of string package functions to avoid name crash with string IDL type
local match  = require("string").match
local format = require("string").format
local table  = require "table"

local OrderedSet        = require "loop.collection.OrderedSet"
local UnorderedArraySet = require "loop.collection.UnorderedArraySet"

local oo     = require "oil.oo"
local assert = require "oil.assert"

module "oil.corba.idl"                                                          --[[VERBOSE]] local verbose = require "oil.verbose"

--------------------------------------------------------------------------------
-- IDL element types -----------------------------------------------------------

BasicTypes = {
	null       = true,
	void       = true,
	short      = true,
	long       = true,
	longlong   = true,
	ushort     = true,
	ulong      = true,
	ulonglong  = true,
	float      = true,
	double     = true,
	longdouble = true,
	boolean    = true,
	char       = true,
	octet      = true,
	any        = true,
	TypeCode   = true,
}

UserTypes = {
	string    = true,
	Object    = true,
	struct    = true,
	union     = true,
	enum      = true,
	sequence  = true,
	array     = true,
	typedef   = true,
	except    = true,
	interface = true,
}

InterfaceElements = {
	attribute = true,
	operation = true,
	module    = true,
}

--------------------------------------------------------------------------------
-- Auxilary module functions ---------------------------------------------------

function istype(object)
	return type(object) == "table" and (
	       	BasicTypes[object._type] == object or
	       	UserTypes[object._type]
	       )
end

function isspec(object)
	return type(object) == "table" and (
	       	BasicTypes[object._type] == object or
	       	UserTypes[object._type] or
	       	InterfaceElements[object._type]
	       )
end

assert.TypeCheckers["idl type"]    = istype
assert.TypeCheckers["idl def."]    = isspec
assert.TypeCheckers["^idl (%l+)$"] = function(value, name)
	if istype(value)
		then return (value._type == name), ("idl "..name.." type")
		else return false, name
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function checkfield(field)
	assert.type(field.name, "string", "field name")
	assert.type(field.type, "idl type", "field type")
end

local function checkfields(fields)
	for _, field in ipairs(fields) do checkfield(field) end
end

--------------------------------------------------------------------------------
-- Basic types -----------------------------------------------------------------

for name in pairs(BasicTypes) do
	local basictype = {_type = name}
	_M[name] = basictype
	BasicTypes[name] = basictype
end

--------------------------------------------------------------------------------
-- Scoped definitions management -----------------------------------------------

function setnameof(contained, name)
	contained.name = name
	local container = contained.defined_in
	if container then
		local start, default = match(container.repID, "^(IDL:.*):(%d+%.%d+)$")
		if not start then
			assert.illegal(container.repID, "parent scope repository ID")
		end
		contained.repID = format("%s/%s:%s", start, contained.name,
		                                     contained.version or default)
	else
		contained.repID = format("IDL:%s:%s", contained.name,
		                                      contained.version or "1.0")
	end
	if contained.definitions then
		for _, contained in ipairs(contained.definitions) do
			setnameof(contained, contained.name)
		end
	end
end

--------------------------------------------------------------------------------

ContainerKey = newproxy()

Contents = oo.class()

function Contents:__newindex(name, contained)
	if type(name) == "string" then
		contained.defined_in = self[ContainerKey]
		setnameof(contained, name)
		return self:_add(contained)
	end
	rawset(self, name, contained)
end

function Contents:_add(contained)
	UnorderedArraySet.add(self, contained)
	rawset(self, contained.name, contained)
	return contained
end

function Contents:_remove(contained)
	contained = UnorderedArraySet.remove(self, contained)
	if contained then
		self[contained.name] = nil
		return contained
	end
end

function Contents:_removeat(index)
	return self:remove(self[index])
end

Contents._removebyname = Contents._removeat

--------------------------------------------------------------------------------

function Container(self)
	if not oo.instanceof(self.definitions, Contents) then
		local contents = Contents{ [ContainerKey] = self }
		if self.definitions then
			for _, value in ipairs(self.definitions) do
				assert.type(value.name, "string", "IDL definition name")
				contents:__newindex(value.name, value)
			end
			for field, value in pairs(self.definitions) do
				if type(field) == "string" then
					contents:__newindex(field, value)
				end
			end
		end
		self.definitions = contents
	end
	return self
end

--------------------------------------------------------------------------------

function Contained(self)
	assert.type(self, "table", "IDL definition")
	if self.name  == nil then self.name = "" end
	if self.repID == nil then setnameof(self, self.name) end
	assert.type(self.name, "string", "IDL definition name")
	assert.type(self.repID, "string", "repository ID")
	return self
end

--------------------------------------------------------------------------------
-- User-defined type constructors ----------------------------------------------

-- Note: internal structure is optimized for un/marshalling.

string = { _type = "string", maxlength = 0 }

function Object(self)
	if type(self) == "string"
		then self = {repID = self}
		else assert.type(self, "table", "Object type definition")
	end
	assert.type(self.repID, "string", "Object type repository ID")
	if self.repID == "IDL:omg.org/CORBA/Object:1.0"
		then self = object
		else self._type = "Object"
	end
	return self
end

function struct(self)
	self = Container(Contained(self))
	self._type = "struct"
	if self.fields == nil then self.fields = self end
	checkfields(self.fields)
	return self
end

function union(self)
	self = Container(Contained(self))
	self._type = "union"
	if self.options == nil then self.options = self end
	if self.default == nil then self.default = -1 end -- indicates no default in CDR
	
	assert.type(self.switch, "idl type", "union type discriminant")
	assert.type(self.options, "table", "union options definition")
	assert.type(self.default, "number", "union default option definition")
	
	self.selector = {} -- maps field names to labels (option selector)
	self.selection = {} -- maps labels (option selector) to options
	for index, option in ipairs(self.options) do
		checkfield(option)
		if option.label == nil then assert.illegal(nil, "option label value") end
		self.selector[option.name] = option.label
		if index ~= self.default + 1 then
			self.selection[option.label] = option
		end
	end
	
	function self.__index(union, field)
		if rawget(union, "_switch") == self.selector[field] then
			return rawget(union, "_value")
		end
	end
	function self.__newindex(union, field, value)
		local label = self.selector[field]
		if label then
			rawset(union, "_switch", label)
			rawset(union, "_value", value)
			rawset(union, "_field", field)
		end
	end
	
	return self
end

function enum(self)
	self = Contained(self)
	self._type = "enum"
	if self.enumvalues == nil then self.enumvalues = self end
	assert.type(self.enumvalues, "table", "enumeration values definition")
	
	self.labelvalue = {}
	for index, label in ipairs(self.enumvalues) do
		assert.type(label, "string", "enumeration value label")
		self.labelvalue[label] = index - 1
	end
	
	return self
end

function sequence(self)
	self._type = "sequence"
	if self.maxlength   == nil then self.maxlength = 0 end
	if self.elementtype == nil then self.elementtype = self[1] end
	assert.type(self.maxlength, "number", "sequence type maximum length ")
	assert.type(self.elementtype, "idl type", "sequence element type")
	return self
end

function array(self)
	self._type = "array"
	assert.type(self.length, "number", "array type length")
	if self.elementtype == nil then self.elementtype = self[1] end
	assert.type(self.elementtype, "idl type", "array element type")
	return self
end

function typedef(self)
	self = Contained(self)
	self._type = "typedef"
	if self.type == nil then self.type = self[1] end
	assert.type(self.type, "idl type", "type in typedef definition")
	return self
end

function except(self)
	self = Container(Contained(self))
	self._type = "except"
	if self.members == nil then self.members = self end
	checkfields(self.members)
	return self
end

--------------------------------------------------------------------------------
-- IDL interface definitions ---------------------------------------------------

-- Note: construtor syntax is optimized for use with Interface Repository

function attribute(self)
	self = Contained(self)
	self._type = "attribute"
	if self.type  == nil then self.type = self[1] end
	assert.type(self.type, "idl type", "attribute type")

	local mode = self.mode
	if mode == "ATTR_READONLY" then
		self.readonly = true
	elseif mode ~= nil and mode ~= "ATTR_NORMAL" then
		assert.illegal(self.mode, "attribute mode")
	end
	
	return self
end

function operation(self)
	self = Contained(self)
	self._type = "operation"
	
	local mode = self.mode
	if mode == "OP_ONEWAY" then
		self.oneway = true
	elseif mode ~= nil and mode ~= "OP_NORMAL" then
		assert.illegal(self.mode, "operation mode")
	end

	self.inputs = {}
	self.outputs = {}
	if self.result and self.result ~= void then
		self.outputs[#self.outputs+1] = self.result
	end
	if self.parameters then
		for _, param in ipairs(self.parameters) do
			checkfield(param)
			if param.mode then
				assert.type(param.mode, "string", "operation parameter mode")
				if param.mode == "PARAM_IN" then
					self.inputs[#self.inputs+1] = param.type
				elseif param.mode == "PARAM_OUT" then
					self.outputs[#self.outputs+1] = param.type
				elseif param.mode == "PARAM_INOUT" then
					self.inputs[#self.inputs+1] = param.type
					self.outputs[#self.outputs+1] = param.type
				else
					assert.illegal(param.mode, "operation parameter mode")
				end
			else
				self.inputs[#self.inputs+1] = param.type
			end
		end
	end

	if self.exceptions then
		for _, except in ipairs(self.exceptions) do
			assert.type(except, "idl except", "raised exception")
			if self.exceptions[except.repID] ~= nil then
				assert.illegal(except.repID,
					"exception raise defintion, got duplicated repository ID")
			end
			self.exceptions[except.repID] = except
		end
	else
		self.exceptions = {}
	end

	return self
end

function module(self)
	self = Container(Contained(self))
	self._type = "module"
	return self
end

--------------------------------------------------------------------------------

local function ibases(queue, interface)
	interface = queue[interface]
	if interface then
		for _, base in ipairs(interface.base_interfaces) do
			queue:enqueue(base)
		end
		return interface
	end
end
function basesof(self)
	local queue = OrderedSet()
	queue:enqueue(self)
	return ibases, queue, OrderedSet.firstkey
end

function interface(self)
	self = Container(Contained(self))
	self._type = "interface"
	if self.base_interfaces == nil then self.base_interfaces = self end
	assert.type(self.base_interfaces, "table", "base interface list")
	self.hierarchy = basesof
	return self
end


--------------------------------------------------------------------------------
-- IDL types used in the implementation of OiL ---------------------------------

object = interface{
	repID = "IDL:omg.org/CORBA/Object:1.0",
	name = "Object",
}
OctetSeq = sequence{octet}
Version = struct{{ type = octet, name = "major" },
                 { type = octet, name = "minor" }}
