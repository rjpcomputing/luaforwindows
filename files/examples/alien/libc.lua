
require "alien"

local libc = alien.default

libc.malloc:types("pointer", "int")
libc.free:types("void", "pointer")
libc.strcpy:types("void", "pointer", "string")
libc.strcat:types("void", "pointer", "string")
libc.puts:types("void", "string")

local foo = libc.malloc(string.len("foo") + string.len("bar") + 1)
libc.strcpy(foo, "foo")
libc.strcat(foo, "bar")
libc.puts(foo)
libc.strcpy(foo, "bar")
libc.puts(foo)
libc.puts("Yeah!")
libc.free(foo)
