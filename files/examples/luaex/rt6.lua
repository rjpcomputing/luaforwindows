#!/usr/bin/env lua
require "ex"

for e in assert(os.dir(".")) do
	print(string.format("%.3s %9d  %s", e.type or 'Unknown', e.size or -1, e.name))
end
--[[
local f,s,i = assert(os.dir(".."))
print(f,s,i)
i=assert(f(s,i))
for e in f,s,i do
	print(e.name,e.type,e.size)
end
--]]
