require "oil"

local orb = oil.init()
orb:loadidl("interface MyObject { void shutdown(); };")

oil.main(function()
	oil.newthread(orb.run, orb)
	local obj = {shutdown = function() orb:shutdown() end}
	local prx = orb:newproxy(orb:tostring(orb:newservant(obj, nil, "MyObject")))
	assert(prx:_is_a("IDL:MyObject:1.0"), "Oops, wrong interface")
	prx:shutdown()
	print("OK")
end)
