--[[ 
		luaunit.lua

Description: A unit testing framework
Homepage: http://phil.freehackers.org/luaunit/
Initial author: Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
Lot of improvements by Philippe Fremy <phil@freehackers.org>
More improvements by Ryan P. <rjpcomputing@gmail.com>
Version: 2.0
License: X11 License, see LICENSE.txt

Changes between 2.0 and 1.3:
- This is a major update that has some breaking changes to make it much more easy to use and code in many different styles
- Made the module only touch the global table for the asserts. You now use the module much more like Lua 5.2 when you require it.
  You need to store the LuaUnit table after you require it to allow you access to the LuaUnit methods and variables.
  (ex. local LuaUnit = require( "luaunit" ))
- Made changes to the style of which LuaUnit forced users to code there test classes. It now is more layed back and give the ability to code in a few styles.
	- Made "testable" classes able to start with 'test' or 'Test' for their name.
	- Made "testable" methods able to start with 'test' or 'Test' for their name.
	- Made testClass:setUp() methods able to be named with 'setUp' or 'Setup' or 'setup'.
	- Made testClass:tearDown() methods able to be named with 'tearDown' or 'TearDown' or 'teardown'.
	- Made LuaUnit.wrapFunctions() function able to be called with 'wrapFunctions' or 'WrapFunctions' or 'wrap_functions'.
	- Made LuaUnit:run() method able to be called with 'run' or 'Run'.
- Added the ability to tell if tables are equal using assertEquals. This uses a deep compare, not just the equality that they are the same memory address.
- Added LuaUnit.is<Type> and LuaUnit.is_<type> helper functions. (e.g. assert( LuaUnit.isString( getString() ) )
- Added assert<Type> and assert_<type> 
- Added assertNot<Type> and assert_not_<type>
- Added _VERSION variable to hold the LuaUnit version
- Added LuaUnit:setVerbosity(lvl) method to the LuaUnit table to allow you to control the verbosity now. If lvl is greater than 1 it will give verbose output.
  This can be called from alias of LuaUnit.SetVerbosity() and LuaUnit:set_verbosity().
- Moved wrapFunctions to the LuaUnit module table (e.g. local LuaUnit = require( "luaunit" ); LuaUnit.wrapFunctions( ... ) )
- Fixed the verbosity to actually format in a way that is closer to other unit testing frameworks I have used.
  NOTE: This is not the only way, I just thought the old output was way to verbose and duplicated the errors.
- Made the errors only show in the "test report" section (at the end of the run)

Changes between 1.3 and 1.2a:
- port to lua 5.1
- use orderedPairs() to iterate over a table in the right order
- change the order of expected, actual in assertEquals() and the default value of
  USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS. This can be adjusted with
  USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS.

Changes between 1.2a and 1.2:
- fix: test classes were not run in the right order

Changes between 1.2 and 1.1:
- tests are now run in alphabetical order
- fix a bug that would prevent all tests from being run

Changes between 1.1 and 1.0:
- internal variables are not global anymore
- you can choose between assertEquals( actual, expected) or assertEquals(
  expected, actual )
- you can assert for an error: assertError( f, a, b ) will assert that calling
  the function f(a,b) generates an error
- display the calling stack when an error is spotted
- a dedicated class collects and displays the result, to provide easy
  customisation
- two verbosity level, like in python unittest
]]--

-- SETUP -----------------------------------------------------------------------
--
local argv = arg
local typenames = { "Nil", "Boolean", "Number", "String", "Table", "Function", "Thread", "Userdata" }

--[[ Some people like assertEquals( actual, expected ) and some people prefer 
assertEquals( expected, actual ).
]]--
USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS = USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS or true

-- HELPER FUNCTIONS ------------------------------------------------------------
--
local function tablePrint(tt, indent, done)
	done = done or {}
	indent = indent or 0
	if type(tt) == "table" then
		local sb = {}
		for key, value in pairs(tt) do
			table.insert(sb, string.rep(" ", indent)) -- indent it
			if type(value) == "table" and not done[value] then
				done[value] = true
				table.insert(sb, "[\""..key.."\"] = {\n");
				table.insert(sb, tablePrint(value, indent + 2, done))
				table.insert(sb, string.rep(" ", indent)) -- indent it
				table.insert(sb, "}\n");
			elseif "number" == type(key) then
				table.insert(sb, string.format("\"%s\"\n", tostring(value)))
			else
				table.insert(sb, string.format(
				"%s = \"%s\"\n", tostring(key), tostring(value)))
			end
		end
			return table.concat(sb)
		else
			return tt .. "\n"
	end
end

local function toString( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return tablePrint(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end

local function deepCompare(t1, t2, ignore_mt)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or not deepCompare(v1,v2) then return false end
	end
	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or not deepCompare(v1,v2) then return false end
	end
	
	return true
end

-- Order of testing
local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key,_ in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

local function orderedNext(t, state)
	-- Equivalent of the next() function of table iteration, but returns the
	-- keys in the alphabetic order. We use a temporary ordered key table that
	-- is stored in the table being iterated.

    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
        return key, t[key]
    end
    -- fetch the next value
    key = nil
    for i = 1,table.getn(t.__orderedIndex) do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

local function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

-- ASSERT FUNCTIONS ------------------------------------------------------------
--
function assertError(f, ...)
	-- assert that calling f with the arguments will raise an error
	-- example: assertError( f, 1, 2 ) => f(1,2) should generate an error
	local has_error, error_msg = not pcall( f, ... )
	if has_error then return end 
	error( "No error generated", 2 )
end
assert_error = assertError

function assertEquals(actual, expected)
	-- assert that two values are equal and calls error else
	if not USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS then
		expected, actual = actual, expected
	end
	
	if "table" == type(actual) then
		if not deepCompare(actual, expected, true) then
			error("table expected: \n"..toString(expected)..", actual: \n"..toString(actual))
		end
	else
		if  actual ~= expected  then
			local function wrapValue( v )
				if type(v) == 'string' then return "'"..v.."'" end
				return tostring(v)
			end
			
			local errorMsg
			--if type(expected) == 'string' then
			--	errorMsg = "\nexpected: "..wrapValue(expected).."\n"..
			--					 "actual  : "..wrapValue(actual).."\n"
			--else
				errorMsg = "expected: "..wrapValue(expected)..", actual: "..wrapValue(actual)
			--end
			--print(errorMsg)
			error(errorMsg, 2)
		end
	end
end
assert_equals = assertEquals

-- assert_<type> functions
for _, typename in ipairs(typenames) do
	local tName = typename:lower()
	local assert_typename = "assert"..typename
	_G[assert_typename] = function(actual, msg)
		local actualtype = type(actual)
		if actualtype ~= tName then
			local errorMsg = tName.." expected but was a "..actualtype
			if msg then 
				errorMsg = msg.."\n"..errorMsg
			end
			error(errorMsg, 2)
		end
		
		return actual
	end
	-- Alias to lower underscore naming
	_G["assert_"..tName] = _G[assert_typename]
end

-- assert_not_<type> functions
for _, typename in ipairs(typenames) do
	local tName = typename:lower()
	local assert_not_typename = "assertNot"..typename
	_G[assert_not_typename] = function(actual, msg)
		if type(actual) == tName then
			local errorMsg = tName.." not expected but was one"
			if msg then 
				errorMsg = msg.."\n"..errorMsg
			end
			error(errorMsg, 2)
		end
	end
	-- Alias to lower underscore naming
	_G["assert_not_"..tName] = _G[assert_not_typename]
end

-- UNITRESULT CLASS ------------------------------------------------------------
--
local UnitResult = { -- class
	failureCount = 0,
	testCount = 0,
	errorList = {},
	currentClassName = "",
	currentTestName = "",
	testHasFailure = false,
	verbosity = 1
}
	function UnitResult:displayClassName()
		--if self.verbosity == 0 then print("") end
		print(self.currentClassName)
	end

	function UnitResult:displayTestName()
		if self.verbosity == 0 then
			io.stdout:write(".")
		else
			io.stdout:write(("  [%s] "):format(self.currentTestName))
		end
	end

	function UnitResult:displayFailure(errorMsg)
		if self.verbosity == 0 then
			io.stdout:write("F")
		else
			--print(errorMsg)
			print("", "Failed")
		end
	end

	function UnitResult:displaySuccess()
		if self.verbosity == 0 then
			io.stdout:write(".")
		else 
			print("", "Ok")
		end
	end

	function UnitResult:displayOneFailedTest(failure)
		testName, errorMsg = unpack(failure)
		print(">>> "..testName.." failed")
		print(errorMsg)
	end

	function UnitResult:displayFailedTests()
		if #self.errorList == 0 then return end
		print("Failed tests:")
		print("-------------")
		table.foreachi(self.errorList, self.displayOneFailedTest)
	end

	function UnitResult:displayFinalResult()
		if self.verbosity == 0 then print("") end
		print("=========================================================")
		self:displayFailedTests()
		local failurePercent, successCount
		if self.testCount == 0 then
			failurePercent = 0
		else
			failurePercent = 100 * self.failureCount / self.testCount
		end
		successCount = self.testCount - self.failureCount
		print( string.format("Success : %d%% - %d / %d",
			100-math.ceil(failurePercent), successCount, self.testCount) )
		return self.failureCount
    end

	function UnitResult:startClass(className)
		self.currentClassName = className
		self:displayClassName()
		-- indent status messages
		if self.verbosity == 0 then io.stdout:write("\t") end
	end

	function UnitResult:startTest(testName)
		self.currentTestName = testName
		self:displayTestName()
        self.testCount = self.testCount + 1
		self.testHasFailure = false
	end

	function UnitResult:addFailure( errorMsg )
		self.failureCount = self.failureCount + 1
		self.testHasFailure = true
		table.insert( self.errorList, { self.currentTestName, errorMsg } )
		self:displayFailure( errorMsg )
	end

	function UnitResult:endTest()
		if not self.testHasFailure then
			self:displaySuccess()
		end
	end

-- class UnitResult end

-- LUAUNIT CLASS ---------------------------------------------------------------
--
local LuaUnit = {
	result = UnitResult,
	_VERSION = "2.0"
}
	-- Sets the verbosity level
	-- @param lvl {number} If greater than 0 there will be verbose output. Defaults to 0
	function LuaUnit:setVerbosity(lvl)
		self.result.verbosity = lvl or 0
		assert("number" == type(self.result.verbosity), ("bad argument #1 to 'setVerbosity' (number expected, got %s)"):format(type(self.result.verbosity)))
	end
	-- Other alias's
	LuaUnit.set_verbosity = LuaUnit.setVerbosity
	LuaUnit.SetVerbosity = LuaUnit.setVerbosity
	
	-- Split text into a list consisting of the strings in text,
	-- separated by strings matching delimiter (which may be a pattern). 
	-- example: strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
	function LuaUnit.strsplit(delimiter, text)
		local list = {}
		local pos = 1
		if string.find("", delimiter, 1) then -- this would result in endless loops
			error("delimiter matches empty string!")
		end
		while 1 do
			local first, last = string.find(text, delimiter, pos)
			if first then -- found?
				table.insert(list, string.sub(text, pos, first-1))
				pos = last+1
			else
				table.insert(list, string.sub(text, pos))
				break
			end
		end
		return list
	end

	-- Type check functions
	for _, typename in ipairs(typenames) do
		local tName = typename:lower()
		LuaUnit["is"..typename] = function(x)
			return type(x) == tName
		end
		-- Alias to lower underscore naming
		LuaUnit["is_"..tName] = LuaUnit["is"..typename]
	end
    
    -- Use me to wrap a set of functions into a Runnable test class:
	-- TestToto = wrapFunctions( f1, f2, f3, f3, f5 )
	-- Now, TestToto will be picked up by LuaUnit:run()
	function LuaUnit.wrapFunctions(...)
		local testClass, testFunction
		testClass = {}
		local function storeAsMethod(idx, testName)
			testFunction = _G[testName]
			testClass[testName] = testFunction
		end
		table.foreachi( {...}, storeAsMethod )
		
		return testClass
	end
	-- Other alias's
	LuaUnit.wrap_functions = LuaUnit.wrapFunctions
	LuaUnit.WrapFunctions = LuaUnit.wrapFunctions

	function LuaUnit.strip_luaunit_stack(stack_trace)
		stack_list = LuaUnit.strsplit( "\n", stack_trace )
		strip_end = nil
		for i = table.getn(stack_list),1,-1 do
			-- a bit rude but it works !
			if string.find(stack_list[i],"[C]: in function `xpcall'",0,true)
				then
				strip_end = i - 2
			end
		end
		if strip_end then
			table.setn( stack_list, strip_end )
		end
		stack_trace = table.concat( stack_list, "\n" )
		return stack_trace
	end

    function LuaUnit:runTestMethod(aName, aClassInstance, aMethod)
		local ok, errorMsg
		-- example: runTestMethod( 'TestToto:test1', TestToto, TestToto.testToto(self) )
		LuaUnit.result:startTest(aName)

		-- run setUp first(if any)
		if self.isFunction( aClassInstance.setUp) then
			aClassInstance:setUp()
		elseif self.isFunction( aClassInstance.Setup) then
			aClassInstance:Setup()
		elseif self.isFunction( aClassInstance.setup) then
			aClassInstance:setup()
		end

		local function err_handler(e)
			return e..'\n'..debug.traceback()
		end

		-- run testMethod()
        ok, errorMsg = xpcall( aMethod, err_handler )
		if not ok then
			errorMsg  = self.strip_luaunit_stack(errorMsg)
			LuaUnit.result:addFailure( errorMsg )
        end

		-- lastly, run tearDown(if any)
		if self.isFunction(aClassInstance.tearDown) then
			aClassInstance:tearDown()
		elseif self.isFunction(aClassInstance.TearDown) then
			aClassInstance:TearDown()
		elseif self.isFunction(aClassInstance.teardown) then
			aClassInstance:teardown()
		end

		self.result:endTest()
    end

	function LuaUnit:runTestMethodName(methodName, classInstance)
		-- example: runTestMethodName( 'TestToto:testToto', TestToto )
		local methodInstance = loadstring(methodName .. '()')
		LuaUnit:runTestMethod(methodName, classInstance, methodInstance)
	end

    function LuaUnit:runTestClassByName(aClassName)
		--assert("table" == type(aClassName), ("bad argument #1 to 'runTestClassByName' (string expected, got %s). Make sure you are not trying to just pass functions not part of a class."):format(type(aClassName)))
		-- example: runTestMethodName( 'TestToto' )
		local hasMethod, methodName, classInstance
		hasMethod = string.find(aClassName, ':' )
		if hasMethod then
			methodName = string.sub(aClassName, hasMethod+1)
			aClassName = string.sub(aClassName,1,hasMethod-1)
		end
        classInstance = _G[aClassName]
		if "table" ~= type(classInstance) then
			error("No such class: "..aClassName)
		end

		LuaUnit.result:startClass( aClassName )

		if hasMethod then
			if not classInstance[ methodName ] then
				error( "No such method: "..methodName )
			end
			LuaUnit:runTestMethodName( aClassName..':'.. methodName, classInstance )
		else
			-- run all test methods of the class
			for methodName, method in orderedPairs(classInstance) do
			--for methodName, method in classInstance do
				if LuaUnit.isFunction(method) and (string.sub(methodName, 1, 4) == "test" or string.sub(methodName, 1, 4) == "Test") then
					LuaUnit:runTestMethodName( aClassName..':'.. methodName, classInstance )
				end
			end
		end
	end

	function LuaUnit:run(...)
		-- Run some specific test classes.
		-- If no arguments are passed, run the class names specified on the
		-- command line. If no class name is specified on the command line
		-- run all classes whose name starts with 'Test'
		--
		-- If arguments are passed, they must be strings of the class names 
		-- that you want to run
		args = {...}
		if #args > 0 then
			table.foreachi( args, LuaUnit.runTestClassByName )
		else 
			if argv and #argv > 1 then
				-- Run files passed on the command line
				table.foreachi(argv, LuaUnit.runTestClassByName )
			else
				-- create the list before. If you do not do it now, you
				-- get undefined result because you modify _G while iterating
				-- over it.
				local testClassList = {}
				for key, val in pairs(_G) do 
					if "table" == type(val) then
						if string.sub(key, 1, 4) == "Test" or string.sub(key, 1, 4) == "test" then
							table.insert( testClassList, key )
						end
					end
				end
				for i, val in orderedPairs(testClassList) do 
					LuaUnit:runTestClassByName(val)
				end
			end
		end
		
		return LuaUnit.result:displayFinalResult()
	end
	-- Other alias
	LuaUnit.Run = LuaUnit.run
-- end class LuaUnit

return LuaUnit
