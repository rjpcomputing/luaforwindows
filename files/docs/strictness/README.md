strictness
===========

[![Build Status](https://travis-ci.org/Yonaba/strictness.png)](https://travis-ci.org/Yonaba/strictness)
[![Coverage Status](https://coveralls.io/repos/Yonaba/strictness/badge.png?branch=master)](https://coveralls.io/r/Yonaba/strictness?branch=master)
[![License](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE)

With the __Lua__ programming language, undeclared variables are not detected until runtime, as Lua will not complain when loading code.
This is releated to the convention that Lua uses : [global by default](http://www.lua.org/pil/1.2.html). In other words, when a variable is not recognized as *local*, it will be
interpreted as a *global* one, and will involve a lookup in the global environment `_G` (for Lua 5.1). Note that this behaviour has been addressed
in Lua 5.2, which strictly speaking has no globals, because of its [lexical scoping](http://www.luafaq.org/#T8.2.1).

*strictness* is a module to track *access and assignment* to undefined variables in your code. It *enforces* to declare globals and modules variables before
assigning them values. As such, it helps having a better control on the scope of variables across the code.

*strictness* is mostly meant to work with Lua [5.1](http://www.lua.org/versions.html#5.1), but it is compatible with Lua [5.2](http://www.lua.org/versions.html#5.2).

##Installation

####Git

    git clone git://github.com/Yonaba/strictness

####Download

* See [releases](https://github.com/Yonaba/strictness/releases)

####LuaRocks

    luarocks install strictness
    
####MoonRocks

    moonrocks install strictness

or 

    luarocks install strictness --server=http://rocks.moonscript.org strictness


## Documentation

See [tutorial.md](doc/tutorial.md).

##Tests

This project has specification tests. To run these tests, execute the following command from the project root folder:

    lua spec/tests.lua

##Similar projects

Feel free to check those alternate implementations, from with *strictness* takes some inspiration:

* [strict.lua](http://rtfc.googlecode.com/svn-history/r2/trunk/lua-5.1/etc/strict.lua) which is included in the official Lua 5.1 distribution,
* [pl.strict](https://github.com/stevedonovan/Penlight/blob/master/lua/pl/strict.lua) which is part of [Penlight](https://github.com/stevedonovan/Penlight),
  
##License
This work is under [MIT-LICENSE](http://www.opensource.org/licenses/mit-license.php)<br/>
*Copyright (c) 2013-2014 Roland Yonaba*.
See [LICENSE](LICENSE).

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/Yonaba/strictness/trend.png)](https://bitdeli.com/free "Bitdeli Badge")