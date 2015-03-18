require "oil"
oil.main(function()
	local orb = oil.init{ port = 2809 }
	
	orb:loadidlfile("hello.idl")
	
	local hello = { count = 0, quiet = true }
	function hello:say_hello_to(name)
		self.count = self.count + 1
		local msg = "Hello " .. name .. "! ("..self.count.." times)"
		if not self.quiet then print(msg) end
		return msg
	end
	
	hello = orb:newservant(hello, "MyHello", "Hello")
	
	orb:run()
end)
