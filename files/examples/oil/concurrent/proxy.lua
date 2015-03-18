require "oil"
oil.main(function()
	local orb = oil.init()
	------------------------------------------------------------------------------
	local server = orb:newproxy(assert(oil.readfrom("server.ior")))
	------------------------------------------------------------------------------
	orb:loadidl [[
		module Concurrency {
			interface Proxy {
				boolean request_work_for(in double seconds);
			};
		};
	]]
	------------------------------------------------------------------------------
	local proxy_impl = { server = server }
	function proxy_impl:request_work_for(seconds)
		return server:do_something_for(seconds)
	end
	------------------------------------------------------------------------------
	local proxy = orb:newservant(proxy_impl, nil, "Concurrency::Proxy")
	------------------------------------------------------------------------------
	assert(oil.writeto("proxy.ior", orb:tostring(proxy)))
	------------------------------------------------------------------------------
	orb:run()
	------------------------------------------------------------------------------
end)
