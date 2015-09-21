-- Copyright (c) 2012-2013 Roland Yonaba
-- An implementation of Binary Heaps data structure in pure Lua

--[[
  Documentation :
  - http://www.algolist.net/Data_structures/Binary_heap/Array-based_int_repr
  - http://www.cs.cmu.edu/~adamchik/15-121/lectures/Binary%20Heaps/heaps.html
  - http://rperrot.developpez.com/articles/algo/structures/arbres/
--]]



local require = require
local assert = assert
local ipairs = ipairs
local pairs = pairs
local floor = math.floor
local tostring = tostring
local setmetatable = setmetatable

-- Default sorting function.
-- Used for Min-Heaps creation.
local function f_min(a,b) return a < b end

-- Value lookup in a table
local indexOf = function(t,v)
	for i = 1,#t do
		if t[i] == v then return i end
	end
	return nil
end

-- Percolates up datum in the heap recursively
local function percolate_up(self,index)
  local pIndex
  if index > 1 then
    pIndex = floor(index/2)
    if self._heap[pIndex] then
      if not (self.sort(self._heap[pIndex].value,self._heap[index].value)) then
        self._heap[pIndex],self._heap[index] = self._heap[index],self._heap[pIndex]
        percolate_up(self,pIndex) -- Recursive call from the parent index
      end
    else
      return
    end
  end
end

-- Percolates down datum in the heap recursively
local function percolate_down(self,index)
  local lfIndex,rtIndex,minIndex
  lfIndex = 2*index
  rtIndex = lfIndex + 1
  if rtIndex > self.size then
    if lfIndex > self.size then return
    else minIndex = lfIndex  end
  else
    if self.sort(self._heap[lfIndex].value,self._heap[rtIndex].value) then
      minIndex = lfIndex
    else
      minIndex = rtIndex
    end
  end
  if not self.sort(self._heap[index].value,self._heap[minIndex].value) then
    self._heap[index],self._heap[minIndex] = self._heap[minIndex],self._heap[index]
    percolate_down(self,minIndex) -- Recursive call from the newly shifted index
  end
end

-- Minimalistic heap class constructor
local function newHeap(class,comp)
  return setmetatable({_heap = {},sort = comp or f_min, size = 0},class)
end

-- The heap class
local heap = setmetatable({}, {__call = function(self,...) return newHeap(self,...) end})
heap.__index = heap

-- Checks if a heap is empty
-- Return true or false [boolean]
function heap:empty()
  return (self.size==0)
end

-- Gets heap size (the very number of elements stored in the heap)
-- Returns the heap size [number]
function heap:getSize()
  return self.size
end

-- Clears the heap
-- Returns nothing [nil]
function heap:clear()
  self._heap = {}
  self.size = 0
  return self
end

-- Returns the left child index of the current index
-- Returned index may not be a valid index in the heap
-- Returns this index [number]
function heap:leftChildIndex(index)
  return (2*index)
end

-- Returns the right child index of the current index
-- Returned index may not be a valid index in the heap
-- Returns this index [number]
function heap:rightChildIndex(index)
  return 2*index+1
end

-- Returns the parent index of the current index
-- Returned index may not be a valid index in the heap
-- Returns this index [number]
function heap:parentIndex(index)
  return floor(index/2)
end

-- Returns the top element in the heap
-- Does not pop the heap
function heap:top()
  assert(not self:empty(),'Heap is empty')
  return self._heap[1].value,self._heap[1].data
end

-- Inserts a value in the heap as a table {value = value, data = data}
-- <data> Argument is optional and may represent extra information linked to <value> argument.
-- Returns nothing [nil]
function heap:insert(value,data)
  self.size = self.size + 1
  self._heap[self.size] = {value = value, data = data}
  percolate_up(self,self.size)
  return self
end
heap.add = heap.insert

-- Pops the first element in the heap
-- Returns this element unpacked: value first then data linked
function heap:pop()
  assert(not self:empty(), 'Heap is empty.')
  local root = self._heap[1]
  self._heap[1] = self._heap[self.size]
  self._heap[self.size] = nil
  self.size = self.size-1
  if self.size>1 then
    percolate_down(self,1)
  end
  return root.value,root.data
end

-- Checks if the given index is valid in the heap
-- Returns the element stored in the heap at that very index [table], otherwise nil. [nil]
function heap:checkIndex(index)
  return self._heap[index] or nil
end

-- Pops the first element in the heap
-- Replaces it with the given element and reorders the heap
-- The size of the heap is preserved
function heap:replace(value,data)
  assert(not self:empty(), 'heap is empty, use insert()')
  local root = self._heap[1]
  self._heap[1] = {value = value,data = data}
  percolate_down(self,1)
  return root.value,root.data
end

-- Resets the heap property regards to the comparison function given as argument (Optional)
-- Returns nothing [nil]
function heap:reset(comp)
  self.sort = comp or self.sort
  local _heap = self._heap
  self._heap = {}
  self.size = 0
  for i in pairs(_heap) do
    self:insert(_heap[i].value,_heap[i].data)
  end
  return self
end

-- Appends a heap contents  to the current one
-- Returns nothing [nil]
function heap:merge(other)
  assert(self:isValid(),'Self heap is not a valid heap')
  assert(other:isValid(),'Argument is not a valid heap')
  assert(self.sort(1,2) == other.sort(1,2),'Heaps must have the same sort functions')
  for i,node in ipairs(other._heap) do
    self:insert(node.value,node.data)
  end
  return self
end

-- Shortcut for merging heaps with '+' operator
-- Returns a new heap based on h1+h2 [table]
function heap.__add(h1,h2)
  local h = heap()
  h:merge(h1)
  h:merge(h2)
  return h
end

-- Tests if each element stored in a heap is located at the right place
-- Returns true on success, false on error. [boolean]
function heap:isValid()
  if self.size <= 1 then return true end
  local i = 1
  local lfIndex,rtIndex
  for i = 1,(floor(self.size/2)) do
    lfIndex = 2*i
    rtIndex = lfIndex+1
      if self:checkIndex(lfIndex) then
        if not self.sort(self._heap[i].value,self._heap[lfIndex].value) then
          return false
        end
      end
      if self:checkIndex(rtIndex) then
        if not self.sort(self._heap[i].value,self._heap[rtIndex].value) then
          return false
        end
      end
  end
  return true
end


-- Restores the heap property
-- Should be used when a heap was found non-valid
function heap:heap(item)
  if (self.size == 0) then return end
	if item then
		local i = indexOf(self.__heap,item)
		if i then 
			percolate_down(self, i)
			percolate_up(self, i)
		end
		return
	end
	for i = floor(self.size/2),1,-1 do
		percolate_down(self,i)
	end
	return self
end


-- (Debug utility) Create a string representation of the current
-- Returns this string to be used with print() or tostring() [string]
function heap.__tostring(self)
  local out = ''
  for k in ipairs(self._heap) do
    out = out.. (('Element %d - Value : %s\n'):format(k,tostring(self._heap[k].value)))
  end
  return out
end

return heap