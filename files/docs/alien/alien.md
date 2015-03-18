Alien - Pure Lua extensions
===========================

Status
------

This is Alien version 0.5.0.

Changelog
---------

* 0.5.0
  * new functions alien.memcpy and alien.memset
  * new type "p" for alien.struct.pack and unpack, to pack pointers
  * new alien.struct.offset function to get the offset of a given record
  * buf:tostring now has optional "offset" argument
  * buf:topointer now has optional "offset" argument
  * added unsigned numbers: uint, ulong, ushort, and "ref uint"
  * basic support for declarative strucutures
  * unified treatment of funcitons and callbacks in the source
  * fixed segfault when collecting 0-arg functions
* 0.4.1
  * fixes bug where Alien was always using cdecl abi for Windows (except in callbacks)
  * fixes build on PPC OSX.
* 0.4.0
  * Windows support - stdcall ABI, including stdcall callbacks
  * alternative syntax for defining types
  * mutable buffers, wrapping lightuserdata in a buffer
  * alien.to*type* functions take optional length argument
  * callbacks are callable from Lua
  * alien.funcptr turns a function pointer into an alien function
  * improved library finding on Linux/FreeBSD, using ldconfig
  * alien.table utility function (wrapper for lua_createtable, useful for extensions)
  * alien.align utility function to get data structure alignment
  * arrays built on mutable buffers, with bounds checking
  * fixed a build bug on Linux ARM
* 0.3.2 - fixes callback bug on NX-bit platforms
* 0.3.1 - initial release with libffi
* 0.3 - retracted due to license conflict

What is Alien
-------------

*Alien* is a Foreign Function Interface (FFI) for Lua. An FFI lets you
call functions in dynamic libraries (.so, .dylib, .dll, etc.) from Lua
code without having to write, compile and link a C binding from the
library to Lua. In other words, it lets you write extensions that call
out to native code using just Lua.

Be careful when you use Alien, I tried to make it as safe as possible,
but it is still very easy to crash Lua if you make a mistake. Alien
itself is not as robust as a standard Lua extension, but you can use
it to write extensions that won't crash if you code them well.

Alien works on Unix-based systems and Windows. It has been tested on Linux x86, 
Linux x64, Linux ARM, FreeBSD x86, Windows x86, OSX x86, and OSX PPC. The Windows
binary uses MSVCR80.DLL for compatibility with LuaBinaries.

Installing Alien
----------------

