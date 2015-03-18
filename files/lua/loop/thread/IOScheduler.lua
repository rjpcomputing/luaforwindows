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
-- Title  : Cooperative Threads Scheduler with Integrated I/O                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

--[[VERBOSE]] local rawget   = rawget
--[[VERBOSE]] local tostring = tostring

local ipairs             = ipairs
local getmetatable       = getmetatable
local math               = require "math"
local oo                 = require "loop.simple"
local MapWithArrayOfKeys = require "loop.collection.MapWithArrayOfKeys"
local Scheduler          = require "loop.thread.Scheduler"

module "loop.thread.IOScheduler"

oo.class(_M, Scheduler)

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

function __init(class, self)
	self = Scheduler.__init(class, self)
	self.reading = MapWithArrayOfKeys()
	self.writing = MapWithArrayOfKeys()
	return self
end
__init(getmetatable(_M), _M)

--------------------------------------------------------------------------------
-- Internal Functions ----------------------------------------------------------
--------------------------------------------------------------------------------

function signalall(self, timeout)                                               --[[VERBOSE]] local verbose = self.verbose
	if timeout then timeout = math.max(timeout - self:time(), 0) end
	local reading, writing = self.reading, self.writing
	if #reading > 0 or #writing > 0 then                                          --[[VERBOSE]] verbose:scheduler(true, "signaling blocked threads for ",timeout," seconds")
		local running = self.running
		local readok, writeok = self.select(reading, writing, timeout)
		local index = 1
		while index <= #reading do
			local channel = reading[index]
			if readok[channel] then                                                   --[[VERBOSE]] verbose:threads("unblocking reading ",reading[channel])
				running:enqueue(reading[channel])
				reading:removeat(index)
			else
				index = index + 1
			end
		end
		index = 1
		while index <= #writing do
			local channel = writing[index]
			if writeok[channel] then                                                  --[[VERBOSE]] verbose:threads("unblocking writing ", writing[channel])
				running:enqueue(writing[channel])
				writing:removeat(index)         
			else
				index = index + 1
			end
		end                                                                         --[[VERBOSE]] verbose:scheduler(false,  "blocked threads signaled")
		return true
	elseif timeout and timeout > 0 then                                           --[[VERBOSE]] verbose:scheduler("no threads blocked, sleeping for ",timeout," seconds")
		self.sleep(timeout)
	end
	return false
end

--------------------------------------------------------------------------------
-- Customizable Behavior -------------------------------------------------------
--------------------------------------------------------------------------------

idle = signalall

--------------------------------------------------------------------------------
-- Exported API ----------------------------------------------------------------
--------------------------------------------------------------------------------

function register(self, routine, previous)
	local reading, writing = self.reading, self.writing
	for _, channel in ipairs(reading) do
		if reading[channel] == routine then return end
	end
	for _, channel in ipairs(writing) do
		if writing[channel] == routine then return end
	end
	return Scheduler.register(self, routine, previous)
end

local function handleremoved(self, routine, removed, ...)
	local reading, writing = self.reading, self.writing
	local index = 1
	while index <= #reading do
		local channel = reading[index]
		if reading[channel] == routine then
			reading:removeat(index)
			removed = routine
		else
			index = index + 1
		end
	end
	index = 1
	while index <= #writing do
		local channel = writing[index]
		if writing[channel] == routine then
			writing:removeat(index)
			removed = routine
		else
			index = index + 1
		end
	end
	return removed, ...
end
function remove(self, routine)
	return handleremoved(self, routine, Scheduler.remove(self, routine))
end

--------------------------------------------------------------------------------
-- Control Functions -----------------------------------------------------------
--------------------------------------------------------------------------------

function step(self, ...)                                                        --[[VERBOSE]] local verbose = self.verbose; verbose:scheduler(true, "performing scheduling step")
	local signaled = self:signalall(0)
	local wokenup = self:wakeupall()
	local resumed = self:resumeall(nil, ...)                                      --[[VERBOSE]] verbose:scheduler(false, "scheduling step performed")
	return signaled or wokenup or resumed
end

--------------------------------------------------------------------------------
-- Verbose Support -------------------------------------------------------------
--------------------------------------------------------------------------------

--[[VERBOSE]] local oldfunc = verbose.custom.threads
--[[VERBOSE]] function verbose.custom:threads(...)
--[[VERBOSE]] 	local viewer  = self.viewer
--[[VERBOSE]] 	local output  = self.viewer.output
--[[VERBOSE]] 	
--[[VERBOSE]] 	oldfunc(self, ...)
--[[VERBOSE]] 	
--[[VERBOSE]] 	local scheduler = rawget(self, "schedulerdetails")
--[[VERBOSE]] 	if scheduler then
--[[VERBOSE]] 		local newline = "\n"..viewer.prefix..viewer.indentation
--[[VERBOSE]] 	
--[[VERBOSE]] 		output:write(newline)
--[[VERBOSE]] 		output:write("Reading:")
--[[VERBOSE]] 		for _, current in ipairs(scheduler.reading) do
--[[VERBOSE]]				current = scheduler.reading[current]
--[[VERBOSE]] 			output:write(" ")
--[[VERBOSE]] 			output:write(tostring(self.labels[current]))
--[[VERBOSE]] 		end
--[[VERBOSE]] 	
--[[VERBOSE]] 		output:write(newline)
--[[VERBOSE]] 		output:write("Writing:")
--[[VERBOSE]] 		for _, current in ipairs(scheduler.writing) do
--[[VERBOSE]]				current = scheduler.writing[current]
--[[VERBOSE]] 			output:write(" ")
--[[VERBOSE]] 			output:write(tostring(self.labels[current]))
--[[VERBOSE]] 		end
--[[VERBOSE]] 	end
--[[VERBOSE]] end
