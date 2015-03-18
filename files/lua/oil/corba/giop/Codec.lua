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
-- Title  : Mapping of Lua values into Common Data Representation (CDR)       --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- decoder interface:                                                         --
--   order(value)    Change or return the endianess of the buffer             --
--   jump(shift)     Places an empty space in the data of the buffer          --
--   getdata()       Returns the raw data stream of marshalled data           --
--   get(type)       Unmarhsall a value of the given type                     --
--                                                                            --
--   void()          Unmarshall a void type value                             --
--   short()         Unmarshall an integer type short value                   --
--   long()          Unmarshall an integer type long value                    --
--   ushort()        Unmarshall an integer type unsigned short value          --
--   ulong()         Unmarshall an integer type unsigned long value           --
--   float()         Unmarshall a floating-point numeric type value           --
--   double()        Unmarshall a double-precision floating-point num. value  --
--   boolean()       Unmarshall a boolean type value                          --
--   char()          Unmarshall a character type value                        --
--   octet()         Unmarshall a raw byte type value                         --
--   any()           Unmarshall a generic type value                          --
--   TypeCode()      Unmarshall a meta-type value                             --
--   string()        Unmarshall a string type value                           --
--                                                                            --
--   Object(type)    Unmarhsall an Object type value, given its type          --
--   struct(type)    Unmarhsall a struct type value, given its type           --
--   union(type)     Unmarhsall a union type value, given its type            --
--   enum(type)      Unmarhsall an enumeration type value, given its type     --
--   sequence(type)  Unmarhsall a sequence type value, given its type         --
--   array(type)     Unmarhsall an array type value, given its type           --
--   typedef(type)   Unmarhsall a type definition value, given its type       --
--   except(type)    Unmarhsall an expection value, given its type            --
--                                                                            --
--   interface(type) Unmarshall an object reference of a given interface      --
--                                                                            --
-- encoder interface:                                                         --
--   order(value)         Change or return the endianess of the buffer        --
--   jump(shift)          Jump an empty space in the data of the buffer       --
--   getdata()            Returns the raw data stream of marshalled data      --
--   put(type)            Marhsall a value of the given type                  --
--                                                                            --
--   void(value)          Marshall a void type value                          --
--   short(value)         Marshall an integer type short value                --
--   long(value)          Marshall an integer type long value                 --
--   ushort(value)        Marshall an integer type unsigned short value       --
--   ulong(value)         Marshall an integer type unsigned long value        --
--   float(value)         Marshall a floating-point numeric type value        --
--   double(value)        Marshall a double-prec. floating-point num. value   --
--   boolean(value)       Marshall a boolean type value                       --
--   char(value)          Marshall a character type value                     --
--   octet(value)         Marshall a raw byte type value                      --
--   any(value)           Marshall a generic type value                       --
--   TypeCode(value)      Marshall a meta-type value                          --
--   string(value)        Marshall a string type value                        --
--                                                                            --
--   Object(value, type)  Marhsall an Object type value, given its type       --
--   struct(value, type)  Marhsall a struct type value, given its type        --
--   union(value, type)   Marhsall an union type value, given its type        --
--   enum(value, type)    Marhsall an enumeration type value, given its type  --
--   sequence(value, type)Marhsall a sequence type value, given its type      --
--   array(value, type)   Marhsall an array type value, given its type        --
--   typedef(value, type) Marhsall a type definition value, given its type    --
--   except(value, type)  Marhsall an expection value, given its type         --
--                                                                            --
--   interface(value,type)Marshall an object reference of a given interface   --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   See section 15.3 of CORBA 3.0 specification.                             --
--------------------------------------------------------------------------------
-- codec:Facet
-- 	encoder:object encoder()
-- 	decoder:object decoder(stream:string)
-- 
-- proxies:Receptacle
-- 	proxy:object proxyto(ior:table, iface:table|string)
-- 
-- objects:Receptacle
-- 	proxy:object register(implementation:object, iface:table|string)
--------------------------------------------------------------------------------

local getmetatable = getmetatable
local ipairs       = ipairs
local pairs        = pairs
local setmetatable = setmetatable
local tonumber     = tonumber
local type         = type

local math   = require "math"
local string = require "string"
local table  = require "table"

local oo     = require "oil.oo"
local assert = require "oil.assert"
local bit    = require "oil.bit"
local idl    = require "oil.corba.idl"
local giop   = require "oil.corba.giop"                                         --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.giop.Codec", oo.class)

context = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

UnionLabelInfo = { name = "label", type = idl.void }

--------------------------------------------------------------------------------
-- TypeCode information --------------------------------------------------------

-- NOTE: Description of type code categories, which is defined by field type
--	empty  : no further parameters are necessary to specify the associated
--           type.
--	simple : parameters that specify the associated type are defined as a
--           sequence of values.
--	complex: parameters that specify the associated type are defined as a
--           structure defined in idl that is stored in a encapsulated octet
--           sequence (i.e. which endianess may differ).

