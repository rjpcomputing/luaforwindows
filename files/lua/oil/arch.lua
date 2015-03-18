local assert       = assert
local getmetatable = getmetatable
local setmetatable = setmetatable
local setfenv      = setfenv                                                    --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.arch"

none = setmetatable({}, { __newindex = function() end })

local Environment = {
	__index = function(self, name)
		return none
	end,
}

function start(comps, level)
	assert(getmetatable(comps) == nil, "component table cannot have a metatable")
	setmetatable(comps, Environment)
	setfenv(1+(level or 1), comps)
	return comps
end

function finish(comps)
	assert(getmetatable(comps) == Environment, "wrong component table")
	setmetatable(comps, nil)
	return comps
end
