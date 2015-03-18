require("luacom")

local obj = {}

function obj:Sum(i1, i2)
  print("Calling Sum...",i1,i2)
  return i1 + i2
end

function obj:I2A(i1)
  print("Calling I2A...",i1)
  return tostring(i1)
end

function obj:IntDivide(i1, i2)
  print("Calling IntDivide...",i1,i2)
  quot, rest = {}, {}
  quot.Type = "int"
  quot.Value = math.floor(i1/i2)
  rest.Type = "int"
  rest.Value = math.mod(i1, i2)
  return quot, rest
end

local COM = {}

local COMAppObject, events, e, cookie

function COM:StartAutomation()
  print("Starting server...")
  -- creates the object using its default interface
  COMAppObject, events, e = luacom.NewObject(obj, "testlua.Teste")
  -- This error will be caught by detectAutomation
  if COMAppObject == nil then
    error("NewObject failed: "..e)
  end
  -- Exposes the object
  cookie = luacom.ExposeObject(COMAppObject)
  if cookie == nil then
    error("ExposeObject failed!")
  end
end

function COM:Register()
  -- fills table with registration information
  local reginfo = {}
  reginfo.VersionIndependentProgID = "testlua.Teste"
  reginfo.ProgID = reginfo.VersionIndependentProgID..".1"
  reginfo.TypeLib = "testlua.tlb"
  reginfo.CoClass = "Teste"
  reginfo.ComponentName = "Test Component"
  reginfo.Arguments = "/Automation"
  reginfo.ScriptFile = "inproc.lua"
  -- stores component information in the registry
  local res = luacom.RegisterObject(reginfo)
  if res == nil then
    error("RegisterObject failed!")
  end
end

function COM:UnRegister()
  -- fills table with registration information
  local reginfo = {}
  reginfo.VersionIndependentProgID = "testlua.Teste"
  reginfo.ProgID = reginfo.VersionIndependentProgID..".1"
  reginfo.TypeLib = "testlua.tlb"
  reginfo.CoClass = "Teste"
  -- deletes component information from the registry
  local res = luacom.UnRegisterObject(reginfo)
  if res == nil then
    error("UnRegisterObject failed!")
  end
end

return luacom.DetectAutomation(COM)