TypeCodeInfo = {
	[0]  = {name = "null"     , type = "empty", idl = idl.null     }, 
	[1]  = {name = "void"     , type = "empty", idl = idl.void     }, 
	[2]  = {name = "short"    , type = "empty", idl = idl.short    },
	[3]  = {name = "long"     , type = "empty", idl = idl.long     },
	[4]  = {name = "ushort"   , type = "empty", idl = idl.ushort   },
	[5]  = {name = "ulong"    , type = "empty", idl = idl.ulong    },
	[6]  = {name = "float"    , type = "empty", idl = idl.float    },
	[7]  = {name = "double"   , type = "empty", idl = idl.double   },
	[8]  = {name = "boolean"  , type = "empty", idl = idl.boolean  },
	[9]  = {name = "char"     , type = "empty", idl = idl.char     },
	[10] = {name = "octet"    , type = "empty", idl = idl.octet    },
	[11] = {name = "any"      , type = "empty", idl = idl.any      },
	[12] = {name = "TypeCode" , type = "empty", idl = idl.TypeCode },
	[13] = {name = "Principal", type = "empty", idl = idl.Principal, unhandled = true},

	[14] = {name = "Object", type = "complex",
		parameters = idl.struct{
			{name = "repID", type = idl.string},
			{name = "name" , type = idl.string},
		},
	},
	[15] = {name = "struct", type = "complex",
		parameters = idl.struct{
			{name = "repID" , type = idl.string},
			{name = "name"  , type = idl.string},
			{name = "fields", type = idl.sequence{
				idl.struct{
					{name = "name", type = idl.string},
					{name = "type", type = idl.TypeCode}
				},
			}},
		},
	},
	[16] = {name = "union", type = "complex",
		parameters = idl.struct{
			{name = "repID"  , type = idl.string  },
			{name = "name"   , type = idl.string  },
			{name = "switch" , type = idl.TypeCode},
			{name = "default", type = idl.long    },
		},
		mutable = {
			{name = "options", type = idl.sequence{
				idl.struct{
					UnionLabelInfo, -- NOTE: depends on field 'switch'.
					{name = "name" , type = idl.string  },
					{name = "type" , type = idl.TypeCode},
				},
			}},
			setup = function(self, union)
				UnionLabelInfo.type = union.switch
				return self
			end,
		},
	},
	[17] = {name = "enum", type = "complex",
		parameters = idl.struct{
			{name = "repID"     , type = idl.string              },
			{name = "name"      , type = idl.string              },
			{name = "enumvalues", type = idl.sequence{idl.string}},
		}
	},
	[18] = {name = "string", type = "simple", idl = idl.string,
		parameters = {
			{name = "maxlength", type = idl.ulong}
		},
	},
	[19] = {name = "sequence", type = "complex",
		parameters = idl.struct{
			{name = "elementtype", type = idl.TypeCode},
			{name = "maxlength"  , type = idl.ulong   },
		}
	},
	[20] = {name = "array", type = "complex",
		parameters = idl.struct{
			{name = "elementtype", type = idl.TypeCode},
			{name = "length"     , type = idl.ulong   },
		}
		},
	[21] = {name = "typedef", type = "complex",
		parameters = idl.struct{
			{name = "repID", type = idl.string  },
			{name = "name" , type = idl.string  },
			{name = "type" , type = idl.TypeCode},
		},
	},
	[22] = {name = "except", type = "complex",
		parameters = idl.struct{
			{name = "repID", type = idl.string},
			{name = "name",  type = idl.string},
			{name = "members", type = idl.sequence{
				idl.struct{
					{name = "name", type = idl.string  },
					{name = "type", type = idl.TypeCode},
				},
			}},
		},
	},
	
	[23] = {name = "longlong"  , type = "empty", idl = idl.longlong  }, 
	[24] = {name = "ulonglong" , type = "empty", idl = idl.ulonglong },
	[25] = {name = "longdouble", type = "empty", idl = idl.longdouble},
	[26] = {name = "wchar"     , type = "empty", unhandled = true},
	
	[27] = {name = "wstring", type = "simple", unhandled = true, kind = "wstring",
		parameters = {
			{name = "maxlength", type = idl.ulong},
		},
	},
	[28] = {name = "fixed", type = "simple", unhandled = true, kind = "fixed",
		parameters = {
			{name = "digits", type = idl.ushort},
			{name = "scale" , type = idl.short },
		},
	},
	
	[29] = {name = "value" , type = "complex", unhandled = true,
		parameters = {
			{name = "repID"     , type = idl.string  },
			{name = "name"      , type = idl.string  },
			{name = "kind"      , type = idl.short   },
			{name = "base_value", type = idl.TypeCode},
			{name = "members", type = idl.sequence{
				idl.struct{
					{name = "name"  , type = idl.string  },
					{name = "type"  , type = idl.TypeCode},
					{name = "access", type = idl.short   },
				},
			}},
		},
	},
	[30] = {name = "value_box", type = "complex", unhandled = true,
		parameters = {
			{name = "repID"            , type = idl.string  },
			{name = "name"             , type = idl.string  },
			{name = "original_type_def", type = idl.TypeCode},
		},
	},
	[31] = {name = "native"            , type = "complex", unhandled = true},
	[32] = {name = "abstract_interface", type = "complex", unhandled = true},
	
	-- [0xffffffff] = {name="none", type = "simple"},
}

