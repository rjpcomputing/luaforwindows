#!/usr/bin/env lua
--------------------------------------------------------------------------------
-- @script  Lua Module Pre-Loader
-- @version 1.1
-- @author  Renato Maia <maia@tecgraf.puc-rio.br>
--

local assert = assert
local ipairs = ipairs
local pairs  = pairs
local select = select
local io     = require "io"
local os     = require "os"

module("preloader", require "loop.compiler.Arguments")

local FILE_SEP = "/"
local FUNC_SEP = "_"
local OPEN_PAT = "int%s+luaopen_([%w_]+)%s*%(%s*lua_State%s*%*[%w_]*%);"

help      = false
names     = false
include   = {}
funcname  = ""
output    = "preload"
prefix    = "LUAPRELOAD_API"
directory = ""

_optpat = "^%-(%-?%w+)(=?)(.-)$"
_alias = {
	I = "include",
	["-help"] = "help",
}
for name in pairs(_M) do
	_alias[name:sub(1, 1)] = name
end

local start, errmsg = _M(...)
if not start or help then
	if errmsg then io.stderr:write("ERROR: ", errmsg, "\n") end
	io.stderr:write([[
Lua Module Pre-Loader 1.1  Copyright (C) 2006-2008 Tecgraf, PUC-Rio
Usage: ]],_NAME,[[.lua [options] [inputs]
  
  [inputs] is a sequence of names that may be header file paths or package
  names, use the options described below to indicate how they should be
  interpreted. If no [inputs] is provided then such names are read from the
  standard input.
  
Options:
  
  -d, -directory    Directory where the output files should be generated. Its
                    default is the current directory.
  
  -I, -i, -include  Adds a directory to the list of paths where the header files
                    are searched.
  
  -f, -funcname     Name of the generated function that pre-loads all library
                    modules. Its default is 'luapreload_' plus the name defined
                    by option '-output'.
  
  -n, -names        Flag that indicates provided input names are actually
                    package names and not header files.
  
  -o, -output       Name used to form the name of the files generated. Two files
                    are generated: a source code file with the sufix '.c' with
                    the pre-loading code and a header file with the sufix '.h'
                    with function signatures. Its default is ']],output,[['.
  
  -p, -prefix       Prefix added to the signature of the functions generated.
                    Its default is ']],prefix,[['.
  
]])
	os.exit(1)
end

--------------------------------------------------------------------------------

local function escapepattern(pattern)
	return pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

local filesep  = escapepattern(FILE_SEP)
local funcsep  = escapepattern(FUNC_SEP)

local function adjustpath(path)
	if path ~= "" and not path:find(filesep.."$") then
		return path..FILE_SEP
	end
	return path
end

local filepath = adjustpath(directory)..output

if funcname == "" then funcname = "luapreload_"..output end

--------------------------------------------------------------------------------

local function openheader(name)
	local file, errmsg = io.open(name)
	if not file then
		for _, path in ipairs(include) do
			path = adjustpath(path)..name
			file, errmsg = io.open(path)
			if file then break end
		end
	end
	return file, errmsg
end

--------------------------------------------------------------------------------

local outh = assert(io.open(filepath..".h", "w"))

local guard = output:upper():gsub("[^%w]", "_")

outh:write([[
#ifndef __]],guard,[[__
#define __]],guard,[[__

#ifndef ]],prefix,[[ 
#define ]],prefix,[[ 
#endif

]],prefix,[[ int ]],funcname,[[(lua_State *L);

#endif /* __]],guard,[[__ */
]])
outh:close()

--------------------------------------------------------------------------------

local inputs = { select(start, ...) }
if #inputs == 0 then
	for name in io.stdin:lines() do
		inputs[#inputs+1] = name
	end
end

local outc = assert(io.open(filepath..".c", "w"))
outc:write([[
#include <lua.h>
#include <lauxlib.h>

]])

for i, input in ipairs(inputs) do
	if names then
		outc:write('int luaopen_',input:gsub("%.", FUNC_SEP),'(lua_State*);\n')
	else
		outc:write('#include "',input,'"\n')
	end
end

outc:write([[
#include "]],output,[[.h"

]],prefix,[[ int ]],funcname,[[(lua_State *L) {
	luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", ]], #inputs, [[);
	
]])
local code = [[
	lua_pushcfunction(L, luaopen_%s);
	lua_setfield(L, -2, "%s");
]]
for i, input in ipairs(inputs) do
	if names then
		outc:write(code:format(input:gsub("%.", FUNC_SEP), input))
	else
		local input = assert(openheader(input))
		local header = input:read("*a")
		input:close()
		for func in header:gmatch(OPEN_PAT) do
			outc:write(code:format(func, func:gsub(funcsep, ".")))
		end
	end
end
outc:write([[
	
	lua_pop(L, 1);
	return 0;
}
]])

outc:close()
