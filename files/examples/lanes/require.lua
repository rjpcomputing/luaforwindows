--
-- REQUIRE.LUA
--
-- Test that 'require' works from sublanes
--
require 'lanes'

local function a_lane()
    -- To require 'math' we still actually need to have it initialized for
    -- the lane.
    --
    require "math"
    assert( math and math.sqrt )
    assert( math.sqrt(4)==2 )

    assert( lanes==nil )
    require "lanes"
    assert( lanes and lanes.gen )

    local h= lanes.gen( function() return 42 end ) ()
    local v= h[1]

    return v==42
end

local gen= lanes.gen( "math,package,string,table", a_lane )

local h= gen()
local ret= h[1]
assert( ret==true )
