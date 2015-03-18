--
-- BASIC.LUA           Copyright (c) 2007-08, Asko Kauppi <akauppi@gmail.com>
--
-- Selftests for Lua Lanes
-- 
-- To do:
--      - ...
--

require "lanes"
require "assert"    -- assert.fails()

local lanes_gen=    assert( lanes.gen )
local lanes_linda=  assert( lanes.linda )

local tostring=     assert( tostring )

local function PRINT(...)
    local str=""
    for i=1,select('#',...) do
        str= str..tostring(select(i,...)).."\t"
    end
    if io then 
        io.stderr:write(str.."\n")
    end
end


---=== Local helpers ===---

local tables_match

-- true if 'a' is a subtable of 'b'
--
local function subtable( a, b )
    --
    assert( type(a)=="table" and type(b)=="table" )

    for k,v in pairs(b) do
        if type(v)~=type(a[k]) then
            return false    -- not subtable (different types, or missing key)
        elseif type(v)=="table" then
            if not tables_match(v,a[k]) then return false end
        else
            if a[k] ~= v then return false end
        end
    end
    return true     -- is a subtable
end

-- true when contents of 'a' and 'b' are identific
--
tables_match= function( a, b )
    return subtable( a, b ) and subtable( b, a )
end


---=== Tasking (basic) ===---

local function task( a, b, c )
    --error "111"     -- testing error messages
    assert(hey)
    local v=0
    for i=a,b,c do
        v= v+i
    end
    return v, hey
end

local task_launch= lanes_gen( "", { globals={hey=true} }, task )
	-- base stdlibs, normal priority

-- 'task_launch' is a factory of multithreaded tasks, we can launch several:

local lane1= task_launch( 100,200,3 )
local lane2= task_launch( 200,300,4 )

-- At this stage, states may be "pending", "running" or "done"

local st1,st2= lane1.status, lane2.status
PRINT(st1,st2)
assert( st1=="pending" or st1=="running" or st1=="done" )
assert( st2=="pending" or st2=="running" or st2=="done" )

-- Accessing results ([1..N]) pends until they are available
--
PRINT("waiting...")
local v1, v1_hey= lane1[1], lane1[2]
local v2, v2_hey= lane2[1], lane2[2]

PRINT( v1, v1_hey )
assert( v1_hey == true )

PRINT( v2, v2_hey )
assert( v2_hey == true )

assert( lane1.status == "done" )
assert( lane1.status == "done" )


---=== Tasking (cancelling) ===---

local task_launch2= lanes_gen( "", { cancelstep=100, globals={hey=true} }, task )

local N=999999999
local lane9= task_launch2(1,N,1)   -- huuuuuuge...

-- Wait until state changes "pending"->"running"
--
local st
local t0= os.time()
while os.time()-t0 < 5 do
    st= lane9.status
    io.stderr:write( (i==1) and st.." " or '.' )
    if st~="pending" then break end
end
PRINT(" "..st)

if st=="error" then
    local _= lane9[0]  -- propagate the error here
end
if st=="done" then
    error( "Looping to "..N.." was not long enough (cannot test cancellation)" )
end
assert( st=="running" )

lane9:cancel()

local t0= os.time()
while os.time()-t0 < 5 do
    st= lane9.status
    io.stderr:write( (i==1) and st.." " or '.' )
    if st~="running" then break end
end
PRINT(" "..st)
assert( st == "cancelled" )


---=== Communications ===---

local function WR(...) io.stderr:write(...) end

local chunk= function( linda )

    local function receive() return linda:receive( "->" ) end
    local function send(...) linda:send( "<-", ... ) end

    WR( "Lane starts!\n" )

    local v
    v=receive(); WR( v.." received\n" ); assert( v==1 )
    v=receive(); WR( v.." received\n" ); assert( v==2 )
    v=receive(); WR( v.." received\n" ); assert( v==3 )

    send( 1,2,3 );              WR( "1,2,3 sent\n" )
    send 'a';                   WR( "'a' sent\n" )
    send { 'a', 'b', 'c', d=10 }; WR( "{'a','b','c',d=10} sent\n" )

    v=receive(); WR( v.." received\n" ); assert( v==4 )
        
    WR( "Lane ends!\n" )
end

local linda= lanes_linda()
assert( type(linda) == "userdata" )
    --
    -- ["->"] master -> slave
    -- ["<-"] slave <- master

local function PEEK() return linda:get("<-") end
local function SEND(...) linda:send( "->", ... ) end
local function RECEIVE() return linda:receive( "<-" ) end

