--
-- RECURSIVE.LUA
--
-- Test program for Lua Lanes
--

io.stderr:write( "depth:" )
local function func( depth )
    io.stderr:write(" " .. depth)
    if depth > 10 then
        return "done!"
    end

    require "lanes"
    local lane= lanes.gen("*", func)( depth+1 )
    return lane[1]
end

local v= func(0)
assert(v=="done!")
io.stderr:write("\n")
