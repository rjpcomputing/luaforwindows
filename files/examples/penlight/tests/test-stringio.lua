local stringio = require 'pl.stringio'
local test = require 'pl.test'
local asserteq = test.asserteq
local T = test.tuple

fs = stringio.create()
for i = 1,100 do
    fs:write('hello','\n','dolly','\n')
end
asserteq(#fs:value(),1200)

fs = stringio.create()
fs:writef("%s %d",'answer',42)  -- note writef() extension method
asserteq(fs:value(),"answer 42")

inf = stringio.open('10 20 30')
asserteq(T(inf:read('*n','*n','*n')),T(10,20,30))

local txt = [[
Some lines
here are they
not for other
english?
]]

inf = stringio.open (txt)
fs = stringio.create()
for l in inf:lines() do
    fs:write(l,'\n')
end
asserteq(txt,fs:value())

inf = stringio.open '1234567890ABCDEF'
asserteq(T(inf:read(3), inf:read(5), inf:read()),T('123','45678','90ABCDEF'))







