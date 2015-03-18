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
-- Title  : Mapping of Lua values into CDR using dynamic generated code       --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
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

local ipairs     = ipairs
local loadstring = loadstring
local select     = select
local unpack     = unpack

local string = require "string"
local table  = require "table"

local oo     = require "oil.oo"
local assert = require "oil.assert"
local idl    = require "oil.corba.idl"
local Codec  = require "oil.corba.giop.Codec"                                   --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.corba.giop.CodecGen"

oo.class(_M, Codec)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CodeGenerator = oo.class{
	stacksize = 0,
	stacktop = 0,
	source = table.concat,
}

local upvaluefmt = "_up%d_"
local stackposfmt = "_%d_"

function CodeGenerator:__init(...)
	self = oo.rawnew(self, ...)
	if self.upvalues == nil then self.upvalues = {n=0} end
	return self
end

function CodeGenerator:add(...)
	for i = 1, select("#", ...) do
		self[#self+1] = select(i, ...)
	end
end

function CodeGenerator:push(...)
	self.stacktop = self.stacktop + 1
	if self.stacktop > self.stacksize then
		self.stacksize = self.stacktop
	end
	self:add(self:top(),' = ',...)
	self:add("\n")
end

function CodeGenerator:pop()
	self.stacktop = self.stacktop - 1
end

function CodeGenerator:top(shift)
	return stackposfmt:format(self.stacktop+(shift or 0))
end

function CodeGenerator:upvalue(value)
	local upvalues = self.upvalues
	if value == nil then value = upvalues end -- special value to represent 'nil'
	if upvalues[value] == nil then
		upvalues.n = upvalues.n + 1
		upvalues[value] = upvaluefmt:format(upvalues.n)
		if value ~= upvalues then
			upvalues[upvalues.n] = value
		end
	end
	return upvalues[value]
end

function CodeGenerator:compile(idltype)
	local source = self:source()
	
	local positions = {"self"}
	for i = 1, self.stacksize do
		positions[i+1] = stackposfmt:format(i)
	end

	source = string.format([=[
local assert = require "oil.assert"                                             --[[VERBOSE]] local verbose = require "oil.verbose"
return function(%s) %s end
]=], table.concat(positions, ","), source)
	
	local upvalues = self.upvalues
	if upvalues.n > 0 then
		local names = {}
		for i = 1, upvalues.n do
			names[i] = upvaluefmt:format(i)
		end
		source = string.format("local %s = ...\n%s", table.concat(names, ","), source)
	end
	
	local codename = string.format("(un)marshaller for %s %s",
		idltype._type,
		idltype.repID or idltype.name or "anonymous")
	return assert.results(loadstring(source, codename))(
		unpack(upvalues, 1, upvalues.n))
end

function CodeGenerator:illegal(description, sysex)
	self:add([[ assert.exception{ ']],(sysex or "illegal value"),[[',
		reason = 'value',
		message = 'illegal ]],description,[[',
		valuename = ']],description,[['
	}
	]])
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

DecoderGenerator = oo.class({}, CodeGenerator)

function DecoderGenerator:__init(...)
	self = CodeGenerator.__init(self, ...)
	if #self == 0 then self[1] = "return " end
	return self
end

local code = "self.unpack('%s',self.data,nil,nil,self:alignedjump(%d))"
local function numberunmarshaller(size, format)
	local code = code:format(format, size)
	return function(self) self:add(code) end
end
DecoderGenerator.null       = function() self:add(" nil") end
DecoderGenerator.void       = DecoderGenerator.null
DecoderGenerator.short      = numberunmarshaller( 2, "s")
DecoderGenerator.long       = numberunmarshaller( 4, "l")
DecoderGenerator.longlong   = numberunmarshaller( 8, "g")
DecoderGenerator.ushort     = numberunmarshaller( 2, "S")
DecoderGenerator.ulong      = numberunmarshaller( 4, "L")
DecoderGenerator.ulonglong  = numberunmarshaller( 8, "G")
DecoderGenerator.float      = numberunmarshaller( 4, "f")
DecoderGenerator.double     = numberunmarshaller( 8, "d")
DecoderGenerator.longdouble = numberunmarshaller(16, "D")

function DecoderGenerator:boolean()
	self:add "("
	self:octet()
	self:add "~=0)"
end

function DecoderGenerator:char()
	self:add "self.data:sub(self.cursor,self:jump(1))"
end

function DecoderGenerator:octet()
	self:add "self.unpack('B',self.data,nil,nil,self:jump(1))"
end

function DecoderGenerator:struct(idltype)
	self:add "setmetatable({\n"
	for _, field in ipairs(idltype.fields) do
		self:add(field.name,'=')
		self:generate(field.type)
		self:add(',\n')
	end
	self:add("},",self:upvalue(idltype),")\n")
end

function DecoderGenerator:union(idltype)
	local gen = DecoderGenerator{""}
	local default = idltype.options[idltype.default+1]
	gen:add([[
local switch
local function default(self)
	return {
		_switch = switch,
]]) if default then gen:add([[
		_field = ]],default.name,[[,
		_value = ]]) gen:generate(default.type) gen:add([[,
]]) end gen:add([[
	}
end
]])
	
	gen:add 'return setmetatable({\n'
	for _, option in ipairs(idltype.options) do
		--[<option.label>] = function()
		--	return {
		--		_switch = <option.label>,
		--		_field = <option.name>,
		--		_value = <unmarhsall(option.type)>,
		--	}
		--end,
		local switch = gen:upvalue(option.label)
		gen:add([[
	[]],switch,[[] = function(self)
		return {
			_switch = ]],switch,[[,
			_field = ']],option.name,[[',
			_value = ]]) gen:generate(option.type) gen:add[[,
		}
	end,
]]
	end
	gen:add[[
},{
	__index=function(_,value)
		switch=value
		return default
	end,
})
]]
	local selector = gen:compile(idltype)
	-- setmetatable(__selector__[<unmarshal(idltype.switch)>](self), __idltype__)
	self:add("setmetatable(",self:upvalue(selector()),"[")
	self:generate(idltype.switch)
	self:add("](self),",self:upvalue(idltype),")")
