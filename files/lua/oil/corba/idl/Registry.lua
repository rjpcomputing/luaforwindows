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
-- Title  : IDL Definition Registry                                           --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- interfaces:Facet
-- 	interface:table register(definition:table)
-- 	interface:table resolve(id:string)
-- 	[interface:table] lookup(name:string)
-- 	[interface:table] lookup_id(repid:string)
--------------------------------------------------------------------------------

local error        = error
local getmetatable = getmetatable
local ipairs       = ipairs
local next         = next
local pairs        = pairs
local rawget       = rawget
local select       = select
local setmetatable = setmetatable
local type         = type
local unpack       = unpack

local string = require "string"
local table  = require "table"

local OrderedSet = require "loop.collection.OrderedSet"
local Publisher  = require "loop.object.Publisher"

local oo        = require "oil.oo"
local assert    = require "oil.assert"
local idl       = require "oil.corba.idl"
local iridl     = require("oil.corba.idl.ir").definitions
local Exception = require "oil.corba.giop.Exception"                            --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.corba.idl.Registry"

--------------------------------------------------------------------------------
-- Internal classes ------------------------------------------------------------

  IRObject                = oo.class()
  Contained               = oo.class({}, IRObject)
  Container               = oo.class({}, IRObject)
  IDLType                 = oo.class({}, IRObject)
  
  PrimitiveDef            = oo.class({ __type = "IDL:omg.org/CORBA/PrimitiveDef:1.0"            }, IDLType)
  ArrayDef                = oo.class({ __type = "IDL:omg.org/CORBA/ArrayDef:1.0"                }, IDLType)
  SequenceDef             = oo.class({ __type = "IDL:omg.org/CORBA/SequenceDef:1.0"             }, IDLType)
  StringDef               = oo.class({ __type = "IDL:omg.org/CORBA/StringDef:1.0"               }, IDLType)
--WstringDef              = oo.class({ __type = "IDL:omg.org/CORBA/WstringDef:1.0"              }, IDLType)
--FixedDef                = oo.class({ __type = "IDL:omg.org/CORBA/FixedDef:1.0"                }, IDLType)
  
  MemberDef               = oo.class(nil                                                            , Contained)
  
  AttributeDef            = oo.class({ __type = "IDL:omg.org/CORBA/AttributeDef:1.0"            }, MemberDef)
  OperationDef            = oo.class({ __type = "IDL:omg.org/CORBA/OperationDef:1.0"            }, MemberDef)
--ValueMemberDef          = oo.class({ __type = "IDL:omg.org/CORBA/ValueMemberDef:1.0"          }, MemberDef)
--ConstantDef             = oo.class({ __type = "IDL:omg.org/CORBA/ConstantDef:1.0"             }, Contained)
  TypedefDef              = oo.class({ __type = "IDL:omg.org/CORBA/TypedefDef:1.0"              }, IDLType, Contained)
  
  StructDef               = oo.class({ __type = "IDL:omg.org/CORBA/StructDef:1.0"               }, TypedefDef , Container)
  UnionDef                = oo.class({ __type = "IDL:omg.org/CORBA/UnionDef:1.0"                }, TypedefDef , Container)
  EnumDef                 = oo.class({ __type = "IDL:omg.org/CORBA/EnumDef:1.0"                 }, TypedefDef)
  AliasDef                = oo.class({ __type = "IDL:omg.org/CORBA/AliasDef:1.0"                }, TypedefDef)
--NativeDef               = oo.class({ __type = "IDL:omg.org/CORBA/NativeDef:1.0"               }, TypedefDef)
--ValueBoxDef             = oo.class({ __type = "IDL:omg.org/CORBA/ValueBoxDef:1.0"             }, TypedefDef)
  
  Repository              = oo.class({ __type = "IDL:omg.org/CORBA/Repository:1.0"              }, Container)
  ModuleDef               = oo.class({ __type = "IDL:omg.org/CORBA/ModuleDef:1.0"               }, Contained, Container)
  ExceptionDef            = oo.class({ __type = "IDL:omg.org/CORBA/ExceptionDef:1.0"            }, Contained, Container)
  InterfaceDef            = oo.class({ __type = "IDL:omg.org/CORBA/InterfaceDef:1.0"            }, IDLType, Contained, Container)
--ValueDef                = oo.class({ __type = "IDL:omg.org/CORBA/ValueDef:1.0"                }, Container, Contained, IDLType)
  
--AbstractInterfaceDef    = oo.class({ __type = "IDL:omg.org/CORBA/AbstractInterfaceDef:1.0"    }, InterfaceDef)
--LocalInterfaceDef       = oo.class({ __type = "IDL:omg.org/CORBA/LocalInterfaceDef:1.0"       }, InterfaceDef)
  
