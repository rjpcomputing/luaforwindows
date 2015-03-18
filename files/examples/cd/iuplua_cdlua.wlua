require"cdlua"
require"iuplua"
require"iupluacd"
--require"cdluacontextplus"

cnv = iup.canvas {size = "200x100"}

box = iup.vbox{
       iup.button { title="Version" },
       cnv,
       iup.button { title="Close" },
     }

dlg = iup.dialog{box; title="Example IUPLUA/CDLUA"}

function cnv:map_cb()
  --cd.UseContextPlus(true)
  canvas = cd.CreateCanvas(cd.IUP, self)
  --cd.UseContextPlus(false)
  self.canvas = canvas     -- store the CD canvas in a IUP attribute
end

function dlg:close_cb()
  cnv = self[1][2]
  canvas = cnv.canvas     -- retrieve the CD canvas from the IUP attribute
  canvas:Kill()
  self:destroy()
  return iup.IGNORE -- because we destroy the dialog
end

bt_version = dlg[1][1]
function bt_version:action()
  iup.Message("Version", "CD Version: " .. cd.Version() .. "\nIUP Version: " .. iup.Version() .. "\n" .. _VERSION)
end

bt_close = dlg[1][3]
function bt_close:action()
  return iup.CLOSE
end

function cnv:action()
  canvas = self.canvas     -- retrieve the CD canvas from the IUP attribute

  canvas:Activate()
  canvas:Clear()
  canvas:Foreground (cd.RED)
  canvas:Box (10, 55, 10, 55)
  canvas:Foreground(cd.EncodeColor(255, 32, 140))
  canvas:Line(0, 0, 300, 100)
end

function cnv:button_cb(b, e, x, y, r)
  print ("Button: " .. "Button="..tostring(b).." Pressed="..tostring(e).." X="..tostring(x).." Y="..tostring(y) )
end

function cnv:resize_cb(w, h)
  print("Resize: Width="..w.."   Height="..h)
end

dlg:show()
iup.MainLoop()
