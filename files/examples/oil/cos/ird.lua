#!/usr/bin/env lua
--------------------------------------------------------------------------------
-- @script  OiL Interface Repository Daemon
-- @version 1.2
-- @author  Renato Maia <maia@tecgraf.puc-rio.br>
--
print("OiL Interface Repository 1.2  Copyright (C) 2005-2008 Tecgraf, PUC-Rio")

local ipairs = ipairs
local select = select
local io     = require "io"
local os     = require "os"
local oil    = require "oil"

module("oil.corba.services.ird", require "loop.compiler.Arguments")
_optpat = "^%-%-(%w+)(=?)(.-)$"
verb = 0
port = 0
ior  = ""
function log(optlist, optname, optvalue)
	local file, errmsg = io.open(optvalue, "w")
	if file
		then oil.verbose:output(file)
		else return errmsg
	end
end

local argidx, errmsg = _M(...)
if not argidx then
	io.stderr:write([[
ERROR: ]],errmsg,[[ 
Usage:	ird.lua [options] <idlfiles>
Options:
	--verb <level>
	--log <file>
	--ior <file>
	--port <number>

]])
	os.exit(1)
end

local files = { select(argidx, ...) }
oil.main(function()
	oil.verbose:level(verb)
	local orb = (port > 0) and oil.init{port=port} or oil.init()
	local ir = orb:getLIR()
	if ior ~= "" then oil.writeto(ior, orb:tostring(ir)) end
	for _, file in ipairs(files) do
		orb:loadidlfile(file)
	end
	orb:run()
end)
