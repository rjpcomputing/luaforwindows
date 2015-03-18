#!/usr/local/bin/lua

require "gzio"
require "tar"

local file = assert(gzio.open("testdir.tar.gz"))
local archive = tar.open(file)

for filename in archive:files() do
	print()
	print('************************************************************')
	print('************************************************************')
	print('file: '..filename)
	print('************************************************************')
	print('************************************************************')
	print()
	print('************************************************************')
	local file = assert(archive:open(filename))
	for k,v in pairs(file) do print(k,v) end
	print('************************************************************')
	print("pointer = "..file:seek("set"))
	print(file:read("*a"))
	print('************************************************************')
	print("pointer = "..file:seek("set"))
	for line in file:lines() do
		print("line: "..line)
	end
	print('************************************************************')
	print()
end

