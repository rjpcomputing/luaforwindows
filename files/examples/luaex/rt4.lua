#!/usr/bin/env lua
require "ex"
local f = assert(io.open("hullo.test", "w+"))
f:lock("w")
f:write("Hello\n")
f:unlock()
f:seek("set")
print(f:read())
f:close()
