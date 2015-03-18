-----------------------------------------------------------------------------
-- UDP sample: echo protocol server
-- LuaSocket sample files
-- Author: Diego Nehab
-- RCS ID: $Id: echosrvr.lua,v 1.12 2005/11/22 08:33:29 diego Exp $
-----------------------------------------------------------------------------
local socket = require("socket")
host = host or "127.0.0.1"
port = port or 7
if arg then
    host = arg[1] or host
    port = arg[2] or port
end
print("Binding to host '" ..host.. "' and port " ..port.. "...")
udp = assert(socket.udp())
assert(udp:setsockname(host, port))
assert(udp:settimeout(5))
ip, port = udp:getsockname()
assert(ip, port)
print("Waiting packets on " .. ip .. ":" .. port .. "...")
while 1 do
	dgram, ip, port = udp:receivefrom()
	if dgram then
		print("Echoing '" .. dgram .. "' to " .. ip .. ":" .. port)
		udp:sendto(dgram, ip, port)
	else
        print(ip)
    end
end