--------------------------------------------------------------------------------
-- Local module functions ------------------------------------------------------

local function alignbuffer(self, alignment)
	local extra = math.mod(self.cursor - 1, alignment)
	if extra > 0 then self:jump(alignment - extra) end
end

NativeEndianess = (bit.endianess() == "little")

--------------------------------------------------------------------------------
--##  ##  ##  ##  ##   ##   ####   #####    ####  ##  ##   ####   ##     ##   --
--##  ##  ### ##  ### ###  ##  ##  ##  ##  ##     ##  ##  ##  ##  ##     ##   --
--##  ##  ######  #######  ######  #####    ###   ######  ######  ##     ##   --
--##  ##  ## ###  ## # ##  ##  ##  ##  ##     ##  ##  ##  ##  ##  ##     ##   --
-- ####   ##  ##  ##   ##  ##  ##  ##  ##  ####   ##  ##  ##  ##  #####  #####--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Unmarshalling buffer class --------------------------------------------------

Decoder = oo.class{
	start = 1,
	cursor = 1,
	unpack = bit.unpack, -- use current platform native endianess
}

function Decoder:order(value)
	if value ~= NativeEndianess then
		self.unpack = bit.invunpack
	end
end

function Decoder:jump(shift)
	local cursor = self.cursor
	self.cursor = cursor + shift
	if self.cursor - 1 > #self.data then
		assert.illegal(self.data, "data stream, insufficient data", "MARSHALL")
	end
	return cursor
end

function Decoder:get(idltype)
	local unmarshall = self[idltype._type]
	if not unmarshall then
		assert.illegal(idltype._type, "supported type", "MARSHALL")
	end
	return unmarshall(self, idltype)
end

function Decoder:append(data)
	self.data = self.data..data
end

function Decoder:getdata()
	return self.data
end

