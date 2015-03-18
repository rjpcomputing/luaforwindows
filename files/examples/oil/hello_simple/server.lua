require "oil"                                    -- Load OiL package

oil.main(function()
	local hello = { count = 0, quiet = true }      -- Get object implementation
	function hello:say_hello_to(name)
		self.count = self.count + 1
		local msg = "Hello " .. name .. "! ("..self.count.." times)"
		if not self.quiet then print(msg) end
		return msg
	end
	function hello:_get_count()
		return self.count
	end
	function hello:_set_quiet(value)
		self.quiet = value
	end

	local orb = oil.init{ flavor = "ludo;base" }
	
	hello = orb:newservant(hello)                  -- Create Ludo object

	local ref = orb:tostring(hello)                -- Get object's reference
	if not oil.writeto("ref.ludo", ref) then
		print(ref)
	end

	orb:run()                                      -- Start ORB main loop
end)
