require "oil"
oil.main(function()
	local orb = oil.init()
	orb:loadidlfile("philo.idl")
	Adaptor = orb:newproxy(oil.readfrom("philo.ior"))

	print(Adaptor:execute("\n\n\n\n\n\n\n"..[[
		function Philosopher:avoid_deadlock()
			if
				((self.has_left_fork and not self.has_right_fork) or
				 (not self.has_left_fork and self.has_right_fork))
				and math.random(3) == 1
			then
				if self.has_left_fork then
					self.left_fork:release()
					self.has_left_fork = false
					print("Deadlock prevention! "..self.name.." drops the left fork.")
					return self:notify()
				elseif self.has_right_fork then
					self.right_fork:release()
					self.has_right_fork = false
					print("Deadlock prevention! "..self.name.." drops the right fork.")
					return self:notify()
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
					self:avoid_deadlock()
				end
			end
			oil.sleep(math.random(1.5, 5.1))
		end
	]]))
end)