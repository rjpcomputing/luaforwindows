local oo     = require "loop.simple"
local socket = require "socket"

math.randomseed(socket.gettime() * 1000)

--------------------------------------------------------------------------------
-- Philosopher Component
--------------------------------------------------------------------------------

Philosopher = oo.class{
	name = "unamed",
	hunger = 0,
	has_left_fork = false,
	has_right_fork = false,
}

function Philosopher:__init(name)
	return oo.rawnew(self, {
		name = name,
		--time = 1.5 + math.random() * 3.6,
	})
end

function Philosopher:sleep()
	--oil.sleep(self.time)
	oil.sleep(1.5 + math.random() * 3.6)
end

function Philosopher:notify()
	local state
	if self.has_left_fork and self.has_right_fork then state = "eating"
	elseif self.hunger < 3 then                        state = "thinking"
	elseif self.hunger < 10 then                       state = "hungry"
	elseif self.hunger < 40 then                       state = "starving"
	else                                               state = "dead"
	end
	self.info:push{
		name = self.name,
		state = state,
		ticks_since_last_meal = self.hunger,
		has_left_fork = self.has_left_fork,
		has_right_fork = self.has_right_fork,
	}
end

function Philosopher:is_hungry()
	return self.hunger > 3
end

function Philosopher:eat_some()
	self.hunger = self.hunger - 3
	if not self:is_hungry() then
		self.hunger = 0
		print(self.name.." has eaten.")
	end
end

function Philosopher:release_forks()
	print(self.name.." droped forks.")
	self.left_fork:release()
	self.right_fork:release()
	self.has_left_fork = false
	self.has_right_fork = false
	return self:notify()
end

function Philosopher:get_more_hungry()
	self.hunger = self.hunger + 1
end

function Philosopher:try_get_fork(fork)
	if (not self["has_"..fork.."_fork"]) and self[fork.."_fork"] then
		self["has_"..fork.."_fork"] = self[fork.."_fork"]:get()
		if self["has_"..fork.."_fork"] then
			print(self.name.." got "..fork.." fork.")
			self:notify()
			return true
		end
	end
end

function Philosopher:update()
	if self.has_left_fork and self.has_right_fork then
		if self:is_hungry()
			then self:eat_some()
			else self:release_forks()
		end
	else
		self:get_more_hungry()
		if self:is_hungry() then
			if self:try_get_fork("left") then return end
			if self:try_get_fork("right") then return end
		end
	end
end

function Philosopher:start()
	if not self.running then
		self.running = true
		return oil.newthread(function()
			while not self.stopped do
				self:update()
				self:sleep()
			end
			self.running = nil
		end)
	end
end

--------------------------------------------------------------------------------
-- Philosopher Home
--------------------------------------------------------------------------------

require "adaptor"

PhilosopherHome = oo.class(nil, Adaptor)

function PhilosopherHome:create(name)
	return Philosopher(name)
end

--------------------------------------------------------------------------------
-- Exporting
--------------------------------------------------------------------------------

require "oil"
oil.main(function()
	local orb = oil.init()
	orb:loadidlfile("philo.idl")
	oil.writeto("philo.ior",
		orb:tostring(
			orb:newservant(PhilosopherHome, nil, "PhilosopherHome")))
	orb:run()
end)