--
-- OBJECTS.LUA
--
-- Tests that objects (metatables) can be passed between lanes.
--

require "lanes"

local linda= lanes.linda()

local start_lane= lanes.gen( "io", 
    function( obj1 )

        assert( obj1.v )
        assert( obj1.print )

        assert( obj1 )
        local mt1= getmetatable(obj1)
        assert(mt1)
    
        local obj2= linda:receive("")
        assert( obj2 )
        local mt2= getmetatable(obj2)
        assert(mt2)
        assert( mt1==mt2 )
        
        local v= obj1:print()
        assert( v=="aaa" )
    
        v= obj2:print()    
        assert( v=="bbb" )
    
        return true
    end
)


local WR= function(str)
    io.stderr:write( tostring(str).."\n")
end


-- Lanes identifies metatables and copies them only once per each lane.
--
-- Having methods in the metatable will make passing objects lighter than
-- having the methods 'fixed' in the object tables themselves.
--
local o_mt= {
    __index= function( me, key )
        if key=="print" then
            return function() WR(me.v); return me.v end
        end
    end
}

local function obj_gen(v)
    local o= { v=v }
    setmetatable( o, o_mt )
    return o
end

local a= obj_gen("aaa")
local b= obj_gen("bbb")

assert( a and b )

local mt_a= getmetatable(a)
local mt_b= getmetatable(b)
assert( mt_a and mt_a==mt_b )

local h= start_lane(a)  -- 1st object as parameter

linda:send( "", b )    -- 2nd object via Linda

assert( h[1]==true )    -- wait for return

