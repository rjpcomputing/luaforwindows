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
-- Title  : IIOP Profile Encoder/Decoder                                      --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   See section 15.7 of CORBA 3.0 specification.                             --
--------------------------------------------------------------------------------
-- profiler:Facet
-- 	stream:string encode(profile:table, [version:number])
-- 	profile:table decode(stream:string)
-- 	objkey:string belongsto(profile:string, orbcfg:table)
-- 	result:boolean equivalent(profile1:string, profile2:string)
-- 	profile:table decodeurl(url:string)
-- 
-- codec:Receptacle
-- 	encoder:object encoder([encapsulated:boolean])
-- 	decoder:object decoder(stream:string, [encapsulated:boolean])
--------------------------------------------------------------------------------

local ipairs   = ipairs
local tonumber = tonumber

local string = require "string"

local socket = require "socket.core"

local oo        = require "oil.oo"
local idl       = require "oil.corba.idl"
local Exception = require "oil.corba.giop.Exception"                            --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.iiop.Profiler", oo.class)

context = false

--------------------------------------------------------------------------------
-- IIOP profile structure

local Empty = {}

local Tag = 0

local TaggedComponentSeq = idl.sequence{idl.struct{
	{name = "tag"           , type = idl.ulong   },
	{name = "component_data", type = idl.OctetSeq},
}}

local ProfileBody_v1_ = {
	-- Note: First profile structure field is read/write directly
	[0] = idl.struct{
		--{name = "iiop_version", type = idl.Version },
		{name = "host"        , type = idl.string  },
		{name = "port"        , type = idl.ushort  },
		{name = "object_key"  , type = idl.OctetSeq},
	},
	[1] = idl.struct{
		--{name = "iiop_version", type = idl.Version       },
		{name = "host"        , type = idl.string        },
		{name = "port"        , type = idl.ushort        },
		{name = "object_key"  , type = idl.OctetSeq      },
		{name = "components"  , type = TaggedComponentSeq},
	},
}
ProfileBody_v1_[2] = ProfileBody_v1_[1] -- same as IIOP 1.1
ProfileBody_v1_[3] = ProfileBody_v1_[1] -- same as IIOP 1.1

--------------------------------------------------------------------------------
-- IIOP profile encode/decode

function encode(self, profiles, object_key, config, minor)
	if not minor then minor = 0 end
	local profileidl = ProfileBody_v1_[minor]
	if profileidl then
		local host = config.refhost or config.host
		local port = config.refport or config.port
		if host == "*" then host = socket.dns.gethostname() end
		local hosts, address = socket.dns.toip(host)
		if hosts then
			hosts = address.ip
			hosts[#hosts+1] = address.name
			for _, alias in ipairs(address.alias) do
				hosts[#hosts+1] = alias
			end
		else
			hosts = {host}
		end
		for _, host in ipairs(hosts) do
			local profile = {
				components = Empty,
				host = host,
				port = port,
				object_key = object_key
			}
			local encoder = self.context.codec:encoder(true)
			encoder:struct({major=1, minor=minor}, idl.Version)
			encoder:struct(profile, profileidl)
			profiles[#profiles+1] = {
				tag          = Tag,
				profile_data = encoder:getdata(),
			}
		end
		return true
	else
		return nil, Exception{ "INTERNAL", minor_code_value = 0,
			message = "IIOP minor version not supported",
			reason = "version",
			protocol = "IIOP",
			version = minor,
		}
	end
end

function decode(self, profile)
	local decoder = self.context.codec:decoder(profile, true)
	local version = decoder:struct(idl.Version)
	local profileidl = ProfileBody_v1_[version.minor]

	if version.major ~= 1 or not profileidl then
		return nil, Exception{ "INTERNAL", minor_code_value = 0,
			reason = "version",
			message = "IIOP version not supported",
			protocol = "IIOP",
			version = version,
		}
	end

	profile = decoder:struct(profileidl)
	profile.iiop_version = version -- add read version directly

	return profile, profile.object_key
end

--------------------------------------------------------------------------------
-- IIOP profile and local ORB config match

function belongsto(self, profile, config)
	local objectkey
	profile, objectkey = self:decode(profile)
	local host = config.host
	if host == "*" then host = socket.dns.gethostname() end
	if profile.host == host and profile.port == config.port then
		return objectkey
	end
end

--------------------------------------------------------------------------------
-- IIOP profile are equivalent

function equivalent(self, profile1, profile2)
	local objectkey1, objectkey2
	profile1, objectkey1 = self:decode(profile1)
	profile2, objectkey2 = self:decode(profile2)
	return objectkey1 == objectkey2 and
	       profile1.host == profile2.host and
	       profile1.port == profile2.port
end

--------------------------------------------------------------------------------
-- IIOP corbaloc URL decoder

function decodeurl(self, data)
	local temp, objectkey = string.match(data, "^([^/]*)/(.*)$")
	if temp
		then data = temp
		else objectkey = "" -- TODO:[maia] is this correct?
	end
	local major, minor
	major, minor, temp = string.match(data, "^(%d+).(%d+)@(.+)$")
	if not minor then minor = 0 end
	local profileidl = ProfileBody_v1_[minor]
	if (major and major ~= "1") or (not profileidl) then
		return nil, Exception{ "INTERNAL", minor_code_value = 0,
			message = "IIOP version not supported",
			reason = "version",
			protocol = "IIOP",
			major = major,
			minor = minor,
			version = major.."."..minor
		}
	end
	if temp then data = temp end
	local host, port = string.match(data, "^([^:]+):(%d*)$")
	if port then
		port = tonumber(port)
	else
		port = 2809
		if data == ""
			then host = "*"
			else host = data
		end
	end
	
	temp = self.context.codec:encoder(true)
	temp:struct({major=1,minor=minor}, idl.Version)
	temp:struct({
		components = Empty,
		host = host,
		port = port,
		object_key = objectkey
	}, profileidl)
	return {
		tag = Tag,
		profile_data = temp:getdata(),
	}
end
