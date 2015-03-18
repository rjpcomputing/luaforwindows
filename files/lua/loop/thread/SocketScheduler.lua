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
-- Title  : Cooperative Threads Scheduler with Integrated Socket API          --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local getmetatable = getmetatable
local luasocket    = require "socket.core"
local oo           = require "loop.simple"
local IOScheduler  = require "loop.thread.IOScheduler"
local CoSocket     = require "loop.thread.CoSocket"

module "loop.thread.SocketScheduler"

oo.class(_M, IOScheduler)

--------------------------------------------------------------------------------
-- Initialization Code ---------------------------------------------------------
--------------------------------------------------------------------------------

function __init(class, self)
	self = IOScheduler.__init(class, self)
	self.sockets = CoSocket({ socketapi = luasocket }, self)
	return self
end
__init(getmetatable(_M), _M)

--------------------------------------------------------------------------------
-- Customizable Behavior -------------------------------------------------------
--------------------------------------------------------------------------------

time   = luasocket.gettime
select = luasocket.select
sleep  = luasocket.sleep

--------------------------------------------------------------------------------
-- Component Version -----------------------------------------------------------
--[[----------------------------------------------------------------------------

SchedulerType = component.Type{
	control = component.Facet,
	threads = component.Facet,
}

SocketSchedulerType = component.Type{ SchedulerType,
	sockets = component.Facet,
}

SocketScheduler = SchedulerType{ IOScheduler,
	socket = CoSocket,
}

scheduler = SocketScheduler{
	time   = luasocket.gettime,
	select = luasocket.select,
	sleep  = luasocket.sleep,
	socket = { socketapi = luasocket }
}

subscheduler = SocketScheduler{
	time   = function(...) return scheduler.threads:time(...) end,
	select = function(...) return scheduler.sockets:select(...) end,
	sleep  = function(...) return scheduler.threads:sleep(...) end,
	socket = { socketapi = scheduler.sockets }
}

subscheduler.threads:register(coroutine.create(function()
	local s = assert(scheduler.sockets:bind("localhost", 8080))
	local c = assert(s:accept())
	print("Got:", c:receive("*a"))
end))

scheduler.threads:register(coroutine.create(function()
	return subscheduler.control:run()
end))

scheduler.control:run()

----------------------------------------------------------------------------]]--