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
-- Title  : Server-Side CORBA Interceptor                                     --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local select = select
local unpack = unpack

local oo   = require "oil.oo"
local giop = require "oil.corba.giop"                                           --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.interceptors.ServerSide", oo.class)

--------------------------------------------------------------------------------

local RequestID = giop.RequestID
local ReplyID   = giop.ReplyID

--------------------------------------------------------------------------------

function handleinterception(self, request, object, ...)
	if request.message.cancelled then
		request.cancel = true
		return select(3, ...)
	end
	return object, ...
end

function before(self, request, object, ...)
	if request.port == "messenger" then
		if request.method == request.object.sendmsg then
			local type, header = select(2, ...)
			if type == ReplyID and self.message then
				header.service_context = self.message.service_context or 
				                         header.service_context
				self.message = nil
			end
		end
	elseif request.port == "dispatcher" then
		if request.method == request.object.dispatch then
			local interceptor = self.interceptor
			if interceptor.receiverequest and self.message then
				local key, operation, default = ...
				local message
				message, self.message = self.message, nil
				message.servant = request.object:retrieve(key)
				message.method = message.servant[operation] or default
				message.count = select("#", ...) - 3
				for i = 1, message.count do
					message[i] = select(i+3, ...)
				end
				interceptor:receiverequest(message)
				request.message = message
				if message.success == nil then
					return object, key, operation, default, unpack(message, 1, message.count)
				else
					request.cancel = true
					return message.success, unpack(message, 1, message.count)
				end
			end
		end
	end
	return object, ...
end

function after(self, request, ...)
	if request.port == "messenger" then
		if request.method == request.object.receivemsg then
			local type, message = ...
			if type == RequestID then
				if self.interceptor.receiverequest then
					request.service_context      = message.service_context
					request.request_id           = message.request_id
					request.response_expected    = message.response_expected
					request.object_key           = message.object_key
					request.operation            = message.operation
					request.requesting_principal = message.requesting_principal
					self.message = request
				else
					self.message = nil
				end
			end
		end
	elseif request.port == "dispatcher" then
		if request.method == request.object.dispatch then
			local interceptor = self.interceptor
			if interceptor.sendreply then
				local message = request.message
				message.success = ...
				message.count = select("#", ...) - 1
				for i = 1, message.count do
					message[i] = select(i+1, ...)
				end
				interceptor:sendreply(message)
				self.message = message
				return message.success, unpack(message, 1, message.count)
			end
		end
	end
	return ...
end
