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
-- Title  : Request Acceptor                                                  --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- acceptor:Facet
-- 	configs:table, [except:table] setup([configs:table])
-- 	success:boolean, [except:table] hasrequest(configs:table)
-- 	success:boolean, [except:table] acceptone(configs:table)
-- 	success:boolean, [except:table] acceptall(configs:table)
-- 	success:boolean, [except:table] halt(configs:table)
-- 
-- listener:Receptacle
-- 	configs:table default([configs:table])
-- 	channel:object, [except:table] getchannel(configs:table)
-- 	success:boolean, [except:table] disposechannels(configs:table)
-- 	success:boolean, [except:table] disposechannel(channel:object)
-- 	request:table, [except:table] = getrequest(channel:object, [probe:boolean])
-- 	success:booelan, [except:table] = sendreply(channel:object, request:table, success:booelan, results...)
-- 
-- dispatcher:Receptacle
-- 	success:boolean, [except:table]|results... dispatch(objectkey:string, operation:string|function, params...)
-- 
-- tasks:Receptacle
-- 	current:thread
-- 	start(func:function, args...)
-- 	remove(thread:thread)
--------------------------------------------------------------------------------

local next  = next
local pairs = pairs

local oo        = require "oil.oo"
local Exception = require "oil.Exception"
local Receiver  = require "oil.kernel.base.Receiver"                            --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.kernel.cooperative.Receiver"

oo.class(_M, Receiver)

context = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function __init(self, object)
	self = oo.rawnew(self, object)
	self.thread = {}
	self.threads = {}
	return self
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function sendreply(self, channel, request, ...)
	local context = self.context
	context.mutex:locksend(channel)
	local result, except = context.listener:sendreply(channel, request, ...)
	context.mutex:freesend(channel)
	if not result and except.reason ~= "closed" and not self.except then
		self.except = except
	end
end

function dispatchrequest(self, channel, request)
	self:sendreply(channel, request, self.context.dispatcher:dispatch(
		request.object_key,
		request.operation,
		request.opimpl,
		request:params()
	))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function getallrequests(self, channelinfo, channel)
	local context = self.context
	local thread = context.tasks.current
	local threads = self.threads[channelinfo]
	threads[thread] = channel
	local result, except
	repeat
		result, except = context.listener:getrequest(channel)
		if result then
			context.tasks:start(self.dispatchrequest, self, channel, result)
		end
	until except or self.except
	if not result and except.reason ~= "closed" and not self.except then
		self.except = except
	end
	threads[thread] = nil
	if next(threads) == nil then
		threads[thread] = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function acceptall(self, channelinfo)                                           --[[VERBOSE]] verbose:acceptor(true, "accept all requests from channel ",channelinfo)
	local context = self.context
	self.thread[channelinfo] = context.tasks.current
	self.threads[channelinfo] = {}
	local result, except
	repeat
		result, except = context.listener:getchannel(channelinfo)
		if result then
			context.tasks:start(self.getallrequests, self, channelinfo, result)
		end
	until not result and except.reason ~= "closed" or self.except                 --[[VERBOSE]] verbose:acceptor(false)
	self.channelinfo = nil
	self.thread[channelinfo] = nil
	return nil, self.except or except
end

function halt(self, channelinfo)                                                --[[VERBOSE]] verbose:acceptor "halt acceptor"
	local tasks = self.context.tasks
	local listener = self.context.listener
	local result, except = nil, Exception{
		reason = "halted",
		message = "orb already halted",
	}
	local thread = self.thread[channelinfo]
	if thread then
		tasks:remove(thread)
		result, except = listener:disposechannels(channelinfo)
		self.thread[channelinfo] = nil
	end
	local threads = self.threads[channelinfo]
	if threads then
		for thread, channel in pairs(threads) do
			tasks:remove(thread)
			result, except = listener:disposechannel(channel)
		end
		self.threads[channelinfo] = nil
	end
	return result, except
end