function Decoder:pointto(buffer)
	self.start = (buffer.start - 1) + (buffer.cursor - #self.data)
	self.history = buffer.history or buffer
end

function Decoder:indirection(unmarshall, ...)
	local pos = (self.start - 1) + self.cursor
	local tag = self:ulong()
	local history = self.history or self
	local value
	if tag == 4294967295 then -- indirection marker (0xffffffff)
		pos = (self.start - 1) + self.cursor
		value = history[pos + self:long()]                                          --[[VERBOSE]] verbose:unmarshal("got indirection to previously unmarshaled value.")
		if value == nil then
			assert.illegal(nil, "indirection offset", "MARSHALL")
		end
	else
		value = unmarshall(self, history, pos, tag, ...)
	end
	return value
end

--------------------------------------------------------------------------------
-- Unmarshalling functions -----------------------------------------------------

local function numberunmarshaller(size, format)
	return function (self)
		alignbuffer(self, size)
		local value = self.cursor
		self:jump(size)
		value = self.unpack(format, self.data, nil, nil, value)                     --[[VERBOSE]] verbose:unmarshal(self, format, value)
		return value
	end
end

Decoder.null       = function() end
Decoder.void       = Decoder.null
Decoder.short      = numberunmarshaller( 2, "s")
Decoder.long       = numberunmarshaller( 4, "l")
Decoder.longlong   = numberunmarshaller( 8, "g")
Decoder.ushort     = numberunmarshaller( 2, "S")
Decoder.ulong      = numberunmarshaller( 4, "L")
Decoder.ulonglong  = numberunmarshaller( 8, "G")
Decoder.float      = numberunmarshaller( 4, "f")
Decoder.double     = numberunmarshaller( 8, "d")
Decoder.longdouble = numberunmarshaller(16, "D")

function Decoder:boolean()                                                      --[[VERBOSE]] verbose:unmarshal(true, self, idl.boolean)
	return (self:octet() ~= 0)                                                    --[[VERBOSE]],verbose:unmarshal(false)
end

function Decoder:char()
	local value = self.data:sub(self.cursor, self.cursor)                         --[[VERBOSE]] verbose:unmarshal(self, idl.char, value)
	self:jump(1)
	return value
end

function Decoder:octet()
	local value = self.unpack("B", self.data, nil, nil, self.cursor)              --[[VERBOSE]] verbose:unmarshal(self, idl.octet, value)
	self:jump(1)
	return value
end

function Decoder:any()                                                          --[[VERBOSE]] verbose:unmarshal(true, self, idl.any) verbose:unmarshal "[type of any]"
	local idltype = self:TypeCode()                                               --[[VERBOSE]] verbose:unmarshal "[value of any]"
	local value = self:get(idltype)                                               --[[VERBOSE]] verbose:unmarshal(false)
	if type(value) == "table" then
		value._anyval = value
		value._anytype = idltype
	else
		value = setmetatable({
			_anyval = value,
			_anytype = idltype,
		}, idltype)
	end
	return value
end

function Decoder:Object(idltype)                                                --[[VERBOSE]] verbose:unmarshal(true, self, idltype)
	local ior = self:struct(giop.IOR)
	if ior.type_id == "" then                                                     --[[VERBOSE]] verbose:unmarshal "got a null reference"
		ior = nil
	else
		local context = self.context
		local objects = context.objects
		local profilers = context.profiler
		if objects and profilers then
			for _, profile in ipairs(ior.profiles) do
				local profiler = profilers[profile.tag]
				if profiler then
					local object = profiler:belongsto(profile.profile_data, objects.config)
					if object then
						object = objects:retrieve(object)
						if object then                                                      --[[VERBOSE]] verbose:unmarshal "local object implementation restored"
							return object
						end
					end
				end
			end
		end
		local proxies = context.proxies
		if proxies then                                                             --[[VERBOSE]] verbose:unmarshal(true, "retrieve proxy for referenced object")
			if idltype._type == "Object" then idltype = idltype.repID end
			ior = assert.results(proxies:proxy(ior, idltype), "MARSHAL")              --[[VERBOSE]] verbose:unmarshal(false)
		end
	end                                                                           --[[VERBOSE]] verbose:unmarshal(false)
	return ior
end

function Decoder:struct(idltype)                                                --[[VERBOSE]] verbose:unmarshal(true, self, idltype)
	local value = {}
	for _, field in ipairs(idltype.fields) do                                     --[[VERBOSE]] verbose:unmarshal("[field ",field.name,"]")
		value[field.name] = self:get(field.type)
	end                                                                           --[[VERBOSE]] verbose:unmarshal(false)
	return setmetatable(value, idltype)
end

function Decoder:union(idltype)                                                 --[[VERBOSE]] verbose:unmarshal(true, self, idltype) verbose:unmarshal "[union switch]"
	local switch = self:get(idltype.switch)
	local value = { _switch = switch }
	local option = idltype.selection[switch] or
	               idltype.options[idltype.default+1]
	if option then                                                                --[[VERBOSE]] verbose:unmarshal("[field",option.name,"]")
		value._field = option.name
		value._value = self:get(option.type)
	end                                                                           --[[VERBOSE]] verbose:unmarshal(false)
	return setmetatable(value, idltype)
end

function Decoder:enum(idltype)                                                  --[[VERBOSE]] verbose:unmarshal(true, self, idltype)
	local value = self:ulong() + 1                                                --[[VERBOSE]] verbose:unmarshal(false)
	if value > #idltype.enumvalues then
		assert.illegal(value, "enumeration value", "MARSHAL")
	end
	return idltype.enumvalues[value]
end

function Decoder:string()                                                       --[[VERBOSE]] verbose:unmarshal(true, self, idl.string)
	local length = self:ulong()
	local value = self.data:sub(self.cursor, self.cursor + length - 2)            --[[VERBOSE]] verbose:unmarshal(false, "got ",verbose.viewer:tostring(value))
	self:jump(length)
	return value
end

function Decoder:sequence(idltype)                                              --[[VERBOSE]] verbose:unmarshal(true, self, idltype)
	local length      = self:ulong()
	local elementtype = idltype.elementtype
	local value
	while elementtype._type == "typecode" do elementtype = elementtype.type end
	if elementtype == idl.octet or elementtype == idl.char then
		value = self.data:sub(self.cursor, self.cursor + length - 1)                --[[VERBOSE]] verbose:unmarshal("got ", verbose.viewer:tostring(value))
		self:jump(length)
	else
		value = setmetatable({ n = length }, idltype)
		for i = 1, length do                                                        --[[VERBOSE]] verbose:unmarshal("[element ",i,"]")
			value[i] = self:get(elementtype)
		end
	end                                                                           --[[VERBOSE]] verbose:unmarshal(false)
	return value
end

function Decoder:array(idltype)                                                 --[[VERBOSE]] verbose:unmarshal(true, self, idltype)
	local length      = idltype.length
	local elementtype = idltype.elementtype
	local value
	while elementtype._type == "typecode" do elementtype = elementtype.type end
	if elementtype == idl.octet or elementtype == idl.char then
		value = self.data:sub(self.cursor, self.cursor + length - 1)                --[[VERBOSE]] verbose:unmarshal("got ",verbose.viewer:tostring(value))
		self:jump(length)
	else
		value = setmetatable({}, idltype)
		for i = 1, length do                                                        --[[VERBOSE]] verbose:unmarshal("[element ",i,"]")
			value[i] = self:get(elementtype)
		end
	end                                                                           --[[VERBOSE]] verbose:unmarshal(false)
	return value
end

function Decoder:typedef(idltype)                                               --[[VERBOSE]] verbose:unmarshal(true, self, idltype)
	return self:get(idltype.type)                                                 --[[VERBOSE]],verbose:unmarshal(false)
end

function Decoder:except(idltype)                                                --[[VERBOSE]] verbose:unmarshal(true, self, idltype)
	local value = {}
	for _, member in ipairs(idltype.members) do                                   --[[VERBOSE]] verbose:unmarshal("[member ",member.name,"]")
		value[member.name] = self:get(member.type)
	end                                                                           --[[VERBOSE]] verbose:unmarshal(false)
	return setmetatable(value, idltype)
end

Decoder.interface = Decoder.Object

local function gettype(decoder, storage, key, kind)
	local tcinfo = TypeCodeInfo[kind]
	
	if tcinfo == nil then assert.illegal(kind, "type code", "MARSHALL") end       --[[VERBOSE]] verbose:unmarshal("TypeCode defines a ",tcinfo.name)
	if tcinfo.unhandled then
		assert.illegal(tcinfo.name, "supported type code", "MARSHALL")
	end
	local value = tcinfo.idl
	
	if tcinfo.type == "simple" then
		
		storage[key] = value
		-- NOTE: The string type is the only simple type being handled,
		--       therefore parameters are ignored.
		for _, param in ipairs(tcinfo.parameters) do                                --[[VERBOSE]] verbose:unmarshal("[parameter ",param.name,"]")
			decoder:get(param.type)
		end
		
	elseif tcinfo.type == "complex" then                                          --[[VERBOSE]] verbose:unmarshal(true, "[parameters encapsulation]")
		
		local params = decoder:sequence(idl.OctetSeq)
		local temp = decoder.context.__component:decoder(params, true)              --[[VERBOSE]] verbose:unmarshal "[parameters values]"
		temp:pointto(decoder)
		value = { _type = tcinfo.name }
		storage[key] = value
		for _, field in ipairs(tcinfo.parameters.fields) do                                     --[[VERBOSE]] verbose:unmarshal("[field ",field.name,"]")
			value[field.name] = temp:get(field.type)
		end                                                                           --[[VERBOSE]] verbose:unmarshal(false)
		if tcinfo.mutable then                                                      --[[VERBOSE]] verbose:unmarshal "[mutable parameters values]"
			for _, param in ipairs(tcinfo.mutable:setup(value)) do
				value[param.name] = temp:get(param.type)
			end
		end                                                                         --[[VERBOSE]] verbose:unmarshal(false)
		return idl[tcinfo.name](value)
		
	end
	
	return value
end

function Decoder:TypeCode()                                                     --[[VERBOSE]] verbose:unmarshal(true, self, idl.TypeCode)
	return self:indirection(gettype)                                              --[[VERBOSE]],verbose:unmarshal(false)
end

--------------------------------------------------------------------------------
--   ##   ##   #####   ######    ######  ##   ##   #####   ##       ##        --
--   ### ###  ##   ##  ##   ##  ##       ##   ##  ##   ##  ##       ##        --
--   #######  #######  ######    #####   #######  #######  ##       ##        --
--   ## # ##  ##   ##  ##   ##       ##  ##   ##  ##   ##  ##       ##        --
--   ##   ##  ##   ##  ##   ##  ######   ##   ##  ##   ##  #######  #######   --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Unmarshalling buffer class --------------------------------------------------

Encoder = oo.class {
	start = 1,
	cursor = 1,
	emptychar = '\255', -- character used in buffer alignment
	pack = bit.pack,    -- use current platform native endianess
}

function Encoder:__init(object)
	self = oo.rawnew(self, object)
	self.format = {}
	return self
end

function Encoder:shift(shift)
	self.cursor = self.cursor + shift
end

function Encoder:jump(shift)
	self:rawput('"', string.rep(self.emptychar, shift), shift)
end

function Encoder:rawput(format, data, size)
	self.format[#self.format+1] = format
	self[#self+1] = data
	self.cursor = self.cursor + size
end

function Encoder:put(value, idltype)
	local marshall = self[idltype._type]
	if not marshall then
		assert.illegal(idltype._type, "supported type", "MARSHALL")
	end
	return marshall(self, value, idltype)
end

function Encoder:getdata()
	return self.pack(table.concat(self.format), self)
end

function Encoder:getlength()
	return self.cursor - 1
end

function Encoder:pointto(encoder)
	self.start = (encoder.start - 1) + encoder.cursor
	self.history = encoder.history or encoder
end

function Encoder:indirection(marshall, value, ...)
	local pos = (self.start - 1) + self.cursor
	local history = self.history or self
	local previous = history[value]
	if previous then
		self:ulong(4294967295) -- indirection marker (0xffffffff)
		pos = (self.start - 1) + self.cursor                                        --[[VERBOSE]] verbose:marshal("indirection to "..(pos-previous).." bytes away.")
		self:long(previous - pos) -- offset
	else
		history[value] = pos
		marshall(self, value, ...)
	end
end

--------------------------------------------------------------------------------
-- Marshalling functions -------------------------------------------------------

local function numbermarshaller(size, format)
	return function (self, value)                                                 --[[VERBOSE]] verbose:marshal(self, format, value)
		assert.type(value, "number", "numeric value", "MARSHAL")
		alignbuffer(self, size)
		self:rawput(format, value, size)
	end
end

Encoder.null       = function() end
Encoder.void       = Encoder.null
Encoder.short      = numbermarshaller( 2, "s")
Encoder.long       = numbermarshaller( 4, "l")
Encoder.longlong   = numbermarshaller( 8, "g")
Encoder.ushort     = numbermarshaller( 2, "S")
Encoder.ulong      = numbermarshaller( 4, "L")
Encoder.ulonglong  = numbermarshaller( 8, "G")
Encoder.float      = numbermarshaller( 4, "f")
Encoder.double     = numbermarshaller( 8, "d")
Encoder.longdouble = numbermarshaller(16, "D")
	
function Encoder:boolean(value)                                                 --[[VERBOSE]] verbose:marshal(true, self, idl.boolean)
	if value
		then self:octet(1)
		else self:octet(0)
	end                                                                           --[[VERBOSE]] verbose:marshal(false)
end

function Encoder:char(value)                                                    --[[VERBOSE]] verbose:marshal(self, idl.char, value)
	assert.type(value, "string", "character", "MARSHAL")
	if #value ~= 1 then
		assert.illegal(value, "character", "MARSHAL")
	end
	self:rawput('"', value, 1)
end

function Encoder:octet(value)                                                   --[[VERBOSE]] verbose:marshal(self, idl.octet, value)
	assert.type(value, "number", "octet value", "MARSHAL")
	self:rawput("B", value, 1)
end

local DefaultMapping = {
	number  = idl.double,
	string  = idl.string,
	boolean = idl.boolean,
	["nil"] = idl.null,
}
function Encoder:any(value)                                                     --[[VERBOSE]] verbose:marshal(true, self, idl.any)
	local luatype = type(value)
	local idltype = DefaultMapping[luatype]
	if not idltype then
		local metatable = getmetatable(value)
		if metatable then
			if idl.istype(metatable) then
				idltype = metatable
			elseif idl.istype(metatable.__type) then
				idltype = metatable.__type
			end
		end
		if luatype == "table" then
			if not idltype and idl.istype(value._anytype) then
				idltype = value._anytype
			end
			if value._anyval ~= nil then
				value = value._anyval
			end
		end
	end
	if not idltype then
		assert.illegal(value, "any, unable to map to an idl type", "MARSHAL")
	end                                                                           --[[VERBOSE]] verbose:marshal "[type of any]"
	self:TypeCode(idltype)                                                        --[[VERBOSE]] verbose:marshal "[value of any]"
	self:put(value, idltype)                                                      --[[VERBOSE]] verbose:marshal(false)
end

local NullReference = { type_id = "", profiles = { n=0 } }
function Encoder:Object(value, idltype)                                         --[[VERBOSE]] verbose:marshal(true, self, idltype)
	local reference
	if value == nil then
		reference = NullReference
	else
		assert.type(value, "table", "object reference", "MARSHAL")
		reference = value.__reference
		if not reference then
			local objects = self.context.objects
			if objects then                                                           --[[VERBOSE]] verbose:marshal(true, "implicit servant creation")
				value = assert.results(objects:object(value, nil, idltype))             --[[VERBOSE]] verbose:marshal(false)
				reference = value.__reference
			else
				assert.illegal(value, "Object, unable to create from value", "MARHSALL")
			end
		end
	end
	self:struct(reference, giop.IOR)                                              --[[VERBOSE]] verbose:marshal(false)
end

local NilEnabledTypes = {
	any = true,
	boolean = true,
	Object = true,
	interface = true,
}
function Encoder:struct(value, idltype)                                         --[[VERBOSE]] verbose:marshal(true, self, idltype)
	assert.type(value, "table", "struct value", "MARSHAL")
	for _, field in ipairs(idltype.fields) do
		local val = value[field.name]                                               --[[VERBOSE]] verbose:marshal("[field ",field.name,"]")
		if val == nil and NilEnabledTypes[field.type._type] then
			assert.illegal(value,
			              "struct value (no value for field "..field.name..")",
			              "MARSHAL")
		end
		self:put(val, field.type)
	end                                                                           --[[VERBOSE]] verbose:marshal(false)
end

function Encoder:union(value, idltype)                                          --[[VERBOSE]] verbose:marshal(true, self, idltype)
	assert.type(value, "table", "union value", "MARSHAL")
	local switch = value._switch

	-- Marshal discriminator
	if switch == nil then
		switch = idltype.selector[value._field]
		if switch == nil then
			for _, option in ipairs(idltype.options) do
				if value[option.name] ~= nil then
					switch = option.label
					break
				end
			end
			if switch == nil then
				switch = idltype.options[idltype.default+1]
				if switch == nil then
					assert.illegal(value, "union value (no discriminator)", "MARSHAL")
				end
			end
		end
	end                                                                           --[[VERBOSE]] verbose:marshal "[union switch]"
	self:put(switch, idltype.switch)
	
	local selection = idltype.selection[switch]
	if selection then
		-- Marshal union value
		local unionvalue = value._value
		if unionvalue == nil then
			unionvalue = value[selection.name]
			if unionvalue == nil then
				assert.illegal(value, "union value (none contents)", "MARSHAL")
			end
		end                                                                         --[[VERBOSE]] verbose:marshal("[field ",selection.name,"]")
		self:put(unionvalue, selection.type)
	end                                                                           --[[VERBOSE]] verbose:marshal(false)
end

function Encoder:enum(value, idltype)                                           --[[VERBOSE]] verbose:marshal(true, self, idltype, value)
	value = idltype.labelvalue[value] or tonumber(value)
	if not value then assert.illegal(value, "enum value", "MARSHAL") end
	self:ulong(value)                                                             --[[VERBOSE]] verbose:marshal(false)
end

function Encoder:string(value)                                                  --[[VERBOSE]] verbose:marshal(true, self, idl.string, value)
	assert.type(value, "string", "string value", "MARSHAL")
	local length = #value
	self:ulong(length + 1)
	self:rawput('"', value, length)
	self:rawput('"', '\0', 1)                                                     --[[VERBOSE]] verbose:marshal(false)
end

function Encoder:sequence(value, idltype)                                       --[[VERBOSE]] verbose:marshal(true, self, idltype, value)
	local elementtype = idltype.elementtype
	if type(value) == "string" then
		local length = #value
		self:ulong(length)
		while elementtype._type == "typedef" do elementtype = elementtype.type end
		if elementtype == idl.octet or elementtype == idl.char then
			self:rawput('"', value, length)
		else
			assert.illegal(value, "sequence value (table expected, got string)",
			                      "MARSHAL")
		end
	else
		assert.type(value, "table", "sequence value", "MARSHAL")
		local length = value.n or #value
		self:ulong(length)
		for i = 1, length do                                                        --[[VERBOSE]] verbose:marshal("[element ",i,"]")
			self:put(value[i], elementtype) 
		end
	end                                                                           --[[VERBOSE]] verbose:marshal(false)
end

function Encoder:array(value, idltype)                                          --[[VERBOSE]] verbose:marshal(true, self, idltype, value)
	local elementtype = idltype.elementtype
	if type(value) == "string" then
		while elementtype._type == "typedef" do elementtype = elementtype.type end
		if elementtype == idl.octet or elementtype == idl.char then
			local length = #value
			if length ~= idltype.length then
				assert.illegal(value, "array value (wrong length)", "MARSHAL")
			end
			self:rawput('"', value, length)
		else
			assert.illegal(value, "array value (table expected, got string)",
			                      "MARSHAL")
		end
	else
		assert.type(value, "table", "array value", "MARSHAL")
		for i = 1, idltype.length do                                                --[[VERBOSE]] verbose:marshal("[element ",i,"]")
			self:put(value[i], elementtype)
		end
	end                                                                           --[[VERBOSE]] verbose:marshal(false)
end

function Encoder:typedef(value, idltype)                                        --[[VERBOSE]] verbose:marshal(true, self, idltype, value)
	self:put(value, idltype.type)                                                 --[[VERBOSE]] verbose:marshal(false)
end

function Encoder:except(value, idltype)                                         --[[VERBOSE]] verbose:marshal(true, self, idltype, value)
	assert.type(value, "table", "except value", "MARSHAL")
	for _, member in ipairs(idltype.members) do                                   --[[VERBOSE]] verbose:marshal("[member ", member.name, "]")
		local val = value[member.name]
		if val == nil and NilEnabledTypes[member.type._type] then
			assert.illegal(value,
			              "except value (no value for member "..member.name..")",
			              "MARSHAL")
		end
		self:put(val, member.type)
	end                                                                           --[[VERBOSE]] verbose:marshal(false)
end

Encoder.interface = Encoder.Object

local TypeCodes = { interface = 14 }
for tcode, info in pairs(TypeCodeInfo) do TypeCodes[info.name] = tcode end

local function puttype(encoder, value, kind, tcinfo)
	
	encoder:ulong(kind)
	
	if tcinfo.type == "simple" then
		
		for _, param in ipairs(tcinfo.parameters) do                                --[[VERBOSE]] verbose:marshal("[parameter ",param.name,"]")
			encoder:put(value[param.name], param.type)
		end
		
	elseif tcinfo.type == "complex" then
		
		local temp = encoder.context.__component:encoder(true)                      --[[VERBOSE]] verbose:marshal "[parameters values]"
		temp:pointto(encoder)
		temp.start = temp.start + 4 -- adds the size of the OctetSeq count
		temp:struct(value, tcinfo.parameters)
		if tcinfo.mutable then                                                      --[[VERBOSE]] verbose:marshal "[mutable parameters values]"
			for _, param in ipairs(tcinfo.mutable:setup(value)) do
				temp:put(value[param.name], param.type)
			end
		end                                                                         --[[VERBOSE]] verbose:marshal(true, "[parameters encapsulation]")
		encoder:sequence(temp:getdata(), idl.OctetSeq)                              --[[VERBOSE]] verbose:marshal(false)
		
	end
end

function Encoder:TypeCode(value)                                                --[[VERBOSE]] verbose:marshal(true, self, idl.TypeCode, value)
	assert.type(value, "idl type", "TypeCode value", "MARSHAL")
	local kind   = TypeCodes[value._type]
	local tcinfo = TypeCodeInfo[kind]

	if not kind then assert.illegal(value, "idl type", "MARSHALL") end
	
	if tcinfo.type == "empty" then
		self:ulong(kind)
	else
		-- top-most TypeCode encoder does not inherits history
		local topmost = not self.history
		-- create history to register nested encoded TypeCodes
		if topmost then self.history = {} end
		self:indirection(puttype, value, kind, tcinfo)
		-- indirection cannot cross top-most TypeCode boundries
		if topmost then self.history = nil end
	end                                                                           --[[VERBOSE]] verbose:marshal(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- NOTE: second parameter indicates an encasulated octet-stream, therefore
--       endianess must be read from stream.
function decoder(self, octets, getorder)
	local decoder = self.Decoder{
		data = octets,
		context = self.context,
	}
	if getorder then decoder:order(decoder:boolean()) end
	return decoder
end

-- NOTE: Presence of a parameter indicates an encapsulated octet-stream.
function encoder(self, putorder)
	local encoder = self.Encoder{ context = self.context }
	if putorder then encoder:boolean(NativeEndianess) end
	return encoder
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[VERBOSE]] local numtype = {
--[[VERBOSE]] 	s = idl.short,
--[[VERBOSE]] 	l = idl.long,
--[[VERBOSE]] 	g = idl.longlong,
--[[VERBOSE]] 	S = idl.ushort,
--[[VERBOSE]] 	L = idl.ulong,
--[[VERBOSE]] 	G = idl.ulonglong,
--[[VERBOSE]] 	f = idl.float,
--[[VERBOSE]] 	d = idl.double,
--[[VERBOSE]] 	D = idl.longdouble,
--[[VERBOSE]] }
--[[VERBOSE]] verbose.codecop = {
--[[VERBOSE]] 	[Encoder] = "marshal",
--[[VERBOSE]] 	[Decoder] = "unmarshal",
--[[VERBOSE]] }
--[[VERBOSE]] local luatype = type
--[[VERBOSE]] function verbose.custom:marshal(codec, type, value)
--[[VERBOSE]] 	local viewer = self.viewer
--[[VERBOSE]] 	local output = viewer.output
--[[VERBOSE]] 	local op = self.codecop[oo.classof(codec)]
--[[VERBOSE]] 	if op then
--[[VERBOSE]] 		type = numtype[type] or type
--[[VERBOSE]] 		output:write(op," of ",type._type)
--[[VERBOSE]] 		type = type.name or type.repID
--[[VERBOSE]] 		if type then
--[[VERBOSE]] 			output:write(" ",type)
--[[VERBOSE]] 		end
--[[VERBOSE]] 		if value ~= nil then
--[[VERBOSE]] 			if luatype(value) == "string" then
--[[VERBOSE]] 				value = value:gsub("[^%w%p%s]", "?")
--[[VERBOSE]] 			end
--[[VERBOSE]] 			output:write(" (got ")
--[[VERBOSE]] 			viewer:write(value)
--[[VERBOSE]] 			output:write(")")
--[[VERBOSE]] 		end
--[[VERBOSE]] 		if self:flag("hexastream") then
--[[VERBOSE]] 			self.custom.hexastream(self, codec:getdata(), codec.cursor)
--[[VERBOSE]] 		end
--[[VERBOSE]] 	else
--[[VERBOSE]] 		return true -- cancel custom message
--[[VERBOSE]] 	end
--[[VERBOSE]] end
--[[VERBOSE]] verbose.custom.unmarshal = verbose.custom.marshal
