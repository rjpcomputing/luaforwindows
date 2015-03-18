require"cdlua"
require"iuplua"
require"iupluacd"

cnv = iup.canvas {size = "200x100"}

box = iup.vbox{
       iup.button { title="Version" },
       cnv,
       iup.button { title="Close" },
     }

dlg = iup.dialog{box; title="Example IUPLUA/CDLUA"}

function cnv:map_cb()
  local canvas = cd.CreateCanvas(cd.IUP, self)
  local dbuffer = cd.CreateCanvas(cd.DBUFFERRGB, canvas);
--  local dbuffer = cd.CreateCanvas(cd.DBUFFER, canvas);
  self.canvas = canvas     -- store the CD canvas in a IUP attribute
  self.dbuffer = dbuffer
end

function cnv:unmap_cb()
  local canvas = self.canvas     -- retrieve the CD canvas from the IUP attribute
  local dbuffer = self.dbuffer
  dbuffer:Kill()
  canvas:Kill()
end

bt_version = dlg[1][1]
function bt_version:action()
  iup.Message("Version", "CD Version: " .. cd.Version() .. "\nIUP Version: " .. iup.Version() .. "\n" .. _VERSION)
end

bt_close = dlg[1][3]
function bt_close:action()
  return iup.CLOSE
end

function Render(dbuffer)
  dbuffer:Activate()
  dbuffer:Clear()
  dbuffer:Foreground (cd.RED)
  dbuffer:Box (10, 55, 10, 55)
  dbuffer:Foreground(cd.EncodeColor(255, 32, 140))
  dbuffer:Line(0, 0, 300, 100)
end

function cnv:action()
  local dbuffer = self.dbuffer     -- retrieve the CD canvas from the IUP attribute
  dbuffer:Flush()
end

function cnv:button_cb(b, e, x, y, r)
  print ("Button: " .. "Button="..tostring(b).." Pressed="..tostring(e).." X="..tostring(x).." Y="..tostring(y) )
end

function cnv:resize_cb()
  local dbuffer = self.dbuffer     -- retrieve the CD canvas from the IUP attribute
  
  -- update size
  dbuffer:Activate()

  -- update render
  Render(dbuffer);
end

dlg:show()
iup.MainLoop()
