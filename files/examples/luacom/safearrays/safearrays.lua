require("luacom")

local cube = {}
cube[1] = {}
cube[2] = {}
cube[3] = {}
cube[4] = {}
	
cube[1][1] = {"[1,1,1]", "[1,1,2]"}
cube[1][2] = {"[1,2,1]", "[1,2,2]"}
cube[1][3] = {"[1,3,1]", "[1,3,2]"}
	
cube[2][1] = {"[2,1,1]", "[2,1,2]"}
cube[2][2] = {"[2,2,1]", "[2,2,2]"}
cube[2][3] = {"[2,3,1]", "[2,3,2]"}
	
cube[3][1] = {"[3,1,1]", "[3,1,2]"}
cube[3][2] = {"[3,2,1]", "[3,2,2]"}
cube[3][3] = {"[3,3,1]", "[3,3,2]"}
	
cube[4][1] = {"[4,1,1]", "[4,1,2]"}
cube[4][2] = {"[4,2,1]", "[4,2,2]"}
cube[4][3] = {"[4,3,1]", "[4,3,2]"}

local matrix = {}
matrix[1] = {"a","b","c"}
matrix[2] = {"d","e","f"}

function PrintDimension(dimension, indices)
	indices = indices or {}
	for k,v in ipairs(dimension) do
		indices[#indices + 1] = tostring(k)
		if type(v) == "table" then
			PrintDimension(v, indices)
		else
			print("["..table.concat(indices, ",").."] => ", v)
		end
		indices[#indices] = nil
	end
end

print("LuaCOM <--> Visual C++")
do
local test = luacom.CreateObject("TestSafeArray.Test")
assert(test)

print("Testing SafeArray COM->Lua")
local array = test:GetArray()
assert(array)

PrintDimension(array)

print("\r\nTesting SafeArray (4,3,2) Lua->COM")
local out = test:SetArray(cube)
assert(#out == #cube, "dimensions mismatch")

print("\r\nTesting SafeArray (2,3) Lua->COM")
local out = test:SetArray(matrix)
assert(#out == #matrix, "dimensions mismatch")

end


print("\r\n\r\n")
print("LuaCOM <--> Visual Basic")
do
local test = luacom.CreateObject("PruebaSafeArrayVB.Test")
assert(test)
array = test:GetArray432()

PrintDimension(array)
end