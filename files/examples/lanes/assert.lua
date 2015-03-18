--
-- ASSERT.LUA                    Copyright (c) 2006-07, <akauppi@gmail.com>
--
-- Converting the Lua 'assert' function into a namespace table (without
-- breaking compatibility with the basic 'assert()' calling).
--
-- This module allows shorthand use s.a. 'assert.table()' for asserting 
-- variable types, and is also being used by Lua-super constraints system
-- for testing function parameter & return types.
--
-- All in all, a worthy module and could be part of Lua future versions.
--
-- Note: the 'assert' table is available for your own assertions, too. Just add
--       more functions s.a. 'assert.myobj()' to check for custom invariants. 
--       They will then be available for the constraints check, too.
--
-- Author:  <akauppi@gmail.com>
--
--[[
/******************************************************************************
* Lua 5.1.1 support and extension functions (assert.lua)
*
* Copyright (C) 2006-07, Asko Kauppi.
*
* NOTE: This license concerns only the particular source file; not necessarily
*       the project with which it has been delivered (the project may have a more
*       restrictive license, s.a. [L]GPL).
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the 
* "Software"), to deal in the Software without restriction, including   
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to   
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
******************************************************************************/
]]--

local m= { _info= { MODULE= "Assert.* functions for constraints, and unit testing",
                    AUTHOR= "akauppi@gmail.com",
                    VERSION= 20070603,    -- last change (yyyymmdd)
                    LICENSE= "MIT/X11" } }

-- Global changes:
--      'assert' redefined, in a backwards compatible way
--
-- Module functions:
--      none

assert( type(assert) == "function" )    -- system assert function

-----
-- Integer range: INT_MIN..INT_MAX
--
local function try_maxint( n )
    return (n > n-1) and n-1   -- false when outside the integer range 
end

local INT_MAX=
    try_maxint( 2^64 ) or
    try_maxint( 2^32 ) or
    try_maxint( 2^24 ) or     -- float (24-bit mantissa)
    assert( false )

local INT_MIN= -(INT_MAX+1)


---=== assert.*() ===---

local at_msg= "type assertion error"  -- TBD: better messages, about that exact situation
local av_msg= "value assertion error"

-- void= _assert( val [, msg_str [, lev_uint]] )
--
local function _assert( cond, msg, lev ) 
    -- original 'assert' provides no level override, so we use 'error'.
    --
    if not cond then
        error( msg or "assertion failed!", (lev or 1)+1 )
    end
end

