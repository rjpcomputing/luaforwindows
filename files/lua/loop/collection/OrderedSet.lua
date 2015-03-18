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
-- Title  : Ordered Set Optimized for Insertions and Removals                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   Storage of strings equal to the name of one method prevents its usage.   --
--------------------------------------------------------------------------------

local oo = require "loop.base"

--------------------------------------------------------------------------------
-- key constants ---------------------------------------------------------------
--------------------------------------------------------------------------------

local FIRST = newproxy()
local LAST = newproxy()

module("loop.collection.OrderedSet", oo.class)

--------------------------------------------------------------------------------
-- basic functionality ---------------------------------------------------------
--------------------------------------------------------------------------------

local function iterator(self, previous)
	return self[previous], previous
end

function sequence(self)
	return iterator, self, FIRST
end

function contains(self, element)
	return element ~= nil and (self[element] ~= nil or element == self[LAST])
end

function first(self)
	return self[FIRST]
end

function last(self)
	return self[LAST]
end

function empty(self)
	return self[FIRST] == nil
end

function insert(self, element, previous)
	if element ~= nil and not contains(self, element) then
		if previous == nil then
			previous = self[LAST]
			if previous == nil then
				previous = FIRST
			end
		elseif not contains(self, previous) and previous ~= FIRST then
			return
		end
		if self[previous] == nil
			then self[LAST] = element
			else self[element] = self[previous]
		end
		self[previous] = element
		return element
	end
end

function previous(self, element, start)
	if contains(self, element) then
		local previous = (start == nil and FIRST or start)
		repeat
			if self[previous] == element then
				return previous
			end
			previous = self[previous]
		until previous == nil
	end
end

function remove(self, element, start)
	local prev = previous(self, element, start)
	if prev ~= nil then
		self[prev] = self[element]
		if self[LAST] == element
			then self[LAST] = prev
			else self[element] = nil
		end
		return element, prev
	end
end

function replace(self, old, new, start)
	local prev = previous(self, old, start)
	if prev ~= nil and new ~= nil and not contains(self, new) then
		self[prev] = new
		self[new] = self[old]
		if old == self[LAST]
			then self[LAST] = new
			else self[old] = nil
		end
		return old, prev
	end
end

function pushfront(self, element)
	if element ~= nil and not contains(self, element) then
		if self[FIRST] ~= nil
			then self[element] = self[FIRST]
			else self[LAST] = element
		end
		self[FIRST] = element
		return element
	end
end

function popfront(self)
	local element = self[FIRST]
	self[FIRST] = self[element]
	if self[FIRST] ~= nil
		then self[element] = nil
		else self[LAST] = nil
	end
	return element
end

function pushback(self, element)
	if element ~= nil and not contains(self, element) then
		if self[LAST] ~= nil
			then self[ self[LAST] ] = element
			else self[FIRST] = element
		end
		self[LAST] = element
		return element
	end
end

--------------------------------------------------------------------------------
-- function aliases ------------------------------------------------------------
--------------------------------------------------------------------------------

-- set operations
add = pushback

-- stack operations
push = pushfront
pop = popfront
top = first

-- queue operations
enqueue = pushback
dequeue = popfront
head = first
tail = last

firstkey = FIRST
