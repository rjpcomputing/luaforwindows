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
--------------------------------------------------------------------------------


local oo        = require "oil.oo"
local Exception = require "oil.Exception"                                       --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.kernel.base.Receiver", oo.class)

context = false

--------------------------------------------------------------------------------

function setup(self, channelinfo)
	return self.context.listener:default(channelinfo)
end

function hasrequest(self, channelinfo)
	return self.context.listener:getchannel(channelinfo, true)
end

function acceptone(self, channelinfo)                                           --[[VERBOSE]] verbose:acceptor(true, "accept one request from channel ",channelinfo)
	local context = self.context
	local listener = context.listener
	local result, except
	result, except = listener:getchannel(channelinfo)
	if result then
		local channel = result
		result, except = listener:getrequest(channel, true)
		channel:release()
		if result then                                                              --[[VERBOSE]] verbose:acceptor(true, "dispatching request from accepted channel")
			local dispatcher = context.dispatcher
			result, except = listener:sendreply(channel, result,
				dispatcher:dispatch(result.object_key,
				                    result.operation,
				                    result.opimpl,
				                    result:params())
			)                                                                         --[[VERBOSE]] verbose:acceptor(false)
		end
	end
	if except and except.reason == "closed" then
		result, except = false, nil
	end                                                                           --[[VERBOSE]] verbose:acceptor(false)
	return result, except
end

function acceptall(self, channelinfo)                                           --[[VERBOSE]] verbose:acceptor(true, "accept all requests from channel ",channelinfo)
	local context = self.context
	local listener = context.listener
	local result, except
	self[channelinfo] = true
	repeat
		result, except = listener:getchannel(channelinfo)
		if result then
			local channel = result
			result, except = listener:getrequest(channel)
			channel:release()
			if result then                                                            --[[VERBOSE]] verbose:acceptor "dispatching request from accepted channel"
				local dispatcher = context.dispatcher
				result, except = listener:sendreply(channel, result,
					dispatcher:dispatch(result.object_key,
					                    result.operation,
					                    result.opimpl,
					                    result:params())
				)
			end
		end
		if not self[channelinfo] then
			if not result and except.reason == "closed" then
				result, except = true, nil
			end
			break
		end
	until not result and except.reason ~= "closed"                                --[[VERBOSE]] verbose:acceptor(false)
	return result, except
end

function halt(self, channelinfo)                                                --[[VERBOSE]] verbose:acceptor "halt acceptor"
	if self[channelinfo] then
		self[channelinfo] = nil
		return self.context.listener:disposechannels(channelinfo)
	else
		return nil, Exception{
			reason = "halt",
			message = "channels not being accepted",
			channels = channelinfo,
		}
	end
end
