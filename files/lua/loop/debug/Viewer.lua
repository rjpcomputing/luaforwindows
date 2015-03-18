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
-- Title  : Visualization of Lua Values                                       --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G           = _G
local select       = select
local type         = type
local next         = next
local pairs        = pairs
local rawget       = rawget
local rawset       = rawset
local getmetatable = getmetatable
local setmetatable = setmetatable
local luatostring  = tostring
local loaded       = package and package.loaded

local string = require "string"
local table  = require "table"
local io     = require "io"
local oo     = require "loop.base"

module("loop.debug.Viewer", oo.class)

maxdepth = -1
indentation = "  "
linebreak = "\n"
prefix = ""
output = io.output()

function writevalue(self, buffer, value, history, prefix, maxdepth)
	local luatype = type(value)
	if luatype == "nil" or luatype == "boolean" or luatype == "number" then
		buffer:write(luatostring(value))
	elseif luatype == "string" then
		buffer:write(string.format("%q", value))
	else
		local label = history[value]
		if label then
			buffer:write(label)
		else
			label = self.labels[value] or self:label(value)
			history[value] = label
			if luatype == "table" then
				buffer:write("{ --[[",label,"]]")
				local key, field = next(value)
				if key then
					if maxdepth == 0 then
						buffer:write(" ... ")
					else
						maxdepth = maxdepth - 1
						local newprefix = prefix..self.indentation
						for i = 1, #value do
							buffer:write(self.linebreak, newprefix)
							self:writevalue(buffer, value[i], history, newprefix, maxdepth)
							buffer:write(",")
						end
						repeat
							local keytype = type(key)
							if keytype ~= "number" or key<=0 or key>#value or (key%1)~=0 then
								buffer:write(self.linebreak, newprefix)
								if keytype == "string" and key:match("^[%a_][%w_]*$") then
									buffer:write(key)
								else
									buffer:write("[")
									self:writevalue(buffer, key, history, newprefix, maxdepth)
									buffer:write("]")
								end
								buffer:write(" = ")
								self:writevalue(buffer, field, history, newprefix, maxdepth)
								buffer:write(",")
							end
							key, field = next(value, key)
						until not key
						buffer:write(self.linebreak, prefix)
					end
				else
					buffer:write(" ")
				end
				buffer:write("}")
			else
				buffer:write(label)
			end
		end
	end
end

function writeto(self, buffer, ...)
	local prefix   = self.prefix
	local maxdepth = self.maxdepth
	local history  = {}
	for i = 1, select("#", ...) do
		if i ~= 1 then buffer:write(", ") end
		self:writevalue(buffer, select(i, ...), history, prefix, maxdepth)
	end
end

local function add(self, ...)
	for i = 1, select("#", ...) do self[#self+1] = select(i, ...) end
end
function tostring(self, ...)
	local buffer = { write = add }
	self:writeto(buffer, ...)
	return table.concat(buffer)
end

function write(self, ...)
	self:writeto(self.output, ...)
end

function print(self, ...)
	local output   = self.output
	local prefix   = self.prefix
	local maxdepth = self.maxdepth
	local history  = {}
	local value
	for i = 1, select("#", ...) do
		value = select(i, ...)
		if type(value) == "string"
			then output:write(value)
			else self:writevalue(output, value, history, prefix, maxdepth)
		end
	end
	output:write("\n")
end

function label(self, value)
	local meta = getmetatable(value)
	if meta then
		local custom = rawget(meta, "__tostring")
		if custom then
			rawset(meta, "__tostring", nil)
			local raw = luatostring(value)
			rawset(meta, "__tostring", custom)
			custom = luatostring(value)
			if raw == custom
				then return raw
				else return custom.." ("..raw..")"
			end
		end
	end
	return luatostring(value)
end

function package(self, name, pack)
	local labels = self.labels
	labels[pack] = name
	for field, member in pairs(pack) do
		local kind = type(member)
		if
 			labels[member] == nil and
			(kind == "function" or kind == "userdata") and
			field:match("^[%a_]+[%w_]*$")
		then
			labels[member] = name.."."..field
		end
	end
end

if loaded then
	local luapacks = {
		coroutine = true,
		package   = true,
		string    = true,
		table     = true,
		math      = true,
		io        = true,
		os        = true,
	}
	-- create cache for global values
	labels = { __mode = "k" }
	setmetatable(labels, labels)
	-- cache names of global functions
	for name, func in pairs(_G) do
		if type(func) == "function" then
			labels[func] = name
		end
	end
	-- label loaded Lua library packages
	for name in pairs(luapacks) do
		local pack = loaded[name]
		if pack then package(_M, name, pack) end
	end
	-- label other loaded packages
	for name, pack in pairs(loaded) do
		if not luapacks[name] and type(pack) == "table" then
			package(_M, name, pack)
		end
	end
end
