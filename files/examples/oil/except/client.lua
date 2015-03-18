require "oil"

local function returnexception(proxy, exception, operation)
	if
		operation.name == "read" and
		exception[1] == "IDL:Control/AccessError:1.0"
	then
		return nil, exception.reason
	end
	error(exception)
end

oil.main(function()
	local orb = oil.init()
	local Server
	
	local success, exception = oil.pcall(function()
		Server = orb:newproxy(oil.readfrom("ref.ior"))
		print("Value of 'a_number' is ", Server:read("a_number")._anyval)
		Server:write("a_number", "bad value")
	end)
	if not success then
		if exception[1] == "IDL:Control/AccessError:1.0" 
			then print(string.format("Got error: %s '%s'", exception.reason, exception.tagname))
			else print("Got unkown exception:", exception[1])
		end
	end
	
	orb:setexcatch(returnexception, "Control::Server")
	
	local success, exception = oil.pcall(function()
		local value, errmsg = Server:read("unknown")
		if value
			then print("Value of 'unknown' is ", value._anyval)
			else print("Error on 'unknown' access:", errmsg)
		end
		Server:write("unknown", 1234)
	end)
	if not success then
		if exception[1] == "IDL:Control/AccessError:1.0" 
			then print(string.format("Got error: %s '%s'", exception.reason, exception.tagname))
			else print("Got unkown exception:", exception[1])
		end
	end
end)
