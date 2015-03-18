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
-- Title  : Unordered Array Optimized for Containment Check                   --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   Can only store non-numeric values.                                       --
--   Storage of strings equal to the name of one method prevents its usage.   --
--------------------------------------------------------------------------------

local rawget = rawget
local oo     = require "loop.base"

module("loop.collection.UnorderedArraySet", oo.class)

valueat = rawget
indexof = rawget

function contains(self, value)
	return self[value] ~= nil
end

function add(self, value)
	if self[value] == nil then
		self[#self+1] = value
		self[value] = #self
		return value
	end
end

function remove(self, value)
	local index = self[value]
	if index then
		local size = #self
		if index ~= size then
			local last = self[size]
			self[index], self[last] = last, index
		end
		self[value] = nil
		self[size] = nil
		return value
	end
end

function removeat(self, index)
	return self:remove(self[index])
end
