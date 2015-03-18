require 'pl'
asserteq = require('pl.test').asserteq
utils.import('pl.func')

 -- _DEBUG = true

function pprint (t)
    print(pretty.write(t))
end

function test (e)
	local v = {}
	print('test',collect_values(e,v))
	if #v > 0 then pprint(v) end
	local rep = repr(e)
    print(rep)
end

import ('math')

test(_1+_2('hello'))
test(sin(_1))
test(_1:method())
test(Not(_1))

asserteq(instantiate(_1+_2)(10,20),30)
asserteq(instantiate(_1+20)(10),30)
asserteq(instantiate(Or(Not(_1),_2))(true,true),true)
test(_1() + _2() + _3())
print(I(_1+_2)(10,20))
test(sin(_1)+cos(_2))


asserteq(instantiate(_1+_2)(10,20),30)

ls = List {1,2,3,4}
res = ls:map(10*_1 - 1)
asserteq(res,List {9,19,29,39})

-- note that relational operators can't be overloaded for _different_ types
ls = List {10,20,30,40}
asserteq(ls:filter(Gt(_1,20)),List {30,40})


local map,map2 = tablex.map,tablex.map2

--~ test(Len(_1))

-- methods can be applied to all items in a table with map
asserteq (map(_1:sub(1,2),{'one','four'}),{'on','fo'})

--~ -- or you can do this using List:map
asserteq( List({'one','four'}):map(_1:sub(1,2)), List{'on','fo'})

--~ -- note that Len can't be represented generally by #, since this can only be overriden by userdata
asserteq( map(Len(_1),{'one','four'}),  {3,4} )

--~ -- simularly, 'and' and 'or' are not really operators in Lua, so we need a function notation for them
asserteq (map2(Or(_1,_2),{false,'b'},{'.lua',false}),{'.lua','b'})

--~ -- binary operators:  + - * / % ^ ..
asserteq (map2(_1.._2,{'a','b'},{'.lua','.c'}),{'a.lua','b.c'})

t1 = {alice=23,fred=34}
t2 = {bob=25,fred=34}

intersection = bind(tablex.merge,_1,_2,false)

asserteq(intersection(t1,t2),{fred=34})

union = bind(tablex.merge,_1,_2,true)

asserteq(union(t1,t2),{bob=25,fred=34,alice=23})

asserteq(repr(_1+_2),"_1 + _2")









