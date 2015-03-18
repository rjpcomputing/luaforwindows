MI Lua classes

Current version: 2.03, Feb. 6, 2007

Files:

	classlib.html           The manual.
	classlib.lua            The library. Load with require 'classlib'.
	unclasslib.lua          A version that only supports unnamed classes.

	Simple examples:

	single.lua              Single inheritance, unnamed classes.
	multiple.lua            Multiple inheritance, unnamed classes.
	nsingle.lua             Single inheritance, named classes.
	nmultiple.lua           Multiple inheritance, named classes.
	account.lua             Multiple inheritance, named classes.

	tuple.lua		A tuple class with indexing.
	set.lua			A set class with metamethods.

Notes:

If keep_ambiguous = true is defined before loading the library, ambiguous symbols are not deleted from classes and objects but left there with a special value. This might be useful for debugging and/or understanding how derivation handles ambiguity.

Unclasslib.lua is a version of classlib.lua that only supports unnamed classes. It should be a little bit more efficient since it eliminates one redundant indexing level when accessing base objects.
