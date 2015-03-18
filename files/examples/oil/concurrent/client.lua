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
	local proxy = orb:newproxy(assert(oil.readfrom("proxy.ior")))
	------------------------------------------------------------------------------
	local function showprogress(id, time)
		print(id, "about to request work for "..time.." seconds")
		if proxy:request_work_for(time)
			then print(id, "result received successfully")
			else print(id, "got an unexpected result")
		end
	end
	------------------------------------------------------------------------------
	for id, time in ipairs(arg) do
		oil.newthread(showprogress, id, tonumber(time))
	end
	------------------------------------------------------------------------------
end)