local t= lanes_gen("io",chunk)(linda)     -- prepare & launch

SEND(1);  WR( "1 sent\n" )
SEND(2);  WR( "2 sent\n" )
for i=1,100 do
    WR "."
    assert( PEEK() == nil )    -- nothing coming in, yet
end
SEND(3);  WR( "3 sent\n" )

local a,b,c= RECEIVE(), RECEIVE(), RECEIVE()
    WR( a..", "..b..", "..c.." received\n" )
assert( a==1 and b==2 and c==3 )

local a= RECEIVE();   WR( a.." received\n" )
assert( a=='a' )

local a= RECEIVE();   WR( type(a).." received\n" )
assert( tables_match( a, {'a','b','c',d=10} ) )

assert( PEEK() == nil )
SEND(4)


---=== Stdlib naming ===---

local function io_os_f()
    assert(io)
    assert(os)
    assert(print)
    return true
end

local f1= lanes_gen( "io,os", io_os_f )     -- any delimiter will do
local f2= lanes_gen( "io+os", io_os_f )
local f3= lanes_gen( "io,os,base", io_os_f )

assert.fails( function() lanes_gen( "xxx", io_os_f ) end )

assert( f1()[1] )
assert( f2()[1] )
assert( f3()[1] )


---=== Comms criss cross ===---

-- We make two identical lanes, which are using the same Linda channel.
--
local tc= lanes_gen( "io",
  function( linda, ch_in, ch_out )

    local function STAGE(str)
        io.stderr:write( ch_in..": "..str.."\n" )
        linda:send( nil, ch_out, str )
        local v= linda:receive( nil, ch_in )
        assert(v==str)
    end
    STAGE("Hello")
    STAGE("I was here first!")
    STAGE("So waht?")
  end
)

local linda= lanes_linda()

local a,b= tc(linda, "A","B"), tc(linda, "B","A")   -- launching two lanes, twisted comms

local _= a[1],b[1]  -- waits until they are both ready


---=== Receive & send of code ===---

local upvalue="123"

local function chunk2( linda )
    assert( upvalue=="123" )    -- even when running as separate thread

    -- function name & line number should be there even as separate thread
    --
    local info= debug.getinfo(1)    -- 1 = us
        --
        for k,v in pairs(info) do PRINT(k,v) end

        assert( info.nups == 2 )    -- one upvalue + PRINT
        assert( info.what == "Lua" )
        
        --assert( info.name == "chunk2" )   -- name does not seem to come through
        assert( string.match( info.source, "^@tests[/\\]basic.lua$" ) )
        assert( string.match( info.short_src, "^tests[/\\]basic.lua$" ) )
        
        -- These vary so let's not be picky (they're there..)
        --
        assert( info.linedefined > 200 )   -- start of 'chunk2'
        assert( info.currentline > info.linedefined )   -- line of 'debug.getinfo'
        assert( info.lastlinedefined > info.currentline )   -- end of 'chunk2'

    local func,k= linda:receive( "down" )
    assert( type(func)=="function" )
    assert( k=="down" )

    func(linda)

    local str= linda:receive( "down" )
    assert( str=="ok" )
    
    linda:send( "up", function() return ":)" end, "ok2" )
end

local linda= lanes.linda()

local t2= lanes_gen( "debug,string", chunk2 )(linda)     -- prepare & launch

linda:send( "down", function(linda) linda:send( "up", "ready!" ) end,
                    "ok" )

-- wait to see if the tiny function gets executed
--
local s= linda:receive( "up" )
PRINT(s)
assert( s=="ready!" )

-- returns of the 'chunk2' itself
--
local f= linda:receive( "up" )
assert( type(f)=="function" )

local s2= f()
assert( s2==":)" )

local ok2= linda:receive( "up" )
assert( ok2 == "ok2" )


---=== :join test ===---

-- NOTE: 'unpack()' cannot be used on the lane handle; it will always return nil
--       (unless [1..n] has been read earlier, in which case it would seemingly
--       work).

local S= lanes_gen( "table",
  function(arg)
    aux= {}
    for i, v in ipairs(arg) do
	   table.insert (aux, 1, v)
    end
    return unpack(aux)
end )

h= S { 12, 13, 14 }     -- execution starts, h[1..3] will get the return values

local a,b,c,d= h:join()
assert(a==14)
assert(b==13)
assert(c==12)
assert(d==nil)

--
io.stderr:write "Done! :)\n"
