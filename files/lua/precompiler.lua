#!/usr/bin/env lua
--------------------------------------------------------------------------------
-- @script  Lua Script Pre-Compiler
-- @version 1.1
-- @author  Renato Maia <maia@tecgraf.puc-rio.br>
--

local assert   = assert
local error    = error
local ipairs   = ipairs
local loadfile = loadfile
local pairs    = pairs
local select   = select
local io       = require "io"
local os       = require "os"
local package  = require "package"
local string   = require "string"
local table    = require "table"

module("precompiler", require "loop.compiler.Arguments")

local FILE_SEP = "/"
local FUNC_SEP = "_"
local PATH_SEP = ";"
local PATH_MARK = "?"

help      = false
bytecodes = false
names     = false
luapath   = package.path
output    = "precompiled"
prefix    = "LUAOPEN_API"
directory = ""

_optpat = "^%-(%-?%w+)(=?)(.-)$"
_alias = { ["-help"] = "help" }
for name in pairs(_M) do
	_alias[name:sub(1, 1)] = name
end

local start, errmsg = _M(...)
if not start or help then
	if errmsg then io.stderr:write("ERROR: ", errmsg, "\n") end
	io.stderr:write([[
Lua Script Pre-Compiler 1.1  Copyright (C) 2006-2008 Tecgraf, PUC-Rio
Usage: ]],_NAME,[[.lua [options] [inputs]
  
  [inputs] is a sequence of names that may be file paths or package names, use
  the options described below to indicate how they should be interpreted. If no
  [inputs] is provided then such names are read from the standard input.
  
Options:
  
  -b, -bytecodes  Flag that indicates the provided [inputs] are files containing
                  bytecodes (e.g. instead of source code), like the output of
                  the 'luac' compiler. When this flag is used no compilation is
                  performed by this script.
  
  -d, -directory  Directory where the output files should be generated. Its
                  default is the current directory.
  
  -l, -luapath    Sequence os path templates used to infer package names from
                  file paths and vice versa. These templates follows the same
                  format of the 'package.path' field of Lua. Its default is the
                  value of 'package.path' that currently is set to:
                  "]],luapath,[["
  
  -n, -names      Flag that indicates provided input names are actually package
                  names and the real file path should be inferred from
                  the path defined by -luapath option. This flag can be used in
                  conjunction with the -bytecodes flag to indicate that inferred
                  file paths contains bytecodes instead of source code.
  
  -o, -output     Name used to form the name of the files generated. Two files
                  are generated: a source code file with the sufix '.c' with
                  the pre-compiled scripts and a header file with the sufix
                  '.h' with function signatures. Its default is ']],output,[['.
  
  -p, -prefix     Prefix added to the signature of the functions generated.
                  Its default is ']],prefix,[['.
  
]])
	os.exit(1)
end

--------------------------------------------------------------------------------

local function escapepattern(pattern)
	return pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

local filesep  = escapepattern(FILE_SEP)
local pathsep  = escapepattern(PATH_SEP)
local pathmark = escapepattern(PATH_MARK)

local function adjustpath(path)
	if path ~= "" and not path:find(filesep.."$") then
		return path..FILE_SEP
	end
	return path
end

local filepath = adjustpath(directory)..output

--------------------------------------------------------------------------------

local function readinput(file, name)
	if bytecodes then
		file = assert(io.open(file))
		file = file:read("*a"), file:close()
	else
		file = string.dump(assert(loadfile(file)))
	end
	return file
end

local template = "[^"..pathsep.."]+"
local function getbytecodes(name)
	if names then
		local file = name:gsub("%.", FILE_SEP)
		local err = {}
		for path in luapath:gmatch(template) do
			path = path:gsub(pathmark, file)
			local file = io.open(path)
			if file then
				file:close()
				return readinput(path)
			end
			table.insert(err, string.format("\tno file '%s'", path))
		end
		err = table.concat(err, "\n")
		error(string.format("module '%s' not found:\n%s", name, err))
	end
	return readinput(name)
end

local function allequals(...)
	local name = ...
	for i = 2, select("#", ...) do
		if name ~= select(i, ...) then return nil end
	end
	return name
end

local function funcname(name)
	if not names then
		local result
		for path in luapath:gmatch(template) do
			path = path:gsub(pathmark, "\0")
			path = escapepattern(path)
			path = path:gsub("%z", "(.-)")
			path = string.format("^%s$", path)
			result = allequals(name:match(path)) or result
		end
		if not result then
			return nil, "unable to figure package name for file '"..name.."'"
		end
		return result:gsub(filesep, FUNC_SEP)
	end
	return name:gsub("%.", FUNC_SEP)
end

--------------------------------------------------------------------------------

local inputs = { select(start, ...) }
if #inputs == 0 then
	for name in io.stdin:lines() do
		inputs[#inputs+1] = name
	end
end

local outc = assert(io.open(filepath..".c", "w"))
local outh = assert(io.open(filepath..".h", "w"))

local guard = output:upper():gsub("[^%w]", "_")

outh:write([[
#ifndef __]],guard,[[__
#define __]],guard,[[__

#include <lua.h>

#ifndef ]],prefix,[[ 
#define ]],prefix,[[ 
#endif

]])

outc:write([[
#include <lua.h>
#include <lauxlib.h>
#include "]],output,[[.h"

]])

for i, input in ipairs(inputs) do
	local bytecodes = getbytecodes(input)
	outc:write("static const unsigned char B",i,"[]={\n")
	for j = 1, #bytecodes do
		outc:write(string.format("%3u,", bytecodes:byte(j)))
		if j % 20 == 0 then outc:write("\n") end
	end
	outc:write("\n};\n\n")
end

for i, input in ipairs(inputs) do
	local func = assert(funcname(input))
	outh:write(prefix," int luaopen_",func,"(lua_State *L);\n")
	outc:write(
prefix,[[ int luaopen_]],func,[[(lua_State *L) {
	int arg = lua_gettop(L);
	luaL_loadbuffer(L,(const char*)B]],i,[[,sizeof(B]],i,[[),"]],input,[[");
	lua_insert(L,1);
	lua_call(L,arg,1);
	return 1;
}
]])
end

outh:write([[

#endif /* __]],guard,[[__ */
]])

outh:close()
outc:close()