-- Note: following code uses the _new_ 'assert()' by purpose, since it provides
--       a level override (original doesn't)
--
local function assert_v( v0 )
    return function(v,msg) 
                _assert( v == v0, msg or av_msg, 2 )
                return v
           end
end
local function assert_t( str )
    return function(v,msg) 
                _assert( type(v) == str, msg or at_msg, 2 )
                return v
           end
end
local function assert_t2( str )
    return function(v,subtype,msg) 
                local t,st= type(v)
                _assert( t==str and ((not subtype) or (st==subtype)),
                         msg or at_msg, 2 )
                return v
           end
end

assert= 
  {
    __call= function(_,v,msg)     -- plain 'assert()' (compatibility)
            if v then return v end
            _assert( v, msg, 2 )
        end,

    -- Hopefully, Lua will allow use of 'nil', 'function' and other reserved words as table 
    -- shortcuts in the future (5.1.1 does not). 
    --
    ["nil"]= assert_v( nil ),
    boolean= assert_t "boolean",
    table= assert_t2 "table",
    ["function"]= assert_t "function",
    userdata= assert_t2 "userdata",

    string= function( v, msg )
        local s= tostring(v)
        _assert( s, msg or at_msg, 2 )
        return v
    end,

    char= function( v, msg )
        -- 'char' is _not_ doing int->string conversion
        _assert( type(v)=="string" and v:len()==1, msg or at_msg, 2 )
        return v
    end,

    number= function( v, msg )
        _assert( tonumber(v), msg or at_msg, 2 )
        return v
    end,

    int= function( v, msg )
        local n= tonumber(v)
        _assert( n and (n >= INT_MIN) and (n <= INT_MAX) and math.floor(n) == n,
                    msg or at_msg, 2 )
        return v
    end,

    uint= function( v, msg )
        local n= tonumber(v)
        -- unsigned integer upper range is the same as integers' (there's no
        -- real unsigned within the Lua)
        _assert( n and (n >= 0) and (n <= INT_MAX) and math.floor(n) == n,
                    msg or at_msg, 2 )
        return v
    end,
    
    ['true']= assert_v( true ),
    ['false']= assert_v( false ),

    string_or_table= function( v, msg )
        assert( tostring(v) or type(v)=="table", msg or at_msg, 2 )
        return v
    end,
    
    number_or_string= function( v, msg )
        assert( tonumber(v) or type(v)=="table", msg or at_msg, 2 )
        return v
    end,

    any= function( v, msg )
        assert( v ~= nil, msg or av_msg, 2 )
        return v
    end,

    -- Range assertion, with extra parameters per instance
    -- 
    -- Note: values may be of _any_ type that can do >=, <= comparisons.
    --
    range= function( lo, hi )
        _assert( lo and hi and lo <= hi, "Bad limits", 2 )
             -- make sure the limits make sense (just once)

        return function(v,msg,lev)
            if ( (lo and v<lo) or (hi and v>hi) ) then
                msg= msg or "not in range: ("..(lo or "")..","..(hi or "")..")"
                _assert( false, msg, 2 )
            end
            return v
        end
    end,
    
    -- Table contents assertion
    --      - no unknown (non-numeric) keys are allowed
    --      - numeric keys are ignored
    --
    -- Constraints patch should point to this, when using the ":{ ... }" constraint.
    -- 
    ["{}"]= function( tbl )

        -- check all keys in 't' (including numeric, if any) that they do exist,
        -- and carry the right type
        --
        local function subf1(v,t,msg,lev)
            _assert(lev)
            for k,f in pairs(t) do
                -- 'f' is an assert function, or subtable
                local ft= type(f)
                if ft=="function" then
                    f( v[k], msg, lev+1 )
                elseif ft=="table" then
                    _assert( type(v[k])=="table", msg or "no subtable "..tostring(k), lev+1 )
                    subf1( v[k], f, msg, lev+1 )
                else
                    error( "Bad constraints table for '"..tostring(k).."'! (not a function)", lev+1 )
                end
            end
        end
                        
        -- check there are no other (non-numeric) keys in 'v'
        local function subf2(v,t,msg,lev)
            _assert(lev)
            for k,vv in pairs(v) do
                if type(k)=="number" then
                    -- skip them
                elseif not t[k] then
                    _assert( false, msg or "extra field: '"..tostring(k).."'", lev+1 )
                elseif type(vv)=="table" then
                    subf2( vv, t[k], msg, lev+1 )
                end
            end
        end
        
        _assert( type(tbl)=="table", "Wrong parameter to assert['{}']" )

        return function( v, msg, lev )
            lev= (lev or 1)+1
            _assert( type(v)=="table" ,msg, lev )
            subf1( v, tbl, msg, lev )
            subf2( v, tbl, msg, lev )
            return v
        end
    end,

    -- ...
}
setmetatable( assert, assert )

assert.void= assert["nil"]


-----    
-- void= assert.fails( function [,err_msg_str] )
--
-- Special assert function, to make sure the call within it fails, and gives a 
-- specific error message (to be used in unit testing).
--
function assert.fails( func_block, err_msg )
    --
    local st,err= pcall( func_block )
    if st then
        _assert( false, "Block expected to fail, but didn't.", 2 )
    elseif err_msg and err ~= err_msg then
        _assert( false, "Failed with wrong error message: \n"..
                       "'"..err.."'\nexpected: '"..err_msg.."'", 2 )
    end
end


-----    
-- void= assert.failsnot( function [,err_msg_str] )
--
-- Similar to 'assert.fails' but expects the code to survive.
--
function assert.failsnot( func_block, err_msg )
    --
    local st,err= pcall( func_block )
    if not st then
        _assert( false, "Block expected NOT to fail, but did."..
                        (err and "\n\tError: '"..err.."'" or ""), 2 )
    end
end


-----    
-- void= assert.nilerr( function [,err_msg_str] )
--
-- Expects the function to return with 'nil,err' failure code, with
-- optionally error string matching. Similar to --> 'assert.fails()'
--
function assert.nilerr( func_block, err_msg )
    --
    local v,err= func_block()
    _assert( v==nil, "Expected to return nil, but didn't: "..tostring(v), 2 )
    if err_msg and err ~= err_msg then
        _assert( false, "Failed with wrong error message: \n"..
                       "'"..err.."'\nexpected: '"..err_msg.."'", 2 )
    end
end


-- Sanity check
--
assert( true )
assert.fails( function() assert( false ) end )
assert.fails( function() assert( nil ) end )


return m    -- just info
