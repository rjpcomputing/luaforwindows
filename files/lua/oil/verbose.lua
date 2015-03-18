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
-- Release: 0.4                                                              --
-- Title  : Verbose Support                                                   --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local rawget = rawget
local type   = type
local unpack = unpack

local math   = require "math"
local string = require "string"

local ObjectCache = require "loop.collection.ObjectCache"
local Viewer      = require "loop.debug.Viewer"
local Verbose     = require "loop.debug.Verbose"
local Inspector   = require "loop.debug.Inspector"

module("oil.verbose", Verbose)

viewer = Viewer{
	maxdepth = 1,
	labels = ObjectCache(),
}
function viewer.labels:retrieve(value)
  local type = type(value)
  local id = rawget(self, type) or 0
  self[type] = id + 1
  local label = {}
  repeat
    label[#label + 1] = string.byte("A") + (id % 26)
    id = math.floor(id / 26)
  until id <= 0
  return string.format("%s:%s", type, string.char(unpack(label)))
end

function output(self, output)
	self.viewer.output = output
end

groups.broker = { "acceptor", "dispatcher", "proxies" }
groups.communication = { "mutex", "invoke", "listen", "message", "channels" }
groups.transport = { "marshal", "unmarshal" }
groups.idltypes = { "idl", "repository" }

_M:newlevel{ "broker" }
_M:newlevel{ "invoke", "listen" }
_M:newlevel{ "mutex" }
_M:newlevel{ "message" }
_M:newlevel{ "channels" }
_M:newlevel{ "transport" }
_M:newlevel{ "hexastream" }
_M:newlevel{ "idltypes" }

local pos
local count
function custom:hexastream(rawdata, cursor)
	local viewer = self.viewer
	local output = viewer.output
	local lines = math.ceil(math.log10(#rawdata))
	lines = string.format("%%%dd-%%%dd:", lines, lines)
	count = 0
	pos = cursor
	for char in rawdata:gmatch("(.)") do
		count = count + 1
		column = math.mod(count, 8)
		if column == 1 then
			output:write("\n",viewer.prefix,lines:format(count, count + 7))
		end
		local hexa
		if count == pos
			then hexa = "[%02x]"
			else hexa = " %02x "
		end
		output:write(hexa:format(string.byte(char)))
	end
end

--------------------------------------------------------------------------------

_M:flag("debug", true)
_M:flag("print", true)

I = Inspector{ viewer = viewer }
function inspect:debug() self.I:stop(4) end
