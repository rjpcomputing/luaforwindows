#!/usr/bin/env lua
require "ex"
assert(arg[1], "need a command name")
print"io.pipe()"
local i, o = assert(io.pipe())
print("got", i, o)
print"os.spawn()"
local t = {command = arg[1], stdin = i}
print(t.stdin)
local proc = assert(os.spawn(t))
print"i:close()"
i:close()
print"o:write()"
o:write("Hello\nWorld\n")
print"o:close()"
o:close()
print"proc:wait()"
print("exit status:", assert(proc:wait()))
