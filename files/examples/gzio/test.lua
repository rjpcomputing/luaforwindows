#!/usr/local/bin/lua

-----------------------------------------------------------------------------
-- gzip file I/O library test script
--
-- This file was created by Judge Maygarden (jmaygarden at computer dot org)
-- and is hereby place in the public domain
-----------------------------------------------------------------------------

require "gzio"

local filename = "test.txt"
local gzFile

-- stream the text file into a gzip file
gzFile = assert(gzio.open(filename..".gz", "w"))
for line in io.lines(filename) do
	gzFile:write(line..'\n')
end
gzFile:close()

-- echo the gzip file to stdout
gzFile = assert(gzio.open(filename, "r"), "gzio.open failed!")
for line in gzFile:lines() do
	print(line)
end

-- rewind and do it again with gzFile:read
gzFile:seek("set")
print(gzFile:read("*a"))

gzFile:close()

-----------------------------------------------------------------------------
-- The following functions also need to be tested:
--
--gzFile:flush
--gzFile:setvbuf
--gzio.close
--gzio.flush
--gzio.input
--gzio.lines
--gzio.output
--gzio.popen
--gzio.read
--gzio.stderr
--gzio.stdin
--gzio.stdout
--gzio.tmpfile
--gzio.type
--gzio.write
-----------------------------------------------------------------------------

