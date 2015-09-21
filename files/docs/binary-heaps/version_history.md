#Version history#

##1.5.1 (03/27/2013)
* `heap()` handles an optional arg `item`
* `heap()` now returns in case it wa found empty.

##1.5 (08/27/12)
* Added chaining
* Added <tt>Heap:add()</tt> as alias to <tt>Heap:insert()</tt>
* Buxfix with <tt>Heap:reset()</tt>
* Deleted unused <tt>Heap:init()</tt>
* Code cleaning, Indentation Fixed

##1.4 (08/01/2012)
* Made the current module independant from [LuaClassSystem][]

##1.3 (06/13/2012)
* Name clashing fixed : size() was renamed getSize()

##1.2 (05/28/12)
* Updated third-party library (Lua Class System)
* Added version_history.md

##1.1 (05/25/12)
* Converted to module

##1.0 (05/21/12)
* Heap class and instances now managed with Lua Class System
* Internal class structure modified, items now stored in a private "_heap" field
* Added heap:init(), heap:top(), heap:replace(), heap:heap()

##0.3 (05/14/12)
* Initial Release	

[LuaClassSystem]: https://github.com/Yonaba/Lua-Class-System