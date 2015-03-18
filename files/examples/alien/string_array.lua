require "luarocks.require"
require "alien"

local glib = alien.load("/usr/lib/libglib-2.0.so.0")
local v,p,i,s = "void","pointer","int","string"

glib.g_strsplit:types(p,s,s,i) -- string to array
glib.g_strjoinv:types(s,s,p) -- array to string
glib.g_strv_length:types(i,p) -- length of array
glib.g_strfreev:types(v,p) -- free array


local delim = "\n"

local strings = {"foo", "bar", "baz"}

local lines=table.concat(strings, delim)
local strv=glib.g_strsplit(lines,delim,0)
print("length:", glib.g_strv_length(strv))

local result=glib.g_strjoinv(delim,strv)

glib.g_strfreev(strv);

print(result)
