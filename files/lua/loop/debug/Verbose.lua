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
-- Title  : Verbose/Log Mechanism for Layered Applications                    --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--[[----------------------------------------------------------------------------

-------------------------------------
LOG = loop.debug.Verbose{
	groups = {
		-- levels
		{"main"},
		{"counter"},
		-- aliases
		all = {"main", "counter"},
	},
}
LOG:flag("all", true)
-------------------------------------
local Counter = loop.base.class{
	value = 0,
	step = 1,
}
function Counter:add()                LOG:counter "Adding step to counter"
	self.value = self.value + self.step
end
-------------------------------------
counter = Counter()                   LOG:main "Counter object created"
steps = 10                            LOG:main(true, "Counting ",steps," steps")
for i=1, steps do counter:add() end   LOG:main(false, "Done! Counter=",counter)
-------------------------------------
--> [main]    Counter object created
--> [main]    Counting 10 steps
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [counter] |  Adding step to counter
--> [main]    Done! Counter={ table: 0x9c3e390
-->           |  value = 10,
-->           }
----------------------------------------------------------------------------]]--

local type         = type
local rawget       = rawget
local setmetatable = setmetatable
local assert       = assert
local ipairs       = ipairs
local tostring     = tostring
local pairs        = pairs
local error        = error
local select       = select

local io        = require "io"
local os        = require "os"
local math      = require "math"
local table     = require "table"
local string    = require "string"
local coroutine = require "coroutine"

local oo          = require "loop.base"
local ObjectCache = require "loop.collection.ObjectCache"
local Viewer      = require "loop.debug.Viewer"

module("loop.debug.Verbose", oo.class)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

flaglength = 8
timelength = 0
viewer = Viewer{ maxdepth = 2 }

function __init(class, verbose)
	verbose = oo.rawnew(class, verbose)
	verbose.flags    = {}
	verbose.tabcount = ObjectCache{ default = 0 }
	verbose.groups   = rawget(verbose, "groups")  or {}
	verbose.custom   = rawget(verbose, "custom")  or {}
	verbose.inspect  = rawget(verbose, "inspect") or {}
	verbose.timed    = rawget(verbose, "timed")   or {}
	return verbose
end

local function dummy() end
function __index(self, field)
	return field and ( _M[field] or self.flags[field] or dummy )
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function write(self, flag, ...)
	local count = select("#", ...)
	if count > 0 then
		local viewer  = self.viewer
		local output  = self.viewer.output
		local timed   = self.timed
		local custom  = self.custom
		local inspect = self.inspect
		
		local flaglength = self.flaglength
		output:write("[", flag, "]")
		output:write(viewer.prefix:sub(#flag + 3, flaglength))
		
		timed = (type(timed) == "table") and timed[flag] or timed
		if timed == true then
			timed = os.date()
			output:write(timed, " - ")
			output:write(viewer.prefix:sub(flaglength + #timed + 4))
		elseif type(timed) == "string" then
			timed = os.date(timed)
			output:write(timed, " ")
			output:write(viewer.prefix:sub(flaglength + #timed + 2))
		else
			output:write(viewer.prefix:sub(flaglength + 1))
		end
		
		custom = custom[flag]
		if custom == nil or custom(self, ...) then
			for i = 1, count do
				local value = select(i, ...)
				if type(value) == "string"
					then output:write(value)
					else viewer:write(value)
				end
			end
		end
	
		inspect = (type(inspect) == "table") and inspect[flag] or inspect
		if inspect == true then
			io.read()
		else
			output:write("\n")
			if type(inspect) == "function" then inspect(self) end
		end
	
		output:flush()
	end
end

local function taggedprint(tag)
	return function (self, start, ...)
		local running = coroutine.running()
		if rawget(self, "current") ~= running then
			self.current = running
			self:updatetabs()
		end
		if start == false then
			self:updatetabs(-1)
			write(self, tag, ...)
		elseif start == true then
			write(self, tag, ...)
			self:updatetabs(1)
		else
			write(self, tag, start, ...)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function updatetabs(self, shift)
	local current = rawget(self, "current")
	local tabcount = self.tabcount
	local viewer = self.viewer
	local tabs = tabcount[current] or tabcount.default
	if shift then
		tabs = math.max(tabs + shift, 0)
		if current
			then tabcount[current] = tabs
			else tabcount.default = tabs
		end
	end
	viewer.prefix = string.rep(" ", self.flaglength + self.timelength)..
	                viewer.indentation:rep(tabs)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function setgroup(self, name, group)
	self.groups[name] = group
end

function newlevel(self, level, group)
	local groups = self.groups
	local count = #groups
	if not group then
		groups[count+1] = level
	elseif level <= count then
		table.insert(groups, level, group)
	else
		self:setlevel(level, group)
	end
end

function setlevel(self, level, group)
	for i = 1, level - 1 do
		if not self.groups[i] then
			self.groups[i] = {}
		end
	end
	self.groups[level] = group
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function flag(self, name, ...)
	local group = self.groups[name]
	if group then
		for _, name in ipairs(group) do
			if not self:flag(name, ...) then return false end
		end
	elseif select("#", ...) > 0 then
		self.flags[name] = (...) and taggedprint(name) or nil
		local timed = self.timed
		local timelen = 0
		local taglen = 5
		for name in pairs(self.flags) do
			local length = (type(timed) == "table") and timed[flag] or timed
			if length == true then
				length = 19 -- length of 'DD/MM/YY HH:mm:ss -'
			elseif type(length) == "string" then
				length = #os.date(length)
			else
				length = 0
			end
			timelen = math.max(timelen, length)
			taglen = math.max(taglen, #name)
		end
		self.flaglength = math.max(taglen + 3, self.flaglength)
		self.timelength = math.max(timelen + 1, self.timelength)
		self:updatetabs()
	else
		return self.flags[name] ~= nil
	end
	return true
end

function level(self, ...)
	if select("#", ...) == 0 then
		for level = 1, #self.groups do
			if not self:flag(level) then return level - 1 end
		end
		return #self.groups
	else
		for level = 1, #self.groups do
			self:flag(level, level <= ...)
		end
	end
end
