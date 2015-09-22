Delaunay
=====

[![Build Status](https://travis-ci.org/Yonaba/delaunay.png)](https://travis-ci.org/Yonaba/delaunay)
[![Coverage Status](https://coveralls.io/repos/Yonaba/delaunay/badge.png?branch=master)](https://coveralls.io/r/Yonaba/delaunay?branch=master)
[![License](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE)

*delaunay* is a Lua module for [delaunay triangulation](http://en.wikipedia.org/wiki/Delaunay_triangulation) of a convex polygon.

##Download

###Git

````
git clone http://github.com/Yonaba/delaunay.git
````

###Archive

* [zip](https://github.com/Yonaba/delaunay/archive/delaunay-0.1-1.zip) | [tar.gz](https://github.com/Yonaba/delaunay/archive/delaunay-0.1-1.tar.gz) | [all](http://github.com/Yonaba/delaunay/tags)

###LuaRocks

````
luarocks install delaunay
````

###MoonRocks

````
luarocks install --server=http://rocks.moonscript.org/manifests/Yonaba delaunay
````

##Installation
Copy the file [delaunay.lua](http://raw.github.com/Yonaba/delaunay/master/delaunay.lua) inside your project folder,
call it with [require](http://pgl.yoyo.org/luai/i/require) function. It will return the `Delaunay` module, keeping safe the global environment.<br/>

##Usage

The module provides 3 classes: <br/> 
* `Point`
* `Edge`
* `Triangle`

It also provides a single function named `triangulate`. This function accepts
a variable list (*vararg* `...`) of instances of class `Point`. Assuming those 
points are the vertices of a convex polygon, it returns a table of instances of the class `Triangle` forming a *Delaunay triangulation* of the given polygon.

A basic code example:
```lua
local Delaunay = require 'Delaunay'
local Point    = Delaunay.Point

-- Creating 10 random points
local points = {}
for i = 1, 10 do
  points[i] = Point(math.random() * 100, math.random() * 100)
end

-- Triangulating de convex polygon made by those points
local triangles = Delaunay.triangulate(unpack(points))

-- Printing the results
for i, triangle in ipairs(triangles) do
  print(triangle)
end
````

See the [documentation](http://yonaba.github.io/delaunay/doc) for more details.

##Testing
###Specification

This repository include unit tests. You can run them using [Telescope](https://github.com/norman/telescope) with the following command from the root foolder:

```
lua tsc -f specs/*
```

###Performance

You can run the random performance tests included with the following command from the root folder:

```lua
lua performance/bench.lua
````

##License
This work is under [MIT-LICENSE](http://www.opensource.org/licenses/mit-license.php).<br/>
Copyright (c) 2013 Roland Yonaba

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

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/Yonaba/delaunay/trend.png)](https://bitdeli.com/free "Bitdeli Badge")