local tab = {
  foo = {x = 1},
  bar = 2
}

for i,v in ipairs(arg) do
	print(i,v)
end

--~ dofile 'testdir/assert.lua'

local k
local p = 0
local tt

--~ tt.x = 1

print("Start")

function bar(x)
  print("In bar",x)
  p = p + 1
end

for i = 1, 3 do
  k = 2*i
  io.write 'go '
  bar(i)
  tab.foo.x = tab.foo.x * 2
--  a.x = 2
end

print("End of test3")

