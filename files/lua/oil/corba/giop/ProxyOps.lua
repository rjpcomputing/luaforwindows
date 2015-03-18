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
-- Title  : Client-Side Interface Indexer                                     --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- indexer:Facet
-- 	interface:table typeof(reference:table)
-- 	member:table, [islocal:function], [cached:boolean] valueof(interface:table, name:string)
-- 
-- members:Receptacle
-- 	member:table valueof(interface:table, name:string)
-- 
-- invoker:Receptacle
-- 	[results:object], [except:table] invoke(reference:table, operation, args...)
-- 
-- types:Receptacle
-- 	[type:table] register(definition:object)
-- 	[type:table] resolve(type:string)
-- 	[type:table] lookup_id(repid:string)
-- 
-- profiler:HashReceptacle
-- 	result:boolean equivalent(profile1:string, profile2:string)
--------------------------------------------------------------------------------

local ipairs = ipairs

local oo        = require "oil.oo"
local assert    = require "oil.assert"
local Proxies   = require "oil.kernel.base.Proxies"
local idl       = require "oil.corba.idl"
local giop      = require "oil.corba.giop"
local Indexer   = require "oil.corba.giop.Indexer"                              --[[VERBOSE]] local verbose = require "oil.verbose"

module"oil.corba.giop.ProxyOps"

oo.class(_M, Indexer)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function context(component, context)
	local localops = {}
	
	local function _non_existentresults(self)
		local success, result = oo.classof(self).results(self)
		if
			not success and
			( result.exception_id == "IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0" or
			  result.reason == "closed" )
		then
			success, result = true, true
		end
		return success, result
	end
	function localops:_non_existent()
		local reply, except = context.invoker:invoke(
			self.__reference, 
			giop.ObjectOperations._non_existent
		)
		if reply then
			reply.results = _non_existentresults
		elseif except.reason == "connect" or except.reason == "closed" then
			reply = Proxies.packresults(true)
		end
		return reply, except
	end
	
	local function _narrowresults(self)
		local success, result = oo.classof(self).results(self)
		if success then
			result = context.types:lookup_id(result:_get_id()) or
			         context.types:register(result)
			result = self.__context.proxies:proxyto(self.__reference, result)
		end
		return success, result
	end
	function localops:_narrow(iface)
		local reply, except
		if iface == nil then
			reply, except = context.invoker:invoke(
				self.__reference, 
				giop.ObjectOperations._interface
			)
			if reply then
				reply.__context = self.__context
				reply.__reference = self.__reference
				reply.results = _narrowresults
			end
		else
			reply, except = context.types:resolve(iface)
			if reply then
				reply, except = self.__context.proxies:proxyto(self.__reference, reply)
			end
			if reply then
				reply = Proxies.packresults(reply)
			end
		end
		return reply, except
	end
	
	local IsEquivalentReply = Proxies.packresults(true)
	local NotEquivalentReply = Proxies.packresults(false)
	function localops:_is_equivalent(proxy)
		local reference = proxy.__reference
		local ref = self.__reference
		local tags = {}
		for _, profile in ipairs(reference.profiles) do
			tags[profile.tag] = profile
		end
		for _, profile in ipairs(ref.profiles) do
			local tag = profile.tag
			local other = tags[tag]
			if other then
				local profiler = context.profiler[tag]
				if
					profiler and
					profiler:equivalent(profile.profile_data, other.profile_data)
				then
					return IsEquivalentReply
				end
			end
		end
		return NotEquivalentReply
	end
	
	component.localops = localops
	component.context = context
end

function importinterfaceof(self, reference)
	local context = self.context
	local operation = giop.ObjectOperations._interface
	local success, result = context.invoker:invoke(reference, operation)
	if success then
		success, result = success:results()
		if success then
			success = context.types:lookup_id(result:_get_id()) or
			          context.types:register(result)
		end
	end
	return success or assert.exception(result)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function typeof(self, reference)
	local type = reference.type_id
	local types = self.context.types
	return self.context.types:lookup_id(type) or
	       self:importinterfaceof(reference)
end

function valueof(self, interface, name)
	local member = Indexer.valueof(self, interface, name)
	if member and member._type ~= "operation" then
		member = nil
	end
	return member, self.localops[name], true
end