The best way to install Alien is through
[LuaRocks](http://luarocks.org). Just do `luarocks install alien`. You may need
root permissions to do this, depending on your LuaRocks configuration.

Go to the Alien rock directory to see local copies of this
documentation, as well as the test suite. If you are in the path of
the test suite (`tests`) you can run the suite with:

    lua -l luarocks.require test_alien.lua

If everything is ok you should see no output.

Alien installs to modules, `alien` and `alien.struct`. The latter is a
slightly modified version of Roberto Ierusalimschy's [struct
library](http://www.inf.puc-rio.br/~roberto/struct) that can unpack
binary blobs (userdata) instead of just strings.

Basic Usage
-----------

Loading a dynamic library is very simple; Alien by default assumes a
naming scheme of lib*name*.dylib for OSX and lib*name*.so for other
Unix systems. If *name* is not one of the
functions the `alien` module exports then you can get a reference to
the library with `alien.`*`name`*. Otherwise (for example, to load a
library called *libwrap.so*) you have to use `alien.load("wrap")`.

You can also specify the full name of the library by calling
`alien.load` with a path or with the appropriate extension, such as
`alien.load("mylibs/libfoo.so")` or `alien.load("libfoo.so")`. 
Either way you get back a reference
to the library that you will use to access its functions.

You can also get a reference to the currently running module using
`alien.default`, this lets you get references to any function exported
by the module and its transitive dependencies on ELF and Mach-O systems.

Once you have a reference to a library you can get a reference to an
exported function with *libref.funcname*. For example:

    > def=alien.default
    > =def.puts
    alien function puts, library defaults
    >

To use a function you first have to tell Alien the function prototype,
using *func:types(ret_type, arg_types...)*, where the types are one of
the following strings: "void", "int", "uint", "double", "char", "string",
"pointer", "ref int", "ref uint", "ref double", "ref char", "callback", "short", "ushort",
"byte", "long", "ulong", and "float". Most correspond directly to C types;
*byte* is a signed char, *string* is *const char\**, *pointer* is *void\**,
*callback* is a generic function pointer, and *ref char*, *ref int*
and *ref double* are by reference versions of the C types. Continuing
the previous example:

    > def.puts:types("int", "string")
    > def.puts("foo")
    foo
    >

As you can see, after defining the prototype you can call the function
just as a Lua function. Alien converts Lua numbers to the C numeric
types, converts *nil* to *NULL* and Lua strings to *const char\** for
*string*, and converts *nil* to *NULL* and userdata to *void\** for
*pointer*. The conversions work in reverse for the return value (with
the *pointer* type converted to a light userdata).

By reference types are special; Alien allocates space on the stack for
the argument, copies the Lua number you passed to it (converting
appropriately), then calling the function with the address of this
space. Then the value is converted back to a Lua number and returned
after the function normal return value. An example, using *scanf*:

    > scanf = alien.default.scanf
    > scanf:types("int", "string", "ref int", "ref double")
    > _, x, y = scanf("%i %lf", 0, 0)
    23 42.5
    > =x
    23
    > =y
    42.5

You have to pass a value even if the function does not use it, as you
can see above.

Another way to specify types is by passing a table to *func:types*. The array
part of this table shoudl have one item for each parameter, and you can also pass
two hash keys, *ret*, the function's return type (defaults to `int` as usual), and
*abi*, the function's calling convention (useful for Windows, where you can specify "stdcall" as the
ABI for `__stdcall` functions. The default ABI is always "default", and all systems
also support "cdecl", the usual C calling convention. On systems that don't have the
stdcall convention "stdcall" is the same as "default".

This is the previous example using this alternate definition:

    > scanf = alien.default.scanf
    > scanf:types{ ret = "int", "string", "ref int", "ref double" }
    > _, x, y = scanf("%i %lf", 0, 0)
    23 42.5
    > =x
    23
    > =y
    42.5

If you get raw function pointer (returned from a function, for example, or 
passed to a callback), you can turn it into an Alien function with `alien.funcptr(fptr)`.
This returns an Alien function object that you can type and call function normally.

Buffers
-------

The basic usage is enough to do a lot of interfacing with C code,
specially with well-behaved libraries that handle their own memory
allocation (the Lua C API is a good example of such an API). But there
are libraries that do not export such a well-behaved API, and require
you to allocate memory that is mutated by the library. This prevents
you from passing Lua strings to them, as Lua strings have to be
immutable, so Alien provides a *buffer* abstraction. The function
`alien.buffer` allocates a new buffer. If you call it with no
arguments it will allocate a buffer with the standard buffer size for
your platform. If call it with a number it will allocate a buffer with
this number of bytes. If you pass it a string it will allocate a
buffer that is a copy of the string. If you pass a light userdata
it will use this userdata as the buffer (be careful with that).

After making a buffer you can pass it in place of any argument of
*string* or *pointer* type. To get back the contents of the buffer you
use `buf:tostring`, and again you can either pass the number of
characters to read from the buffer or don't pass anything, which treat
the buffer as a C string (read until finding a *\0*). You can also
call `buf:len`, which calls *strlen* on the buffer. Finally,
`tostring(buf)` is the same as `buf:tostring()`.

An example of how to use a buffer:

    > gets = alien.default.gets
    > gets:types("pointer", "string")
    > buf = alien.buffer()
    > gets(buf)
    Foo bar
    > =tostring(buf)
    Foo bar
    >

You can access the i-th character of a buffer with `buf[i]`, and you can
set its value with `buf[i] = v`. Notice that these are C characters (bytes),
not Lua 1-character strings, so you need to use `string.char` and `string.byte`
to convert between Lua characters and C characters. **Access to Alien buffers 
from Lua is 1-based instead of 0-based**.

You can also get and set other values by using *buf:get(offset, type)*, and
set it by *buf:set(offset, val, type)*. The offset is in bytes, *not* in elements, so
if *buf* has three "int" values their offsets are 1, 5 and 9, respectively, assuming
each "int" is four bytes long.

All get and set operations do no bounds-checking, so be extra careful, or use the
safer alien.array abstraction that is built on top of buffers.

Arrays
------

Arrays are buffers with an extra layer of safety and sugar on top. You create an array
with `alien.array(type, length)`, where *type* is the Alien type of the array's elements,
and length is how many elements the array has. After creating an array *arr* you can get the
type of its elements with *arr.type*, how many elements it has with *arr.length*, and the
size (in bytes) of each element with *arr.size*. The underlying buffer is *arr.buffer*.

You can access the i-th element with *arr[i]*, and set it with *arr[i] = val*. Type 
conversions are the same as with buffers, or function calls. Storing a string or userdata
in an array pins it so it won't be collected while it is in the array.

For convenience `alien.array` also accepts two other forms: `alien.array(type, tab)` creates
an array with the same length as *tab* and initializes it with its values; 
`alien.array(type, length, buf)` creates an array with *buf* as the underlying buffer. You can
also iterate over the array's contents with `arr:ipairs()`.

The following example shows an use of arrays:

    local function sort(a, b)
      return a - b
    end
    local compare = alien.callback(sort, "int", "ref int", "ref int")
    
    local qsort = alien.default.qsort
    qsort:types("void", "pointer", "int", "int", "callback")
    
    local nums = alien.array(t, { 4, 5, 3, 2, 6, 1 })
    qsort(nums.buffer, nums.length, nums.size, compare)
    for i, v in nums:ipairs() do print(v) end

This prints numbers one to six on the console.

Structs
-------

Alien also has basic support for declarative structs that is also implemented as a layer of sugar
on the basic buffers. The `alien.defstruct(description)` function creates a struct type with the
given description, which is a list of pairs with the name and type of each field, where the type is any
basic alien type (no structs inside structs yet). For example:

    rect = alien.defstruct{
      { "left", "long" },
      { "top", "long" },
      { "right", "long" },
      { "bottom", "long" }
    }

This creates a new struct type with four fields of type "long", and stores it in `rect`. To create an
instance of this structure (backed by a buffer) call `rect:new()`. You can then set the fields of the
struct just like you do on a Lua table, like `r.left = 3`. To get the underlying buffer (to pass it
to a C function, for example) you have to call the instance, `r()`. Continuing the example:

    r = rect:new()
    r.left = 2
    doubleleft = alien.rectdll.double_left
    doubleleft:types("void", "pointer")
    doubleleft(r()))
    assert(r.left == 4)

