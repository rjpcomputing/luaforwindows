-- stdlib expected prog table that holds the Lua application 
prog =
{
	name = "io_ext stdlib Example",
	banner = " 0.1 (05/27/2008) by RJP Computing <rjpcomputing@gmail.com>)",
	purpose = "Shows some of the 'io_ext' functions that stdlib includes",
}

require( "io_ext" )
require( "list" )

-- Remember to always use the '/' slash.
winPath = "C:/Program Files/Lua/5.1/lua.exe"
posixPath = "/c/program files/lua/5.1/lua.exe"

-- Test the path functions
print( "basename=", io.basename( winPath ) )
print( "posix basename=", io.basename( posixPath ) )
print( "dirname=", io.dirname( winPath ) )
print( "posix dirname=", io.dirname( posixPath ) )
print( "pathSplit=", io.pathSplit( winPath ) )
print( "posix pathSplit=", io.pathSplit( posixPath ) )
print( "pathConcat=", io.pathConcat( posixPath, winPath ) )

-- Test file extention functions.
fileName = "lua"
fileNameWithExtention = io.addSuffix( "exe", fileName )
print( "addSuffix=", fileNameWithExtention )
print( "changeSuffix=", io.changeSuffix( "exe", "so", fileNameWithExtention ) )

-- Test the shell function.
print( "shell", io.shell( "dir ." ) )
