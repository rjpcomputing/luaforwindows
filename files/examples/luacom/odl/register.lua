require("luacom")

lib = luacomE.NewLibrary {
  name = "TestLibrary",
  uuid = "AB290DA3-2F9E-4200-8A69-AE4C3A6082EF",
  version = "1.0"
}

lib:AddImport("stdole32.tlb")

int = lib:AddInterface{
  name = "ITestLuaCOM",
  uuid = "05E662B4-05A3-4ba2-A8AB-B5A365C0B624",
}

int:AddMethod{
  type = "int",
  name = "Sum",
  parameters = {
    { attributes = { "in" }, type = "int", name = "i1" },
    { attributes = { "in" }, type = "int", name = "i2" }
  }
}

int:AddMethod{
  type = "BSTR",
  name = "I2A",
  parameters = {
    { attributes = { "in" }, type = "int", name = "i1" },
  }
}

int:AddMethod{
  name = "IntDivide",
  parameters = {
    { attributes = { "in" }, type = "int", name = "i1" },
    { attributes = { "in" }, type = "int", name = "i2" },
    { attributes = { "out" }, type = "int*", name = "quot" },
    { attributes = { "out" }, type = "int*", name = "rem" }
  }
}

coclass = lib:AddCoclass{
  name = "Teste",
  uuid = "687362C8-00D6-4eff-9207-DDB22EE2306D"
}

coclass:AddInterface{
  "default",
  name = "ITestLuaCOM"
}

lib:WriteTLB("testlua")

obj = {}

function obj:Sum(i1, i2)
  return i1 + i2
end

function obj:I2A(i1)
  return tostring(i1)
end

function obj:IntDivide(i1, i2)
  return math.floor(i1/i2),math.mod(i1, i2)
end

com_obj = luacom.ImplInterfaceFromTypelib(obj,"testlua.tlb","ITestLuaCOM")

if com_obj ~= nil then
  print(com_obj:Sum(2,3))
  print(type(com_obj:I2A(7)))
  quot, rem = com_obj:IntDivide(5,2)
  print(quot,rem)
else
  print("Implementation failed")
end

