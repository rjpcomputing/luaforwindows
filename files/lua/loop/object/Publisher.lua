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
-- Title  : Class that Implement Group Invocation                             --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local pairs = pairs

local oo          = require "loop.base"
local ObjectCache = require "loop.collection.ObjectCache"

module("loop.object.Publisher", oo.class)

__index = ObjectCache{
	retrieve = function(_, method)
		return function(self, ...)
			for _, object in pairs(self) do
				object[method](object, ...)
			end
		end
	end
}

function __newindex(self, key, value)
	for _, object in pairs(self) do
		object[key] = value
	end
end

function __call(self, ...)
	for _, object in pairs(self) do
		object(...)
	end
end