--ExtAttributeDef         = oo.class({ __type = "IDL:omg.org/CORBA/ExtAttributeDef:1.0"         }, AttributeDef)
--ExtValueDef             = oo.class({ __type = "IDL:omg.org/CORBA/ExtValueDef:1.0"             }, ValueDef)
--ExtInterfaceDef         = oo.class({ __type = "IDL:omg.org/CORBA/ExtInterfaceDef:1.0"         }, InterfaceDef, InterfaceAttrExtension)
--ExtAbstractInterfaceDef = oo.class({ __type = "IDL:omg.org/CORBA/ExtAbstractInterfaceDef:1.0" }, AbstractInterfaceDef, InterfaceAttrExtension)
--ExtLocalInterfaceDef    = oo.class({ __type = "IDL:omg.org/CORBA/ExtLocalInterfaceDef:1.0"    }, LocalInterfaceDef, InterfaceAttrExtension)
  
  ObjectRef               = oo.class() -- fake class

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Empty = setmetatable({}, { __newindex = function(_, field) verbose:debug("attempt to set table 'Empty'") end })

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--
-- Implementation
--

function IRObject:__init(...)
	self = oo.rawnew(self, ...)
	self.references = self.references or {}
	self.observer = self.observer or Publisher()
	return self
end

function IRObject:watch(object, field)
	local references = object.references
	if references then
		if not references[self] then
			references[self] = {}
		end
		references[self][field] = true
	end
	return object
end

function IRObject:nowatch(object, field)
	local references = object.references
	if references then
		references[self][field] = nil
		if next(references[self]) == nil then
			references[self] = nil
		end
	end
end

function IRObject:notify(...)
	local queue = OrderedSet()
	queue:enqueue(self)
	repeat
		if self.observer then self.observer:notify(...) end
		if self.references then
			for ref in pairs(self.references) do queue:enqueue(ref) end
		end
		self = queue[self]
	until self == nil
end

--
-- Operations
--
function IRObject:destroy()
	if self.observer == nil or next(self.references) ~= nil then
		assert.exception{ "BAD_INV_ORDER", minor_error_code = 1,
			message = "attempt to destroy IR definition in use",
			reason = "irdestroy",
			object = self,
		}
	end
	if self.defined_in then
		self.defined_in.definitions:_remove(self)
	end
	self.containing_repository.definition_map[self.repID] = nil
end

--------------------------------------------------------------------------------

--
-- Implementation
--
Contained.version = "1.0"
Contained.definition_fields = {
	defined_in = { type = Container, optional = true },
	repID      = { type = "string" , optional = true },
	version    = { type = "string" , optional = true },
	name       = { type = "string" },
}

function Contained:update(new)
	new.defined_in = new.defined_in or self.containing_repository
	if new.defined_in.containing_repository ~= self.containing_repository then
		assert.illegal(defined_in,
		              "container, repository does not match",
		              "BAD_PARAM")
	end
	if new.repID then
		self:_set_id(new.repID)
	end
	self:move(new.defined_in, new.name, new.version)
end

local RepIDFormat = "IDL:%s:%s"
function Contained:updatename()
	local old = self.absolute_name
	self.absolute_name = self.defined_in.absolute_name.."::"..self.name
	if not self.repID then
		self:_set_id(RepIDFormat:format(self.absolute_name:gsub("::", "/"):sub(2),
		                                self.version))
	end
	if self.definitions then
		for _, contained in ipairs(self.definitions) do
			contained:updatename()
		end
	end
	if self.absolute_name ~= old then self:notify("absolute_name") end
end

--
-- Attributes
--
function Contained:_set_id(id)
	local definitions = self.containing_repository.definition_map
	if definitions[id] and definitions[id] ~= self then
		assert.illegal(id, "repository ID, already exists", "BAD_PARAM", 2)
	end
	if self.repID then
		definitions[self.repID] = nil
	end
	local old = self.repID
	self.repID = id
	self.id = id
	definitions[id] = self
	if self.repID ~= old then self:notify("repID") end
end

function Contained:_set_name(name)
	local contents = self.defined_in.definitions
	if contents[name] and contents[name] ~= self then
		assert.illegal(name, "contained name, name clash", "BAD_PARAM", 1)
	end
	local old = self.name
	contents:_remove(self)
	self.name = name
	contents:_add(self)
	self:updatename()
	if self.name ~= old then self:notify("name") end
end

--
-- Operations
--
local ContainedDescription = iridl.Contained.definitions.Description
function Contained:describe()
	local description = self:get_description()
	description.name       = self.name
	description.id         = self.repID
	description.defined_in = self.defined_in.repID
	description.version    = self.version
	return setmetatable({
		kind = self.def_kind,
		value = description,
	}, ContainedDescription)
end

--function Contained:within() -- TODO:[maia] This op is described in specs but
--end                         --             is not listed in IR IDL!

function Contained:move(new_container, new_name, new_version)
	if new_container.containing_repository ~= self.containing_repository then
		assert.illegal(new_container, "container", "BAD_PARAM", 4)
	end
	
	local new = new_container.definitions
	if new[new_name] and new[new_name] ~= self then
		assert.illegal(new_name, "contained name, already exists", "BAD_PARAM", 3)
	end
	
	if self.defined_in then
		self.defined_in.definitions:_remove(self)
	end
	
	local old = self.defined_in
	self.defined_in = new_container
	self.version = new_version
	self:_set_name(new_name)
	if self.defined_in ~= old then
		if old then old:notify("contents") end
		self.defined_in:notify("contents")
		self:notify("defined_in")
	end
