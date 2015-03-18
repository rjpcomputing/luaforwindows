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
-- Title  : Stream that Serializes and Restores Values from Files             --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local assert = assert
local table = require "table"
local oo = require "loop.simple"
local Serializer = require "loop.serial.Serializer"

module"loop.serial.FileStream"

oo.class(_M, Serializer)

buffersize = 1024

function write(self, ...)
	self.file:write(...)
end

function put(self, ...)
	self:serialize(...)
	self.file:write("\0")
end

function get(self)
	local lines = {}
	local line
	repeat
		line = self.remains or self.file:read(self.buffersize)
		self.remains = nil
		if line and line:find("%z") then
			line, self.remains = line:match("^([^%z]*)%z(.*)$")
		end
		lines[#lines+1] = line
	until not line or self.remains
	return assert(self:load("return "..table.concat(lines)))()
end
