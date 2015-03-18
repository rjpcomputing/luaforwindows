-- test-pylib.lua
local List = require 'pl.List'
require 'pl.stringx'.import()
local text = require 'pl.text'
local Template = text.Template
local asserteq = require 'pl.test' . asserteq

l = List{10,20,30,40,50}
s = List{1,2,3,4,5}

-- test using: lua pylist.lua
local lst = List:new()
lst:append(10)
lst:extend{20,30,40,50}
assert (lst == List{10,20,30,40,50})
lst:insert(3,11)
lst:remove_value(40)
assert (lst == List{10,20,11,30,50})
local q=lst:pop()
assert( lst:index(30)==4 )
assert( lst:count(10)==1 )
lst:sort()
lst:reverse()
assert (lst == List{30,20,11,10})
assert (lst[#lst] == 10)
assert (lst[#lst-2] == 20)

lst = List {10,20,30,40,50}
asserteq (lst:slice(2),{20,30,40,50})
asserteq (lst:slice(-2),{40,50})
asserteq (lst:slice(nil,3),{10,20,30})
asserteq (lst:slice(2,4),{20,30,40})
asserteq (lst:slice(-4,-2),{20,30,40})

lst = List.range(0,9)
seq = List{0,1,2,3,4,5,6,7,8,9}
asserteq(List.range(0,8,2),{0,2,4,6,8})
asserteq(List.range(0,1,0.2),{0,0.2,0.4,0.6,0.8,1},1e-9)


assert(lst == seq)
asserteq (List('abcd'),List{'a','b','c','d'})
ls = List{10,20,30,40}
ls:slice_assign(2,3,{21,31})
assert (ls == List{10,21,31,40})
-- strings ---
s = '123'
assert (s:isdigit())
assert (not s:isspace())
s = 'here the dog is just a dog'
assert (s:startswith('here'))
assert (s:endswith('dog'))
assert (s:count('dog') == 2)
s = '  here we go    '
assert (s:lstrip() == 'here we go    ')
assert (s:rstrip() == '  here we go')
assert (s:strip() == 'here we go')
assert (('hello'):center(20,'+') == '++++++++hello+++++++')

t = Template('${here} is the $answer')
assert(t:substitute {here = 'one', answer = 'two'} == 'one is the two')

assert (('hello dolly'):title() == 'Hello Dolly')
assert (('h bk bonzo TOK fred m'):title() == 'H Bk Bonzo Tok Fred M')
