wxLua readme.txt

-------------------------------------------------------------------------------
wxLua is a lua scripting language wrapper around the wxWidgets cross-platform
GUI library. It consists of an executable for running standalone wxLua scripts
and a library for extending C++ programs with a fast, small, fully embeddable
scripting language.

References:
http://wxlua.sourceforge.net
http://www.lua.org
http://www.wxwidgets.org

-------------------------------------------------------------------------------
The wxLua "big picture"

Lua is an ANSI C compatible scripting language that can load and run
interpreted scripts as either files or strings. The language itself is very
dynamic and contains a limited number of data types, mainly numbers, strings,
and tables. Perhaps the most powerful feature of the lua language is that the
tables can be used as either arrays or as hashtables that can contain numbers,
strings, and/or subtables.

wxLua adds to this small and elegant language the power of the wxWidgets
cross-platform GUI library. This incudes the ability to create complex user
interface dialogs, image manipulation, file manipulation, sockets, displaying
HTML, and printing to name a few.
