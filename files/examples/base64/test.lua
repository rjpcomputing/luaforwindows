-- test base64 library

require"base64"

print(base64.version)
print""

function test(s)
 local a=base64.encode(s)
 local b=base64.decode(a)
 print(string.len(s),b==s,a,s)
 assert(b==s)
end

for i=0,9 do
 local s=string.sub("Lua-scripting-language",1,i)
 test(s)
end

function test(p)
 print("testing prefix "..string.len(p))
 for i=0,255 do
  local s=p..string.char(i)
  local a=base64.encode(s)
  local b=base64.decode(a)
  assert(b==s,i)
 end
end

print""
test""
test"x"
test"xy"
test"xyz"

print""
s="Lua-scripting-language"
a=base64.encode(s)
b=base64.decode(a)
print(a,b,string.len(b))

a=base64.encode(s)
a=string.gsub(a,"[A-Z]","?")
b=base64.decode(a)
print(a,b)

a=base64.encode(s)
a=string.gsub(a,"[a-z]","?")
b=base64.decode(a)
print(a,b)

a=base64.encode(s)
a=string.gsub(a,"[A-Z]","=")
b=base64.decode(a)
print(a,b,string.len(b))

a=base64.encode(s)
a=string.gsub(a,"[a-z]","=")
b=base64.decode(a)
print(a,b,string.len(b))

print""
print(base64.version)

-- eof
