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
-- Title  : Class of Dynamic Wrapper Objects for Method Invocation            --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local type        = type
local oo          = require "loop.base"
local ObjectCache = require "loop.collection.ObjectCache"

module("loop.object.Wrapper", oo.class)

function __init(self, ...)
	self = oo.rawnew(self, ...)
	self.__methods = ObjectCache()
	function self.__methods.retrieve(_, method)
		return function(_, ...)
			return method(self.__object, ...)
		end
	end
	return self
end

function __index(self, key)
	local value = self.__object[key]
	if type(value) == "function"
		then return self.__methods[value]
		else return value
	end
end
