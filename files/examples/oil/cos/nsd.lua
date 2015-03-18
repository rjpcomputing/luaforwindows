#!/usr/bin/env lua
--------------------------------------------------------------------------------
-- @script  OiL Naming Service Daemon
-- @version 1.1
-- @author  Renato Maia <maia@tecgraf.puc-rio.br>
--
print("OiL Naming Service 1.1  Copyright (C) 2006-2008 Tecgraf, PUC-Rio")

local select = select
local io     = require "io"
local os     = require "os"
local oil    = require "oil"
local naming = require "oil.corba.services.naming"

module("oil.corba.services.nsd", require "loop.compiler.Arguments")
_optpat = "^%-%-(%w+)(=?)(.-)$"
verb = 0
port = 0
ior  = ""
ir = ""
function log(optlist, optname, optvalue)
	local file, errmsg = io.open(optvalue, "w")
	if file
		then oil.verbose:output(file)
		else return errmsg
	end
end

local argidx, errmsg = _M(...)
if not argidx or argidx <= select("#", ...) then
	if errmsg then io.stderr:write("ERROR: ", errmsg, "\n") end
	io.stderr:write([[
Usage:	nsd.lua [options]
Options:
	--verb <level>
	--log <file>
	--ior <file>
	--port <number>
	--ir <objref>

]])
	os.exit(1)
end

oil.main(function()
	oil.verbose:level(verb)
	local orb = (port > 0) and oil.init{port=port} or oil.init()
	if ir ~= ""
		then orb:setIR(orb:narrow(orb:newproxy(ir)))
		else orb:loadidlfile("CosNaming.idl")
	end
	ns = orb:newservant(naming.new())
	if ior ~= "" then oil.writeto(ior, orb:tostring(ns)) end
	orb:run()
end)