end

--------------------------------------------------------------------------------

--
-- Implementation
--
function Container:update()
	if not self.expandable then self.definitions = nil end
	idl.Container(self)
end

local function isingle(self, ended)
	if not ended then return self end
end
function Container:hierarchy()
	return isingle, self
end

--
-- Read interface
--

function Container:lookup(search_name)
	local scope
	if search_name:find("^::") then
		scope = self.containing_repository
	else
		scope = self
		search_name = "::"..search_name
	end
	for nextscope in string.gmatch(search_name, "::([^:]+)") do
		if not scope or not scope.definitions then return nil end
		scope = scope.definitions[nextscope]
	end
	return scope
end

function Container:contents(limit_type, exclude_inherited, max_returned_objs)
	max_returned_objs = max_returned_objs or -1
	local contents = {}
	for container in self:hierarchy() do
		for _, contained in ipairs(container.definitions)	do
			if limit_type == "dk_all" or contained.def_kind == limit_type then
				if max_returned_objs == 0 then break end
				contents[#contents+1] = contained
				max_returned_objs = max_returned_objs - 1
			end
		end
		if exclude_inherited then break end
	end
	return contents, max_returned_objs
end

function Container:lookup_name(search_name, levels_to_search,
                               limit_type, exclude_inherited)
	local results = {}
	for container in self:hierarchy() do
		for _, contained in ipairs(container.definitions)	do
			if
				contained.name == search_name and
				(limit_type == "dk_all" or contained.def_kind == limit_type)
			then
				results[#results+1] = contained
			end
		end
		if exclude_inherited then break end
	end
	return results
end

local ContainerDescription = iridl.Container.definitions.Description
function Container:describe_contents(limit_type, exclude_inherited,
                                     max_returned_objs)
	local contents = self:contents(limit_type,
	                               exclude_inherited,
	                               max_returned_objs)
	for index, content in ipairs(contents) do
		contents[index] = setmetatable({
			contained_object = content,
			kind = content.def_kind,
			value = content:describe(),
		}, ContainerDescription)
	end
	return contents
end

--
-- Write interface
--

function Container:create_module(id, name, version)
	local created = ModuleDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,
	}
	return created
end

--function Container:create_constant(id, name, version, type, value)
--end

function Container:create_struct(id, name, version, members)
	local created = StructDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,
		
		fields = members,
	}
	return created
end

function Container:create_union(id, name, version, discriminator_type, members)
	local created = UnionDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,
		
		switch = discriminator_type.type,
		members = members,
	}
	return created
end

function Container:create_enum(id, name, version, members)
	local created = EnumDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,
		
		enumvalues = members,
	}
	return created
end

function Container:create_alias(id, name, version, original_type)
	local created = AliasDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,
		
		type = original_type.type
	}
	return created
end

function Container:create_interface(id, name, version, base_interfaces)
	local created = InterfaceDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,

		base_interfaces = base_interfaces,
	}
	return created
end

--function Container:create_value(id, name, version,
--                                is_custom,
--                                is_abstract,
--																base_value,
--																is_truncatable,
--																abstract_base_values,
--																supported_interfaces,
--																initializers)
--end
--
--function Container:create_value_box(id, name, version, original_type_def)
--end

function Container:create_exception(id, name, version, members)
	local created = ExceptionDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,
		
		members = members,
	}
	return created
end

--function Container:create_native(id, name, version)
--end
--
--function Container:create_abstract_interface(id, name, version, base_interfaces)
--end
--
--function Container:create_local_interface(id, name, version, base_interfaces)
--end
--
--function Container:create_ext_value(id, name, version,
--                                    is_custom,
--                                    is_abstract,
--                                    base_value,
--                                    is_truncatable,
--                                    abstract_base_values,
--                                    supported_interfaces,
--                                    initializers)
--end

--------------------------------------------------------------------------------

function IDLType:update()
	self.type = self
end

--------------------------------------------------------------------------------

local PrimitiveTypes = {
	pk_null       = idl.null,
	pk_void       = idl.void,
	pk_short      = idl.short,
	pk_long       = idl.long,
	pk_longlong   = idl.longlong,
	pk_ushort     = idl.ushort,
	pk_ulong      = idl.ulong,
	pk_ulonglong  = idl.ulonglong,
	pk_float      = idl.float,
	pk_double     = idl.double,
	pk_longdouble = idl.double,
	pk_boolean    = idl.boolean,
	pk_char       = idl.char,
	pk_octet      = idl.octet,
	pk_any        = idl.any,
	pk_TypeCode   = idl.TypeCode,
	pk_string     = idl.string,
	pk_objref     = idl.object,
}

PrimitiveDef.def_kind = "dk_Primitive"

