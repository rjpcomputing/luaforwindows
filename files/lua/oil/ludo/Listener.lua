--------------------------------------------------------------------------------
------------------------------  #####      ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------ ##   ## ##  ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------  #####  ### ###### ------------------------------
--------------------------------                --------------------------------
----------------------- An Object Request Broker in Lua ------------------------
--------------------------------------------------------------------------------
-- Project: OiL - ORB in Lua                                                  --
-- Release: 0.4                                                               --
-- Title  : Server-side LuDO Protocol                                         --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- listener:Facet
-- 	configs:table default([configs:table])
-- 	channel:object, [except:table] getchannel(configs:table)
-- 	request:object, [except:table], [requests:table] = getrequest(channel:object, [probe:boolean])
-- 
-- channels:Receptacle
-- 	channel:object retieve(configs:table)
-- 	configs:table default([configs:table])
-- 
-- codec:Receptacle
-- 	encoder:object encoder()
-- 	decoder:object decoder(stream:string)
--------------------------------------------------------------------------------

local select = select
local unpack = unpack

local oo        = require "oil.oo"
local Exception = require "oil.Exception"                                       --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.ludo.Listener", oo.class)

oo.class(_M, Messenger)

context = false

--------------------------------------------------------------------------------

function getchannel(self, configs, probe)
	return self.context.channels:retrieve(configs, probe)
end

--------------------------------------------------------------------------------

function disposechannels(self, configs)                                         --[[VERBOSE]] verbose:listen("closing all channels with configs ",configs)
	local channels = self.context.channels
	return channels:dispose(configs)
end

--------------------------------------------------------------------------------

function disposechannel(self, channel)                                          --[[VERBOSE]] verbose:listen "close channel"
	return channel:close()
end

--------------------------------------------------------------------------------

local Request = oo.class()

function Request:__init(requestid, objectkey, operation, ...)                   --[[VERBOSE]] verbose:listen("got request for request ",requestid," to object ",objectkey,":",operation)
	self = oo.rawnew(self, {...})
	self.requestid = requestid
	self.object_key = objectkey
	self.operation = operation
	self.paramcount = select("#", ...)
	return self
end

function Request:params()
	return unpack(self, 1, self.paramcount)
end

function getrequest(self, channel, probe)
	local result, except = false
	if not probe or channel:probe() then
		result, except = channel:receive()
		if result then
			local decoder = self.context.codec:decoder(result:gsub("%z", "\n"))
			result = Request(decoder:get())
			channel[result.requestid] = result
		else
			if except == "closed" then channel:close() end
			except = Exception{
				reason = except,
				message = "channel closed",
				channel = channel,
			}
		end
	end
	return result, except
end

--------------------------------------------------------------------------------

function sendreply(self, channel, request, ...)                                 --[[VERBOSE]] verbose:listen("got reply for request ",request.requestid," to object ",request.object_key,":",request.operation)
	local encoder = self.context.codec:encoder()
	encoder:put(request.requestid, ...)
	channel[request.requestid] = nil
	local result, except = channel:send(encoder:__tostring():gsub("\n", "\0").."\n")
	if not result then
		if except == "closed" then channel:close() end
		except = Exception{
			reason = except,
			message = "channel closed",
			channel = channel,
		}
	end
	return result, except
end

--------------------------------------------------------------------------------

function default(self, configs)
	return self.context.channels:default(configs)
end
