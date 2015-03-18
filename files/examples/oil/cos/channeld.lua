#!/usr/bin/env lua
--------------------------------------------------------------------------------
-- @script  OiL Event Channel Daemon
-- @version 1.1
-- @author  Renato Maia <maia@tecgraf.puc-rio.br>
--
print("OiL Event Channel 1.1  Copyright (C) 2006-2008 Tecgraf, PUC-Rio")

local select = select
local io     = require "io"
local os     = require "os"
local oil    = require "oil"
local event  = require "oil.corba.services.event"

module("oil.corba.services.channeld", require "loop.compiler.Arguments")
_optpat = "^%-%-(%w+)(=?)(.-)$"
_alias = { maxqueue = "oil.cos.event.max_queue_length" }
verb = 0
port = 0
ior  = ""
ir = ""
ns = ""
name = ""
function log(optlist, optname, optvalue)
	local file, errmsg = io.open(optvalue, "w")
	if file
		then oil.verbose:output(file)
		else return errmsg
	end
end
_M[_alias.maxqueue] = 0

local argidx, errmsg = _M(...)
if not argidx or argidx <= select("#", ...) then
	if errmsg then io.stderr:write("ERROR: ", errmsg, "\n") end
	io.stderr:write([[
Usage:	channeld.lua [options]
Options:
	--verb <level>
	--log <file>
	--ior <file>
	--port <number>
	--maxqueue <number>
	--ir <objref>
	--ns <objref>
	--name <name>

]])
	os.exit(1)
end

oil.main(function()
	oil.verbose:level(verb)
	local orb = (port > 0) and oil.init{port=port} or oil.init()
	
	if ir ~= ""
		then orb:setIR(orb:narrow(orb:newproxy(ir)))
		else orb:loadidlfile("CosEvent.idl")
	end
	
	local channel = orb:newservant(event.new(_M))
	if ior ~= "" then oil.writeto(ior, orb:tostring(channel)) end
	
	if name ~= "" then
		if ns ~= ""
			then ns = orb:narrow(orb:newproxy(ns))
			else ns = orb:narrow(orb:newproxy("corbaloc::/NameService"))
		end
		if ns then ns:rebind({{id=name,kind="EventChannel"}}, channel) end
	end
	
	orb:run()
end)
