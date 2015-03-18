require 'tuple'

class.Set()

function Set:__init(...)	-- Construct with initial elements
	local arg = {...}
	self.elem = {}
	self.n = #arg
	for i, v in ipairs(arg) do self.elem[v] = true end
end

function Set:__tostring()	-- String representation
	local function ascii(e)
		return type(e) == 'string' and string.format('%q', e) or tostring(e)
	end
	local s = ''
	for e in pairs(self.elem) do
		s = #s == 0 and ascii(e) or s .. ', ' .. ascii(e)
	end
	return '[' .. s .. ']'
end

function Set:insert(e)		-- Add an element
	if not self.elem[e] then
		self.elem[e] = true
		self.n = self.n + 1
	end
end

function Set:erase(e)		-- Remove an element
	if self.elem[e] then
		self.elem[e] = nil
		self.n = self.n - 1
	end
end

function Set:clear()		-- Remove all elements
	self.elem = {}
	self.n = 0
end

function Set:size()			-- Cardinality
	return self.n
end

function Set:contains(e)	-- Check an element
	return self.elem[e] or false
end

function Set:clone()		-- Clone
	local new = Set()
	new.n = self.n
	for e in pairs(self.elem) do new.elem[e] = true end
	return new
end

function Set:__add(r)		-- Union
	local new = self:clone()
	for e in pairs(r.elem) do new:insert(e) end
	return new
end

function Set:__sub(r)		-- Difference
	local new = Set()
	for e in pairs(self.elem) do if not r.elem[e] then new:insert(e) end end
	return new
end

function Set:__mod(r)		-- Symmetric difference
	return (self - r) + (r - self)
end

function Set:__pow(r)		-- Intersection
	local new = Set()
	for e in pairs(self.elem) do if r.elem[e] then new:insert(e) end end
	return new
end

function Set:__mul(r)		-- Cartesian product
	local new = Set()
	for first in pairs(self.elem) do
		for second in pairs(r.elem) do
			new:insert(Tuple(first, second))
		end
	end
	return new
end

function Set:__le(r)		-- Containment
	for e in pairs(self.elem) do if not r.elem[e] then return false end end
	return true
end

function Set:__lt(r)		-- Strict containment
	return self <= r and self.n < r.n
end

function Set:__eq(r)		-- Congruence
	return self <= r and self.n == r.n
end

