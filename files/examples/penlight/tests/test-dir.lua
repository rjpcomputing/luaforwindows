-- This test file expects to be ran from 'run.lua' in the root Penlight directory.

local dir = require( "pl.dir" )
local file = require( "pl.file" )
local path = require( "pl.path" )
local asserteq = require( "pl.test" ).asserteq
local pretty = require( "pl.pretty" )

local normpath = path.normpath

local expected = {normpath "../docs/config.ld"}

local files = dir.getallfiles( normpath "../docs/", "*.ld" )

asserteq( files, expected )

-- Test move files -----------------------------------------

-- Create a dummy file
local fileName = path.tmpname()
file.write( fileName, string.rep( "poot ", 1000 ) )

local newFileName = path.tmpname()
local err, msg = dir.movefile( fileName, newFileName )

-- Make sure the move is successful
assert( err, msg )

-- Check to make sure the original file is gone

asserteq( path.exists( fileName ), false )

-- Check to make sure the new file is there
asserteq (path.exists( newFileName ) , newFileName)

-- Clean up
file.delete( newFileName )

