#!/usr/bin/env lua
require "ex"
assert(arg[1], "argument required")
local proc = assert(os.spawn(arg[1]))
print(proc)
print(assert(proc:wait()))
