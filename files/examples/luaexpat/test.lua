#!/usr/local/bin/lua5.1
-- See Copyright Notice in license.html
-- $Id: test.lua,v 1.6 2006/06/08 20:34:52 tomas Exp $

require"lxp"
print (lxp._VERSION)

-- basic test with no preamble
local p = lxp.new{}
p:setencoding("ISO-8859-1")
assert(p:parse[[<tag cap="5">hi</tag>]])
p:close()


preamble = [[
<?xml version="1.0" encoding="ISO-8859-1"?>

<!DOCTYPE greeting [
  <!ENTITY xuxu "is this a xuxu?">

  <!ATTLIST to
     method  CDATA   #FIXED "POST"
  >

  <!ENTITY test-entity
           SYSTEM "entity1.xml">

  <!NOTATION TXT SYSTEM "txt">

  <!ENTITY test-unparsed SYSTEM "unparsed.txt" NDATA txt>

  <!ATTLIST hihi
      explanation ENTITY #REQUIRED>

]>
]]

local X
function getargs (...) X = arg end

function xgetargs (c)
  return function (...)
    table.insert(arg, 1, c)
    table.insert(X, arg)
  end
end


-------------------------------
print("testing start/end tags")
callbacks = {
  StartElement = getargs,
  EndElement = getargs,
}
p = lxp.new(callbacks)
assert(p:getcallbacks() == callbacks)
assert(p:parse(preamble))
assert(p:parse([[
<to priority="10" xu = "hi">
]]))
assert(X.n == 3 and X[1] == p and X[2] == "to")
x = X[3]
assert(x.priority=="10" and x.xu=="hi" and x.method=="POST")
assert(x[1] == "priority" and x[2] == "xu" and table.getn(x) == 2)
assert(p:parse("</to>"))
assert(p:parse())
p:close()


