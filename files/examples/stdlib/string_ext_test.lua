-- stdlib expected prog table that holds the Lua application 
prog =
{
	name = "string_ext stdlib Example",
	banner = " 0.1 (05/27/2008) by RJP Computing <rjpcomputing@gmail.com>)",
	purpose = "Shows some of the 'string_ext' functions that stdlib includes",
}

require( "string_ext" )
require( "math_ext" )

-- Edgar Allan Poe, The Raven
poem = "Then this ebony bird beguiling my sad fancy into smiling, By the grave and stern decorum of the countenance it wore.\"Though thy crest be shorn and shaven, thou,\" I said, \"art sure nocraven,Ghastly grim and ancient raven wandering from the Nightly shore-Tell me what thy lordly name is on the Night's Plutonian shore!\"Quoth the Raven, \"Nevermore.\"Much I marvelled this ungainly fowl to hear discourse so plainly,Though its answer little meaning- little relevancy bore;For we cannot help agreeing that no living human beingEver yet was blest with seeing bird above his chamber door-Bird or beast upon the sculptured bust above his chamber door,With such name as \"Nevermore.\"But the raven, sitting lonely on the placid bust, spoke onlyThat one word, as if his soul in that one word he did outpour.Nothing further then he uttered- not a feather then he fluttered-Till I scarcely more than muttered, \"other friends have flownbefore-On the morrow he will leave me, as my hopes have flown before.\"Then the bird said, \"Nevermore.\""

-- helper strings
str1 = "Short strings are "
str2 = "easy to work with.\n"

-- Test the index metamethod
print( poem[3] )
-- Test the string concatination
print( str1..str2 )
-- Test the CamelCase function.
print( str1:caps() )
-- Test the chomp removal of newlines function.
print( str2:chomp() )
-- Test the escapePattern function. I think this is used for Lua patterns.
print( string.escapePattern( "This is the (number) 1. A string to that contains a \"double\" 2.0" ) )
-- Test escapeShell function. I think this is used for bash and the like.
print( string.escapeShell( "C:\\Program Files\\Lua\\5.1" ) )
-- Test ordinalSuffix function.
print( "short version of second =", string.ordinalSuffix( 2 ) )
-- Test the pad function.
print( string.pad( poem, -80 ) )
-- Test wrap function.
print( poem:wrap( 80, 2, 4 ) )
-- Test numbertosi function.
print( string.numbertosi( 14300 ) )

