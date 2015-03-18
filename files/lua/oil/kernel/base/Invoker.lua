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
--------------------------------------------------------------------------------

local pairs    = pairs
local newproxy = newproxy
local rawset   = rawset
local type     = type
local unpack   = unpack

local oo = require "oil.oo"                                                     --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.kernel.base.Invoker", oo.class)

context = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

ChannelKey = newproxy()
InvokerKey = newproxy()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function forward(self, channel, request, probe)
	local result, except = self.context.requester:getchannel(request[1])
	if result then
		request.success = nil
		request[1] = nil
		return self:receivefrom(channel, request, probe)
	else
		request.success = false
		request[1] = except
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function receivefrom(self, channel, request, probe)
	if request.success == nil then
		local requester = self.context.requester
		local result, except, failed
		repeat
			result, except, failed = requester:getreply(channel, probe)
			if result == nil then
				for requestid, request in pairs(failed) do
					if type(requestid) == "number" then
						request.success = false
						request.resultcount = 1
						request[1] = except
					end
				end
				break
			end
		until result == request or (probe and result == true)
	end                                                                           --[[VERBOSE]] verbose:invoke(false)
	local handler = self[request.success]
	if handler then
		return handler(self, channel, request, probe)
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Request = oo.class()

function Request:ready()                                                        --[[VERBOSE]] verbose:invoke(true, "check reply")
	self[InvokerKey]:receivefrom(self[ChannelKey], self, true)                    --[[VERBOSE]] verbose:invoke(false)
	return self.success ~= nil
end

function Request:results()                                                      --[[VERBOSE]] verbose:invoke(true, "get reply")
	self[InvokerKey]:receivefrom(self[ChannelKey], self)                          --[[VERBOSE]] verbose:invoke(false)
	return self.success, unpack(self, 1, self.resultcount)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function invoke(self, reference, operation, ...)                                --[[VERBOSE]] verbose:invoke(true, "invoke remote operation")
	local requester = self.context.requester
	local result, except = requester:getchannel(reference)
	if result then
		local channel = result
		result, except = requester:newrequest(channel, reference, operation, ...)
		if result then
			result[InvokerKey] = self
			result[ChannelKey] = channel
			result = Request(result)
		end
	end                                                                           --[[VERBOSE]] verbose:invoke(false)
	return result, except
end
