-- unclasslib.lua 2.03

-- PRIVATE

--[[
	Define unique value for identifying ambiguous base objects and inherited
	attributes. Ambiguous values are normally removed from classes and objects,
	but if keep_ambiguous == true they are left there and the ambiguous value
	is made to behave in a way useful for debugging.
]]

local ambiguous = { __type = 'ambiguous' }
local remove_ambiguous

if keep_ambiguous then

	-- Make ambiguous complain about everything except tostring()
	local function invalid(operation)
		return function() 
			error('Invalid ' .. operation .. ' on ambiguous')
		end
	end
	local ambiguous_mt =
	{
		__add		= invalid('addition'),
		__sub		= invalid('substraction'),
		__mul		= invalid('multiplication'),
		__div		= invalid('division'),
		__mod		= invalid('modulus operation'),
		__pow		= invalid('exponentiation'),
		__unm		= invalid('unary minus'),
		__concat	= invalid('concatenation'),
		__len		= invalid('length operation'),
		__eq		= invalid('equality comparison'),
		__lt		= invalid('less than'),
		__le		= invalid('less or equal'),
		__index		= invalid('indexing'),
		__newindex	= invalid('new indexing'),
		__call		= invalid('call'),
		__tostring	= function() return 'ambiguous' end,
		__tonumber	= invalid('conversion to number')
	}
	setmetatable(ambiguous, ambiguous_mt)

	-- Don't remove ambiguous values from classes and objects
	remove_ambiguous = function() end

else

	-- Remove ambiguous values from classes and objects
	remove_ambiguous = function(t)
		for k, v in pairs(t) do
			if v == ambiguous then t[k] = nil end
		end
	end

end


--[[
	Reserved attribute names.
]]

local reserved =
{
	__index			= true,
	__newindex		= true,
	__type			= true,
	__class			= true,
	__bases			= true,
	__inherited		= true,
	__from			= true,
	__shared		= true,
	__user_init		= true,
	__initialized	= true
}

--[[
	Some special user-set attributes are renamed.
]]

local rename =
{
	__init	= '__user_init',
	__set	= '__user_set',
	__get	= '__user_get'
}

--[[
	The metatable of all classes, containing:

	To be used by the classes:
 	__call()		for creating instances
 	__init() 		default constructor
 	is_a()			for checking object and class types
	implements()	for checking interface support

	For internal use:
	__newindex()	for controlling class population
]]

local class_mt = {}
class_mt.__index = class_mt

--[[
	This controls class population.
	Here 'self' is a class being populated by inheritance or by the user.
]]

function class_mt:__newindex(name, value)

	-- Rename special user-set attributes	
	if rename[name] then name = rename[name] end

	-- __user_get() needs an __index() handler
	if name == '__user_get' then
		self.__index = value and function(obj, k)
			local v = self[k]
			if v == nil and not reserved[k] then v = value(obj, k) end
			return v
		end or self

	-- __user_set() needs a __newindex() handler
	elseif name == '__user_set' then
		self.__newindex = value and function(obj, k, v)
			if reserved[k] or not value(obj, k, v) then rawset(obj, k, v) end
		end or nil
	
	end

	-- Assign the attribute
	rawset(self, name, value)
end

--[[
	This function creates an object of a certain class and calls itself
	recursively to create one child object for each base class. Base objects
	are accessed by using the base class as an index into the object.
	Classes derived in shared mode will create only a single base object.
	Unambiguous grandchildren are inherited by the parent if they do not 
	collide with direct children.
]]

local function build(class, shared_objs, shared)

	-- Repository for storing shared objects
	shared_objs = shared_objs or {}

	-- Shared inheritance creates a single shared child per base class
	if shared and shared_objs[class] then return shared_objs[class] end

	-- New object
	local obj = { __type = 'object' }
	
	-- Repository for storing inherited base objects
	local inherited = {}
	
	-- Build child objects for each base class
	for i, base in ipairs(class.__bases) do
		local child = build(base, shared_objs, class.__shared[base])
		obj[base] = child

		-- Get inherited grandchildren from this child
		for c, grandchild in pairs(child) do

			-- We can only accept one inherited grandchild of each class,
			-- otherwise this is an ambiguous reference
			if not inherited[c] then inherited[c] = grandchild
			elseif inherited[c] ~= grandchild then inherited[c] = ambiguous
			end
		end
	end
	
	-- Accept inherited grandchildren if they don't collide with
	-- direct children
	for k, v in pairs(inherited) do
		if not obj[k] then obj[k] = v end
	end

	-- Remove ambiguous inherited grandchildren
	remove_ambiguous(obj)

	-- Object is ready
	setmetatable(obj, class)
	
	-- If shared, add it to the repository of shared objects
	if shared then shared_objs[class] = obj end

	return obj
end

--[[
	The __call() operator creates an instance of the class and initializes it.
]]

function class_mt:__call(...)
	local obj = build(self)
	obj:__init(...)
	return obj
end

--[[
	The implements() method checks that an object or class supports the
	interface of a target class. This means it can be passed as an argument to
	any function that expects the target class. We consider only functions
	and callable objects to be part of the interface of a class.
]]

