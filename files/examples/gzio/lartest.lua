#!/usr/local/bin/lua

gzip = require "gzio"
require "tar"
require "lar"

-- test LAR loadfile
chunk, msg  = loadfile("testdir/testdir/test.lua")
if chunk then chunk() else print(msg) end

-- test LAR dofile
dofile("testdir/testdir/test.lua")

-- test LAR io.open
file, msg = io.open("testdir/testdir/testdir1/test.txt")
if file then print(file:read("*a")) else print(msg) end

-- test LAR require
require("testdir/testdir/test")

