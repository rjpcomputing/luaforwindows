require("iuplua")
require("iupluagl")
require("luagl")
require("imlua")

iup.key_open()

texture = 0

cnv = iup.glcanvas{buffer="DOUBLE", rastersize = "640x480"}

function cnv:resize_cb(width, height)
  iup.GLMakeCurrent(self)
  gl.Viewport(0, 0, width, height)
end

function cnv:action(x, y)
  iup.GLMakeCurrent(self)
  gl.PixelStore(gl.UNPACK_ALIGNMENT, 1)
  gl.Clear('COLOR_BUFFER_BIT,DEPTH_BUFFER_BIT') -- Clear Screen And Depth Buffer
  
  gl.DrawPixelsRaw (image:Width(), image:Height(), glformat, gl.UNSIGNED_BYTE, gldata)
  
  iup.GLSwapBuffers(self)
end              

function cnv:k_any(c)
  if c == iup.K_q or c == iup.K_ESC then
    return iup.CLOSE
  end
  
  if c == iup.K_F1 then
    if fullscreen then
      fullscreen = false
      dlg.fullscreen = "No"
    else
      fullscreen = true
      dlg.fullscreen = "Yes"
    end
  end
  
  if c == iup.K_F2 then
    fileName = iup.GetFile("*.*")
    new_image = im.FileImageLoadBitmap(fileName)
    if (not new_image) then
      iup.Message("Error", "LoadBitmap failed.")
    else
      gldata, glformat = new_image:GetOpenGLData()
      if (image) then image:Destroy() end
      image = new_image
      iup.Update(cnv)
    end
  end
  
end

if arg and arg[1] ~= nil then
  fileName = arg[1]
else
  fileName = iup.GetFile("*.*")
end

image = im.FileImageLoadBitmap(fileName)
if (not image) then
  error("LoadBitmap failed.")
end
gldata, glformat = image:GetOpenGLData()

dlg = iup.dialog{cnv; title="LuaGL/IUP/IM Loader"}

dlg:show()
cnv.rastersize = nil -- reset minimum limitation

if (not iup.MainLoopLevel or iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
