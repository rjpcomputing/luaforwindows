--------------------------------------------------------------------------------
------------------------------  #####      ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------ ##   ## ##  ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------  #####  ### ###### ------------------------------
--------------------------------                --------------------------------
----------------------- An Object Request Broker in Lua ------------------------
--------------------------------------------------------------------------------
-- Project: OiL - ORB in Lua: An Object Request Broker in Lua                 --
-- Release: 0.4                                                               --
-- Title  : Server-Side Broker                                                --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- broker:Facet
-- 	[configs:table], [except:table] initialize([configs:table])
-- 	servant:object object(impl:object, [objectkey:string])
-- 	reference:string tostring(servant:object)
-- 	success:boolean, [except:table] pending()
-- 	success:boolean, [except:table] step()
-- 	success:boolean, [except:table] run()
-- 	success:boolean, [except:table] shutdown()
-- 
-- objects:Receptacle
-- 	configs:table
-- 	object:object register(impl:object, key:string)
-- 	impl:object unregister(key:string)
-- 	impl:object retrieve(key:string)
-- 
-- acceptor:Receptacle
-- 	configs:table, [except:table] setup([configs:table])
-- 	success:boolean, [except:table] hasrequest(configs:table)
-- 	success:boolean, [except:table] acceptone(configs:table)
-- 	success:boolean, [except:table] acceptall(configs:table)
-- 	success:boolean, [except:table] halt(configs:table)
-- 
-- references:Receptacle
-- 	reference:table referenceto(objectkey:string, accesspointinfo:table...)
-- 	stringfiedref:string encode(reference:table)
--------------------------------------------------------------------------------

local getmetatable = getmetatable
local rawget       = rawget
local rawset       = rawset
local setmetatable = setmetatable
local luatostring  = tostring
local type         = type

local oo = require "oil.oo"
local table = require "loop.table"
local ObjectCache = require "loop.collection.ObjectCache"                       --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.kernel.base.Server", oo.class)

context = false

--------------------------------------------------------------------------------
-- Servant object proxy

local function deactivate(self)
	return self._dispatcher:unregister(self._key)
end

local function indexer(self, key)
	local value = self.__newindex[key]
	if type(value) == "function"
		then return self.__methods[value]
		else return value
	end
end

function __init(self, ...)
	self = oo.rawnew(self, ...)
	self.wrappers = ObjectCache{
		retrieve = function(_, key)
			local object
			object = {
				_deactivate = deactivate,
				_dispatcher = self.context.objects,
				_key = key,
				__index = indexer,
				__methods = ObjectCache{
					retrieve = function(_, method)
						return function(_, ...)
							return method(object.__newindex, ...)
						end
					end
				}
			}
			return setmetatable(object, object)
		end
	}
	return self
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function initialize(self, config)
	local except
	self.config, except = self.context.acceptor:setup(config)
	return self.config, except
end

function hashof(self, object)
	local meta = getmetatable(object)
	local backup
	if meta then
		backup = rawget(meta, "__tostring")
		if backup ~= nil then rawset(meta, "__tostring", nil) end
	end
	local hash = luatostring(object)
	if meta then
		if backup ~= nil then rawset(meta, "__tostring", backup) end
	end
	return hash:match("%l+: (%w+)") or hash
end

function object(self, object, key)
	local context = self.context
	key = key or "\0"..self:hashof(object)
	local result, except = context.objects:register(object, key)
	if result then
		result, except = context.references:referenceto(key, self.config)
		if result then
			local wrapper = self.wrappers[key]
			rawset(wrapper, "__newindex", object)
			rawset(wrapper, "__reference", result)
			result = wrapper
		else
			context.objects:unregister(key)
		end
	end
	return result, except
end

function remove(self, object)
	local key
	if type(object) == "table" then key = rawget(object, "_key") or object end
	if type(key) ~= "string" then
		key = object.__objkey
		if key == nil then
			local meta = getmetatable(object)
			if meta then key = meta.__objkey end
			if key == nil then
				key = "\0"..self:hashof(key)
			end
		end
	end
	local success, errmsg = context.objects:unregister(key)
	if success then self.wrappers[key] = nil end
	return success, errmsg
end

function tostring(self, object)
	return self.context.references:encode(object.__reference)
end

function retrieve(self, key)
	return self.context.objects:retrieve(key)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function pending(self)
	return self.context.acceptor:hasrequest(self.config)
end

function step(self)
	return self.context.acceptor:acceptone(self.config)
end

function run(self)
	return self.context.acceptor:acceptall(self.config)
end

function shutdown(self)
	return self.context.acceptor:halt(self.config)
end