function PrimitiveDef:__init(object)
	self = oo.rawnew(self, object)
	IDLType.update(self)
	return self
end

for kind, type in pairs(PrimitiveTypes) do
	PrimitiveDef(type).kind = kind
end

--------------------------------------------------------------------------------

function ObjectRef:__init(object, registry)
	if object.repID ~= PrimitiveTypes.pk_objref.repID then
		return registry.repository:lookup_id(object.repID) or
		       assert.illegal(new, "Object type, use interface definition instead")
	end
	return PrimitiveTypes.pk_objref
end

--------------------------------------------------------------------------------

ArrayDef._type = "array"
ArrayDef.def_kind = "dk_Array"
ArrayDef.definition_fields = {
	length      = { type = "number" },
	elementtype = { type = IDLType  },
}

function ArrayDef:update(new, registry)
	self.length = new.length
	self:_set_element_type_def(new.elementtype, registry)
end

function ArrayDef:_get_element_type() return self.elementtype end

function ArrayDef:_set_element_type_def(type_def, registry)
	local old = self.elementtype
	type_def = self.containing_repository:put(type_def.type, registry)
	if self.element_type_def then
		self:nowatch(self.element_type_def, "elementtype")
	end
	self.element_type_def = type_def
	self.elementtype = type_def.type
	self:watch(self.element_type_def, "elementtype")
	if self.elementtype ~= old then self:notify("elementtype") end
end

--------------------------------------------------------------------------------

SequenceDef._type = "sequence"
SequenceDef.def_kind = "dk_Sequence"
SequenceDef.maxlength = 0
SequenceDef.definition_fields = {
	maxlength   = { type = "number", optional = true },
	elementtype = { type = IDLType  },
}

function SequenceDef:update(new, registry)
	self.maxlength = new.maxlength
	self:_set_element_type_def(new.elementtype, registry)
end

SequenceDef._get_element_type = ArrayDef._get_element_type
SequenceDef._set_element_type_def = ArrayDef._set_element_type_def
function SequenceDef:_set_bound(value) self.maxlength = value end
function SequenceDef:_get_bound() return self.maxlength end

--------------------------------------------------------------------------------

StringDef._type = "string"
StringDef.def_kind = "dk_String"
StringDef.maxlength = 0
StringDef.definition_fields = {
	maxlength   = { type = "number", optional = true },
}
StringDef._set_bound = SequenceDef._set_bound
StringDef._get_bound = SequenceDef._get_bound

--------------------------------------------------------------------------------

function MemberDef:move(new_container, new_name, new_version)
	local name = self.name
	local container = self.defined_in
	Contained.move(self, new_container, new_name, new_version)
	if container then container:nowatch(self, name) end
	self.defined_in:watch(self, self.name)
end

--------------------------------------------------------------------------------

AttributeDef._type = "attribute"
AttributeDef.def_kind = "dk_Attribute"
AttributeDef.definition_fields = {
	defined_in = { type = InterfaceDef, optional = true },
	readonly   = { type = "boolean", optional = true },
	type       = { type = IDLType },
}

function AttributeDef:update(new, registry)
	self:_set_mode(new.readonly and "ATTR_READONLY" or "ATTR_NORMAL")
	self:_set_type_def(new.type, registry)
end

function AttributeDef:_set_mode(value)
	local old = self.readonly
	self.mode = value
	self.readonly = (value == "ATTR_READONLY")
	if self.readonly ~= old then self:notify("readonly") end
end

function AttributeDef:_set_type_def(type_def, registry)
	local old = self.type
	type_def = self.containing_repository:put(type_def.type, registry)
	if self.type_def then
		self:nowatch(self.type_def, "type")
	end
	self.type_def = type_def
	self.type = type_def.type
	self:watch(self.type_def, "type")
	if self.type ~= old then self:notify("type") end
end

function AttributeDef:get_description()
	return setmetatable({
		type = self.type,
		mode = self.mode,
	}, iridl.AttributeDescription)
end

--------------------------------------------------------------------------------

OperationDef._type = "operation"
OperationDef.def_kind = "dk_Operation"
OperationDef.contexts = Empty
OperationDef.parameters = Empty
OperationDef.inputs = Empty
OperationDef.outputs = Empty
OperationDef.exceptions = Empty
OperationDef.result = idl.void
OperationDef.result_def = idl.void
OperationDef.definition_fields = {
	defined_in = { type = InterfaceDef, optional = true },
	oneway     = { type = "boolean"   , optional = true },
	contexts   = { type = "table"     , optional = true },
	exceptions = { type = ExceptionDef, optional = true, list = true },
	result     = { type = IDLType     , optional = true },
	parameters = { type = {
		name = { type = "string" },
		type = { type = IDLType },
		mode = { type = "string", optional = true },
	}, optional = true, list = true },
}

