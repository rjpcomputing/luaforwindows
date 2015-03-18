require("luacom")

function make_control()

local obj = {}

local cd_canvas         = nil
local cd_dbuffer_canvas = nil
local x,y = 0,0

local function draw()
    cd.Activate(cd_dbuffer_canvas)
    cd.Background(cd.BLACK)
    cd.Clear()

    cd.Foreground(cd.EncodeColor(255,255,0))
    cd.Box(x,x+120,y,y+120)
    cd.Flush()
end

local incx = 1
local incy = 1

local function idle()
  if not cd_canvas then return end
  
  x = x + incx
  y = y + incy

  local w, h = cd.GetCanvasSize()
  
  if ((x + 120) > w) or (x < 0) then
    x = x - incx
    incx = incx * -1
    x = x + incx
  end

  if ((y + 120) > h) or (y < 0) then
    y = y - incy
    incy = incy * -1
    y = y + incy
  end
 
  draw()
end

local timer1 = iup.timer{time=10}

local canvas = iup.canvas{
  rastersize = "512x512",
  expand     = "YES",
  action = function(self)
    if cd_canvas == nil then
      cd_canvas = cd.CreateCanvas(cd.IUP, self)
      if cd_canvas == nil then
        print("Error creating cdCanvas(IUP)!!!")
        exit(-1)
      end

      cd_dbuffer_canvas = cd.CreateCanvas(cd.DBUFFER, cd_canvas)
      if cd_dbuffer_canvas == nil then
        print("Error creating cdCanvas(DBUFFER)!!!")
        exit(-1)
      end
--      IupSetIdle(idle)
    end
    draw()
    
    local w,h = cd.GetCanvasSize()
    local color = cd.EncodeColor(1,2,3)
  end,
}

function timer1:action_cb()
  idle()
  return iup.DEFAULT
end

local dialog = iup.dialog{
  iup.vbox{
    canvas,
  }
}

function canvas:keypress_cb(c, press)
  draw()
  if press == 1 then
    if c == iup.K_UP then
      local w,h = cd.GetCanvasSize()
      y = y + 10
      if y + 120 > h then y = 380 end
      draw() 
    elseif c == iup.K_DOWN then
      y = y - 10
      if y < 0 then y = 0 end
      draw() 
    elseif c == iup.K_LEFT then
      x = x - 10
      if x < 0 then x = 0 end
      draw() 
    elseif c == iup.K_RIGHT then
      local w,h = cd.GetCanvasSize()
      x = x + 10
      if x + 120 > w then x = 380 end
      draw() 
    end
  end
end

-- Methods required for all Lua controls

function obj:InitialSize()
  return 500,600
end

function obj:CreateWindow(hwndParent, x, y, cx, cy)

  iup.SetAttribute(dialog, "NATIVEPARENT", hwndParent)
  iup.SetAttribute(dialog, "CONTROL", "YES")
  iup.SetAttribute(dialog, "RASTERSIZE", cx .. "x" .. cy)

  timer1.run = "YES"

  dialog:map()

  return iup.GetAttributeData(dialog, "WID")
end

function obj:SetExtent(cx, cy)
   return true
end

function obj:GetClass()
  return "{687362C8-00D6-4eff-9207-DDB22EE23A6D}"
end

function obj:DestroyWindow()
  timer1.run = "NO"
  cd.KillCanvas(cd_dbuffer_canvas)
  cd.KillCanvas(cd_canvas)
  dialog:destroy()
end

-- ITestLuaControl implementation

luacom.TableVariants = true

function obj:Sum(i1, i2)
  print("Calling Sum...",i1,i2.Type)
  return i1 + i2.Value
end

function obj:I2A(i1)
  print("Calling I2A...",i1)
  return tostring(i1)
end

function obj:IntDivide(i1, i2)
  print("Calling IntDivide...",i1,i2)
  div = {}
  div.Type = "decimal"
  div.Value = i1/i2
  return div,math.mod(i1, i2)
end

return obj

end -- make_control()

local COM = {}

local COMAppObject, events, e, cookie

function COM:StartAutomation()
  print("Starting server...")
  -- creates the object using its default interface
  COMAppObject, events, e = luacom.NewControl(make_control(), "testlua.Teste")
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
  reginfo.VersionIndependentProgID = "testcontrol.Teste"
  reginfo.ProgID = reginfo.VersionIndependentProgID..".1"
  reginfo.TypeLib = "testcontrol.tlb"
  reginfo.CoClass = "Teste"
  reginfo.ComponentName = "Test Control"
  reginfo.Arguments = "/Automation"
  reginfo.ScriptFile = "control.lua"
  reginfo.Control = true
  -- stores component information in the registry
  local res = luacom.RegisterObject(reginfo)
  if res == nil then
    error("RegisterObject failed!")
  end
end

function COM:UnRegister()
  -- fills table with registration information
  local reginfo = {}
  reginfo.VersionIndependentProgID = "testcontrol.Teste"
  reginfo.ProgID = reginfo.VersionIndependentProgID..".1"
  reginfo.TypeLib = "testcontrol.tlb"
  reginfo.CoClass = "Teste"
  -- deletes component information from the registry
  local res = luacom.UnRegisterObject(reginfo)
  if res == nil then
    error("UnRegisterObject failed!")
  end
end

return luacom.DetectAutomation(COM)

