require "oil"                                   -- Load OiL package

oil.main(function()
	local orb = oil.init()
	orb:loadidl [[
		module Concurrency {
			interface Server {
				boolean do_something_for(in double seconds);
			};
		};
	]]
	
	local server_impl = {}
	function server_impl:do_something_for(seconds)
		oil.sleep(seconds)
		return true
	end
	
	local server = orb:newservant(server_impl, nil, "Concurrency::Server")
	
	assert(oil.writeto("server.ior", orb:tostring(server)))
	
	orb:run()
end)
