#!/usr/bin/env lua
require "ex"

print"os.chdir"
assert(os.chdir("../luaex"))
print(os.currentdir())

print"os.mkdir"
assert(os.mkdir("Foo.test"))
assert(os.chdir("Foo.test"))