function OperationDef:update(new, registry)
	self:_set_mode(new.oneway and "OP_ONEWAY" or "OP_NORMAL")
	if new.exceptions then self:_set_exceptions(new.exceptions, registry) end
	if new.result then self:_set_result_def(new.result, registry) end
	if new.parameters then self:_set_params(new.parameters, registry) end
	self.contexts = new.contexts
end

function OperationDef:_set_mode(value)
	local old = self.oneway
	self.mode = value
	self.oneway = (value == "OP_ONEWAY")
	if self.oneway ~= old then self:notify("oneway") end
end

function OperationDef:_set_result_def(type_def, registry)
	type_def = self.containing_repository:put(type_def.type, registry)
	local current = self.result
	local newval = type_def.type
	if current ~= newval then
		if self.result_def then
			self:nowatch(self.result_def, "result")
		end
		self.result_def = type_def
		self.result = newval
		self:watch(self.result_def, "result")
		if current == idl.void then
			if self.outputs == Empty then
				self.outputs = { newval }
			else
				table.insert(self.outputs, 1, newval)
			end
		elseif newval == idl.void then
			table.remove(self.outputs, 1)
		else
			self.outputs[1] = newval
		end
		self:notify("result")
	end
end

function OperationDef:_get_params() return self.parameters end
function OperationDef:_set_params(parameters, registry)
	local inputs = {}
	local outputs = {}
	if self.result ~= idl.void then
		outputs[#outputs+1] = self.result
	end
	for index, param in ipairs(parameters) do
		param.type_def = self.containing_repository:put(param.type, registry)
		param.type = param.type_def.type
		param.mode = param.mode or "PARAM_IN"
		if param.mode == "PARAM_IN" then
			inputs[#inputs+1] = param.type
		elseif param.mode == "PARAM_OUT" then
			outputs[#outputs+1] = param.type
		elseif param.mode == "PARAM_INOUT" then
			inputs[#inputs+1] = param.type
			outputs[#outputs+1] = param.type
		else
			assert.illegal(mode, "operation parameter mode")
		end
	end
	for index, param in ipairs(self.parameters) do
		self:nowatch(param.type_def, "parameter "..index)
	end
	self.parameters = parameters
	self.inputs = inputs
	self.outputs = outputs
	for index, param in ipairs(self.parameters) do
		self:watch(param.type_def, "parameter "..index)
	end
	self:notify("parameters")
end

function OperationDef:_set_exceptions(exceptions, registry)
	for index, except in ipairs(exceptions) do
		except = self.containing_repository:put(except:get_description().type, registry)
		exceptions[index] = except
		exceptions[except.repID] = except
	end
	for index, except in ipairs(self.exceptions) do
		self:nowatch(except, "exception "..index)
	end
	self.exceptions = exceptions
	for index, except in ipairs(self.exceptions) do
		self:watch(except, "exception "..index)
	end
	self:notify("exceptions")
end

function OperationDef:get_description()
	local exceptions = {}
	for _, except in ipairs(self.exceptions) do
		exceptions[#exceptions+1] = except:describe().value
	end
	return setmetatable({
		result     = self.result,
		mode       = self.mode,
		contexts   = self.contexts,
		parameters = self.parameters,
		exceptions = exceptions,
	}, iridl.OperationDescription)
end

--------------------------------------------------------------------------------

TypedefDef._type = "typedef"
TypedefDef.def_kind = "dk_Typedef"

function TypedefDef:get_description()
	return setmetatable({ type = self.type }, iridl.TypeDescription)
end

--------------------------------------------------------------------------------

StructDef._type = "struct"
StructDef.def_kind = "dk_Struct"
StructDef.fields = Empty
StructDef.definition_fields = {
	fields = {
		type = {
			name = { type = "string" },
			type = { type = IDLType },
		},
		optional = true,
		list = true,
	},
}

function StructDef:update(new, registry)
	if new.fields then self:_set_members(new.fields, registry) end
end

function StructDef:_get_members() return self.fields end
function StructDef:_set_members(members, registry)
	for index, field in ipairs(members) do
		field.type_def = self.containing_repository:put(field.type, registry)
		field.type = field.type_def.type
	end
	for index, field in ipairs(self.fields) do
		self:nowatch(field.type_def, "field "..field.name)
	end
	self.fields = members
	for index, field in ipairs(self.fields) do
		self:watch(field.type_def, "field "..field.name)
	end
	self:notify("fields")
end

--------------------------------------------------------------------------------

UnionDef._type = "union"
UnionDef.def_kind = "dk_Union"
UnionDef.default = -1
UnionDef.options = Empty
UnionDef.members = Empty
UnionDef.definition_fields = {
	switch  = { type = IDLType },
	default = { type = "number", optional = true },
	options = { type = {
		label = { type = nil },
		name  = { type = "string" },
		type  = { type = IDLType },
	}, optional = true, list = true },
}

function UnionDef:update(new, registry)
	self:_set_discriminator_type_def(new.switch, registry)
	
	if new.options then
		for _, option in ipairs(new.options) do
			option.label = setmetatable({ _anyval = option.label }, self.switch)
		end
		self:_set_members(new.options)
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
end

function UnionDef:_get_discriminator_type() return self.switch end

function UnionDef:_set_discriminator_type_def(type_def, registry)
	local old = self.switch
	type_def = self.containing_repository:put(type_def.type, registry)
	if self.discriminator_type_def then
		self:nowatch(self.discriminator_type_def, "switch")
	end
	self.discriminator_type_def = type_def
	self.switch = type_def.type
	self:watch(self.discriminator_type_def, "switch")
	if self.switch ~= old then self:notify("switch") end
end

function UnionDef:_set_members(members, registry)
	local options = {}
	local selector = {}
	local selection = {}
	
	for index, member in ipairs(members) do
		member.type_def = self.containing_repository:put(member.type, registry)
		member.type = member.type_def.type
		local option = {
			label = member.label._anyval,
			name = member.name,
			type = member.type,
			type_def = member.type_def,
		}
		options[index] = option
		selector[option.name] = option.label
		selection[option.label] = option
	end
	for index, member in ipairs(self.members) do
		self:nowatch(member.type_def, "option "..index)
	end
	self.options = options
	self.selector = selector
	self.selection = selection
	self.members = members
	for index, member in ipairs(self.members) do
		self:watch(member.type_def, "option "..index)
	end
	self:notify("options")
end

--------------------------------------------------------------------------------

EnumDef._type = "enum"
EnumDef.def_kind = "dk_Enum"
EnumDef.definition_fields = {
	enumvalues = { type = "string", list = true },
}

function EnumDef:update(new)
	self:_set_members(new.enumvalues)
end

function EnumDef:_get_members() return self.enumvalues end
function EnumDef:_set_members(members)
	local labelvalue = {}
	for index, label in ipairs(members) do
		labelvalue[label] = index - 1
	end
	self.enumvalues = members
	self.labelvalue = labelvalue
	self:notify("enumvalues")
end

--------------------------------------------------------------------------------

AliasDef._type = "typedef"
AliasDef.def_kind = "dk_Alias"
AliasDef.definition_fields = {
	type = { type = IDLType },
}

function AliasDef:update(new, registry)
	self:_set_original_type_def(new.type, registry)
end

function AliasDef:_set_original_type_def(type_def, registry)
	local old = self.type
	type_def = self.containing_repository:put(type_def.type, registry)
	self.original_type_def = type_def
	self.type = type_def.type
	if self.type ~= old then self:notify("type") end
end

--------------------------------------------------------------------------------

Repository.def_kind = "dk_Repository"
Repository.repID = ""
Repository.absolute_name = ""

function Repository:__init(object)
	self = oo.rawnew(self, object)
	self.containing_repository = self
	self.definition_map = self.definition_map or {}
	Container.update(self, self)
	return self
end

--
-- Read interface
--

function Repository:lookup_id(search_id)
	return self.definition_map[search_id]
end

--function Repository:get_canonical_typecode(tc)
--end

function Repository:get_primitive(kind)
	return PrimitiveTypes[kind]
end

--
-- Write interface
--
--
--function Repository:create_string(bound)
--end
--
--function Repository:create_wstring(bound)
--end

function Repository:create_sequence(bound, element_type)
	local created = SequenceDef{ containing_repository=self.containing_repository }
	created:update{
		elementtype = element_type.type,
		maxlength = bound,
	}
	return created
end

function Repository:create_array(length, element_type)
	local created = ArrayDef{ containing_repository=self.containing_repository }
	created:update{
		elementtype = element_type.type,
		length = length,
	}
	return created
end

--function Repository:create_fixed(digits, scale)
--end

--------------------------------------------------------------------------------

--function ExtAttributeDef:describe_attribute()
--end

--------------------------------------------------------------------------------

ModuleDef._type = "module"
ModuleDef.def_kind = "dk_Module"
ModuleDef.expandable = true

function ModuleDef:get_description()
	return setmetatable({}, iridl.ModuleDescription)
end

--------------------------------------------------------------------------------

ExceptionDef._type = "except"
ExceptionDef.def_kind = "dk_Exception"
ExceptionDef.members = Empty
ExceptionDef.definition_fields = {
	members = { type = {
		name = { type = "string" },
		type = { type = IDLType },
	}, optional = true, list = true },
}

function ExceptionDef:update(new, registry)
	self.type = self
	if new.members then self:_set_members(new.members, registry) end
end

function ExceptionDef:_set_members(members, registry)
	for index, member in ipairs(members) do
		member.type_def = self.containing_repository:put(member.type, registry)
		member.type = member.type_def.type
	end
	for index, member in ipairs(self.members) do
		self:nowatch(member.type_def, "member "..member.name)
	end
	self.members = members
	for index, member in ipairs(self.members) do
		self:watch(member.type_def, "member "..member.name)
	end
	self:notify("members")
end

function ExceptionDef:get_description()
	return setmetatable({ type = self }, iridl.ExceptionDescription)
end

--------------------------------------------------------------------------------

InterfaceDef._type = "interface"
InterfaceDef.def_kind = "dk_Interface"
InterfaceDef.base_interfaces = Empty
InterfaceDef.definition_fields = {
	base_interfaces = { type = InterfaceDef, optional = true, list = true },
}

InterfaceDef.hierarchy = idl.basesof

function InterfaceDef:update(new)
	if new.base_interfaces then
		self:_set_base_interfaces(new.base_interfaces)
	end
end

function InterfaceDef:get_description()
	local base_interfaces = {}
	for index, base in ipairs(self.base_interfaces) do
		base_interfaces[index] = base.repID
	end
	return setmetatable({ base_interfaces = base_interfaces },
	                    iridl.InterfaceDescription)
end

--
-- Read interface
--

function InterfaceDef:is_a(interface_id)
	if interface_id == self.repID then return true end
	for _, base in ipairs(self.base_interfaces) do
		if base:is_a(interface_id) then return true end
	end
	return false
end

local FullIfaceDescription = iridl.InterfaceDef.definitions.FullInterfaceDescription
function InterfaceDef:describe_interface()
	local operations = {}
	local attributes = {}
	local base_interfaces = {}
	for index, base in ipairs(self.base_interfaces) do
		base_interfaces[index] = base.repID
	end
	for base in self:hierarchy() do
		for _, contained in ipairs(base.definitions) do
			if contained._type == "attribute" then
				attributes[#attributes+1] = contained:describe().value
			elseif contained._type == "operation" then
				operations[#operations+1] = contained:describe().value
			end
		end
	end
	return setmetatable({
		name = self.name,
		id = self.id,
		defined_in = self.defined_in.repID,
		version = self.version,
		base_interfaces = base_interfaces,
		type = self,
		operations = operations,
		attributes = attributes,
	}, FullIfaceDescription)
end

--
-- Write interface
--

function InterfaceDef:_set_base_interfaces(bases)
	for _, interface in ipairs(bases) do
		assert.type(interface, "idl interface", "BAD_PARAM", 4)
		for _, contained in ipairs(self.definitions) do
			if #interface:lookup_name(contained.name, -1, "dk_All", false) > 0 then
				assert.illegal(bases,
				               "base interfaces, member '"..
				               member.name..
				               "' override not allowed",
				               "BAD_PARAM", 5)
			end
		end
	end
	for index, base in ipairs(self.base_interfaces) do
		self:nowatch(base, "base "..index)
	end
	self.base_interfaces = bases
	for index, base in ipairs(self.base_interfaces) do
		self:watch(base, "base "..index)
	end
	self:notify("bases")
end

function InterfaceDef:create_attribute(id, name, version, type, mode)
	local created = AttributeDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,
		
		type = type.type,
		readonly = (mode == "ATTR_READONLY"),
	}
	return created
end

function InterfaceDef:create_operation(id, name, version,
                                       result, mode, params,
                                       exceptions, contexts)
	local created = OperationDef{ containing_repository=self.containing_repository }
	created:update{
		defined_in = self,
		
		repID = id,
		name = name,
		version = version,
		
		result = result.type,
		
		parameters = params,
		exceptions = exceptions,
		contexts = contexts,
		
		oneway = (mode == "OP_ONEWAY"),
	}
	return created
end

--------------------------------------------------------------------------------

--
-- Read interface
--
--
--function InterfaceAttrExtension:describe_ext_interface()
--end

--
-- Write interface
--
--
--function InterfaceAttrExtension:create_ext_attribute()
--end

--------------------------------------------------------------------------------

--
-- Read interface
--
--
--function ValueDef:is_a(id)
--end
--
--function ValueDef:describe_value()
--end

--
-- Write interface
--
--
--function ValueDef:create_value_member(id, name, version, type, access)
--end
--
--function ValueDef:create_attribute(id, name, version, type, mode)
--end
--
--function ValueDef:create_operation(id, name, version,
--                                   result, mode, params,
--                                   exceptions, contexts)
--end

--------------------------------------------------------------------------------

--
-- Read interface
--
--
--function ExtValueDef:describe_ext_value()
--end

--
-- Write interface
--
--
--function ExtValueDef:create_ext_attribute(id, name, version, type, mode,
--                                          get_exceptions, set_exceptions)
--end


--------------------------------------------------------------------------------
-- Implementation --------------------------------------------------------------

oo.class(_M, Repository)

Classes = {
	struct     = StructDef,
	union      = UnionDef,
	enum       = EnumDef,
	sequence   = SequenceDef,
	array      = ArrayDef,
	string     = StringDef,
	typedef    = AliasDef,
	except     = ExceptionDef,
	attribute  = AttributeDef,
	operation  = OperationDef,
	module     = ModuleDef,
	interface  = InterfaceDef,
	Object     = ObjectRef,
}

--------------------------------------------------------------------------------

local function topdown(stack, class)
	while stack[class] do
		local ready = true
		for _, super in oo.supers(stack[class]) do
			if stack:insert(super, class) then
				ready = false
				break
			end
		end
	 	if ready then return stack[class] end
	end
end
local function iconstruct(class)
	local stack = OrderedSet()
	stack:push(class)
	return topdown, stack, OrderedSet.firstkey
end

local function getupdate(self, value, name, typespec)
	if type(typespec) == "string" then
		assert.type(value, typespec, name)
	elseif type(typespec) == "table" then
		if oo.isclass(typespec) then
			value = self[value]
			if not oo.instanceof(value, typespec) then
				assert.illegal(value, name)
			end
		else
			local new = {}
			for name, field in pairs(typespec) do
				local result = value[name]
				if result ~= nil or not field.optional then
					if field.list then
						local new = {}
						for index, value in ipairs(result) do
							new[index] = getupdate(self, value, name, field.type)
						end
						result = new
					else
						result = getupdate(self, result, name, field.type)
					end
				end
				new[name] = result
			end
			value = new
		end
	end
	return value
end

Registry = oo.class()

function Registry:__init(object)
	self = oo.rawnew(self, object)
	self[PrimitiveTypes.pk_null      ] = PrimitiveTypes.pk_null
	self[PrimitiveTypes.pk_void      ] = PrimitiveTypes.pk_void
	self[PrimitiveTypes.pk_short     ] = PrimitiveTypes.pk_short
	self[PrimitiveTypes.pk_long      ] = PrimitiveTypes.pk_long
	self[PrimitiveTypes.pk_longlong  ] = PrimitiveTypes.pk_longlong
	self[PrimitiveTypes.pk_ushort    ] = PrimitiveTypes.pk_ushort
	self[PrimitiveTypes.pk_ulong     ] = PrimitiveTypes.pk_ulong
	self[PrimitiveTypes.pk_ulonglong ] = PrimitiveTypes.pk_ulonglong
	self[PrimitiveTypes.pk_float     ] = PrimitiveTypes.pk_float
	self[PrimitiveTypes.pk_double    ] = PrimitiveTypes.pk_double
	self[PrimitiveTypes.pk_longdouble] = PrimitiveTypes.pk_longdouble
	self[PrimitiveTypes.pk_boolean   ] = PrimitiveTypes.pk_boolean
	self[PrimitiveTypes.pk_char      ] = PrimitiveTypes.pk_char
	self[PrimitiveTypes.pk_octet     ] = PrimitiveTypes.pk_octet
	self[PrimitiveTypes.pk_any       ] = PrimitiveTypes.pk_any
	self[PrimitiveTypes.pk_TypeCode  ] = PrimitiveTypes.pk_TypeCode
	self[PrimitiveTypes.pk_string    ] = PrimitiveTypes.pk_string
	self[PrimitiveTypes.pk_objref    ] = PrimitiveTypes.pk_objref
	self[self.repository             ] = self.repository
	return self
end

function Registry:__index(definition)
	if definition then
		local repository = self.repository
		local class = repository.Classes[definition._type]
		local result
		if class then
			result = repository:lookup_id(definition.repID)
			if definition ~= result then                                              --[[VERBOSE]] verbose:repository(true, definition._type," ",definition.repID or definition.name)
				result = class(result)
				result.containing_repository = repository
				self[definition] = result -- to avoid loops in cycles during 'getupdate'
				self[result] = result
				for class in iconstruct(class) do                                       --[[VERBOSE]] verbose:repository("[",class.__type,"]")
					local update = oo.memberof(class, "update")
					if update then
						local fields = oo.memberof(class, "definition_fields")
						local new = fields and getupdate(self, definition, "object", fields)
						update(result, new, self)
					end
				end                                                                     --[[VERBOSE]] verbose:repository(false)
				if oo.instanceof(result, Container) then
					for _, contained in ipairs(definition.definitions) do
						getupdate(self, contained, "contained", Contained)
					end
				end
			end
		elseif oo.classof(definition) == _M then
			result = self.repository
		end
		self[definition] = result
		self[result] = result
		return result
	end
end

--------------------------------------------------------------------------------

function put(self, definition, registry)
	registry = registry or self.Registry{ repository = self }
	return registry[definition]
end

function register(self, ...)
	local registry = self.Registry{ repository = self }
	local results = {}
	local count = select("#", ...)
	for i = 1, count do
		local definition = select(i, ...)
		assert.type(definition, "table", "IR object definition")
		results[i] = registry[definition]
	end
	return unpack(results, 1, count)
end

function resolve(self, typeref)
	local result, errmsg = type(typeref)
	if result == "string" then
		result = self:lookup(typeref) or self:lookup_id(typeref)
		if not result then
			errmsg = Exception{ "INTERNAL", minor_code_value = 0,
				reason = "interface",
				message = "unknown interface",
				interface = typeref,
			}
		end
	elseif result == "table" and typeref._type == "interface" then
		return self:register(typeref)
	else
		result, errmsg = nil, Exception{ "INTERNAL", minor_code_value = 0,
			reason = "interface",
			message = "illegal IDL type",
			type = typeref,
		}
	end
	return result, errmsg
end
