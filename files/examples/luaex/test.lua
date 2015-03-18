-- ---------------------------------------------------------------------------
--	ex.lua - This is a small example of some of the things that can be done
--			 with the 'ex' library.
--
--	Author:		Ryan Pusztai
--	Date:		07/23/2007
--	Version:	1.00
--
--	NOTES:
--				* You can use the 'ex' namespace for all of the commands in the 'ex'
--				  library. ex: ex.currentdir() and ex.chdir()
-- ---------------------------------------------------------------------------

-- INCLUDES ------------------------------------------------------------------
--
require( "ex" )

-- DEBUGGING -----------------------------------------------------------------
--

print( "-- CURRENT DIRECTORY --------------------------------------------------------" )
local oldCurDir = os.currentdir()
print( oldCurDir )
print( "-- CHANGE DIRECTORY (UP ONE DIRECTORY) --------------------------------------" )
os.chdir( ".." )
print( os.currentdir() )
print( "-- CHANGE DIRECTORY (BACK TO ORIGINAL) --------------------------------------" )
os.chdir( oldCurDir )
print( os.currentdir() )

print( "\n-- $PATH ENVIRONMENT VARIABLE -----------------------------------------------" )
print( os.getenv( "PATH" ) )

print( "\n-- ENUMERATE ALL ENVIRONMENT VARIABLES --------------------------------------" )
local e = assert( os.environ() )
table.foreach( e, function( nam, val ) print( string.format( "%s=%s", nam, val) ) end )

print( "\n-- SHOW ALL FILES AND DIRECTORIES IN THE CURRENT DIRECTORY ------------------" )
for e in assert(os.dir(".")) do
	print(string.format("%.4s %9d  %s", e.type or 'Unknown', e.size or -1, e.name))
end

print( "\n-- PING GOOGLE.COM ----------------------------------------------------------" )
local proc = assert( os.spawn( "ping", { "google.com" } ) )
print( proc )
print( "Process exit code:", assert( proc:wait() ) )
