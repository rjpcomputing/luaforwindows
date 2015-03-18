require "oil"
oil.main(function()
	local orb = oil.init()
	------------------------------------------------------------------------------
	orb:loadidl [[
		module Adaptation {
			interface Server {
				boolean do_something_for(in long seconds);
			};
			interface Adaptor {
				void update_definition(in string definition);
			};
		};
	]]
	------------------------------------------------------------------------------
	local server_impl = {}
	function server_impl:do_something_for(seconds)
		print("about to sleep for "..seconds.." seconds")
		oil.sleep(seconds)
		return true
	end
	local adaptor_impl = {}
	function adaptor_impl:update_definition(definition)
		orb:loadidl(definition)
	end
	------------------------------------------------------------------------------
	local server = orb:newservant(server_impl, nil, "IDL:Adaptation/Server:1.0")
	local adaptor = orb:newservant(adaptor_impl, nil, "IDL:Adaptation/Adaptor:1.0")
	------------------------------------------------------------------------------
	oil.writeto("server.ior", orb:tostring(server))
	oil.writeto("serveradaptor.ior", orb:tostring(adaptor))
	------------------------------------------------------------------------------
	orb:run()
end)
