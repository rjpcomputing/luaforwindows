#!/usr/bin/env lua
require "ex"

print"os.environ"
local e = assert(os.environ())
table.foreach(e, function(nam,val) print(string.format("%s=%s", nam, val)) end)
