require("luacom")

local obj = luacom.CreateObject("testlua.Teste")

print(obj:Sum(2,3))
print(type(obj:I2A(3)))
print(obj:IntDivide(5,2))
print("Finishing...")