end

function DecoderGenerator:enum(idltype)
	-- <idltype.enumvalues>[unmarhsal(ulong)+1] or illegal("enumeration value")
	self:add(self:upvalue(idltype.enumvalues),"[")
	self:ulong()
	self:add("+1] or ")
	self:illegal("enumeration value", "MARSHAL")
end

function DecoderGenerator:string()
	self:add "self.data:sub(self:jump("
	self:ulong()
	self:add "),self.cursor-2)"
end

function DecoderGenerator:sequence(idltype)
	local elementtype = idltype.elementtype
	while elementtype._type == "typecode" do elementtype = elementtype.type end
	if elementtype == idl.octet or elementtype == idl.char then
		self:add "self.data:sub(self:jump("
		self:ulong()
		self:add "),self.cursor-1)"
	else
		local gen = DecoderGenerator()
		gen:generate(elementtype)
		self:add("setmetatable(self:sequenceof(",self:upvalue(gen:compile(elementtype)),",")
		self:ulong()
		self:add("),",self:upvalue(elementtype),")")
	end
end

function DecoderGenerator:array(idltype)
	local length      = idltype.length
	local elementtype = idltype.elementtype
	while elementtype._type == "typecode" do elementtype = elementtype.type end
	if elementtype == idl.octet or elementtype == idl.char then
		self:add("self.data:sub(self:jump(",length,"),self.cursor-1)")
	else
		self:add "setmetatable({\n"
		for i = 1, length do
			self:generate(elementtype)
			self:add ",\n"
		end
		self:add("},",self:upvalue(elementtype),")")
	end
end

function DecoderGenerator:typedef(idltype)
	return self:generate(idltype.type)
end

function DecoderGenerator:except(idltype)
	self:add "setmetatable({\n"
	for _, member in ipairs(idltype.members) do
		self:add(member.name,"=")
		self:generate(member.type)
		self:add(",\n")
	end
	self:add("},",self:upvalue(idltype),")")
end

function DecoderGenerator:generate(idltype)
	local generator = self[idltype._type]
	if generator then                                                             --[[VERBOSE]] self:add("verbose:gen_marshal(self,",self:upvalue(idltype),",")
		generator(self, idltype)                                                    --[[VERBOSE]] self:add(")")
	else
		self:add("self:",idltype._type,"(",self:upvalue(idltype),")")
	end
end

--------------------------------------------------------------------------------

Decoder = oo.class({}, Decoder)

function Decoder:alignedjump(value)
	local pos = self.cursor - 2
	pos = pos + 1 + (value - pos % value)
	self.cursor = pos + value
	return pos
end

function Decoder:sequenceof(decoder, length)
	local sequence = {}
	for i = 1, length do
		sequence[i] = decoder(self)
	end
	return sequence
end

