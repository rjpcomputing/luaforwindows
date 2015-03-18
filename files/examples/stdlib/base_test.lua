-- stdlib expected prog table that holds the Lua application 
prog =
{
	name = "base stdlib Example",
	banner = " 0.1 (05/27/2008) by RJP Computing <rjpcomputing@gmail.com>)",
	purpose = "Shows some of the 'base' functions that stdlib includes",
}

nestedTable = 
{
	hi = "there",
	"I",
	"see",
	"you",
	{
		"another",
		"table",
		what = "A nested table"
	}
}
print( "old style 'print()' " )
print( nestedTable )

require( "base" )
print( "stdlib version of 'print()'" )
print( nestedTable )


print( "prettytostring of table" )
print( prettytostring( nestedTable ) )

require( "io_ext" ) -- Needed by warn()
warn( "some warning:%i", 101 )