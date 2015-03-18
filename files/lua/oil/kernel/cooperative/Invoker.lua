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
-- Title  : Remote Object Invoker                                             --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- invoker:Facet
-- 	[results:object], [except:table] invoke(reference, operation, args...)
-- 
-- requester:Receptacle
-- 	channel:object getchannel(reference)
-- 	[request:table], [except:table], [requests:table] request(channel:object, reference, operation, args...)
-- 	[request:table], [except:table], [requests:table] getreply(channel:object, [probe:boolean])
-- 
-- mutex:Facet
-- 	locksend(channel:object)
-- 	freesend(channel:object)
-- 	lockreceive(channel:object, request:object)
-- 	notifyreceived(channel:object, request:object)
-- 	freereceive(channel:object)
--------------------------------------------------------------------------------

local ipairs   = ipairs
local next     = next
local newproxy = newproxy
local pairs    = pairs
local rawset   = rawset
local type     = type
local unpack   = unpack

local oo      = require "oil.oo"
local Invoker = require "oil.kernel.base.Invoker"                               --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.kernel.cooperative.Invoker"

oo.class(_M, Invoker)

context = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function receivefrom(self, channel, request, probe)
	if request.success == nil then
		local requester = self.context.requester
		local mutex = self.context.mutex
		if not mutex or mutex:lockreceive(channel, request) then
			local result, except, failed
			repeat
				result, except, failed = requester:getreply(channel, probe)
				if result then
					mutex:notifyreceived(channel, result)
				else
					for requestid, request in pairs(failed) do
						if type(requestid) == "number" then
							request.success = false
							request.resultcount = 1
							request[1] = except
							mutex:notifyreceived(channel, request)
						end
					end
					break
				end
			until result == request or (probe and result == true)
			mutex:freereceive(channel)
		end
	end
	local handler = self[request.success]
	if handler then
		return handler(self, channel, request, probe)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function invoke(self, reference, operation, ...)                                --[[VERBOSE]] verbose:invoke(true, "invoke remote operation")
	local context = self.context
	local requester = context.requester
	local result, except = requester:getchannel(reference)
	if result then
		local channel = result
		local mutex = context.mutex
		mutex:locksend(channel)
		result, except = requester:newrequest(channel, reference, operation, ...)
		mutex:freesend(channel)
		if result then
			result[InvokerKey] = self
			result[ChannelKey] = channel
			result = Request(result)
		end
	end                                                                           --[[VERBOSE]] verbose:invoke(false)
	return result, except
end
