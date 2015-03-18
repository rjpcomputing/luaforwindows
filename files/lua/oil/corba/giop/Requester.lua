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
-- Title  : Client-side CORBA GIOP Protocol                                   --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   See chapter 15 of CORBA 3.0 specification.                               --
--------------------------------------------------------------------------------
-- requests:Facet
-- 	channel:object getchannel(reference:table)
-- 	reply:object, [except:table], [requests:table] newrequest(channel:object, reference:table, operation:table, args...)
-- 	reply:object, [except:table], [requests:table] getreply(channel:object, [probe:boolean])
-- 
-- messenger:Receptacle
-- 	success:boolean, [except:table] sendmsg(channel:object, type:number, header:table, idltypes:table, values...)
-- 	type:number, [header:table|except:table], [decoder:object] receivemsg(channel:object)
-- 
-- channels:HashReceptacle
-- 	channel:object retieve(configs:table)
-- 
-- profiler:HashReceptacle
-- 	info:table decode(stream:string)
-- 
-- mutex:Receptacle
-- 	locksend(channel:object)
-- 	freesend(channel:object)
--------------------------------------------------------------------------------

local ipairs   = ipairs
local newproxy = newproxy
local pairs    = pairs
local type     = type
local unpack   = unpack

local oo        = require "oil.oo"
local bit       = require "oil.bit"
local giop      = require "oil.corba.giop"
local Exception = require "oil.corba.giop.Exception"                            --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.giop.Requester", oo.class)

context = false

--------------------------------------------------------------------------------

local IOR                = giop.IOR
local RequestID          = giop.RequestID
local ReplyID            = giop.ReplyID
local LocateRequestID    = giop.LocateRequestID
local LocateReplyID      = giop.LocateReplyID
local CloseConnectionID  = giop.CloseConnectionID
local MessageErrorID     = giop.MessageErrorID
local MessageType        = giop.MessageType
local SystemExceptionIDL = giop.SystemExceptionIDL

local Empty = {}

local ChannelKey = newproxy()

--------------------------------------------------------------------------------
-- request id management for channels

local function register(channel, request)
	local id = #channel + 1
	channel[id] = request
	return id
end

local function unregister(channel, id)
	local request = channel[id]
	channel[id] = nil
	return request
end

--------------------------------------------------------------------------------

function getchannel(self, reference)                                            --[[VERBOSE]] verbose:invoke(true, "get communication channel")
	local channel, except = reference[ChannelKey]
	if not channel then
		for _, profile in ipairs(reference.profiles) do                             --[[VERBOSE]] verbose:invoke("[IOR profile with tag ",profile.tag,"]")
			local tag = profile.tag
			local context = self.context
			local channels = context.channels[tag]
			local profiler = context.profiler[tag]
			if channels and profiler then
				profiler, except = profiler:decode(profile.profile_data)
				if profiler then
					reference._object = except
					channel, except = channels:retrieve(profiler)
					if channel then
						reference[ChannelKey] = channel
					elseif except == "connection refused" then
						except = Exception{ "COMM_FAILURE", minor_code_value = 1,
							reason = "connect",
							message = "connection to profile refused",
							profile = profiler,
						}
					elseif except == "too many open connections" then
						except = Exception{ "NO_RESOURCES", minor_code_value = 0,
							reason = "resources",
							message = "too many open connections by protocol",
							protocol = tag,
						}
					end
				end
				break
	 		end
		end
		if not channel and not except then
		 	except = Exception{ "IMP_LIMIT", minor_code_value = 1,
				message = "no supported GIOP profile found",
				reason = "profiles",
			}
		end
	end                                                                           --[[VERBOSE]] verbose:invoke(false)
	return channel, except
end

--------------------------------------------------------------------------------

local OneWayRequest = {
	service_context      = Empty,
	request_id           = 0, -- value not used
	response_expected    = false,
	object_key           = nil, -- defined later
	operation            = nil, -- defined later
	requesting_principal = Empty,
	resultcount          = 0,
	success              = true,
}

function newrequest(self, channel, reference, operation, ...)
	local request
	if operation.oneway then
		request = OneWayRequest
	else
		request = {
			response_expected    = true,
			service_context      = Empty,
			requesting_principal = Empty,
			inputs               = operation.inputs,
			...,
		}
		request.request_id = register(channel, request)
	end                                                                           --[[VERBOSE]] verbose:invoke(true, "request ",request.request_id," for operation '",operation.name,"'")
	request.object_key = reference._object
	request.operation  = operation.name
	request.opidl      = operation
	local success, except = self.context.messenger:sendmsg(channel,
	                                                       RequestID, request,
	                                                       operation.inputs, ...)
	if not success then
		request = nil
	end	                                                                          --[[VERBOSE]] verbose:invoke(false)
	return request, except, except and channel
end

--------------------------------------------------------------------------------

