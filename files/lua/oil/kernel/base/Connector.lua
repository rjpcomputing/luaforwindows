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
-- Title  : Client-side CORBA GIOP Protocol specific to IIOP                  --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   See section 15.7 of CORBA 3.0 specification.                             --
--   See section 13.6.10.3 of CORBA 3.0 specification for IIOP corbaloc.      --
--------------------------------------------------------------------------------
-- channels:Facet
-- 	channel:object retieve(configs:table, [probe:boolean])
-- 
-- sockets:Receptacle
-- 	socket:object tcp()
-- 	input:table, output:table select([input:table], [output:table], [timeout:number])
--------------------------------------------------------------------------------

local next         = next
local pairs        = pairs
local setmetatable = setmetatable
local type         = type

local ObjectCache = require "loop.collection.ObjectCache"
local Wrapper     = require "loop.object.Wrapper"

local oo = require "oil.oo"                                                     --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.kernel.base.Connector", oo.class)

context = false

--------------------------------------------------------------------------------
-- connection management

local function reset_wrapped_socket(self)                                       --[[VERBOSE]] verbose:channels("resetting channel (attempt to reconnect)")
	self.__object:close()
	local sockets = self.factory.context.sockets
	local result, errmsg = sockets:tcp()
	if result then
		local socket = result
		result, errmsg = socket:connect(self.host, self.port)
		if result then
			self.__object = socket.__object
		end
	end
	return result, errmsg
end

local function reset_plain_socket(self)                                         --[[VERBOSE]] verbose:channels("resetting channel (attempt to reconnect)")
	self.__object:close()
	local sockets = self.factory.context.sockets
	local result, errmsg = sockets:tcp()
	if result then
		local socket = result
		result, errmsg = socket:connect(self.host, self.port)
		if result then
			self.__object = socket
		end
	end
	return result, errmsg
end

local function probe_wrapped_socket(self)
	local list = { self }
	return self.factory.context.sockets:select(list, nil, 0)[1] == list[1]
end

local list = {}
local function probe_plain_socket(self)
	list[1] = self.__object
	return self.factory.context.sockets:select(list, nil, 0)[1] == list[1]
end

local function close_socket(self)
	local ports = self.factory.cache[self.host]
	ports[self.port] = nil
	if next(ports) == nil then
		self.cache[self.host] = nil
	end
	return self.__object:close()
end

--------------------------------------------------------------------------------
-- setup of TCP socket options

function setupsocket(self, socket)
	local options = self.options
	if options then
		for name, value in pairs(options) do
			socket:setoption(name, value)
		end
	end
	return socket
end

--------------------------------------------------------------------------------
-- channel cache for reuse

SocketCache = oo.class{ __index = ObjectCache.__index, __mode = "v" }

function __init(self, object)
	self = oo.rawnew(self, object)
	--
	-- cache of active channels
	-- self.cache[host][port] == <channel to host:port>
	--
	self.cache = ObjectCache()
	function self.cache.retrieve(_, host)
		local cache = SocketCache()
		function cache.retrieve(_, port)
			local socket, errmsg = self.context.sockets:tcp()
			if socket then                                                            --[[VERBOSE]] verbose:channels("new socket to ",host,":",port)
				local success
				success, errmsg = socket:connect(host, port)
				if success then
					if type(socket) ~= "table" then
						socket = Wrapper{
							__object = socket,
							probe = probe_plain_socket,
							reset = reset_plain_socket,
						}
					else
						socket.probe = probe_wrapped_socket
						socket.reset = reset_wrapped_socket
					end
					socket.factory = self
					socket.host    = host
					socket.port    = port
					socket.close   = close_socket
					return self:setupsocket(socket)
				else
					self.except = "connection refused"
				end
			else
				self.except = "too many open connections"
			end
		end
		cache[cache.retrieve] = true -- avoid being collected as unused sockets
		return cache
	end
	return self
end

--------------------------------------------------------------------------------
-- channel factory

function retrieve(self, profile)                                                --[[VERBOSE]] verbose:channels("retrieve channel connected to ",profile.host,":",profile.port)
	local channel = self.cache[profile.host][profile.port]
	if channel then
		return channel
	else
		return nil, self.except
	end	
end
