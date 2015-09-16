30log
=====

[![Join the chat at https://gitter.im/Yonaba/30log](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Yonaba/30log?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build Status](https://travis-ci.org/Yonaba/30log.png)](https://travis-ci.org/Yonaba/30log)
[![Coverage Status](https://coveralls.io/repos/Yonaba/30log/badge.png?branch=master)](https://coveralls.io/r/Yonaba/30log?branch=master)
[![License](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE)

__30log__, in extenso *30 Lines Of Goodness* is a minified framework for [object-orientation](http://lua-users.org/wiki/ObjectOrientedProgramming) in Lua.
It features __named (and unnamed) classes__, __single inheritance__ and a basic support for __mixins__.<br/>
It makes __30 lines__. No less, no more.<br/>
__30log__ was written with [Lua 5.1](http://www.lua.org/versions.html#5.1) in mind, but is compatible with [Lua 5.2](http://www.lua.org/versions.html#5.2).


# <a name='TOC'>Table of Contents</a>

* [Download](#download)
* [Adding *30log* to your code](#add30log)
* [Quicktour](#quicktour)
	* [Declaring classes](#declaring)
	* [Creating instances](#instances)
	* [Methods and metamethods](#methods)
	* [Inheritance](#inheritance)
	* [Introspection](#introspection)
	* [Mixins](#mixins)
* [Singleton pattern](#singleton)
* [Class-Commons](#classcommons)
* [Specification](#spec)
* [About the source](#aboutsource)
* [Contributors](#contrib)
* [License](#license)


# <a name='download'>Download</a>

#### Bash

```
git clone git://github.com/Yonaba/30log.git
```

#### Archive

* __zip__: [1.0.0](https://github.com/Yonaba/30log/archive/30log-1.0.0.zip) (*latest stable, recommended*) | [older versions](https://github.com/Yonaba/30log/tags)
* __tar.gz__: [1.0.0](https://github.com/Yonaba/30log/archive/30log-1.0.0.tar.gz) (*latest stable, recommended*) | [older versions](https://github.com/Yonaba/30log/tags)


#### LuaRocks

````
luarocks install 30log
````

####MoonRocks

````
moonrocks install 30log
````

**[[⬆]](#TOC)**

# <a name='add30log'>Adding 30log to your code</a>

Copy the file [30log.lua](https://github.com/Yonaba/30log/blob/master/30log.lua) inside your project folder,
call it using [require](http://pgl.yoyo.org/luai/i/require) function. It will return a local table, keeping safe the global environment.<br/>

**[[⬆]](#TOC)**

# <a name='quicktour'>A quicktour of the library</a>

## <a name='declaring'>Declaring classes</a>

Let us create a `Window` class.

```lua
class = require "30log"
Window = class("Window")
````

That's it. The first argument is the name of the class (defined as string).
Later, we can query that name by indexing the `.name` key. This argument is __optional__.

```lua
print(Window.name) -- "Window"
````

Custom attributes can be added to any class. Here, we can define a "width" and "height" attributes and assign them values.

```lua
Window.width, Window.height = 100,100
````

But we could have also have the same result by passing a table with named keys as a `params` argument when declaring the `Window` class. This argument is also __optional__.

```lua
Window = class("Window", {width = 150, height = 100})
print(Window.width) -- 150
print(Window.height) -- 100
````

When a class has a `.name` attribute, it is considered to be a __named class__. In that case, passing that class to `tostring` or any function that triggers its `__tostring` metamethod returns the following:

```lua
print(Window) -- "class 'Window' (table: 0x0002cdc0)"
````

In case the class has no name, it is considered to be an __unnamed class__. In that case, when passing it to a function like `print` or `tostring`, the output is slightly different.

```lua
Window = class(nil, {width = 150, height = 100}) -- no name argument specified
print(Window.name) -- nil
print(Window.width) -- 150
print(Window.height) -- 100
print(Window) -- "class '?' (table: 0x0002cdb8)"
````

The ability to turn classes to string is mostly meant for debugging purposes. One can change this behavior by modifying the `__tostring` function of any class metatable.

```lua
Window = class('Window')
getmetatable(Window).__tostring = function(t)
  return "I am class "..(t.name or "unnamed")
end
print(Window) -- "I am class Window"
````

**[[⬆]](#TOC)**

## <a name='instances'>Creating instances</a>

### <a name='class:new'>The `class:new()` method</a>

An instance of class is created using the class method `new()`:

```lua
appWindow = Window:new()
````

Once created, an instance can access its class attributes. 

```lua
print(appWindow.width,appWindow.height) -- 100, 100
````

But this instance has its own copy of those attributes. Changing them will affect neither the class itself, nor any other instance.

```lua
-- assigning new values to the instance attributes
appWindow.width, appWindow.height = 720, 480
print(appWindow.width,appWindow.height) -- 720, 480

-- Class attributes are left untouched
print(Window.width, Window.height) -- 100, 100
````

**[[⬆]](#TOC)**

### <a name='class()'>The `class()` call way</a>

An instance can also be created calling the class itself as a function. It is just a syntactic sugar.

```lua
appWindow = Window() -- same as Window:new()
print(appWindow.width,appWindow.height) -- 100, 100
````

**[[⬆]](#TOC)**

### <a name='class:init'>`class:init(...)`</a>

From the two examples above, you might have noticed that once an instance is created from a class, it already shares the properties of his mother class.

Yet, instances can be initialized when creating them from a class. In this way, they already have their attributes set with custom values right after being created.

It just requires to implement a  __class constructor__. Typically, it is a method (a function) that will be called right after `class:new()` method. The class constructor will take as a first argument the `instance` and customize it.<br/>
__30log__ uses the reserved key `init` for __class constructors__.

```lua
Window = class("Window")
function Window:init(width,height)
  self.width,self.height = width,height
end

appWindow = Window:new(800,600) -- or appFrame = Window(800,600)
print(appWindow.width,appWindow.height) -- 800, 600
````

`init` can also be defined as a table with named keys, instead of a function. In that case, any new instance created will get a raw copy of the keys and values found in this table.

```lua
Window = class("Window")
Window.init = { width = 500, height = 500}

appWindow = Window()
print(appFrame.width,appFrame.height) --> 500, 500
````

**[[⬆]](#TOC)**

### <a name='someother'>some other features of instances`</a>

Passing an instance to `print` or `tostring` returns a string representing the instance itself. As for classes, this behavior is meant for debugging. And it can be customized from the user code.

```lua
-- example with a named class
Window = class("Window")
appWindow = Window()
print(appWindow) -- "instance of 'Window' (table: 0x0002cf70)"

-- example with an unnamed class
Window = class()
appWindow = Window()
print(appWindow) -- "instance of '?' (table: 0x0002cf70)"
````

Any instance has an attribute `.class` which points to its class.

```lua
Window = class("Window")
appWindow = Window()
print(appWindow.class) -- "class 'Window' (table: 0x0002cdf8)"
````

Also, *30log* classes are metatables of their own instances. This implies that one can inspect the relationship between a class and its instances via Lua's standard function [getmetatable](http://www.lua.org/manual/5.2/manual.html#pdf-getmetatable).

```lua
local aClass = class()
local someInstance = aClass()
print(getmetatable(someInstance) == aClass) -- true
````

**[[⬆]](#TOC)**

## <a name='methods'>Methods and metamethods</a>
 
Instances have access to their class __methods__.

```lua
Window = class("Window", {width = 100, height = 100})

function Window:init(width,height)
  self.width,self.height = width,height
end

function Window:cap(maxWidth, maxHeight)
  self.width = math.max(self.width, maxWidth)
  self.height = math.max(self.height, maxHeight)
end

appWindow = Window(200, 200)
appWindow:cap(Window.width, Window.height)
print(appWindow.width,appWindow.height) -- 100,100
````

Instances cannot be used to instantiate new objects though. They are not meant for this.

```lua
appWindow = Window:new()
aWindow = appWindow:new() -- Creates an error
aWindow = appWindow()     -- Also creates an error
````

Classes support metamethods as well as methods. Those metamethods are inherited by subclasses.

```lua
function Window:__add(size) 
  self.width = self.width + size
  self.height = self.height + size
  return self
end

local window = Window(600,300)      -- creates a new Window instance
print(window.width, window.height)  -- 600, 300
window = window + 100               -- increases dimensions
print(window.width, window.height)  -- 700, 400
````

**[[⬆]](#TOC)**

## <a name='inheritance'>Inheritance</a>

A subclass can be derived from any other class using a reserved method named `extend`. Similarly to `class`, this method also takes an __optional__ argument `name` and an __optional__ table with named keys `params` as arguments.

The new subclass will inherit its superclass __attributes__ and __methods__.

```lua
Window = class ("Window",{ width = 100, height = 100})
Frame = Window:extend("Frame", { color = "black" })

appFrame = Frame()
print(appFrame.width, appFrame.height, appFrame.color) -- 100,100,"black"
````

Any subclass has a `.super` attribute which points to its superclass.

```lua
print(Frame.super) -- "class 'Window' (table: 0x0002ceb8)"
````

A subclass can __redefine any method__ implemented in its superclass without affecting the superclass method itself.
Also, the subclass *still* has access to his mother class methods and properties via a the `super` key.

```lua
-- A base class "Window"
Window = class ("Window", {x = 10, y = 10, width = 100, height = 100})

function Window:init(x, y, width, height)
  Window.set(self, x, y, width, height)
end

function Window:set(x, y, w, h)
  self.x, self.y, self.width, self.height = x, y, w, h
end

-- a "Frame" subclass
Frame = Window:extend({color = 'black'})
function Frame:init(x, y, width, height, color)
  -- Calling the superclass constructor
  Frame.super.init(self, x, y, width, height)
  
  -- Setting the extra class member
  self.color = color
end

-- Redefining the set() method
function Frame:set(x,y)
  self.x = x - self.width/2
  self.y = y - self.height/2
end

-- An appFrame from "Frame" class
appFrame = Frame(100,100,800,600,'red')
print(appFrame.x,appFrame.y) -- 100, 100

-- Calls the new set() method
appFrame:set(400,400)
print(appFrame.x,appFrame.y) -- 0, 100

-- Calls the old set() method in the mother class "Window"
appFrame.super.set(appFrame,400,300)
print(appFrame.x,appFrame.y) -- 400, 300
````

Also, classes are metatables of their subclasses.

```lua
local aClass = class("aClass")
local someDerivedClass = aClass:extend()
print(getmetatable(someDerivedClass)) -- "class 'aClass' (table: 0x0002cee8)"
````

**[[⬆]](#TOC)**

## <a name='introspection'>Introspection</a>

### <a name='class.isClass'>`class.isClass(class, super)`</a>

`class.isClass` returns true if the only argument given, `class`, is a *30log* class.

```lua
local aClass = class()
local notaClass = {}
print(class.isClass(aClass)) -- true
print(class.isClass(notaClass)) -- false
````

If a second argument `super` is passed, it returns true if and only if `class` is an immediate subclass of `super`.

```lua
local superclass = class()
local subclass = superclass:extend()
print(class.isClass(subclass, superclass)) -- true 
````

**[[⬆]](#TOC)**

### <a name='class.isInstance'>`class.isInstance(instance, class)`</a>

`class.isInstance` returns true if the only argument given, `instance`, is an instance of a *30log* class.

```lua
local aClass = class()
local instance = aClass()
local noinstance = {}
print(class.isInstance(instance)) -- true
print(class.isInstance(noinstance)) -- false
````

If a second argument `class` is passed, it returns true if and only if `instance` is an instance of `class`.

```lua
local aClass = class()
local instance = aClass()
print(class.isInstance(instance, aClass)) -- true 
````

**[[⬆]](#TOC)**

### <a name='class:extends'>`class:extends()`</a>

`class:extends()` returns true if a class derives from a superclass, even if the superclass is not an immediate ancestor.

```lua
local superclass = class()
local subclass = superclass:extend():extend():extend()
print(subclass:extends(superclass)) -- true
````

**[[⬆]](#TOC)**

## <a name='mixins'>Mixins</a>

__30log__ provides a basic support for [mixins](http://en.wikipedia.org/wiki/Mixin). This is a powerful concept that can be used to share the same functionality among different classes even if they are unrelated.

__30log__ assumes a `mixin` to be a table containing a **set of methods** (functions). A mixin is included in a class using `class:include()` method: 

```lua
-- A mixin
Geometry = {
  getArea = function(self) return self.width * self.height end,
}

-- Let us define two unrelated classes
Window = class ("Window", {width = 480, height = 250})
Button = class ("Button", {width = 100, height = 50, onClick = false})

-- Include the "Geometry" mixin
Window:include(Geometry)
Button:include(Geometry)

-- Let us define instances from those classes
local aWindow = Window()
local aButton = Button()

-- Instances can use functionalities brought by the mixin.
print(aWindow:getArea()) -- 120000
print(aButton:getArea()) -- 5000
````

It is possible to check if a class includes a particular mixin using `class:includes()`.

```lua
print(Window:includes(Geometry)) -- true
print(Button:includes(Geometry)) -- true
````

**[[⬆]](#TOC)**

# <a name='singleton'>Singleton pattern</a>

The [singleton pattern](http://en.wikipedia.org/wiki/Singleton_pattern) can be reproduced with *30log*. See the implemention given for reference in the file [singleton.lua](singleton.lua).

**[[⬆]](#TOC)**

# <a name='classcommons'>Class-Commons</a>

[Class-Commons](https://github.com/bartbes/Class-Commons) is an interface that provides a common API for a wide range of object orientation libraries in Lua. There is a small plugin, originally written by [TsT](https://github.com/tst2005) 
which provides compatibility between *30log* and *Class-commons*. <br/>
See here: [30logclasscommons](http://github.com/Yonaba/30logclasscommons).

**[[⬆]](#TOC)**

# <a name='spec'>Specification</a>

You can run the included specs with [Telescope](https://github.com/norman/telescope) using the following command from Lua from the root foolder:

```
lua tsc -f specs/*
```

**[[⬆]](#TOC)**

# <a name='aboutsource'>About the source</a>

####30logclean.lua
*30log* was initially designed for minimalistic purposes. But then commit after commit, I came up with a source code that was obviously surpassing 30 lines. As I wanted to stick to the "30-lines" rule that defines the name of this library, I had to use an ugly syntax which not much elegant, yet 100 % functional.<br/>
For those who might be interested though, the file [30logclean.lua](http://github.com/Yonaba/30log/blob/master/30logclean.lua) contains the full source code, properly formatted and well indented for your perusal.

####30logglobal.lua
The file [30logglobal.lua](http://github.com/Yonaba/30log/blob/master/30logglobal.lua) features the exact same source as the original [30log.lua](http://github.com/Yonaba/30log/blob/master/30log.lua), 
excepts that it sets a global named `class`. This is convenient for Lua-based frameworks such as [Codea](http://twolivesleft.com/Codea/).

####Benchmark
Performance tests featuring classes creation, instantiation and such have been included. You can run these tests with the following command with Lua from the root folder, passing to the test script the actual implementation to be tested.

````
lua performance/test.lua 30log
````

Find [here an example of output](https://github.com/Yonaba/30log/tree/master/performance/results.md) for the latest version of *30log*.

**[[⬆]](#TOC)**

# <a name='contrib'>Contributors</a>

* [TsT2005](https://github.com/tst2005), for the original Class-commons support.


**[[⬆]](#TOC)**

# <a name='license'>License</a>

This work is under [MIT-LICENSE](http://www.opensource.org/licenses/mit-license.php)<br/>
Copyright (c) 2012-2015 Roland Yonaba

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/Yonaba/30log/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

**[[⬆]](#TOC)**