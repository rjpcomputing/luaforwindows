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
-- Title  : Client-Side Broker                                                --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- broker:Facet
-- 	proxy:object fromstring(reference:string, [type:string])
-- 	proxy:object proxy(reference:table), [type:string]
-- 
-- proxies:Receptacle
-- 	proxy:object proxyto(reference:table, type)
-- 
-- references:Receptacle
-- 	reference:table decode(stringfiedref:string)
-- 
-- types:Receptacle
-- 	type:table resolve(type:string)
--------------------------------------------------------------------------------

local type = type

local oo = require "oil.oo"                                                     --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.kernel.typed.Client", oo.class)

context = false

function fromstring(self, reference, type)
	local result, except = self.context.references:decode(reference)
	if result then
		result, except = self:proxy(result, type)
	end
	return result, except
end

function proxy(self, reference, type)                                           --[[VERBOSE]] verbose:client "creating proxy"
	local result, except = true
	if type then
		result, except = self.context.types:resolve(type)
		if result then type = result end
	end
	if result then
		result, except = self.context.proxies:proxyto(reference, type)
	end
	return result, except
end

function excepthandler(self, handler, type)                                     --[[VERBOSE]] verbose:client("setting exception handler for proxies of ",type)
	local result, except = true
	if type then
		result, except = self.context.types:resolve(type)
		if result then type = result end
	end
	if result then
		result, except = self.context.proxies:excepthandler(handler, type)
	end
	return result, except
end
