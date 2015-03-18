--
-- FIBONACCI.LUA         Copyright (c) 2007-08, Asko Kauppi <akauppi@gmail.com>
--
-- Parallel calculation of Fibonacci numbers
--
-- A sample of task splitting like Intel TBB library does.
-- 
-- References:
--      Intel Threading Building Blocks, 'test all'
--      <http://shareit.intel.com/WikiHome/Articles/111111316>
--

-- Need to say it's 'local' so it can be an upvalue
--
local lanes= require "lanes"

local function WR(str)
    io.stderr:write( str.."\n" )
end

-- Threshold for serial calculation (optimal depends on multithreading fixed
-- cost and is system specific)
--
local KNOWN= { [0]=0, 1,1,2,3,5,8,13,21,34,55,89,144 }

--
-- uint= fib( n_uint )
--
local function fib( n )
    --
    local sum
    local floor= assert(math.floor)

    WR( "fib("..n..")" )

    if n <= #KNOWN then
        sum= KNOWN[n]
    else
        -- Splits into two; this task remains waiting for the results
        --
        local gen_f= lanes.gen( "io,math,debug", fib )

        local n1=floor(n/2) +1
        local n2=floor(n/2) -1 + n%2

        WR( "splitting "..n.." -> "..n1.." "..n2 )

        local a= gen_f( n1 )
        local b= gen_f( n2 )

        -- children running...

        local a2= a[1]^2
        local b2= b[1]^2

        sum = (n%2==1) and a2+b2 or a2-b2
    end

    io.stderr:write( "fib("..n..") = "..sum.."\n" )
    
    return sum
end

--
-- Right answers from: <http://sonic.net/~douglasi/fibo.htm>
--
local right= { 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765, 10946, 17711, 28657, 46368, 75025, 121393, 196418, 317811, 514229, 832040, 1346269, 2178309, 3524578, 5702887, 9227465, 14930352, 24157817, 39088169, 63245986, 102334155, 165580141, 267914296, 433494437, 701408733, 1134903170, 1836311903, 2971215073, 4807526976, 7778742049, 12586269025, 20365011074, 32951280099, 53316291173, 86267571272, 139583862445, 225851433717, 365435296162, 591286729879, 956722026041, 1548008755920, 2504730781961, 4052739537881, 6557470319842, 10610209857723, 17167680177565, 27777890035288, 44945570212853, 72723460248141, 117669030460994, 190392490709135, 308061521170129, 498454011879264, 806515533049393, 1304969544928657, 2111485077978050, 3416454622906707, 5527939700884757, 8944394323791464, 14472334024676220, 23416728348467684, 37889062373143900, 61305790721611580, 99194853094755490, 160500643816367070, 259695496911122560, 420196140727489660, 679891637638612200, 1100087778366101900, 1779979416004714000, 2880067194370816000, 4660046610375530000, 7540113804746346000, 12200160415121877000, 19740274219868226000, 31940434634990105000, 51680708854858334000, 83621143489848440000, 135301852344706780000, 218922995834555200000
}
assert( #right==99 )

local N= 80
local res= fib(N)
print( right[N] )
assert( res==right[N] )

