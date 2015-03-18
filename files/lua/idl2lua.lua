#!/usr/bin/env lua
--------------------------------------------------------------------------------
-- @script  IDL Descriptor Pre-Loader
-- @version 1.0
-- @author  Renato Maia <maia@tecgraf.puc-rio.br>
--

local assert     = assert
local pairs      = pairs
local select     = select
local io         = require "io"
local os         = require "os"
local string     = require "string"
local luaidl     = require "luaidl"
local idl        = require "oil.corba.idl"
local Compiler   = require "oil.corba.idl.Compiler"
local Serializer = require "loop.serial.Serializer"

module("idl2lua", require "loop.compiler.Arguments")

output   = "idl.lua"
instance = "require('oil').init()"

_alias = {}
for name in pairs(_M) do
	_alias[name:sub(1, 1)] = name
end

local start, errmsg = _M(...)
local finish = select("#", ...)
if not start or start ~= finish then
	if errmsg then io.stderr:write("ERROR: ", errmsg, "\n") end
	io.stderr:write([[
IDL Descriptor Pre-Loader 1.0  Copyright (C) 2006-2008 Tecgraf, PUC-Rio
Usage: ]].._NAME..[[.lua [options] <idlfile>
Options:
	
	-o, -output     Output file that should be generated. Its default is
	                ']],output,[['.
	
	-i, -instance   ORB instance the IDL must be loaded to. Its default
	                is ']],instance,[[' that denotes the instance returned
	                by the 'oil' package.
	
]])
	os.exit(1)
end

--------------------------------------------------------------------------------

local file = assert(io.open(output, "w"))

local stream = Serializer()
function stream:write(...)
	return file:write(...)
end

stream[idl]              = "idl"
stream[idl.void]         = "idl.void"
stream[idl.short]        = "idl.short"
stream[idl.long]         = "idl.long"
stream[idl.longlong]     = "idl.longlong"
stream[idl.ushort]       = "idl.ushort"
stream[idl.ulong]        = "idl.ulong"
stream[idl.ulonglong]    = "idl.ulonglong"
stream[idl.float]        = "idl.float"
stream[idl.double]       = "idl.double"
stream[idl.longdouble]   = "idl.longdouble"
stream[idl.boolean]      = "idl.boolean"
stream[idl.char]         = "idl.char"
stream[idl.octet]        = "idl.octet"
stream[idl.any]          = "idl.any"
stream[idl.TypeCode]     = "idl.TypeCode"
stream[idl.string]       = "idl.string"
stream[idl.object]       = "idl.object"
stream[idl.basesof]      = "idl.basesof"
stream[idl.Contents]     = "idl.Contents"
stream[idl.ContainerKey] = "idl.ContainerKey"

file:write(instance,[[.TypeRepository.types:register(
	setfenv(
		function()
			return ]])

stream:serialize(luaidl.parsefile(select(start, ...), Compiler.Options))

file:write([[ 
		end,
		{
			idl = require "oil.corba.idl",
			]],stream.namespace,[[ = require("loop.serial.Serializer")(),
		}
	)()
)
]])
file:close()
