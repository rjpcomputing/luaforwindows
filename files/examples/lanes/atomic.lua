--
-- ATOMIC.LUA
--
-- Test program for Lua Lanes
--

require "lanes"

local linda= lanes.linda()
local key= "$"

local f= lanes.genatomic( linda, key, 5 )

local v
v= f(); print(v); assert(v==6)
v= f(-0.5); print(v); assert(v==5.5)

v= f(-10); print(v); assert(v==-4.5)
