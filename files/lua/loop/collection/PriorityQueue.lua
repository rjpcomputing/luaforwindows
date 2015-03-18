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
-- Title  : Priority Queue Optimized for Insertions and Removals              --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   Storage of strings equal to the name of one method prevents its usage.   --
--------------------------------------------------------------------------------

local oo         = require "loop.base"
local OrderedSet = require "loop.collection.OrderedSet"

module("loop.collection.PriorityQueue", oo.class)

--------------------------------------------------------------------------------
-- internal constants ----------------------------------------------------------
--------------------------------------------------------------------------------

local PRIORITY = {}

--------------------------------------------------------------------------------
-- basic functionality ---------------------------------------------------------
--------------------------------------------------------------------------------

-- internal functions
local function getpriorities(self)
	if not self[PRIORITY] then
		self[PRIORITY] = {}
	end
	return self[PRIORITY]
end
local function removepriority(self, element)
	if element then
		local priorities = getpriorities(self)
		local priority = priorities[element]
		priorities[element] = nil
		return element, priority
	end
end

-- borrowed functions
sequence = OrderedSet.sequence
contains = OrderedSet.contains
empty = OrderedSet.empty
head = OrderedSet.head
tail = OrderedSet.tail

-- specific functions
function priority(self, element)
	return getpriorities(self)[element]
end

function enqueue(self, element, priority)
	if not contains(self, element) then
		local previous
		if priority then
			local priorities = getpriorities(self)
			for elem, prev in sequence(self) do
				local prio = priorities[elem]
				if prio and prio > priority then
					previous = prev
					break
				end
			end
			priorities[element] = priority
		end
		return OrderedSet.insert(self, element, previous)
	end
end

function dequeue(self)
	return removepriority(self, OrderedSet.dequeue(self))
end

function remove(self, element, previous)
	return removepriority(self, OrderedSet.remove(self, element, previous))
end
