require "oil"                                           -- Load OiL package

oil.main(function()
	local orbCORBA = oil.init()
	local orbLuDO = oil.init{ flavor = "ludo;cooperative;base" }
	
	orbCORBA:loadidlfile("hello.idl")
	
	local hello = { count = 0, quiet = true }             -- Get object implementation
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
	
	helloCORBA = orbCORBA:newservant(hello, nil, "Hello") -- Create CORBA object
	helloLuDO  = orbLuDO:newservant(hello)                -- Create LuDO object
	
	oil.writeto("ref.ior", orbCORBA:tostring(helloCORBA))
	oil.writeto("ref.ludo", orbLuDO:tostring(helloLuDO))
	
	oil.newthread(orbCORBA.run, orbCORBA)
	oil.newthread(orbLuDO.run, orbLuDO)
end)
