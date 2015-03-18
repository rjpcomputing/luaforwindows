#!/usr/bin/env lua
require "ex"

--print"os.sleep"
--os.sleep(2);

assert(os.setenv("foo", "42"))
print("expect foo= 42")
print("foo=", os.getenv("foo"))
assert(os.setenv("foo", nil))
print("expect foo= nil")
print("foo=", os.getenv("foo"))


