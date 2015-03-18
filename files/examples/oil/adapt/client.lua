if select("#", ...) == 0 then
	io.stderr:write "usage: lua client.lua <time of client 1>, <time of client 2>, ..."
	os.exit(-1)
end
local arg = {...}
--------------------------------------------------------------------------------
require "oil"
oil.main(function()
	local orb = oil.init()
	------------------------------------------------------------------------------
	orb:loadidl [[
		module Adaptation {
			interface Proxy {
				boolean request_work_for(in long seconds);
			};
			interface Adaptor {
				void update_definition(in string definition);
			};
		};
	]]
	------------------------------------------------------------------------------
	local proxy = orb:newproxy(oil.readfrom("proxy.ior"), "IDL:Adaptation/Proxy:1.0")
	local padpt = orb:newproxy(oil.readfrom("proxyadaptor.ior"), "IDL:Adaptation/Adaptor:1.0")
	local sadpt = orb:newproxy(oil.readfrom("serveradaptor.ior"), "IDL:Adaptation/Adaptor:1.0")
	------------------------------------------------------------------------------
	local function showprogress(id, time)
		print(id, "about to request work for "..time.." seconds")
		if proxy:request_work_for(time)
			then print(id, "result received successfully")
			else print(id, "got an unexpected result")
		end
	end
	------------------------------------------------------------------------------
	local maximum = 0
	for id, time in ipairs(arg) do
		time = tonumber(time)
		oil.newthread(showprogress, id, time)
		maximum = math.max(time, maximum)
	end
	------------------------------------------------------------------------------
	local NewServerIDL = [[
		module Adaptation {
			interface Server {
				boolean do_something_for(in double seconds);
			};
		};
	]]

	local NewProxyIDL = [[
		module Adaptation {
			interface Proxy {
				boolean request_work_for(in double seconds);
			};
		};
	]]
	
	oil.sleep(maximum + 1)
	orb:loadidl(NewProxyIDL)
	padpt:update_definition(NewProxyIDL)
	padpt:update_definition(NewServerIDL)
	sadpt:update_definition(NewServerIDL)
	
	for id, time in ipairs(arg) do
		oil.newthread(showprogress, id, tonumber(time))
	end
	------------------------------------------------------------------------------
end)
