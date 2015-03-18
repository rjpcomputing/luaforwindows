require('LuaXml')

-- load XML data from file "test.xml" into local table xfile
local xfile = xml.load("test.xml")
-- search for substatement having the tag "scene"
local xscene = xfile:find("scene")
-- if this substatement is found…
if xscene ~= nil then
  --  …print it to screen
  print(xscene)
  --  print  tag, attribute id and first substatement
  print( xscene:tag(), xscene.id, xscene[1] )
end

-- create a new XML object and set its tag to "root"
local x = xml.new("root")
-- append a new subordinate XML object, set its tag to "child", and its content to 123
x:append("child")[1] = 123
print(x)
