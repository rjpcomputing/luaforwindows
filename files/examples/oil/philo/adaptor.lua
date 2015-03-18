local oo = require "loop.simple"

Adaptor = oo.class()

local errmsg
function Adaptor:execute(code)
	code, errmsg = loadstring(code)
	if code then code, errmsg = pcall(code) end
	return code and "OK" or error
end
