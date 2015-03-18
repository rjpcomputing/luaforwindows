Extended LuaInterface Examples

These scripts show how to access the .NET framework using Lua.

The filenames correspond to the examples mentioned in the Guide;
see ..\..\docs\LuaInterface\LuaInterface.html.

The scripts ending in .lua are command-line scripts showing how
to access .NET classes, both with the raw luanet calls and 
with the simplified approach offered by CLRPackage.

The .wlua scripts are GUI examples using System Windows Forms.
They demonstrate the powerful functionality provided by the
CLRForm module, including auto-generated dialogs and easy
menu construction.

lconsole.wlua is an interactive GUI-friendly Lua prompt for 
experimenting with LuaInterface. It also illustrates how a
custom assembly can be brought in to solve problems that 
currently cannot be done in pure Lua. (In particular, TextBox.dll
overrides the key handling of a standard rich text control so
that the up and down keys can be used to access command history.)