You can also pass a buffer or other userdata to the `new` method of your struct type, and in this case this will
be the backing store of the struct instance you are creating. This is useful for unpacking a foreign struct that
a C function returned.

Pointer Unpacking
-----------------

Alien also provides three convenience functions that let you
dereference a pointer and convert the value to a Lua type:

* `alien.tostring` takes a userdata (usually returned from a function
  that has a *pointer* return value), casts it to *char\**, and
  returns a Lua string. You can supply an optional size argument (if 
  you don't Alien calls *strlen* on the buffer first).
* `alien.toint` takes a userdata, casts it to *int\**,
  dereferences it and returns it as a number. If you pass it a number
  it assumes the userdata is an array with this number of elements.
* `alien.toshort`, `alien.tolong`, `alien.tofloat`, and
  `alien.todouble` are like `alien.toint`, but works with
  with the respective typecasts. Unsigned versions are also available.

The numeric alien.to*type* functions take an optional second argument that
tells how many items to unpack from the userdata. For example, if ptr is
a pointer to an array of four floats, the following code unpacks this array:

    > fs = alien.tofloat(ptr, 4)
    > =#fs
    4
    >

Use these functions with extra care, they don't make any safety
checks. For more advanced unmarshaling use the `alien.struct.unpack`
function.

Tags
----

A common pattern when wrapping objects from C libraries is to put a
pointer to this object inside a full userdata, then associate this userdata
with a metatable that is associated with a string tag. This tag is
used to check if the userdata is a valid userdata in each function
that uses it. As the userdata is a full userdata it also can have a
`__gc` metamethod for resource reclamation.

Alien has three functions that let you replicate this pattern on your
extensions:

* `alien.tag(*tagname*)` creates a new metatable with tag *tagname* if one
  does not exist, or returns the metatable with this tag. The
  namespace for tags is global, so a good pattern is to prefix the tag
  name with the name of your module (such as *mymod_mytag*).
* `alien.wrap(*tagname*, ...)` creates a full userdata, tags it with
  the metatable associated with *tagname*, stores the values
  you passed, then returns the full userdata. Valid values are *nil*, 
  integers and other userdata.
* `alien.unwrap(*tagname*, obj)` tests if *obj* is tagged with
  *tagname*, throwing an error if it is not, then returns the values
  previously stored in it.
* `alien.rewrap(*tagname*, obj, ...)` replaces the elements on *obj* with
  new values. If you pass more values than *obj* had previously the extra
  values are silently ignored. If you pass less tehn *obj* is filled with
  *nil*.

For example, suppose *libfoo* has a `create_foo` function that returns
a `Foo*` object. These objects have to be properly disposed by calling
`destroy_foo` when they are not used anymore. This is easy to
implement:

    local tag_foo = alien.tag("libfoo_foo")
    alien.foo.create_foo:types("pointer")
    alien.foo.destroy_foo_types("void", "pointer")    

    function new_foo()
      local foo = alien.foo.create_foo()
      return alien.wrap("libfoo_foo", foo)
    end
    
    tag_foo = {
      __gc = function (obj)
               local foo = alien.unwrap("libfoo_foo", obj)
               alien.foo.destroy_foo(foo)
             end
    }

Then on any function that operates on `Foo*` types you first unwrap to
get the pointer, then pass it to the function in *libfoo*.

Error Codes
-----------

Several operating system functions return errors on a special variable
called *errno*. To get the value of *errno* with Alien call
`alien.errno()`.

Callbacks
---------

Some libraries have functions that take *callbacks*, functions that
get called by the library. Most GUI libraries use callbacks, but even
the C library has *qsort*. Alien lets you create a callback from a Lua
function with `alien.callback`. You pass the function and the callback
prototype that the library expects. Alien will return a callback
object that you can pass in any argument of *callback* type. A simple
example, using *qsort*:

    local function cmp(a, b)
      return a - b
    end
    local cmp_cb = alien.callback(sort, "int", "ref char", "ref char")
    
    local qsort = alien.default.qsort
    qsort:types("void", "pointer", "int", "int", "callback")
    
    local chars = alien.buffer("spam, spam, and spam")
    qsort(chars, chars:len(), alien.sizeof("char"), cmp_cb)
    assert(chars:tostring() == "   ,,aaaadmmmnpppsss")

The *qsort* function sorts an array in-place, so we have to use a
buffer.

Callbacks are callable from Lua just like any other Alien function, and you can freely
change their types with their "types" method.

Magic Numbers
-------------

C libraries are full of symbolic constants that are in truth magic
numbers, as they are replaced by the preprocessor before even the C
compiler has a chance to see them. This means that all these constants
are on header files. This also includes things such as the layout and
size of strucutres the library depends on. All this information can
change from version to version of the library, or from platform to
platform.

Alien provides a utility script called *constants* that makes it
easier to work with these numbers. This utility takes three arguments
on the command line: a *definitions file*, the name of the C file you
want it to generate, and the name of a Lua file that the C file will
generate when compiled and run. The definitions file can contain
preprocessor directives, blank lines, and lines with definitions
either of the form *identifier* or *lua_identifier* = *c_identifier*. The first
form is equivalent to *identifier* = *identifier*. It is best to
explain by example (from a libevent binding):

    #include <sys/types.h>
    #include <event.h>
    
    EV_SIZE = sizeof(struct event)
    EV_READ
    EV_WRITE
    EV_TIMEOUT
    EVLOOP_NONBLOCK
    EVLOOP_ONCE

Lines with preprocessor directives are copied verbatim to the C file
*constants generates*. The above definitions file generates this C
file:

    /* Generated by Alien constants */
    
    #include <stdio.h>
    
    #include <sys/types.h>
    #include <event.h>
    #define LUA_FILE "event_constants.lua"
    int main() {
      FILE *f = fopen(LUA_FILE, "w+");
      fprintf(f, "-- Generated by Alien constants\n\n");
      fprintf(f, "%s = %i\n", "EV_SIZE ",  sizeof(struct event));
      fprintf(f, "%s = %i\n", "EV_READ", EV_READ);
      fprintf(f, "%s = %i\n", "EV_WRITE", EV_WRITE);
      fprintf(f, "%s = %i\n", "EV_TIMEOUT", EV_TIMEOUT);
      fprintf(f, "%s = %i\n", "EVLOOP_NONBLOCK", EVLOOP_NONBLOCK);
      fprintf(f, "%s = %i\n", "EVLOOP_ONCE", EVLOOP_ONCE);
      fclose(f);
    }

Which, when compile and run, generates this file on a Linux/Intel
system:

    -- Generated by Alien constants
    
    EV_SIZE  = 84
    EV_READ = 2
    EV_WRITE = 4
    EV_TIMEOUT = 1
    EVLOOP_NONBLOCK = 2
    EVLOOP_ONCE = 1

These steps (generating the C file, compiling, generating the Lua
file) are best done in the build step of your extension.

Miscellanea
-----------

You can query what platform your extension is running on with
`alien.platform`. Right now this can be either "unix" or "osx". Other
platforms will be added as they are tested. You can use this
information for conditional execution in your extensions.

You can get the sizes of the types Alien supports using
`alien.sizeof(*typename*)`, as the *qsort* example in the Callbacks
section shows. You can also get strucutre aligment information
with `alien.align(*typename*)`.

Several extensions may need to create Lua tables with preallocated
array and/or hash parts, for performance reasons (implementing a circular queue, for
example). Alien exposes the `lua_createtable` function as `alien.table(narray, nhash)`.

Credits
-------

Alien is designed and implemented by Fabio Mascarenhas. It uses the
great [libffi](http://sources.redhat.com/libffi)
library by Anthony Green (and others) to do the heavy lifting of calling to and from C. The
name is stolen from Common Lisp FFIs.

License
-------

Alien's uses the MIT license, reproduced below:

Copyright (c) 2008-2009 Fabio Mascarenhas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
