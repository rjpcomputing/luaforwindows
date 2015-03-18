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
-- Title  : Timer for Triggering of Events at Regular Rates                   --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local math      = require "math"
local coroutine = require "coroutine"
local oo        = require "loop.base"

module("loop.thread.Timer", oo.class)

function __init(class, self)
	self = oo.rawnew(class, self)
	self.thread = coroutine.create(function() return self:timer() end)
	return self
end

function timer(self)
	local scheduler = self.scheduler
	if self.enabled then
		local rate = self.rate
		local next = scheduler:time() + rate
		self:action()
		local now = scheduler:time()
		if now < next
			then scheduler:suspend(next - now)
			else scheduler:suspend(rate - math.fmod(now - next, rate))
		end
	else
		scheduler:suspend()
	end
	return self:timer()
end

function enable(self)
	if not self.enabled then
		self.enabled = true
		return self.scheduler:register(self.thread)
	end
end

function disable(self)
	self.enabled = nil
end