function Decoder:get(idltype)
	local unmarshall = idltype.unmarshall
	if unmarshall == nil then
		local type = idltype._type
		if DecoderGenerator[type] then
			local gen = DecoderGenerator()
			gen:generate(idltype)                                                     --[[VERBOSE]] verbose:marshal("generating new unmarshaller for type ",idltype._type)
			unmarshall = gen:compile(idltype)
			idltype.unmarshall = unmarshall
		else                                                                        --[[VERBOSE]] verbose:marshal("using dynamic unmarshaller for type ",idltype._type)
			unmarshall = self[type] or
			             assert.illegal(type, "supported type", "MARSHALL")
		end                                                                         --[[VERBOSE]] else verbose:marshal("generated unmarshaller found for type ",idltype._type)
	end
	return unmarshall(self, idltype)
end

-- generate string decoder because 'Decoder:string()' does not get an argument.
local gen = DecoderGenerator()
gen:generate(idl.string)
idl.string.unmarshall = gen:compile(idl.string)
Decoder.string = idl.string.unmarshall

Decoder.struct     = Decoder.get
Decoder.union      = Decoder.get
Decoder.enum       = Decoder.get
Decoder.sequence   = Decoder.get
Decoder.array      = Decoder.get
Decoder.typedef    = Decoder.get
Decoder.except     = Decoder.get

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

EncoderGenerator = oo.class({
	stacksize = 1,
	stacktop = 1,
}, CodeGenerator)

function EncoderGenerator:__init(...)
	self = CodeGenerator.__init(self, ...)
	if #self == 0 then
		self[1] = [[
local format = self.format
local aux
]]
	end
	return self
end

function EncoderGenerator:rawput(format, size, value)
	self:add("format[#format+1],self[#self+1] = '",format,"',",value or self:top())
	self:add("\nself.cursor = self.cursor+",size,"\n")
end

local function numbermarshaller(size, format)
	return function(self)
		self:add('aux = ',size-1,'-(self.cursor-2)%',size,'\n')
		self:rawput('"', 'aux', '("\\255"):rep(aux)')
		self:rawput(format, size)
	end
end
EncoderGenerator.null       = function() end
EncoderGenerator.void       = DecoderGenerator.null
EncoderGenerator.short      = numbermarshaller( 2, "s")
EncoderGenerator.long       = numbermarshaller( 4, "l")
EncoderGenerator.longlong   = numbermarshaller( 8, "g")
EncoderGenerator.ushort     = numbermarshaller( 2, "S")
EncoderGenerator.ulong      = numbermarshaller( 4, "L")
EncoderGenerator.ulonglong  = numbermarshaller( 8, "G")
EncoderGenerator.float      = numbermarshaller( 4, "f")
EncoderGenerator.double     = numbermarshaller( 8, "d")
EncoderGenerator.longdouble = numbermarshaller(16, "D")

function EncoderGenerator:boolean()
	self:add(self:top(),' = ',self:top(),' and 1 or 0\n')
	self:octet()
end

function EncoderGenerator:char()
	self:add('if #',self:top(),' ~= 1 then assert.illegal(',self:top(),', "character", "MARSHAL") end\n')
	self:rawput('"', 1)
end

function EncoderGenerator:octet()
	self:rawput("B", 1)
end

function EncoderGenerator:struct(idltype)
	for _, field in ipairs(idltype.fields) do
		self:push(self:top(),".",field.name)
		self:generate(field.type)
		self:pop()
	end
end

function EncoderGenerator:union(idltype)
	self:push(self:top(),"._switch")
	self:add('if ',self:top(),' == nil then\n')
		self:pop() -- nil
		self:push(self:upvalue(idltype.selector),'[',self:top(),'._field]')
		self:add('if ',self:top(),' == nil then\n')
			for index, option in ipairs(idltype.options) do
				self:pop() -- nil
				self:add('if ',self:top(),'.',option.name,' ~= nil then ')
				self:push(self:upvalue(option.label))
				self:add('else')
			end
			self:add '\n'
			local default = idltype.options[idltype.default+1]
			if default then
				self:pop() -- nil
				self:push(self:upvalue(default))
			else
				self:illegal("union value (no discriminator)", "MARSHAL")
			end
	self:add 'end\nend\nend\n'
	self:generate(idltype.switch)
	
	for index, option in ipairs(idltype.options) do
		self:add('if ',self:top(),' == ',self:upvalue(option.label),' then\n')
			self:pop() -- switch
			self:push(self:top(),'._value')
			self:add('if ',self:top(),' == nil then\n')
				self:pop() -- nil
				self:push(self:top(),".",option.name)
				self:add('if ',self:top(),' == nil then\n')
					self:illegal("union value (none contents)", "MARSHAL")
			self:add "end\nend\n"
			self:generate(option.type)
		if index == #idltype.options
			then self:add 'end\n'
			else self:add 'else'
		end
	end
	self:pop() -- switch or value
