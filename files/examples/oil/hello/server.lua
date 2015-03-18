require "oil"                                    -- Load OiL package

oil.main(function()
	local hello = { count = 0, quiet = true }      -- Get object implementation
	function hello:say_hello_to(name)
		self.count = self.count + 1
		local msg = "Hello " .. name .. "! ("..self.count.." times)"
		if not self.quiet then print(msg) end
		return msg
	end
	
	local orb = oil.init()
	
	orb:loadidl [[                                   // Load the interface IDL
		interface Hello {
			attribute boolean quiet;
			readonly attribute long count;
			string say_hello_to(in string name);
		};
	]]
	
	hello = orb:newservant(hello, nil, "Hello")    -- Create CORBA object
	
	local ref = orb:tostring(hello)                -- Get object's reference
	if not oil.writeto("ref.ior", ref) then
		print(ref)
	end

	orb:run()                                      -- Start ORB main loop
end)
