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
-- Title  : Map of Objects that Keeps an Array of Key Values                  --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   Can only store non-numeric values.                                       --
--   Use of key strings equal to the name of one method prevents its usage.   --
--------------------------------------------------------------------------------

local rawget         = rawget
local table          = require "table"
local oo             = require "loop.simple"
local UnorderedArray = require "loop.collection.UnorderedArray"

module("loop.collection.MapWithArrayOfKeys", oo.class)

keyat = rawget

function value(self, key, value)
	if value == nil
		then return self[key]
		else self[key] = value
	end
end

function add(self, key, value)
	self[#self + 1] = key
	self[key] = value
end

function addat(self, index, key, value)
	table.insert(self, index, key)
	self[key] = value
end

function remove(self, key)
	for i = 1, #self do
		if self[i] == key then
			return removeat(self, i)
		end
	end
end

function removeat(self, index)
	self[ self[index] ] = nil
	return UnorderedArray.remove(self, index)
end

function valueat(self, index, value)
	if value == nil
		then return self[ self[index] ]
		else self[ self[index] ] = value
	end
end
