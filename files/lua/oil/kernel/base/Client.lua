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
-- 	proxy:object fromstring(reference:string)
-- 	proxy:object proxy(reference:table)
-- 
-- proxies:Receptacle
-- 	proxy:object proxyto(reference:table)
-- 
-- references:Receptacle
-- 	reference:table decode(stringfiedref:string)
--------------------------------------------------------------------------------

local type = type

local oo = require "oil.oo"                                                     --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.kernel.base.Client", oo.class)

context = false

function fromstring(self, reference)
	local result, except = self.context.references:decode(reference)
	if result then
		result, except = self:proxy(result)
	end
	return result, except
end

function proxy(self, reference)                                                 --[[VERBOSE]] verbose:client "creating proxy"
	return self.context.proxies:proxyto(reference)
end

function excepthandler(self, handler)                                           --[[VERBOSE]] verbose:client "setting exception handler"
	return self.context.proxies:excepthandler(handler)
end
