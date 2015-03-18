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
-- Title  : Interoperable Object Reference (IOR) support                      --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   See section 13.6 of CORBA 3.0 specification.                             --
--   See section 13.6.10 of CORBA 3.0 specification for corbaloc.             --
--------------------------------------------------------------------------------
-- references:Facet
-- 	reference:table referenceto(objectkey:string, accesspointinfo:table...)
-- 	reference:string encode(reference:table)
-- 	reference:table decode(reference:string)
-- 
-- codec:Receptacle
-- 	encoder:object encoder()
-- 	decoder:object decoder(stream:string)
-- 
-- profiler:HashReceptacle
-- 	profile:table decodeurl(url:string)
-- 	data:string encode(objectkey:string, acceptorinfo...)
-- 
-- types:Receptacle--[[
-- 	interface:table typeof(objectkey:string)
--------------------------------------------------------------------------------

local select = select
local tonumber  = tonumber

local string = require "string"

local oo        = require "oil.oo"
local giop      = require "oil.corba.giop"
local Exception = require "oil.corba.giop.Exception"                            --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.giop.Referrer", oo.class)

context = false

--------------------------------------------------------------------------------
-- String/byte conversions -----------------------------------------------------

local function byte2hexa(value)
	return (string.gsub(value, '(.)', function (char)
		-- TODO:[maia] check char to byte conversion
		return (string.format("%02x", string.byte(char)))
	end))
end

local function hexa2byte(value)
	local error
	value = (string.gsub(value, '(%x%x)', function (hexa)
		hexa = tonumber(hexa, 16)
		if hexa
			-- TODO:[maia] check byte to char conversion
			then return string.char(hexa)
			else error = true
		end
	end))
	if not error then return value end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function IOR(self, stream)
	local decoder = self.context.codec:decoder(hexa2byte(stream), true)
	return decoder:struct(giop.IOR)
end

function corbaloc(self, encoded)
	for token, data in string.gmatch(encoded, "(%w*):([^,]*)") do
		local profiler = self.context.profiler[token]
		if profiler then
			return {
				type_id = "",
				profiles = { profiler:decodeurl(data) },
			}
		end
	end
	return nil, Exception{ "INV_OBJREF",
		reason = "corbaloc",
		message = "corbaloc, no supported protocol found",
		reference = encoded,
	}
end

--------------------------------------------------------------------------------
-- Coding ----------------------------------------------------------------------

function referenceto(self, objectkey, ...)
	local profiles = {}
	for i = 1, select("#", ...) do
		local acceptor = select(i, ...)
		local tag = acceptor.tag or 0
		local profiler = self.context.profiler[tag]
		if profiler then
			local ok, except = profiler:encode(profiles, objectkey, acceptor)
			if not ok then return nil, except end
		else
			return nil, Exception{ "IMP_LIMIT", minor_code_value = 1,
				message = "GIOP profile tag not supported",
				reason = "profiles",
				tag = tag,
			}
		end
	end
	return {
		type_id = self.context.types:typeof(objectkey).repID,
		profiles = profiles,
	}
end

function encode(self, ior)
	local encoder = self.context.codec:encoder(true)
	encoder:struct(ior, giop.IOR)
	return "IOR:"..byte2hexa(encoder:getdata())
end

function decode(self, encoded)
	local token, stream = encoded:match("^(%w+):(.+)$")
	local decoder = self[token]
	if not decoder then
		return nil, Exception{ "INV_OBJREF",
			reason = "reference",
			message = "illegal reference format, currently not supported",
			format = token,
			reference = enconded,
		}
	end
	return decoder(self, stream)
end
