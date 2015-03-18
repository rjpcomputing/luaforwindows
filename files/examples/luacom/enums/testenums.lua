require("luacom")

local conn = luacom.CreateObject("ADODB.Connection")

local typeinfo = luacom.GetTypeInfo(conn)
local typelib = typeinfo:GetTypeLib()
local enums = typelib:ExportEnumerations()
print(enums)
for key, val in pairs(enums) do
  print(key)
  print("============================")
  if(type(val)=="table") then
    for key, val in pairs(val) do
      print(tostring(key) .. " = " .. tostring(val))
    end
  end
  print()
end
