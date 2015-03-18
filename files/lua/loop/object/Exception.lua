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
-- Title  : Data structure to hold information about exceptions in Lua        --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local error     = error
local type      = type
local traceback = debug and debug.traceback

local table = require "table"
local oo    = require "loop.base"

module("loop.object.Exception", oo.class)

function __init(class, object)
	if traceback then
		if not object then
			object = { traceback = traceback() }
		elseif object.traceback == nil then
			object.traceback = traceback()
		end
	end
	return oo.rawnew(class, object)
end

function __concat(op1, op2)
	if type(op1) == "table" and type(op1.__tostring) == "function" then
		op1 = op1:__tostring()
	end
	if type(op2) == "table" and type(op2.__tostring) == "function" then
		op2 = op2:__tostring()
	end
	return op1..op2
end

function __tostring(self)
	local message = { self[1] or self._NAME or "Exception"," raised" }
	if self.message then
		message[#message + 1] = ": "
		message[#message + 1] = self.message
	end
	if self.traceback then
		message[#message + 1] = "\n"
		message[#message + 1] = self.traceback
	end
	return table.concat(message)
end
