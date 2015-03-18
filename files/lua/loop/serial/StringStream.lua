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
-- Title  : Stream that Serializes and Restores Values from Strings           --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local assert = assert
local select = select
local table = require "table"
local oo = require "loop.simple"
local Serializer = require "loop.serial.Serializer"

module"loop.serial.StringStream"

oo.class(_M, Serializer)

pos = 1

__tostring = table.concat

function write(self, ...)
	for i=1, select("#", ...) do
		self[#self+1] = select(i, ...)
	end
end

function put(self, ...)
	if #self > 0 then self[#self+1] = "\0" end
	self:serialize(...)
end

function get(self)
	local code = self.data or self:__tostring()
	local newpos = code:find("%z", self.pos) or #code + 1
	code = code:sub(self.pos, newpos - 1)
	self.pos = newpos + 1
	return assert(self:load("return "..code))()
end
