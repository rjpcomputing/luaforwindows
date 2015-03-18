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
-- channels:Facet
-- 	channel:object retieve(configs:table)
-- 	channel:object select(channel|configs...)
-- 	configs:table default(configs:table)
-- 
-- sockets:Receptacle
-- 	socket:object tcp()
-- 	input:table, output:table select([input:table], [output:table], [timeout:number])
--------------------------------------------------------------------------------

local pairs   = pairs
local require = require

local table        = require "loop.table"
local StringStream = require "loop.serial.StringStream"

local oo = require "oil.oo"                                                     --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.ludo.Codec", oo.class)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local WeakKey    = oo.class{ __mode = "k" }
local WeakValues = oo.class{ __mode = "v" }

function __init(self, ...)
	self = oo.rawnew(self, ...)
	self.names = WeakKey(self.names)
	self.values = WeakValues(self.values)
	return self
end

function localresources(self, resources)
	local names = self.names
	local values = self.values
	for name, resource in pairs(resources) do
		names[resource] = name
		values[name] = resource
	end
end

function encoder(self)
	return StringStream(table.copy(self.names))
end

function decoder(self, stream)
	return StringStream{
		environment = table.copy(self.values),
		data = stream,
	}
end
