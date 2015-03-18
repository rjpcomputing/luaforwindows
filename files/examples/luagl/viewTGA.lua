require("iuplua")
require("iupluagl")
require("luagl")
require("luaglu")
require("LoadTGA")

iup.key_open()

texture = 0

cnv = iup.glcanvas{buffer="DOUBLE", rastersize = "640x480"}

function cnv:resize_cb(width, height)
  iup.GLMakeCurrent(self)
  gl.Viewport(0, 0, width, height)

  gl.MatrixMode('PROJECTION')   -- Select The Projection Matrix
  gl.LoadIdentity()             -- Reset The Projection Matrix
  
  if height == 0 then           -- Calculate The Aspect Ratio Of The Window
    height = 1
  end

  glu.Perspective(45, width / height, 0.1, 5)

  gl.MatrixMode('MODELVIEW')    -- Select The Model View Matrix
  gl.LoadIdentity()             -- Reset The Model View Matrix
end

function cnv:action(x, y)
  iup.GLMakeCurrent(self)
  gl.Clear('COLOR_BUFFER_BIT,DEPTH_BUFFER_BIT') -- Clear Screen And Depth Buffer
  
  gl.LoadIdentity()             -- Reset The Current Modelview Matrix
	gl.Translate(0,0,-2.5)

  gl.BindTexture('TEXTURE_2D', texture[1])

  gl.Begin('QUADS')
    gl.TexCoord(0, 0) gl.Vertex(-1, -1)
    gl.TexCoord(1, 0) gl.Vertex( 1, -1)
    gl.TexCoord(1, 1) gl.Vertex( 1,  1)
    gl.TexCoord(0, 1) gl.Vertex(-1,  1)
  gl.End()

  iup.GLSwapBuffers(self)
end              

function cnv:k_any(c)
  if c == iup.K_q or c == iup.K_ESC then
    return iup.CLOSE
  elseif c == iup.K_F1 then
    if fullscreen then
      fullscreen = false
      dlg.fullscreen = "No"
    else
      fullscreen = true
      dlg.fullscreen = "Yes"
    end
  end
end

function cnv:map_cb()
  iup.GLMakeCurrent(self)
  gl.Enable('TEXTURE_2D')            -- Enable Texture Mapping ( NEW )

  texture = gl.GenTextures(1)  -- Create The Texture

  -- Typical Texture Generation Using Data From The Bitmap
  gl.BindTexture('TEXTURE_2D', texture[1])
  gl.TexParameter('TEXTURE_2D','TEXTURE_MIN_FILTER','LINEAR')
  gl.TexParameter('TEXTURE_2D','TEXTURE_MAG_FILTER','LINEAR')

  img = LoadTGA(fileName)

  if img == nil then
    print ("Unnable to open the TGA file: " .. fileName)
    os.exit()
  end
 
  glu.Build2DMipmaps(img)
end              

if arg[1] ~= nil then
  fileName = arg[1]
else
  fileName = 'luagl.tga'
end

dlg = iup.dialog{cnv; title="LuaGL TGA Loader"}

dlg:show()
cnv.rastersize = nil -- reset minimum limitation

if (not iup.MainLoopLevel or iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
