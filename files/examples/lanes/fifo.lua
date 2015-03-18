--
-- FIFO.LUA
--
-- Sample program for Lua Lanes
--

require "lanes"

local linda= lanes.linda()
local atomic_inc= lanes.genatomic( linda, "FIFO_n" )

assert( atomic_inc()==1 )
assert( atomic_inc()==2 )

local function FIFO()
    local my_channel= "FIFO"..atomic_inc()

    return {
        -- Giving explicit 'nil' timeout allows numbers to be used as 'my_channel'
        --
        send= function(...) linda:send( nil, my_channel, ... ) end,
        receive= function(timeout) linda:receive( timeout, my_channel ) end
    }
end

local A= FIFO()
local B= FIFO()

print "Sending to A.."
A:send( 1,2,3,4,5 )

print "Sending to B.."
B:send( 'a','b','c' )

print "Reading A.."
print( A:receive( 1.0 ) )

print "Reading B.."
print( B:receive( 2.0 ) )

-- Note: A and B can be passed between threads, or used as upvalues
--       by multiple threads (other parts will be copied but the 'linda'
--       handle is shared userdata and will thus point to the single place)
