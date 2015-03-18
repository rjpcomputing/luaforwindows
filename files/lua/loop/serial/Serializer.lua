--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Serializer that Serialize Values to Lua Code                      --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G = _G
local getmetatable = getmetatable
local setmetatable = setmetatable
local getfenv = getfenv
local setfenv = setfenv
local package = package
local assert = assert
local select = select
local pairs = pairs
local pcall = pcall
local ipairs = ipairs
local loadstring = loadstring
local rawget = rawget
local rawset = rawset
local require = require
local tostring = tostring
local tonumber = tonumber
local error = error
local type = type

local debug = debug
local string = require "string"
local table = require "loop.table"
local oo = require "loop.base"

module("loop.serial.Serializer", oo.class)

__mode = "k"

namespace = "serial"

------------------------------------------------------------------------------
_M.globals = _G
_M.require = require
_M.getmetatable = getmetatable
_M.setmetatable = setmetatable
_M.getfenv = getfenv
_M.setfenv = setfenv
_M.getupvalue = debug and debug.getupvalue
_M.setupvalue = debug and debug.setupvalue
_M.package = package and package.loaded
------------------------------------------------------------------------------
Environment = oo.class{ __index = _G }

function addmembers(self, pack)
	if type(pack) == "table" then
		for field, member in pairs(pack) do
			local kind = type(member)
			if
				self[member] == nil and
				kind ~= "boolean" and kind ~= "number" and kind ~= "string" and
				type(field) == "string" and field:match("^[%a_]+[%w_]*$")
			then
				self[member] = self[pack].."."..field
			end
		end
	end
end

function __init(self, object)
	self = oo.rawnew(self, object)
	self.environment = self.environment or Environment()
	self.environment[self.namespace] = self
	if self.globals then
		self[self.globals] = self.namespace..".globals"
		for field, member in pairs(self.globals) do
			if
				self[member] == nil and
				type(field) == "string" and field:match("^[%a_]+[%w_]*$") and
				type(member) == "function" and not pcall(string.dump, member)
			then
				self[member] = self.namespace..".globals."..field
			end
		end
	end
	if self.package then
		for name, pack in pairs(self.package) do
			if self[pack] == nil then
				self[pack] = self.namespace..'.require("'..name..'")'
				self:addmembers(pack)
			end
		end
	end
	return self
end

------------------------------------------------------------------------------
local Incomplete = oo.class()

function Incomplete:__load(contents, metatable)
	table.copy(contents, self)
	return setmetatable(self, metatable)
end

function value(self, id, type, ...)
	local value = self[id]
	if not value then
		if type == "function" then
			value = assert(loadstring((...)))
		elseif type == "userdata" then
			value = assert(self[...], "unknown userdata")()
		elseif type == "table" then
			local meta
			value, meta = ...
			if meta and self.setmetatable then
				self.setmetatable(value, meta)
			end
		else
			value = Incomplete()
		end
		self[id] = value
	elseif type == "table" and oo.classof(value) == Incomplete then
		value:__load(...)
	end
	return value
end

function setup(self, value, ...)
	local type = type(value)
	if type == "function" then
		if self.setfenv then self.setfenv(value, ... or self.globals) end
		local setupvalue = self.setupvalue
		if setupvalue then
			local up = 1
			while setupvalue(value, up, select(up+1, ...) or nil) do
				up = up + 1
			end
		end
	else
		local loader = getmetatable(value)
		if loader then loader = loader.__load end
		if loader then loader(value, ...) end
	end
	return value
end

function load(self, data)
	local errmsg
	data, errmsg = loadstring(data)
	if data then setfenv(data, self.environment) end
	return data, errmsg
end
------------------------------------------------------------------------------
function serialstring(self, string)
	self:write(string.format("%q", string))
end

function serialtable(self, table, id)
	self[table] = self.namespace..":value("..id..")"
	
	-- serialize contents
	self:write(self.namespace,":value(",id,",'table',{")
	for key, val in pairs(table) do
		self:write("[")
		self:serialize(key)
		self:write("]=")
		self:serialize(val)
		self:write(",")
	end
	self:write("}")

	-- serialize metatable
	if self.getmetatable then
		local meta = self.getmetatable(table)
		if meta then
			self:write(",")
			self:serialize(meta)
		end
	end
	
	self:write(")")
end

function serialfunction(self, func, id)
	self[func] = self.namespace..":value("..id..")"
	self:write(self.namespace,":setup(")
	
	-- serialize bytecodes
	self:write(self.namespace,":value(",id,",'function','")
	local bytecodes = string.dump(func)
	for i = 1, #bytecodes do
		self:write("\\",string.byte(bytecodes, i))
	end
	self:write("')")

	-- serialize environment
	local env
	if self.getfenv then
		env = self.getfenv(func)
		if env == self.globals then env = nil end
	end
	self:write(",")
	self:serialize(env)

	-- serialize upvalues
	if self.getupvalue then
		local name, value
		local up = 1
		repeat
			name, value = self.getupvalue(func, up)
			if name then
				self:write(",")
				self:serialize(value)
			end
			up = up + 1
		until not name
	end
	
	self:write(")")
end

function serialcustom(self, id, name, ...)
	local state = select("#", ...) > 0
	if state then
		self:write(self.namespace,":setup(")
	end
	self:write(self.namespace,":value(",id,",'userdata','",name,"')")
	if state then
		self:write(",")
		self:serialize(...)
		self:write(")")
	end
end

function serialuserdata(self, userdata, id)
	local serializer = getmetatable(userdata)
	if serializer then
		serializer = serializer.__serialize
		if serializer then
			self[userdata] = self.namespace..":value("..id..")"
			return self:serialcustom(id, serializer(userdata))
		end
	end
	error("unable to serialize a userdata without custom serialization")
end

local function getidfor(value)
	local meta = getmetatable(value)
	local backup
	if meta then
		backup = rawget(meta, "__tostring")
		if backup ~= nil then rawset(meta, "__tostring", nil) end
	end
	local id = string.match(tostring(value), "%l+: (%w+)")
	if meta then
		if backup ~= nil then rawset(meta, "__tostring", backup) end
	end
	return tonumber(id, 16) or id
end

function serialize(self, ...)
	for i=1, select("#", ...) do
		if i ~= 1 then self:write(",") end
		local value = select(i, ...)
		local type = type(value)
		if type == "nil" or type == "boolean" or type == "number" then
			self:write(tostring(value))
		elseif type == "string" then
			self:serialstring(value)
		else
			local id = self[value]
			if id then
				self:write(id)
			elseif self[type] then
				self[type](self, value, getidfor(value))
			else
				error("unable to serialize a "..type)
			end
		end
	end
end

_M["table"]    = serialtable
_M["function"] = serialfunction
_M["userdata"] = serialuserdata
_M["thread"]   = serialthread
