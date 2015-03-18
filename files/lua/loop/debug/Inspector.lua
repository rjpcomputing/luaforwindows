--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Interactive Inspector of Application State                        --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local _G           = _G
local assert       = assert
local error        = error
local getfenv      = getfenv
local ipairs       = ipairs
local load         = load
local loadstring   = loadstring
local next         = next
local pairs        = pairs
local rawget       = rawget
local rawset       = rawset
local select       = select
local setfenv      = setfenv
local setmetatable = setmetatable
local type         = type
local xpcall       = xpcall

local coroutine = require "coroutine"
local debug     = require "debug"
local io        = require "io"
local table     = require "table"

local oo          = require "loop.base"
local Viewer      = require "loop.debug.Viewer"

module("loop.debug.Inspector", oo.class)

active = true
input = io.stdin
viewer = Viewer

local function call(self, op, ...)
	self = self[".thread"]
	if self
		then return op(self, ...)
		else return op(...)
	end
end

local self
local infoflags = "Slnuf"
local Command = {}

function Command.see(...)
	self.viewer:write(...)
	self.viewer.output:write("\n")
end

function Command.loc(which, ...)
	local level = self[".level"]
	if level then
		local index = 1
		local name, value
		repeat
			name, value = call(self, debug.getlocal, level, index)
			if not which and name then
				local viewer = self.viewer
				local output = viewer.output
				output:write(name)
				output:write(" = ")
				viewer:write(value)
				output:write("\n")
			elseif name == which then
			if select("#", ...) == 0
				then return value
				else return call(self, debug.setlocal, level, index, (...))
			end
			end
			index = index + 1
		until not name
	end
end

function Command.upv(which, ...)
	local func = self[".current"].func
	local index = 1
	local name, value
	repeat
		name, value = debug.getupvalue(func, index)
		if not which and name then
			local viewer = self.viewer
			local output = viewer.output
			output:write(name," = ")
			viewer:write(value)
			output:write("\n")
		elseif name == which then
			if select("#", ...) == 0
				then return value
				else return debug.setupvalue(func, index, (...))
			end
		end
		index = index + 1
	until not name
end

function Command.env(which, ...)
	local env = getfenv(self[".current"].func)
	if which then
		if select("#", ...) == 0
			then return env[which]
			else env[which] = (...)
		end
	else
		self.viewer:print(env)
	end
end

function Command.lua(which, ...)
	if which then
		if select("#", ...) == 0
			then return _G[which]
			else _G[which] = (...)
		end
	else
		self.viewer:print(_G)
	end
end

