require 'classlib'

class.Tuple()

function Tuple:__init(...)				-- construct with initial elements
	self.elem = {...}
	self.n = #self.elem
end

function Tuple:__tostring()				-- string representation
	local function ascii(e)
		return type(e) == 'string' and string.format('%q', e) or tostring(e)
	end
	local s = ''
	for i, v in ipairs(self.elem) do
		s = #s == 0 and ascii(v) or s .. ', ' .. ascii(v)
	end
	return '(' .. s .. ')'
end

local function checkrange(i, max)
	assert(i >= 1 and i <= max, 
			'Index must be >= 1 and <= ' .. max)
end

local function checkindex(i, max)
	assert(type(i) == 'number', 'Index must be a number')
	checkrange(i, max)
end

function Tuple:push(i, v)				-- push an element anywhere
	if v == nil then
		v = i
		i = self.n + 1					-- by default push at the end
	end
	if v == nil then return end			-- pushing nil has no effect
	checkindex(i, self.n + 1)			-- allow appending
	table.insert(self.elem, i, v)		-- insert it
	self.n = self.n + 1					-- count it
end

function Tuple:pop(i)					-- pop an element anywhere
	if i == nil then
		i = self.n 						-- by default pop at the end
		if i == 0 then return nil end
	end
	local e = self[i]
	self[i] = nil						-- remove it
	return e							-- return it
end

function Tuple:clear()					-- empty tuple
	self.elem = {}
	self.n = 0
end

function Tuple:size()					-- tuple size
	return self.n
end

function Tuple:__get(i)					-- read an element
	if type(i) ~= 'number' then return nil end
	checkrange(i, self.n + 1)			-- allow reading one past the end
	return self.elem[i]					-- read it
end

function Tuple:__set(i, v)				-- assign an element
	if type(i) ~= 'number' then return false end
	checkrange(i, self.n + 1)			-- allow assigning one past the end
	if v == nil then
		if i <= self.n then				-- if removing, count it
			table.remove(self.elem, i)
			self.n = self.n - 1
		end
		return true
	end 
	if i == self.n + 1 then				-- if appending, count it
		self.n = i
	end
	self.elem[i] = v					-- assign it
	return true
end
