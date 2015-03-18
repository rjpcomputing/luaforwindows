--[[ 
		test_luaunit.lua

Description: Tests for the luaunit testing framework


Author: Philippe Fremy <phil@freehackers.org>
Version: 1.1 
License: X11 License, see LICENSE.txt

]]--

-- This is a bit tricky since the test uses the features that it tests.

local LuaUnit = require('luaunit')

TestLuaUnit = {} --class
    function TestLuaUnit:test_assertError()
        local function f() end

        has_error = not pcall( error, "coucou" )
        assert( has_error == true )
        assertError( error, "coucou" )
        has_error = not pcall( assertError, error, "coucou" )
        assert( has_error == false )

        has_error = not pcall( f )
        assert( has_error == false )
        has_error = not pcall( assertError, f )
        assert( has_error == true )

        -- multiple arguments
        local function multif(a,b,c)
            if a == b and b == c then return end
            error("three arguments not equal")
        end

        assertError( multif, 1, 1, 3 )
        assertError( multif, 1, 3, 1 )
        assertError( multif, 3, 1, 1 )

        has_error = not pcall( assertError, multif, 1, 1, 1 )
        assert( has_error == true )
    end

    function TestLuaUnit:test_assertEquals()
        assertEquals( 1, 1 )
        has_error = not pcall( assertEquals, 1, 2 )
        assert( has_error == true )
    end

    function TestLuaUnit:Xtest_xpcall()
        local function f() error("[this is a normal error]") end
        local function g() f() end
        g()
    end

--[[ Class to test that tests are run in the right order ]]

TestToto1 = {} --class
    function TestToto1:test1() end
    function TestToto1:test2() end
    function TestToto1:test3() end
    function TestToto1:test4() end
    function TestToto1:test5() end
    function TestToto1:testa() end
    function TestToto1:testb() end

TestToto2 = {} --class
    function TestToto2:test1() end
    function TestToto2:test2() end
    function TestToto2:test3() end
    function TestToto2:test4() end
    function TestToto2:test5() end
    function TestToto2:testa() end
    function TestToto2:testb() end


TestToto3 = {} --class
    function TestToto3:test1() end
    function TestToto3:test2() end
    function TestToto3:test3() end
    function TestToto3:test4() end
    function TestToto3:test5() end
    function TestToto3:testa() end
    function TestToto3:testb() end

TestTotoa = {} --class
    function TestTotoa:test1() end
    function TestTotoa:test2() end
    function TestTotoa:test3() end
    function TestTotoa:test4() end
    function TestTotoa:test5() end
    function TestTotoa:testa() end
    function TestTotoa:testb() end

TestTotob = {} --class
    function TestTotob:test1() end
    function TestTotob:test2() end
    function TestTotob:test3() end
    function TestTotob:test4() end
    function TestTotob:test5() end
    function TestTotob:testa() end
    function TestTotob:testb() end


-- LuaUnit:run('TestLuaBinding:test_setline') -- will execute only one test
-- LuaUnit:run('TestLuaBinding') -- will execute only one class of test
-- LuaUnit.result.verbosity = 0
LuaUnit:run() -- will execute all tests

