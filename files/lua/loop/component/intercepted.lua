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
-- Title  : Port Model with Interception Support                              --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Exported API:                                                              --
--   Facet                                                                    --
--   Receptacle                                                               --
--   ListReceptacle                                                           --
--   HashReceptacle                                                           --
--   SetReceptacle                                                            --
--   intercept(template|factory|comp, portname, event, interceptor)           --
--------------------------------------------------------------------------------

local getmetatable = getmetatable
local pairs        = pairs
local rawget       = rawget
local rawset       = rawset
local tostring     = tostring
local type         = type

local ObjectCache = require "loop.collection.ObjectCache"
local oo          = require "loop.cached"
local base        = require "loop.component.base"

module "loop.component.intercepted"

--------------------------------------------------------------------------------

local function doafter(iceptor, request, method, ...)
	local operation = iceptor.after
	if operation then
		if request.cancel
			then return operation(iceptor, request, ...)
			else return operation(iceptor, request, method(...))
		end
	else
		if request.cancel
			then return ...
			else return method(...)
		end
	end
end

local function dobefore(iceptor, request, method, ...)
	local operation = iceptor.before
	if operation
		then return doafter(iceptor, request, method, operation(iceptor, request, ...))
		else return doafter(iceptor, request, method, ...)
	end
end

--------------------------------------------------------------------------------

Wrapper = oo.class()

function Wrapper:__init(object)
	local name = object.__name
	object.__init        = false
	object.__methodkey   = "  method"..name
	object.__indexkey    = "  index"..name
	object.__newindexkey = "  newindex"..name
	object.__callkey     = "  call"..name
	return oo.rawnew(self, object)
end

MethodCache = ObjectCache()
function MethodCache:retrieve(method)
	return function(self, ...)
		local object = self:__get()
		local iceptor = rawget(self, "  method") or self.__factory[self.__methodkey]
		if iceptor then
			local request = {
				context = self.__context,
				port = self.__name,
				object = object,
				method = method,
				event = "method",
			}
			return dobefore(iceptor, request, method, object, ...)
		end
		return method(object, ...)
	end
end

local function getfield(table, field)
	return table[field]
end
function Wrapper:__index(field)
	-- NOTE: retrieve class members first
	local class = oo.classof(self)
	if class[field] then return class[field] end

	local object = self:__get()
	local factory = self.__factory
	local iceptor = rawget(self, "  index") or factory[self.__indexkey]

	local value
	if iceptor then
		local request = {
			context = self.__context,
			port = self.__name,
			object = object,
			field = field,
			event = "index",
		}
		value = dobefore(iceptor, request, getfield, object, field)
	else
		value = object[field]
	end

	if type(value) == "function" then
		value = MethodCache[value]
	end

	return value
end

local function setfield(table, field, value)
	table[field] = value
end
function Wrapper:__newindex(field, value)
	local object = self:__get()
	local factory = self.__factory
	local interceptor = rawget(self, "  newindex") or factory[self.__newindex]
	if interceptor then
		local request = {
			context = self.__context,
			port = self.__name,
			object = object,
			field = field,
			event = "newindex",
		}
		dobefore(iceptor, request, setfield, object, field, value)
	else
		object[field] = value
	end
end

function Wrapper:__call(...)
	local object = self:__get()
	local factory = self.__factory
	local iceptor = rawget(self, "  call") or factory[self.__callkey]
	if iceptor then
		local request = {
			context = self.__context,
			port = self.__name,
			object = object,
			event = "call",
		}
		return dobefore(iceptor, request, object, ...)
	else
		return object(...)
	end
end

function Wrapper:__intercept(event, iceptor)
	rawset(self, "  "..event, iceptor)
end

function intercept(scope, port, event, iceptor)
	local container = rawget(scope, "__container")
	local wrapper = container and container[port]
	if oo.instanceof(wrapper, Wrapper)
		then rawset(wrapper, "  "..event, iceptor)
		else scope["  "..event..port] = iceptor
	end
end

--[[----------------------------------------------------------------------------

-- Intercept at all ports of all components
loop.component.intercepted.Wrapper:__intercept(event, iceptor)
-- Intercept all facets of all components
loop.component.intercepted.Facet:__intercept(event, iceptor)
-- Intercept a particular port of a component type
loop.component.intercepted.intercept(MyCompType, "MyPort", event, iceptor)
-- Intercept a particular port of a component implementation
loop.component.intercepted.intercept(MyCompFactory, "MyPort", event, iceptor)
-- Intercept a particular port of a component instance
loop.component.intercepted.intercept(MyComponent, "MyPort", event, iceptor)

----------------------------------------------------------------------------]]--

