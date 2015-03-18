#! /usr/bin/env lua
prog = {
  name = "",
  banner = " VERSION (DATE) by AUTHOR <EMAIL>)",
  purpose = "",
}


require "std"


-- Process a file
function main (file, number)
end


-- Command-line options
options = {
  Option {{"test", "t"},
    "test option"},
}

-- Main routine
getopt.processArgs ()
if table.getn (arg) == 0 then
  getopt.dieWithUsage ()
end
io.processFiles (main)


-- Changelog

--   0.1  Program started
