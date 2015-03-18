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
-- Release: 0.4 alpha                                                         --
-- Title  : Client-side CORBA GIOP Protocol                                   --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local select = select
local unpack = unpack

local oo   = require "oil.oo"
local giop = require "oil.corba.giop"                                           --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.interceptors.ClientSide", oo.class)

--------------------------------------------------------------------------------

local RequestID = giop.RequestID
local ReplyID   = giop.ReplyID

--------------------------------------------------------------------------------

CanceledRequest = oo.class()

function CanceledRequest:ready()
	return true
end

function CanceledRequest:results()
	return self.success, unpack(self, 1, self.resultcount)
end

function before(self, request, object, ...)
	if request.port == "requests" then
		if request.method == request.object.newrequest then
			local interceptor = self.interceptor
			if interceptor.sendrequest then
				local channel, reference, operation = ...
				request.service_context      = nil
				request.object_key           = reference._object
				request.interface            = operation.defined_in
				request.operation            = operation.name
				request.response_expected    = not operation.oneway
				request.requesting_principal = nil
				request.count = select("#", ...) - 3
				for i = 1, request.count do
					request[i] = select(i+3, ...)
				end
				interceptor:sendrequest(request)
				if request.success == nil then
					self.message = request
					request.cancel = nil
					return object, channel, reference, operation, unpack(request, 1, request.count)
				else
					self.message = nil
					request.cancel = true
					request.resultcount = request.count
					return CanceledRequest(request)
				end
			else
				self.message = nil
			end
		end
	elseif request.port == "messenger" then
		if request.method == request.object.sendmsg then
			local type, header = select(2, ...)
			if type == RequestID and self.message then
				local message = self.message
				if message.service_context then
					header.service_context = message.service_context
				end
				if message.requesting_principal then
					header.requesting_principal = message.requesting_principal
				end
				self.message = nil
			end
		end
	end
	return object, ...
end

function after(self, request, ...)
	if request.port == "messenger" then
		if request.method == request.object.receivemsg then
			local type, message = ...
			if type == ReplyID then
				if self.interceptor.receivereply then
					self.message = message
				else
					self.message = nil
				end
			end
		end
	elseif request.port == "requests" then
		if request.method == request.object.newrequest then
			local futurereply = ...
			if futurereply then
				futurereply.message = request
			end
		elseif request.method == request.object.getreply then
			local interceptor = self.interceptor
			if interceptor.receivereply then
				local header, reply = self.message, ...
				if header and reply then
					local message = reply.message
					self.message = nil
					message.service_context = header.service_context
					message.request_id      = header.request_id
					message.reply_status    = header.reply_status
					message.success         = reply.success
					message.count           = reply.resultcount
					for i = 1, message.count do
						message[i] = reply[i]
					end
					interceptor:receivereply(message)
					reply.success = message.success
					reply.resultcount = message.count
					for i = 1, message.count do
						reply[i] = message[i]
					end
					return reply
				end
			end
		end
	end
	return ...
end
