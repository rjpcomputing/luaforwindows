local pretty = require 'pl.pretty'
local asserteq = require('pl.test').asserteq

t1 = {
    'one','two','three',{1,2,3},
    alpha=1,beta=2,gamma=3,['&']=true,[0]=false,
    _fred = {true,true},
    s = [[
hello dolly
you're so fine
]]
}

s = pretty.write(t1) --,' ',true)
t2,err = pretty.read(s)
if err then return print(err) end
asserteq(t1,t2)

res,err = pretty.read [[
  {
	['function'] = true,
	['do'] = true,
  }
]]
assert(res)

res,err = pretty.read [[
  {
	['function'] = true,
	['do'] = function() return end
  }
]]
assert(err == 'cannot have Lua keywords in table definition')

-- Check to make sure that no spaces exist when write is told not to
local tbl = { "a", 2, "c", false, 23, 453, "poot", 34 }
asserteq( pretty.write( tbl, "" ), [[{"a",2,"c",false,23,453,"poot",34}]] )

function testm(x,s)
  asserteq(pretty.number(x,'M'),s)
end

testm(123,'123B')
testm(1234,'1.2KiB')
testm(10*1024,'10.0KiB')
testm(1024*1024,'1.0MiB')

function testn(x,s)
  asserteq(pretty.number(x,'N',2),s)
end

testn(123,'123')
testn(1234,'1.23K')
testn(10*1024,'10.24K')
testn(1024*1024,'1.05M')
testn(1024*1024*1024,'1.07B')

function testc(x,s)
  asserteq(pretty.number(x,'T'),s)
end

testc(123,'123')
testc(1234,'1,234')
testc(12345,'12,345')
testc(123456,'123,456')
testc(1234567,'1,234,567')
testc(12345678,'12,345,678')

asserteq(pretty.number(1e12,'N'),'1000.0B')

