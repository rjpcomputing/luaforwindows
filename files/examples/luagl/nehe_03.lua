require("iuplua")
require("iupluagl")
require("luagl")
require("luaglu")

iup.key_open()

cnv = iup.glcanvas{buffer="DOUBLE", rastersize = "640x480"}

function cnv:resize_cb(width, height)
  iup.GLMakeCurrent(self)
  gl.Viewport(0, 0, width, height)

  gl.MatrixMode('PROJECTION')   -- Select The Projection Matrix
  gl.LoadIdentity()             -- Reset The Projection Matrix
  
  if height == 0 then           -- Calculate The Aspect Ratio Of The Window
    height = 1
  end

  glu.Perspective(80, width / height, 1, 5000)

  gl.MatrixMode('MODELVIEW')    -- Select The Model View Matrix
  gl.LoadIdentity()             -- Reset The Model View Matrix
end

function cnv:action(x, y)
  iup.GLMakeCurrent(self)
  gl.Clear('COLOR_BUFFER_BIT,DEPTH_BUFFER_BIT') -- Clear Screen And Depth Buffer
  
  gl.LoadIdentity()             -- Reset The Current Modelview Matrix
  gl.Translate(-1.5, 0, -6)     -- Move Left 1.5 Units And Into The Screen 6.0
  
  gl.Begin('TRIANGLES')         -- Drawing Using Triangles
    gl.Color ( 1, 0, 0)         -- Set The Color To Red
		gl.Vertex( 0, 1, 0)         -- Move Up One Unit From Center (Top Point)
    gl.Color ( 0, 1, 0)         -- Set The Color To Green
    gl.Vertex(-1,-1, 0)         -- Left And Down One Unit (Bottom Left)
    gl.Color ( 0, 0, 1)         -- Set The Color To Blue
    gl.Vertex( 1,-1, 0)         -- Right And Down One Unit (Bottom Right)
  gl.End()                      -- Done Drawing A Triangle
  
  gl.Translate(3, 0, 0)         -- From Right Point Move 3 Units Right
  
  gl.Color (0.5, 0.5, 1)        -- Set The Color To Blue One Time Only
  gl.Begin('QUADS')             -- Draw A Quad
    gl.Vertex(-1, 1, 0)         -- Top Left
    gl.Vertex( 1, 1, 0)         -- Top Right
    gl.Vertex( 1,-1, 0)         -- Bottom Right
    gl.Vertex(-1,-1, 0)         -- Bottom Left
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
  gl.ShadeModel('SMOOTH')            -- Enable Smooth Shading
  gl.ClearColor(0, 0, 0, 0.5)        -- Black Background
  gl.ClearDepth(1.0)                 -- Depth Buffer Setup
  gl.Enable('DEPTH_TEST')            -- Enables Depth Testing
  gl.DepthFunc('LEQUAL')             -- The Type Of Depth Testing To Do
  gl.Enable('COLOR_MATERIAL')
  gl.Hint('PERSPECTIVE_CORRECTION_HINT','NICEST')
end

dlg = iup.dialog{cnv; title="LuaGL Test Application 03"}

dlg:show()
cnv.rastersize = nil -- reset minimum limitation

if (not iup.MainLoopLevel or iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
