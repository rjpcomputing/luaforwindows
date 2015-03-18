--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Release: 2.3 beta                                                          --
-- Title  : Cached Class Model                                                --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Exported API:                                                              --
--   class(class, ...)                                                        --
--   new(class, ...)                                                          --
--   classof(object)                                                          --
--   isclass(class)                                                           --
--   instanceof(object, class)                                                --
--   memberof(class, name)                                                    --
--   members(class)                                                           --
--   superclass(class)                                                        --
--   subclassof(class, super)                                                 --
--   supers(class)                                                            --
--   allmembers(class)                                                        --
--------------------------------------------------------------------------------

local type         = type
local unpack       = unpack
local pairs        = pairs
local rawget       = rawget
local rawset       = rawset
local require      = require
local ipairs       = ipairs
local setmetatable = setmetatable
local select       = select

local table = require "loop.table"

module "loop.cached"
--------------------------------------------------------------------------------
local OrderedSet  = require "loop.collection.OrderedSet"
local base        = require "loop.multiple"
--------------------------------------------------------------------------------
table.copy(base, _M)
--------------------------------------------------------------------------------
local function subsiterator(queue, class)
	class = queue[class]
	if class then
		for sub in pairs(class.subs) do
			queue:enqueue(sub)
		end
		return class
	end
end
function subs(class)
	queue = OrderedSet()
	queue:enqueue(class)
	return subsiterator, queue, OrderedSet.firstkey
end
--------------------------------------------------------------------------------
local function proxy_newindex(proxy, field, value)
	return base.classof(proxy):updatefield(field, value)
end
--------------------------------------------------------------------------------
function getclass(class)
	local cached = base.classof(class)
	if base.instanceof(cached, CachedClass) then
		return cached
	end
end
--------------------------------------------------------------------------------
local ClassMap = base.new { __mode = "k" }
--------------------------------------------------------------------------------
CachedClass = base.class()

function CachedClass:__init(class)
	local meta = {}
	self = base.rawnew(self, {
		__call = new,
		__index = meta,
		__newindex = proxy_newindex,
		supers = {},
		subs = {},
		members = table.copy(class, {}),
		class = meta,
	})
	self.proxy = setmetatable(class and table.clear(class) or {}, self)
	ClassMap[self.class] = self.proxy
	return self
end

function CachedClass:updatehierarchy(...)
	-- separate cached from non-cached classes
	local caches = {}
	local supers = {}
	for i = 1, select("#", ...) do
		local super = select(i, ...)
		local cached = getclass(super)
		if cached
			then caches[#caches + 1] = cached
			else supers[#supers + 1] = super
		end
	end

	-- remove it from its old superclasses
	for _, super in ipairs(self.supers) do
		super:removesubclass(self)
	end
	
	-- update superclasses
	self.uncached = supers
	self.supers = caches

	-- register as subclass in all superclasses
	for _, super in ipairs(self.supers) do
		super:addsubclass(self)
	end
end

function CachedClass:updateinheritance()
	-- relink all affected classes
	for sub in subs(self) do
		sub:updatemembers()
		sub:updatesuperclasses()
	end
end

function CachedClass:addsubclass(class)
	self.subs[class] = true
end

function CachedClass:removesubclass(class)
	self.subs[class] = nil
end

function CachedClass:updatesuperclasses()
	local uncached = {}
	-- copy uncached superclasses defined in the class
	for _, super in ipairs(self.uncached) do
		if not uncached[super] then
			uncached[super] = true
			uncached[#uncached + 1] = super
		end
	end
	-- copy inherited uncached superclasses
	for _, cached in ipairs(self.supers) do
		for _, super in base.supers(cached.class) do
			if not uncached[super] then
				uncached[super] = true
				uncached[#uncached + 1] = super
			end
		end
	end
	base.class(self.class, unpack(uncached))
end

function CachedClass:updatemembers()
	local class = table.clear(self.class)
	for i = #self.supers, 1, -1 do
		local super = self.supers[i].class
		-- copy inherited members
		table.copy(super, class)
		-- do not copy the default __index value
		if rawget(class, "__index") == super then
			rawset(class, "__index", nil)
		end
	end
	-- copy members defined in the class
	table.copy(self.members, class)
	-- set the default __index value
	if rawget(class, "__index") == nil then
		rawset(class, "__index", class)
	end
end

function CachedClass:updatefield(name, member)
	-- update member list
	local members = self.members
	members[name] = member

	-- get old linkage
	local class = self.class
	local old = class[name]
	
	-- replace old linkage for the new one
	class[name] = member
	local queue = OrderedSet()
	for sub in pairs(self.subs) do
		queue:enqueue(sub)
	end
	while queue:head() do
		local current = queue:dequeue()
		class = current.class
		members = current.members
		if members[name] == nil then
			for _, super in ipairs(current.supers) do
				local superclass = super.class
				if superclass[name] ~= nil then
					if superclass[name] ~= class[name] then
						class[name] = superclass[name]
						for sub in pairs(current.subs) do
							queue:enqueue(sub)
						end
					end
					break
				end
			end
		end
	end
	return old
end
--------------------------------------------------------------------------------
function class(class, ...)
	class = getclass(class) or CachedClass(class)
	class:updatehierarchy(...)
	class:updateinheritance()
	return class.proxy
end
--------------------------------------------------------------------------------
function rawnew(class, object)
	local cached = getclass(class)
	if cached then class = cached.class end
	return base.rawnew(class, object)
end
--------------------------------------------------------------------------------
function new(class, ...)
	if class.__init
		then return class:__init(...)
		else return rawnew(class, ...)
	end
end
--------------------------------------------------------------------------------
function classof(object)
	local class = base.classof(object)
	return ClassMap[class] or class
end
--------------------------------------------------------------------------------
function isclass(class)
	return getclass(class) ~= nil
end
--------------------------------------------------------------------------------
function superclass(class)
	local supers = {}
	local cached = getclass(class)
	if cached then
		for index, super in ipairs(cached.supers) do
			supers[index] = super.proxy
		end
		class = cached.class
	end
	for _, super in base.supers(class) do
		supers[#supers + 1] = super
	end
	return unpack(supers)
end
--------------------------------------------------------------------------------
local function icached(cached, index)
	local super
	local supers = cached.supers
	index = index + 1
	-- check if index points to a cached superclass
	super = supers[index]
	if super then return index, super.proxy end
	-- check if index points to an uncached superclass
	super = cached.uncached[index - #supers]
	if super then return index, super end
end
function supers(class)
	local cached = getclass(class)
	if cached
		then return icached, cached, 0
		else return base.supers(class)
	end
end
--------------------------------------------------------------------------------
function subclassof(class, super)
	if class == super then return true end
	for _, superclass in supers(class) do
		if subclassof(superclass, super) then return true end
	end
	return false
end
--------------------------------------------------------------------------------
function instanceof(object, class)
	return subclassof(classof(object), class)
end
--------------------------------------------------------------------------------
function memberof(class, name)
	local cached = getclass(class)
	if cached
		then return cached.members[name]
		else return base.member(class, name)
	end
end
--------------------------------------------------------------------------------
function members(class)
	local cached = getclass(class)
	if cached
		then return pairs(cached.members)
		else return base.members(class)
	end
end
--------------------------------------------------------------------------------
function allmembers(class)
	local cached = getclass(class)
	if cached
		then return pairs(cached.class)
		else return base.members(class)
	end
end