Facet = oo.class({}, Wrapper)

function Facet:__init(state, key, context)
	local wrapper = Wrapper.__init(self, {
		__state = state,
		__context = context,
		__key = key,
		__name = tostring(key),
		__factory = state.__factory,
	})
	wrapper:__bind(state[key] or state.__component[key] or state.__component)
	return wrapper
end

function Facet:__bind(port)
	self.__state[self.__key] = port
end

function Facet:__get()
	return self.__state[self.__key]
end

--------------------------------------------------------------------------------

Receptacle = oo.class({}, Wrapper)

function Receptacle:__init(state, key, context)
	local wrapper = Wrapper.__init(self, {
		__state = state,
		__context = context,
		__key = key,
		__name = tostring(key),
		__factory = state.__factory,
	})
	wrapper:__bind(state[key])
	return wrapper
end

function Receptacle:__bind(port)
	rawset(self, "__external", port)
	self.__state[self.__key] = port and self
end

function Receptacle:__unbind()
	rawset(self, "__external", nil)
	self.__state[self.__key] = nil
end

function Receptacle:__get()
	return rawget(self, "__external")
end

local function iterator(self, done)
	if not done then return 1, self:__get() end
end
function Receptacle:__all()
	return iterator, self
end

Receptacle.__hasany = Receptacle.__get

--------------------------------------------------------------------------------

local ReceptacleWrapper = oo.class()

function ReceptacleWrapper:__init(state, key, context)
	self = oo.rawnew(self, state[key])
	
	local connections
	for key, port in self.__receptacle:__all() do
		connections = {}
		for key, port in self.__receptacle:__all() do
			connections[key] = port
		end
		break
	end
	
	rawset(self, "__new", oo.class(Wrapper:__init{
		__get = Receptacle.__get,
		__state = state,
		__context = context,
		__key = key,
		__name = tostring(key),
		__factory = state.__factory,
	}, Wrapper))
	
	if connections then
		for key, port in pairs(connections) do
			self.__receptacle:__unbind(key)
			self:__bind(port, key)
		end
	end
	
	return self
end

function ReceptacleWrapper:__index(key)
	return getmetatable(self)[key] or self:__get(key)
end

function ReceptacleWrapper:__newindex(key, value)
	if value == nil
		then self:__unbind(key)
		else self:__bind(value, key)
	end
end

function ReceptacleWrapper:__bind(port, key)
	return self.__receptacle:__bind(self.__new{ __external = port }, key)
end

function ReceptacleWrapper:__unbind(key)
	return rawget(self.__receptacle:__unbind(key), "__external")
end

function ReceptacleWrapper:__get(key)
	local element = self.__receptacle:__get(key)
	if element then return rawget(element, "__external") end
end

function ReceptacleWrapper:__all()
	local iterator, state, key = self.__receptacle:__all()
	local element
	return function(state, key)
		key, element = iterator(state, key)
		if key and element then return key, rawget(element, "__external") end
	end, state, key
end

function ReceptacleWrapper:__intercept(interceptor, event, field)
	return self.__new:__intercept(interceptor, event, field)
end

--------------------------------------------------------------------------------

MultipleReceptacle = oo.class()

function MultipleReceptacle:__init(segments, name, context)
	segments[name] = { __receptacle = oo.rawnew(self, segments[name]) }
	return ReceptacleWrapper(segments, name, context)
end

--------------------------------------------------------------------------------

ListReceptacle = oo.class({}, MultipleReceptacle, base.ListReceptacle)

--------------------------------------------------------------------------------

HashReceptacle = oo.class({}, MultipleReceptacle, base.HashReceptacle)

--------------------------------------------------------------------------------

SetReceptacle = oo.class({}, MultipleReceptacle, base.SetReceptacle)

--------------------------------------------------------------------------------

_M[Facet         ] = "Facet"
_M[Receptacle    ] = "Receptacle"
_M[ListReceptacle] = "ListReceptacle"
_M[HashReceptacle] = "HashReceptacle"
_M[SetReceptacle ] = "SetReceptacle"