function Command.goto(where)
	local kind = type(where)
	if kind == "thread" then
		local status = coroutine.status(where)
		if status ~= "running" and status ~= "suspended" then
			error("unable to inspect an inactive thread")
		end
	elseif kind ~= "function" then
		error("invalid inspection value, got `"..kind.."' (`function' or `thread' expected)")
	end

	if self[".level"] then
		rawset(self, #self+1, self[".level"])
		rawset(self, #self+1, self[".thread"])
	else
		rawset(self, #self+1, self[".current"].func)
	end
	if kind == "thread" then
		self[".level"] = 1
		self[".thread"] = where
		self[".current"] = call(self, debug.getinfo, self[".level"], infoflags)
	else
		self[".level"] = false
		self[".thread"] = false
		self[".current"] = call(self, debug.getinfo, where, infoflags)
	end
end

function Command.goup()
	local level = self[".level"]
	if level then
		local next = call(self, debug.getinfo, level + 1, infoflags)
		if next then
			rawset(self, #self+1, -1)
			self[".level"] = level + 1
			self[".current"] = next
		else
			error("top level reached")
		end
	else
		error("unable to go up in inactive functions")
	end
end

function Command.back()
	if #self > 0 then
		local kind = type(self[#self])
		if kind == "number" then
			self[".level"] = self[".level"] + self[#self]
			self[".current"] = call(self, debug.getinfo, self[".level"], infoflags)
			self[#self] = nil
		elseif kind == "function" then
			self[".level"] = false
			self[".thread"] = false
			self[".current"] = call(self, debug.getinfo, self[#self], infoflags)
			self[#self] = nil
		else
			self[".thread"] = self[#self]
			self[#self] = nil
			self[".level"] = self[#self]
			self[#self] = nil
			self[".current"] = call(self, debug.getinfo, self[".level"], infoflags)
		end
	else
		error("no more backs avaliable")
	end
end

function Command.hist()
	local index = #self
	while self[index] ~= nil do
		local kind = type(self[index])
		if kind == "number" then
			self.viewer:print("  up one level")
			index = index - 1
		elseif kind == "function" then
			self.viewer:print("  left inactive ",self[index])
			index = index - 1
		else
			self.viewer:print("  left ",self[index] or "main thread"," at level ",self[index-1])
			index = index - 2
		end
	end
end

function Command.curr()
	local viewer = self.viewer
	local level  = self[".level"]
	if level then
		local thread = self[".thread"]
		if thread
			then viewer:write(thread)
			else viewer.output:write("main thread")
		end
		viewer:print(", level ", call(self, debug.traceback, level, level))
	else
		viewer:print("inactive function ",self[".current"].func)
	end
end

function Command.done()
	while #self > 0 do
		self[#self] = nil
	end
	self[".thread"] = false
	self[".level"] = false
	self[".current"] = false
end

function Command.step(level)
	if level == "in"  then level = -1
	elseif level == "out" then level = 1
	else level = 0 end
	rawset(self, ".hook", level)
	Command.done()
end

function Command.lsbp()
	local breaks = {}
	for line, files in pairs(self.breaks) do
		for file in pairs(files) do
			breaks[#breaks+1] = file..":"..line
		end
	end
	table.sort(breaks)
	for _, bp in ipairs(breaks) do
		self.viewer:print(bp)
	end
end

function Command.mkbp(file, line)
	assert(type(file) == "string", "usage: mkbp(<file>, <line>)")
	assert(type(line) == "number", "usage: mkbp(<file>, <line>)")
	self.breaks[line][file] = true
end

function Command.rmbp(file, line)
	assert(type(file) == "string", "usage: rmbp(<file>, <line>)")
	assert(type(line) == "number", "usage: rmbp(<file>, <line>)")
	local files = rawget(self.breaks, line)
	if files then
		files[file] = nil
		if next(files) == nil then
			self.breaks[line] = nil
		end
	end
end

--------------------------------------------------------------------------------

local BreaksListMeta = {
	__index = function(self, line)
		local files = {}
		rawset(self, line, files)
		return files
	end,
}
function __init(self, object)
	self = oo.rawnew(self, object)
	
	self.breaks = setmetatable(self.breaks or {}, BreaksListMeta)
	
	function self.breakhook(event, line)
		local level = rawget(self, "break.level")
		if event == "line" then
			-- check for break points
			local files = rawget(self.breaks, line)
			if files then
				local source = debug.getinfo(2, "S").source
				for file in pairs(files) do
					if source:find(file, #source - #file + 1, true) then
						level = 0
						break
					end
				end
			end
			if level == nil or level > 0 then return end
			self:console(2)
			level = rawget(self, ".hook")
			rawset(self, ".hook", nil)
			if level == nil then self:restorehook() end
		elseif level ~= nil then
			if event == "call" then
				level = level + 1
			else
				level = level - 1
			end
		end
		rawset(self, "break.level", level)
		
		local hookbak = rawget(self, "hook.bak")
		if hookbak then
			return hookbak(event, line)
		end
	end
	
	return self
end

function __index(inspector, field)
	if rawget(_M, field) ~= nil then
		return rawget(_M, field)
	end
	
	if Command[field] then
		self = inspector
		return Command[field]
	end

	local name, value
	
	local func = rawget(inspector, ".level")
	if func then
		local index = 1
		repeat
			name, value = call(inspector, debug.getlocal, func, index)
			if name == field
				then return value
				else index = index + 1
			end
		until not name
	end
	
	local func = rawget(inspector, ".current")
	if func then
		func = func.func
		local index = 1
		repeat
			name, value = debug.getupvalue(func, index)
			if name == field
				then return value
				else index = index + 1
			end
		until not name
		
		value = getfenv(func)[field]
		if value ~= nil then return value end
		
		return _G[field]
	end
end

function __newindex(inspector, field, value)
	if rawget(_M, field) == nil then
		local name
		local index
		local func = inspector[".level"]
		if func then
			index = 1
			repeat
				name = call(inspector, debug.getlocal, func, index)
				if name == field
					then return call(inspector, debug.setlocal, func, index, value)
					else index = index + 1
				end
			until not name
		end
	
		func = inspector[".current"]
		if func then
			func = func.func
			index = 1
			repeat
				name = debug.getupvalue(func, index)
				if name == field
					then return debug.setupvalue(func, index, value)
					else index = index + 1
				end
			until not name
			
			getfenv(func)[field] = value
			return
		end
	end
	rawset(inspector, field, value)
end

local function results(self, success, ...)
	if not success then
		io.stderr:write(..., "\n")
	elseif select("#", ...) > 0 then
		self.viewer:write(...)
		self.viewer.output:write("\n")
	end
end
function console(self, level)
	if self.active then
		assert(not rawget(self, ".current"),
			"cannot invoke inspector operation from the console")
		level = level or 1
		rawset(self, ".thread", coroutine.running() or false)
		rawset(self, ".current", call(self, debug.getinfo, level + 2, infoflags)) -- call, stop
		rawset(self, ".level", level + 5) -- call, command, <inspection>, xpcall, stop
		local viewer = self.viewer
		local input = self.input
		local cmd, errmsg
		repeat
			local info = self[".current"]
			viewer.output:write(
				info.short_src or info.what,
				":",
				(info.currentline ~= -1 and info.currentline) or
				(info.linedefined ~= -1 and info.linedefined) or "?",
				" ",
				info.namewhat,
				info.namewhat == "" and "" or " ",
				info.name or viewer:tostring(info.func),
				"> "
			)
			cmd = assert(input:read())
			local short = cmd:match("^%s*([%a_][%w_]*)%s*$")
			if short and Command[short]
				then cmd = short.."()"
				else cmd = cmd:gsub("^%s*=", "return ")
			end
			cmd, errmsg = loadstring(cmd, "inspection")
			if cmd then
				setfenv(cmd, self)
				results(self, xpcall(cmd, debug.traceback))
			else
				viewer.output:write(errmsg, "\n")
			end
		until not rawget(self, ".current")
	end
end

--------------------------------------------------------------------------------

function restorehook(self)
	if next(self.breaks) == nil then
		debug.sethook(
			rawget(self, "hook.bak") or nil,
			rawget(self, "mask.bak"),
			rawget(self, "count.bak")
		)
		rawset(self, "hook.bak", nil)
		rawset(self, "mask.bak", nil)
		rawset(self, "count.bak", nil)
		rawset(self, "break.level", nil)
	end
end

function setuphook(self)
	if rawget(self, "hook.bak") ~= self.breakhook then
		local hook, mask, count = debug.gethook()
		rawset(self, "hook.bak", hook or false)
		rawset(self, "mask.bak", mask)
		rawset(self, "count.bak", count)
		debug.sethook(self.breakhook, "crl", count)
	end
end

function stop(self, level)
	rawset(self, "break.level", level and level+2 or 3)
	self:setuphook()
end

function setbreak(self, file, line)
	self.breaks[line][file] = true
	self:setuphook()
end

function removebreak(self, file, line)
	local files = rawget(self.breaks, line)
	if files then
		files[file] = nil
		if next(files) == nil then
			self.breaks[line] = nil
			if rawget(self, "break.level") == nil then
				self:restorehook()
			end
		end
	end
end

local function ibreaks(self, file, line)
	local files = rawget(self.breaks, line)
	while files do
		file = next(files, file)
		if file then
			return file, line
		end
		line, files = next(self.breaks, line)
	end
end
function allbreaks(self)
	return ibreaks, self, nil, next(self.breaks)
end
