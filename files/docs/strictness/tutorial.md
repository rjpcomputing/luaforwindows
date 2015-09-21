strictness tutorial
===================

# <a name='TOC'>Table of Contents</a>

* [What is *strictness* ?](#what)
* [Tutorial](#tuto)
  * [Adding *strictness* to your project](#adding)
  * [The *strictness* module](#module)
     * [Strict tables](#stricttables)
     * [Non-strict tables](#unstricttables)
     * [Checking strictness](#checking)
     * [Strict functions](#strictf)
     * [Non-strict functions](#unstrictf)
     * [Combo functions](#combo)
* [License](#license)

# <a name='what'>What is *strictness* ?</a>

*strictness* is a Lua module for tracking accesses and assignements to indefined variables in Lua code. It is actually known that [undefined variables](http://lua-users.org/wiki/DetectingUndefinedVariables) and global variables as well can be very problematic especially when working on large projects and maintaining code that spans across several files.

*strictness* aims to address this problem by providing a solution similar to [strict structs](http://lua-users.org/wiki/StrictStructs), so that accessing undefined fields will always throw an error. 

**[[⬆]](#TOC)**

# <a name='tuto'>Tutorial</a>

##  <a name='adding'>Adding *strictness* to your project</a>

Place the file [strictness.lua](strictness.lua) in your Lua project and call it with [require](http://pgl.yoyo.org/luai/i/require). *strictness* does not write anything in the global (or the current) environnement. It rather returns a local module of functions.

```lua
local strictness = require "strictness"
````

**[[⬆]](#TOC)**

##  <a name='module'>The *strictness* module</a>

### <a name='stricttables'>Strict tables</a>

*strictness* provides the function `strictness.strict` that patches a given table, so that we can no longer access to undefined keys in this table.
Let us apply appy this on the global environnement:

```lua
strictness.strict(_G)
print(x) --> this line produces an error
````

The statement `print(x)`produces the following error:

````
...\test.lua:2: Attempt to access undeclared variable "x" in <table: 0x00321328>.
```

To avoid this, we now have to __declare explitely__ our globals. Assigning `nil` will do:

```lua
strictness.strict(_G)
x = nil
print(x) --> nil
x = 3
print(x) --> 3
````

A table can be made strict with allowed varnames.

```lua
strictness.strict(_G, 'x', 'y', 'z') -- "varnames x, y and z are allowed"
print(x, y, z) --> nil, nil, nil
x, y, z = 1, 2, 3
print(x, y, z) --> 1, 2, 3
````

Also, in case nothing is passed to `strictness.strict`, it will return a new table:

```lua
local t = strictness.strict()
print(t.k) --> produces an error
t.k = nil  --> declare a field "k"
print(t.k) --> nil
````

`strictness.strict` preserves the metatable of the passed-in table.

```lua
local t = setmetatable({}, {
    __call = function() return 'call' end,
    __tostring = function() return t.name end
})
t.name = 'table t'
strictness.strict(t)
print(t()) --> "call"
print(t) --> "table t"
````

In case a table was already made strict, passing it again to `strictness.strict` will raise an error:

```lua
local t = {}
strictness.strict(t)
strictness.strict(t) --> this will produce an error
````

````
...\test.lua:3: <table: 0x0032c110> was already made strict.
````

**[[⬆]](#TOC)**

### <a name='unstricttables'>Non-Strict (or normal) tables</a>

A strict table can be converted back to a normal one via `strictness.unstrict`:

```lua
local t = strictness.strict()
strictness.unstrict(t)
t.k = 5
print(t.k) --> 5
````

**[[⬆]](#TOC)**

### <a name='checking'>Checking strictness</a>

`strictness.is_strict` checks if a given table was patched via `strictness.strict`:

```lua
local strict_table = strictness.strict()
local normal_table = {}

print(strictness.is_strict(strict_table)) --> true
print(strictness.is_strict(normal_table)) --> false
````

**[[⬆]](#TOC)**

### <a name='strictf'>Strict functions</a>

`strictness.strictf` returns a wrapper function that runs the original function in strict mode. The returned function is not allowed to write or access undefined fields in its environment. Let us draw an example:

```lua
local env = {}  -- a blank environment for our functions

-- A function that writes a varname and assigns it a value 
local function normal_f(varname, value)
  env[varname] = value
end
-- Convert the original function to a strict one
local strict_f = strictness.strictf(normal_f)

-- set environments for functions
setfenv(normal_f, env)
setfenv(strict_f, env)

-- Call the normal function, no error
normal_f("var1", "hello")
print(env.var1) --> "hello"


strict_f("var2", "hello") --> produces an error 
````

````
...\test.lua:5: Attempt to assign value to an undeclared variable "var2" in <table: 0x0032c440>.
````

Notice that here, the strict function always run in strict mode whether its environment is strict or not.

**[[⬆]](#TOC)**

### <a name='unstrictf'>Non-strict functions</a>

Similarly, `strictness.unstrictf` creates a wrapper function that runs in non-strict mode in its environment. In other terms, the returned function is allowed to access and assign values in its environments, whether or not this environment is strict.

```lua
local env = strictness.strict()  -- a blank and strict environment for our functions

-- A function that assigns a value to a variable named "some_var"
local function normal_f(value)  
  some_var = value  
end

-- Converts the original function to a non-strict one
local unstrict_f = strictness.unstrictf(normal_f)

-- set environments for functions
setfenv(normal_f, env)
setfenv(unstrict_f, env)

-- Call the normal function, it should err because its env is strict
normal_f("hello") --> produces an error

-- Call the non-strict function, no error
unstrict_f("hello")
print(env.some_var) --> "hello
````

Here is an example with Lua 5.2:

```lua
local new_env = {print = print} --  a new env
do
  local _ENV = strictness.strict(new_env) -- sets a new strict env for the do..end scope
  local function normal_f(value) some_var = value end -- our normal function
  normal_f(5) --> produces an error, since normal_f cannot write in the strict _ENV
end
````

```lua
local new_env = {print = print} --  a new env
do
  local _ENV = strictness.strict(new_env) -- sets a new strict env for the do..end scope
  local function normal_f(value) some_var = value end -- our normal function
  local unstrict_f = strictness.unstrictf(normal_f) -- the non-strict version of our normal function 
  unstrict_f(5) -- no longer produces error
  print(some_var) --> 5
end
````

**[[⬆]](#TOC)**

### <a name='combo'>Combo functions</a>

*strictness* also provides two combo functions, `strictness.run_strict` and `strictness.run_unstrict`. Those functions takes a function `f` plus an optional vararg `...` and return the result of the call `f(...)` in strict and non-strict mode respectively.
Syntactically speaking, `strictnes.run_strict` is the equivalent to this:

```lua
local strict_f = strictness.strictf(f)
strict_f(...)
````

While `strictness.run_unstrict` is a short for:

```lua
local unstrict_f = strictness.unstrictf(f)
unstrict_f(...)
````

Here is an example for `strictness.run_strict`:

```lua
local strictness = require 'strictness'

local env = {}  -- an environment

-- A function that assigns a value to a variable named "some_var"
local function normal_f(value)  some_var = value  end

setfenv(normal_f, env) -- defines an env for normal_f
strictness.run_strict(normal_f, 3) --> produces an error
````

And another example with `strictness.run_unstrict``:

```lua
local strictness = require 'strictness'

local env = strictness.strict()  -- a strict environment

-- A function that assigns a value to a variable named "some_var"
local function normal_f(value)  some_var = value  end

setfenv(normal_f, env) -- defines an env for normal_f
strictness.run_unstrict`(normal_f, 3) -- no error!
print(env.some_var, some_var) --> 3, nil
````

**[[⬆]](#TOC)**

# <a name='license'>LICENSE</a>

This work is under [MIT-LICENSE](http://www.opensource.org/licenses/mit-license.php)<br/>
*Copyright (c) 2013-2014 Roland Yonaba*.<br/>
See [LICENSE](http://github.com/Yonaba/strictness/blob/master/LICENSE).

**[[⬆]](#TOC)**