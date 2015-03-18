local path = require 'pl.path'
asserteq = require 'pl.test'.asserteq

function quote(s)
	return '"'..s..'"'
end

function print2(s1,s2)
	print(quote(s1),quote(s2))
end

function testpath(pth)
    print2 (path.splitpath(pth))
    print2 (path.splitext(pth))
end

testpath [[c:\bonzo\dog_stuff\cat.txt]]
testpath [[/bonzo/dog/cat/fred.stuff]]
testpath [[../../alice/jones]]
testpath [[alice]]
testpath [[/path-to\dog\]]

asserteq( path.isdir( "../docs" ), true )
asserteq( path.isdir( "../docs/config.ld" ), false )

asserteq( path.isfile( "../docs" ), false )
asserteq( path.isfile( "../docs/config.ld" ), true )

local norm = path.normpath
local p = norm '/a/b'

asserteq(norm '/a/fred/../b',p)
asserteq(norm '/a//b',p)

if path.is_windows then
  asserteq(norm [[\a\.\b]],p)
end

asserteq(norm '1/2/../3/4/../5',norm '1/3/5')


