require "oil"

oil.main(function()
	local orb = oil.init()
	
	orb:loadidlfile("hello.idl")

	local hello = orb:newproxy("corbaloc::/MyHello", "Hello")

	local secs = 1
	local dots = 3
	while hello:_non_existent() do
		io.write "Server object is not avaliable yet "
		for i=1, dots do io.write "." socket.sleep(secs/dots) end
		print()
	end

	hello:_set_quiet(false)
	for i = 1, 3 do print(hello:say_hello_to("world")) end
	print("Object already said hello "..hello:_get_count().." times till now.")
end)