-------------------------------
print("testing CharacterData/Cdata")
callbacks = {
  CharacterData = getargs,
}
p = lxp.new(callbacks)
assert(p:parse(preamble))
assert(p:parse"<to>a basic text&lt;<![CDATA[<<ha>>]]></to>")
assert(X[1] == p and X[2] == "a basic text<<<ha>>")
callbacks.chardata = error   -- no more calls to `chardata'
assert(p:parse(""))
assert(p:parse())
-- assert(p:parse())   -- no problem to finish twice. alas, it has problems
assert(p:getcallbacks() == callbacks)
p:close()

-------------------------------
callbacks = {
  CharacterData = xgetargs"c",
  StartCdataSection = xgetargs"s",
  EndCdataSection = xgetargs"e", 
}
X = {}
p = lxp.new(callbacks)
assert(p:parse(preamble))
assert(p:parse"<to>")
assert(p:parse"<![CDATA[hi]]>")
assert(table.getn(X) == 3)
assert(X[1][1] == "s" and X[1][2] == p)
assert(X[2][1] == "c" and X[2][2] == p and X[2][3] == "hi")
assert(X[3][1] == "e" and X[3][2] == p)
assert(p:parse"</to>")
p:close()


-------------------------------
print("testing ProcessingInstruction")
callbacks = {ProcessingInstruction = getargs}
p = lxp.new(callbacks)
assert(p:parse[[
<to>
  <?lua how is this passed to <here>? ?>
</to>
]])
assert(X[1] == p and X[2] == "lua" and
       X[3] == "how is this passed to <here>? ")
p:close()


------------------------------
print("testing Comment")
callbacks = {Comment = xgetargs"c"; CharacterData = xgetargs"t"}
X = {}
p = lxp.new(callbacks)
assert(p:parse[[
<to>some text
<!-- <a comment> with some & symbols -->
some more text</to>

]])
p:close()

assert(X[1][1] == "t" and X[2][1] == "c" and X[3][1] == "t")
assert(X[1][2] == X[2][2] and X[2][2] == X[3][2] and X[3][2] == p)
assert(X[1][3] == "some text\n")
assert(X[2][3] == " <a comment> with some & symbols ")
assert(X[3][3] == "\nsome more text")


----------------------------
print("testing ExternalEntity")
entities = {
["entity1.xml"] = "<hi/>"
}

callbacks = {StartElement = xgetargs"s", EndElement = xgetargs"e",
  ExternalEntityRef = function (p, context, base, systemID, publicId)
    assert(base == "/base")
    return context:parse(entities[systemID])
  end}

X = {}
p = lxp.new(callbacks)
p:setbase("/base")
assert(p:parse(preamble))
assert(p:parse[[
<to> &test-entity;
</to>
]])
assert(p:getbase() == "/base")
p:close()
assert(X[1][1] == "s" and X[1][3] == "to")
assert(X[2][1] == "s" and X[2][3] == "hi")
assert(X[3][1] == "e" and X[3][3] == "hi")
assert(X[4][1] == "e" and X[4][3] == "to")


----------------------------
print("testing default handles")
text = [[<to> hi &xuxu; </to>]]
local t = ""

callbacks = { Default = function (p, s) t = t .. s end }
p = lxp.new(callbacks)
assert(p:parse(preamble))
assert(p:parse(text))
p:close()
assert(t == preamble..text)

t = ""
callbacks = { DefaultExpand = function (p, s) t = t .. s end }
p = lxp.new(callbacks)
assert(p:parse(preamble))
assert(p:parse(text))
p:close()
assert(t == preamble..string.gsub(text, "&xuxu;", "is this a xuxu?"))


----------------------------
print("testing notation declarations and unparsed entities")

callbacks = {
  UnparsedEntityDecl = getargs,
  NotationDecl = function (p, name, base, systemId, publicId)
    assert(name == "TXT" and systemId == "txt" and base == "/base")
  end,
 }
p = lxp.new(callbacks)
p:setbase("/base")
assert(p:parse(preamble))
assert(p:parse[[<hihi explanation="test-unparsed"/>]])
p:close()
assert(X[2] == "test-unparsed" and X[3] == "/base" and
       X[4] == "unparsed.txt" and X[6] == "txt" and X.n == 6)



----------------------------
print("testing namespace declarations")
callbacks = { StartNamespaceDecl = xgetargs"sn",
              EndNamespaceDecl = xgetargs"en",
              StartElement = xgetargs"s",
              EndElement = xgetargs"e",
}
X = {}
p = lxp.new(callbacks, "?")
assert(p:parse[[
<x xmlns:space='a/namespace'>
  <space:a/>
</x>
]])
p:close()
x = X[1]
assert(x[1] == "sn" and x[3] == "space" and x[4] == "a/namespace" and table.getn(x) == 4)
x = X[3]
assert(x[1] == "s" and x[3] == "a/namespace?a")
x = X[4]
assert(x[1] == "e" and x[3] == "a/namespace?a")
x = X[6]
assert(x[1] == "en" and x[3] == "space" and table.getn(x) == 3)



-- Error reporting
p = lxp.new{}
data = [[
<tag>
  <other< </other>
</tag>
]]
local status, msg, line, col, byte = p:parse(data)
assert(status == nil and type(msg) == "string" and line == 2 and col == 9)
assert(string.sub(data, byte, byte) == "<")

p = lxp.new{}
p:parse("<to>")
local status, msg, line, col, byte = p:parse()
assert(status == nil and line == 1 and col == 5 and byte == 5)


-- position reporting
callbacks = { ProcessingInstruction = function (p)
  X = {p:pos()}
end
}

p = lxp.new(callbacks)
assert(p:parse[[
<to> <?test where is `pos'? ?>
</to>
]])
p:close()
assert(X[1] == 1  and X[2] == 6 and X[3] == 6)  -- line, column, abs. position



print("testing errors")
-- invalid keys
assert(not pcall(lxp.new, {StatCdata=print}))
assert(pcall(lxp.new, {StatCdata=print, _nonstrict = true}))

-- invalid sequences
p = lxp.new{}
assert(p:parse[[<to></to>]])
assert(p:parse())
assert(p:parse(" ") == nil)

-- closing unfinished document
p = lxp.new{}
assert(p:parse[[<to>]])
local status, err = pcall(p.close, p)
assert(not status and string.find(err, "error closing parser"))


-- test for GC
print("\ntesting garbage collection")
collectgarbage(); collectgarbage()
local x = gcinfo()
for i=1,100000 do
  -- due to a small bug in Lua...
  if math.mod(i, 100) == 0 then collectgarbage() end
  lxp.new({})
end
collectgarbage(); collectgarbage()
assert(math.abs(gcinfo() - x) <= 2)


print"OK"

