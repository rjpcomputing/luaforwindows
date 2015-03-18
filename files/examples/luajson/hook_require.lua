local os = require("os")
local old_require = require
if os.getenv('LUA_OLD_INIT') then
	assert(loadstring(os.getenv('LUA_OLD_INIT')))()
else
	require("luarocks.require")
end
local luarocks_require = require

function require(module, ...)
	if module == "json" or module:match("^json%.") then
		return old_require(module, ...)
	end
	return luarocks_require(module, ...)
end