function class_mt:implements(class)

	-- Auxiliary function to determine if something is callable
	local function is_callable(v)
		if v == ambiguous then return false end
		if type(v) == 'function' then return true end
		local mt = getmetatable(v)
		return mt and type(mt.__call) == 'function'
	end

	-- Check we have all the target's callables (except reserved names)
	for k, v in pairs(class) do
		if not reserved[k] and is_callable(v) and not is_callable(self[k]) then
			return false
		end
	end
	return true
end

--[[
	The is_a() method checks the type of an object or class starting from 
	its class and following the derivation chain upwards looking for
	the target class. If the target class is found, it checks that its
	interface is supported (this may fail in multiple inheritance because
	of ambiguities).
]]

function class_mt:is_a(class)

	-- If our class is the target class this is trivially true
	if self.__class == class then return true end

	-- Auxiliary function to determine if a target class is one of a list of
	-- classes or one of their bases
	local function find(target, classlist)
		for i, class in ipairs(classlist) do
			if class == target or find(target, class.__bases) then
				return true
			end
		end
		return false
	end

	-- Check that we derive from the target
	if not find(class, self.__bases) then return false end

	-- Check that we implement the target's interface.
	return self:implements(class)
end

--[[
	Factory-supplied constructor, calls the user-supplied constructor if any,
	then calls the constructors of the bases to initialize those that were
	not initialized before. Objects are initialized exactly once.
]]

function class_mt:__init(...)
	if self.__initialized then return end
	if self.__user_init then self:__user_init(...) end
	for i, base in ipairs(self.__bases) do
		self[base]:__init(...)
	end
	self.__initialized = true
end


-- PUBLIC

--[[
	Utility type and interface checking functions
]]

function typeof(value)
	local t = type(value)
	return t =='table' and value.__type or t 
end

function classof(value)
	local t = type(value)
	return t == 'table' and value.__class or nil
end

function implements(value, class)
	return classof(value) and value:implements(class) or false
end

function is_a(value, class)
	return classof(value) and value:is_a(class) or false
end

--[[
	Create a class by calling class(...). 
	Arguments are the classes or shared classes to be derived from.
]]

function class(...)

	local arg = {...}

	-- Create a new class
	local c =
	{
		__type = 'class',
		__bases = {},
		__shared = {}
	}
	c.__class = c
	c.__index = c

	-- Repository of inherited attributes
	local inherited = {}
	local from = {}

	-- Inherit from the base classes
	for i, base in ipairs(arg) do

		-- Get the base and whether it is inherited in shared mode
		local basetype = typeof(base)
		local shared = basetype == 'share'
		assert(basetype == 'class' or shared, 
				'Base ' .. i .. ' is not a class or shared class')
		if shared then base = base.__class end

		-- Just in case, check this base is not repeated
		assert(c.__shared[base] == nil, 'Base ' .. i .. ' is duplicated')
	
		-- Accept it
		c.__bases[i] = base
		c.__shared[base] = shared
		
		-- Get attributes that could be inherited from this base
		for k, v in pairs(base) do

			-- Skip reserved and ambiguous attributes
			if not reserved[k] and v ~= ambiguous and
											inherited[k] ~= ambiguous then

				-- Where does this attribute come from?
				local new_from

				-- Check if the attribute was inherited by the base
				local base_inherited = base.__inherited[k]
				if base_inherited then

					-- If it has been redefined, cancel this inheritance 
					if base_inherited ~= v then		-- (1)
						base.__inherited[k] = nil
						base.__from[k] = nil

					-- It is still inherited, get it from the original
					else
						new_from = base.__from[k]
					end
				end

				-- If it is not inherited by the base, it originates there
				new_from = new_from or { class = base, shared = shared }

				-- Accept a first-time inheritance
				local current_from = from[k]
				if not current_from then
					from[k] = new_from

					-- Wrap methods so that they are called with the correct
					-- base object self. For functions that are not methods
					-- this creates some useless code.
					if type(v) == 'function' then
						local origin = new_from.class
						inherited[k] = function(self, ...)
							return origin[k](self[origin], ...)
						end

					-- Properties are copied
					else
						inherited[k] = v
					end

				-- Attributes inherited more than once are ambiguous unless
				-- they originate in the same shared class.
				elseif current_from.class ~= new_from.class or
						not current_from.shared or not new_from.shared then
					inherited[k] = ambiguous
					from[k] = nil
				end
			end
		end
	end

	-- Remove ambiguous inherited attributes
	remove_ambiguous(inherited)

	-- Set the metatable now, it monitors attribute setting and does some
	-- special processing for some of them.
	setmetatable(c, class_mt)

	-- Set inherited attributes in the class, they may be redefined afterwards
	for k, v in pairs(inherited) do c[k] = v end	-- checked at (1)
	c.__inherited = inherited
	c.__from = from

	return c
end

--[[
	Wrap a class for shared derivation.
]]

function shared(class)
	assert(typeof(class) == 'class', 'Argument is not a class')
	return { __type = 'share', __class = class }
end
