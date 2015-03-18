--
-- LAUNCHTEST.LUA       Copyright (c) 2007-08, Asko Kauppi <akauppi@gmail.com>
--
-- Tests launching speed of N threads
--
-- Usage:
--      [time] lua -lstrict launchtest.lua [threads] [-libs[=io,os,math,...]]
--
--      threads: number of threads to launch (like: 2000) :)
--      libs: combination of "os","io","math","package", ...
--            just "-libs" for all libraries
--
-- Note:
--      One _can_ reach the system threading level, ie. doing 10000 on 
--      PowerBook G4:
--      <<
--          pthread_create( ref, &a, lane_main, data ) failed @ line 316: 35 
--          Command terminated abnormally.
--      <<
--
--      (Lua Lanes _can_ be made tolerable to such congestion cases. Just
--       currently, it is not. btw, 5000 seems to run okay - system limit
--       being 2040 simultaneous threads)
--
-- To do:
--      - ...
--

local N= 1000   -- threads/loops to use
local M= 1000   -- sieves from 1..M
local LIBS= nil -- default: load no libraries

local function HELP()
    io.stderr:write( "Usage: lua launchtest.lua [threads] [-libs[=io,os,math,...]]\n" )
    exit(1)
end

local m= require "argtable"
local argtable= assert(m.argtable)

for k,v in pairs( argtable(...) ) do
    if k==1 then            N= tonumber(v) or HELP()
    elseif k=="libs" then   LIBS= (v==true) and "*" or v
    else                    HELP()
    end
end

require "lanes"

local g= lanes.gen( LIBS, function(i) 
                        --io.stderr:write( i.."\t" )
                        return i 
                    end )

local t= {}

for i=1,N do
    t[i]= g(i)
end

if false then
    -- just finish here, without waiting for threads to finish
    --
    local st= t[N].status
    print(st)   -- if that is "done", they flew already! :)
else
    -- mark that all have been launched, now wait for them to return
    --
    io.stderr:write( N.." lanes launched.\n" )
    
    for i=1,N do
        local rc= t[i]:join()
        assert( rc==i )
    end

    io.stderr:write( N.." lanes finished.\n" )
end

