--[[------------------------------------------------------------------------
test_zip.lua
test code for luazip
--]]------------------------------------------------------------------------

-- compatibility code for Lua version 5.0 providing 5.1 behavior
if string.find (_VERSION, "Lua 5.0") and not package then
	if not LUA_PATH then
		LUA_PATH = os.getenv("LUA_PATH") or "./?.lua;"
	end
	require"compat-5.1"
	package.cpath = os.getenv("LUA_CPATH") or "./?.so;./?.dll;./?.dylib"
end

require('zip')

function test_open ()
	local zfile, err = zip.open('luazip.zip')
	
	assert(zfile, err)
	
	print("File list begin")
	for file in zfile:files() do
		print(file.filename)
	end
	print("File list ended OK!")
	print()
	
	print("Testing zfile:open")
	local f1, err = zfile:open('README')
	assert(f1, err)
	
	local f2, err = zfile:open('luazip.h')
	assert(f2, err)
	print("zfile:open OK!")
	print()
	
	print("Testing reading by number")
	local c = f1:read(1)
	while c ~= nil do
		io.write(c)
		c = f1:read(1)
	end

	print()
	print("OK")
	print()
end

function test_openfile ()
	print("Testing the openfile magic")
	
	local d, err = zip.openfile('a/b/c/d.txt')
	assert(d, err)
	
	local e, err = zip.openfile('a/b/c/e.txt')
	assert(e == nil, err)
	
	local d2, err = zip.openfile('a2/b2/c2/d2.txt', "ext2")
	assert(d2, err)
	
	local e2, err = zip.openfile('a2/b2/c2/e2.txt', "ext2")
	assert(e2 == nil, err)
	
	local d3, err = zip.openfile('a3/b3/c3/d3.txt', {"ext2", "ext3"})
	assert(d3, err)
	
	local e3, err = zip.openfile('a3/b3/c3/e3.txt', {"ext2", "ext3"})
	assert(e3 == nil, err)
	
	print("Smooth magic!")
	print()
end

test_open()
test_openfile()
