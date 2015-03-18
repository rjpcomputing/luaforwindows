-- functions for turning a format string into a callable function
-- they work by calling parse(), passing it the format string and
-- a table of code generators appropriate for whether we are reading
-- or writing.
-- The resulting code is then prefixed with some setup code and postfixed
-- with a return value and loadstring() is called on it to generate a function
-- Copyright � 2008 Ben "ToxicFrog" Kelly; see COPYING

local require,loadstring,setfenv,type,select,unpack,setmetatable
	= require,loadstring,setfenv,type,select,unpack,setmetatable

local print,assert,error,xpcall,pairs,where
	= print,assert,error,xpcall,pairs,debug.traceback

module((...))

local parse = require(_PACKAGE.."parser")

local function nulsafe_error(s)
	return error(s:gsub('%z', '_'))
end

local function xpcall2(f, err, ...)  
	local args = {n=select('#', ...), ...}  
	return xpcall(function() return f(unpack(args, 1, args.n)) end, err)  
end

local function err_generate(message, format, trace)
	nulsafe_error([[
struct: internal error in code generator
This is an internal error in the struct library
Please report it as a bug and include the following information:
-- error message
]]..message.."\n\n"..[[
-- format string
]]..format.."\n\n"..[[
-- stack trace
]]..trace)
end

local function err_compile(message, format, source)
	nulsafe_error([[
struct: syntax error in emitted lua source
This is an internal error in the struct library
Please report it as a bug and include the following information:
-- loadstring error
]]..message.."\n\n"..[[
-- format string
]]..format.."\n\n"..[[
-- emitted source
]]..source.."\n\n"..[[
-- stack trace
]])
end

local function err_execute(message, format, source, trace)
	nulsafe_error([[
struct: runtime error in generated function
This is at some level an internal error in the struct library
It could be a genuine error in the emitted code (in which case this is a code
generation bug)
Alternately, it could be that you gave it a malformed format string, a bad
file descriptor, or data that does not match the given format (in which case
it is an argument validation bug and you should be getting an error anyways).
Please report this as a bug and include the following information:
-- execution error
]]..message.."\n\n"..[[
-- format string
]]..format.."\n\n"..[[
-- emitted source
]]..source.."\n\n"..[[
-- stack trace
]]..trace)
end

local function compile(format, gen, env)
	local status,source = xpcall(function()
		return parse(format, gen, true)
	end,
	function(message)
		return { message, where("",2) }
	end)

	if not status then
		if type(source[1]) == "function" then
			error(source[1]()..source[2])
		end
		err_generate(source[1], format, source[2])
	end
	
	local fn,err = loadstring(source)
	
	if not fn then
		err_compile(err, format, source)
	end
	
	setfenv(fn, env)
	
	local fn = function(...)
		local status,ret,len = xpcall2(fn, function(message)
			return { message, where("",2) }
		end, ...)
		
		-- call succeeded without errors
		if status then return ret,len end
		
		local message,where = ret[1],ret[2]
		
		-- call generated a deliberate error; call the provided closure
		-- it will either emit an error code or re-throw
		if type(message) == "function" then return nil,message() end
		
		-- call generated an internal error; re-throw with extra debug info
		err_execute(message, format, source, where)
	end
	
	return fn
end

local gen_unpack = require(_PACKAGE.."gen_unpack")
local io_unpack = require(_PACKAGE.."io_unpack")

function _M.unpack(format)
	return compile(format, gen_unpack, io_unpack)
end

local gen_pack = require(_PACKAGE.."gen_pack")
local io_pack = require(_PACKAGE.."io_pack")

function _M.pack(format)
	return compile(format, gen_pack, io_pack)
end

return _M
