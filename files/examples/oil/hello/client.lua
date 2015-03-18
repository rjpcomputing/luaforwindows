require "oil"                                           -- Load OiL package

oil.main(function()
	local orb = oil.init()
	
	hello = orb:newproxy(assert(oil.readfrom("ref.ior"))) -- Get proxy to object
	
	hello:_set_quiet(false)                               -- Access the object
	for i = 1, 3 do print(hello:say_hello_to("world")) end
	print("Object already said hello "..hello:_get_count().." times till now.")
end)