end

function EncoderGenerator:enum(idltype)
	self:push(self:upvalue(idltype.labelvalue),'[',self:top(),'] or tonumber(',self:top(),')')
	self:ulong()
	self:pop()
end

function EncoderGenerator:string()
	self:push('#',self:top(),'+1')
	self:ulong()
	self:pop()
	self:rawput('"', self:top(1))
	self:rawput('"', 0, "'\\0'")
end

function EncoderGenerator:sequence(idltype)
	local elementtype = idltype.elementtype
	while elementtype._type == "typecode" do elementtype = elementtype.type end
	local dostring = elementtype == idl.octet or elementtype == idl.char
	if dostring then
		self:add('if type(',self:top(),') == "string" then\n')
			self:push('#',self:top())
			self:ulong()
			self:pop()
			self:rawput('"', self:top(1))
		self:add 'else\n'
	end
	self:push(self:top(),'.n or #',self:top())
	self:ulong()
	self:pop()
	self:add('for i = 1, ',self:top(1),' do\n')
	self:push(self:top(),'[i]')
	self:generate(elementtype) 
	self:pop()
	self:add 'end\n'
	if dostring then
		self:add 'end\n'
	end
end

function EncoderGenerator:array(idltype)
	local elementtype = idltype.elementtype
	while elementtype._type == "typecode" do elementtype = elementtype.type end
	local dostring = elementtype == idl.octet or elementtype == idl.char
	if dostring then
		self:add('if type(',self:top(),') == "string" then\n')
		self:rawput('"', idltype.length)
		self:add('else\n')
	end
	self:add('for i = 1,',idltype.length,' do\n')
	self:generate(elementtype) 
	self:add 'end\n'
	if dostring then self:add 'end\n' end
end

function EncoderGenerator:typedef(idltype)
	return self:generate(idltype.type)
end

function EncoderGenerator:except(idltype)
	for _, member in ipairs(idltype.members) do
		self:push(self:top(),'.',member.name)
		self:generate(member.type)
		self:pop()
	end
end

function EncoderGenerator:generate(idltype)
	local generator = self[idltype._type]
	if generator then                                                             --[[VERBOSE]] self:add('verbose:marshal(true,self,',self:upvalue(idltype),',',self:top(),')\n')
		generator(self, idltype)                                                    --[[VERBOSE]] self:add('verbose:marshal(false)\n')
	else
		self:add('self:',idltype._type,'(',self:top(),',',self:upvalue(idltype),')\n')
	end
end

--------------------------------------------------------------------------------

Encoder = oo.class({}, Encoder)

function Encoder:alignedjump(value)
	local pos = self.cursor - 2
	self:jump(value - pos % value - 1)
	return self.cursor
end

function Encoder:put(value, idltype)
	local marshall = idltype.marshall
	if marshall == nil then
		local type = idltype._type
		if EncoderGenerator[type] then
			local gen = EncoderGenerator()
			gen:generate(idltype)                                                     --[[VERBOSE]] verbose:marshal("generating new marshaller for type ",idltype._type)
			marshall = gen:compile(idltype)
			idltype.marshall = marshall
		else                                                                        --[[VERBOSE]] verbose:marshal("using dynamic marshaller for type ",idltype._type)
			marshall = self[type] or
			           assert.illegal(type, "supported type", "MARSHALL")
		end                                                                         --[[VERBOSE]] else verbose:marshal("generated marshaller found for type ",idltype._type)
	end
	return marshall(self, value, idltype)
end

-- generate string encoder because 'Decoder:string()' does not get an argument.
local gen = EncoderGenerator()
gen:generate(idl.string)
idl.string.marshall = gen:compile(idl.string)
Encoder.string = idl.string.marshall

Encoder.struct     = Encoder.put
Encoder.union      = Encoder.put
Encoder.enum       = Encoder.put
Encoder.sequence   = Encoder.put
Encoder.array      = Encoder.put
Encoder.typedef    = Encoder.put
Encoder.except     = Encoder.put

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[VERBOSE]] verbose.codecop[Encoder] = verbose.codecop[Codec.Encoder]
--[[VERBOSE]] verbose.codecop[Decoder] = verbose.codecop[Codec.Decoder]
--[[VERBOSE]] function verbose:gen_marshal(codec, type, value)
--[[VERBOSE]] 	self:marshal(codec, type, value)
--[[VERBOSE]] 	return value
--[[VERBOSE]] end