function reissue(self, channel, request)                                        --[[VERBOSE]] verbose:invoke(true, "reissue request for operation '",request.operation,"'")
	local context = self.context
	local mutex = context.mutex
	if mutex then mutex:locksend(channel) end
	local success, except = context.messenger:sendmsg(channel, RequestID,
	                                                  request, request.inputs,
	                                                  unpack(request, 1,
	                                                         #request.inputs))
	if mutex then mutex:freesend(channel) end                                     --[[VERBOSE]] verbose:invoke(false)
	return success, except, except and channel
end

function getreply(self, channel, probe)                                         --[[VERBOSE]] verbose:invoke(true, "get a reply from communication channel")
	local context = self.context
	if probe and not channel:probe() then
		return true                                                                 --[[VERBOSE]],verbose:invoke(false, "no reply available at the moment")
	end
	local result, except
	local msgid, header, decoder = context.messenger:receivemsg(channel)
	if msgid == ReplyID then
		result = unregister(channel, header.request_id)
		if result then
			local status = header.reply_status
			if status == "LOCATION_FORWARD" then                                      --[[VERBOSE]] verbose:invoke("forwarding request ",header.request_id," through other channel")
				result.success = "forward"
				result[1] = decoder:struct(IOR)
			else
				local operation = result.opidl
				if status == "NO_EXCEPTION" then                                        --[[VERBOSE]] verbose:invoke(true, "got successful reply for request ",header.request_id)
					result.success = true
					result.resultcount = #operation.outputs
					for index, output in ipairs(operation.outputs) do
						result[index] = decoder:get(output)
					end                                                                   --[[VERBOSE]] verbose:invoke(false)
				else
					
					result.success = false
					result.resultcount = 1
					if status == "USER_EXCEPTION" then                                    --[[VERBOSE]] verbose:invoke(true, "got reply with exception for ",header.request_id)
						local repId = decoder:string()
						local exception = operation.exceptions[repId]
						if exception then
							exception = Exception(decoder:except(exception))
							exception[1] = repId
							result[1] = exception
						else
							result[1] = Exception{ "UNKNOWN", minor_code_value = 0,
								message = "unexpected user-defined exception",
								reason = "exception",
								exception = exception,
							}
						end                                                                 --[[VERBOSE]] verbose:invoke(false)
					elseif status == "SYSTEM_EXCEPTION" then                              --[[VERBOSE]] verbose:invoke(true, "got reply with system exception for ",header.request_id)
						-- TODO:[maia] set its type to the proper SystemExcep.
						local exception = decoder:struct(SystemExceptionIDL)
						exception[1] = exception.exception_id
						result[1] = Exception(exception)
					else
						result[1] = Exception{ "INTERNAL", minor_code_value = 0,
							message = "unsupported reply status",
							reason = "replystatus",
							status = status,
						}
					end                                                                   --[[VERBOSE]] verbose:invoke(false)
					
				end
			end
		else
			except = Exception{ "INTERNAL", minor_code_value = 0,
				message = "unexpected request id",
				reason = "requestid",
				id = header.request_id,
			}
		end
	elseif msgid == LocateReplyID then                                            --[[VERBOSE]] verbose:invoke("got object location reply for ",header.request_id)
		result = unregister(channel, header.request_id)
		result.locate_status = header.locate_status
		if result.locate_status == "OBJECT_FORWARD" then
			result.success = "forward"
			result[1] = decoder:struct(IOR)
		end
	elseif (msgid == CloseConnectionID) or
	       (msgid == nil and header.reason == "closed") then                      --[[VERBOSE]] verbose:invoke("got remote request to close channel or channel is broken")
		result, except = channel:reset()
		if result then                                                              --[[VERBOSE]] verbose:invoke(true, "reissue all pending requests")
			for id, request in pairs(channel) do
				if type(id) == "number" then
					result, except = self:reissue(channel, request)
					if not result then break end
				end
			end                                                                       --[[VERBOSE]] verbose:invoke(false)
			if result then                                                            --[[VERBOSE]] verbose:invoke(false, "get a reply from renewed channel")
				return self:getreply(channel, probe)
			end
		elseif except == "connection refused" then
			except = Exception{ "COMM_FAILURE", minor_code_value = 1,
				reason = "connect",
				message = "unable to restablish channel",
				channel = channel,
			}
		elseif except == "too many open connections" then
			except = Exception{ "NO_RESOURCES", minor_code_value = 0,
				reason = "resources",
				message = "unbale to restablish channel, too many open connections",
				channel = channel,
			}
		end
	elseif msgid == MessageErrorID then
		except = Exception{ "COMM_FAILURE", minor_code_value = 0,
			reason = "server",
			message = "error in server message processing",
		}
	elseif MessageType[msgid] then
		except = Exception{ "INTERNAL", minor_code_value = 0,
			reason = "unexpected",
			message = "unexpected GIOP message",
			message = MessageType[msgid],
			id = msgid,
		}
	elseif header.reason == "version" then                                        --[[VERBOSE]] verbose:invoke(true, "got message with wrong version")
		local mutex = context.mutex
		if mutex then mutex:locksend(channel) end
		result, except = context.messenger:sendmsg(channel, MessageErrorID)         --[[VERBOSE]] verbose:invoke "send message error notification"
		if mutex then mutex:freesend(channel) end                                   --[[VERBOSE]] verbose:invoke(false)
		if result then                                                              --[[VERBOSE]] verbose:invoke(false, "get a reply from renewed channel")
			return self:getreply(channel, probe)
		end
	else
		except = header
	end                                                                           --[[VERBOSE]] verbose:invoke(false)
	return result, except, except and channel
end
