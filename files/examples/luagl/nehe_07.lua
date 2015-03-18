require("iuplua")
require("iupluagl")
require("luagl")
require("luaglu")
require("LoadTGA")

iup.key_open()

light = false             -- Lighting ON / OFF
lp = false                -- L Pressed?
fp = false                -- F Pressed?

xrot = 0                  -- X Rotation
yrot = 0                  -- Y Rotation
xspeed = 0                -- X Rotation Speed
yspeed = 0                -- Y Rotation Speed
z = -5                    -- Depth Into The Screen

LightAmbient = {0.5, 0.5, 0.5, 1}    -- Ambient Light Values ( NEW )
LightDiffuse = {1, 1, 1, 1}          -- Diffuse Light Values ( NEW )
LightPosition = {0, 0, 2, 1}         -- Light Position ( NEW )

filter = 1                           -- Which Filter To Use
texture = 0                          -- Storage for the textures

cnv = iup.glcanvas{buffer="DOUBLE", rastersize = "640x480"}

timer = iup.timer{time=10}

function timer:action_cb()
	xrot = xrot + xspeed
	yrot = yrot + yspeed
  iup.Update(cnv)
end

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
	gl.Translate(0,0,z)           -- Translate Into/Out Of The Screen By z

	gl.Rotate(xrot,1,0,0)
	gl.Rotate(yrot,0,1,0)

  gl.BindTexture('TEXTURE_2D', texture[filter])

  gl.Begin('QUADS')

    -- Front Face
    gl.Normal( 0, 0, 1)                      -- Normal Pointing Towards Viewer
    gl.TexCoord(0, 0) gl.Vertex(-1, -1,  1)  -- Point 1 (Front)
    gl.TexCoord(1, 0) gl.Vertex( 1, -1,  1)  -- Point 2 (Front)
    gl.TexCoord(1, 1) gl.Vertex( 1,  1,  1)  -- Point 3 (Front)
    gl.TexCoord(0, 1) gl.Vertex(-1,  1,  1)  -- Point 4 (Front)
    
    -- Back Face
    gl.Normal( 0, 0,-1)                      -- Normal Pointing Away From Viewer
    gl.TexCoord(1, 0) gl.Vertex(-1, -1, -1)  -- Point 1 (Back)
    gl.TexCoord(1, 1) gl.Vertex(-1,  1, -1)  -- Point 2 (Back)
    gl.TexCoord(0, 1) gl.Vertex( 1,  1, -1)  -- Point 3 (Back)
    gl.TexCoord(0, 0) gl.Vertex( 1, -1, -1)  -- Point 4 (Back)
    
    -- Top Face
    gl.Normal( 0, 1, 0)                      -- Normal Pointing Up
    gl.TexCoord(0, 1) gl.Vertex(-1,  1, -1)  -- Point 1 (Top)
    gl.TexCoord(0, 0) gl.Vertex(-1,  1,  1)  -- Point 2 (Top)
    gl.TexCoord(1, 0) gl.Vertex( 1,  1,  1)  -- Point 3 (Top)
    gl.TexCoord(1, 1) gl.Vertex( 1,  1, -1)  -- Point 4 (Top)
    
    -- Bottom Face
    gl.Normal( 0,-1, 0)                      -- Normal Pointing Down
    gl.TexCoord(1, 1) gl.Vertex(-1, -1, -1)  -- Point 1 (Bottom)
    gl.TexCoord(0, 1) gl.Vertex( 1, -1, -1)  -- Point 2 (Bottom)
    gl.TexCoord(0, 0) gl.Vertex( 1, -1,  1)  -- Point 3 (Bottom)
    gl.TexCoord(1, 0) gl.Vertex(-1, -1,  1)  -- Point 4 (Bottom)

    -- Right face
    gl.Normal( 1, 0, 0)                      -- Normal Pointing Right
    gl.TexCoord(1, 0) gl.Vertex( 1, -1, -1)  -- Point 1 (Right)
    gl.TexCoord(1, 1) gl.Vertex( 1,  1, -1)  -- Point 2 (Right)
    gl.TexCoord(0, 1) gl.Vertex( 1,  1,  1)  -- Point 3 (Right)
    gl.TexCoord(0, 0) gl.Vertex( 1, -1,  1)  -- Point 4 (Right)

    -- Left Face
    gl.Normal(-1, 0, 0)                      -- Normal Pointing Left
    gl.TexCoord(0, 0) gl.Vertex(-1, -1, -1)  -- Point 1 (Left)
    gl.TexCoord(1, 0) gl.Vertex(-1, -1,  1)  -- Point 2 (Left)
    gl.TexCoord(1, 1) gl.Vertex(-1,  1,  1)  -- Point 3 (Left)
    gl.TexCoord(0, 1) gl.Vertex(-1,  1, -1)  -- Point 4 (Left)

  gl.End()

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

  if c == iup.K_l then   -- 'L' Key Being Pressed ?
    if (light) then
      gl.Disable('LIGHTING')
      light = false
    else
      gl.Enable('LIGHTING')
      light = true
    end
  end

  if c == iup.K_f then   -- 'F' Key Being Pressed ?
    filter = filter + 1
    if filter > 3 then
      filter = 1
    end    
  end

  if c == iup.K_PGUP then  z = z - 2 end   -- Is Page Up Being Pressed? If So, Move Into The Screen.
  if c == iup.K_PGDN then  z = z + 2 end   -- Is Page Down Being Pressed? If So, Move Towards The Viewer.

  if c == iup.K_UP then  xspeed = xspeed - 0.01 end -- Is Up Arrow Being Pressed? If So, Decrease xspeed.
  if c == iup.K_DOWN then  xspeed = xspeed + 0.01 end -- Is Down Arrow Being Pressed? If So, Increase xspeed.

  if c == iup.K_LEFT then  yspeed = yspeed - 0.01 end -- Is Left Arrow Being Pressed? If So, Decrease yspeed.
  if c == iup.K_RIGHT then  yspeed = yspeed + 0.01 end -- Is Right Arrow Being Pressed? If So, Increase yspeed.
  
end

function LoadGLTextures()
  texture = gl.GenTextures(3)   -- Create The Textures
  
  -- Create Nearest Filtered Texture
  gl.BindTexture('TEXTURE_2D', texture[1])
  gl.TexParameter('TEXTURE_2D','TEXTURE_MIN_FILTER','NEAREST')
  gl.TexParameter('TEXTURE_2D','TEXTURE_MAG_FILTER','NEAREST')

  crate = LoadTGA('crate.tga')

  --gl.TexImage(0, crate)
  gl.TexImage(0, crate.components, crate.format, crate)

  -- Create Linear Filtered Texture
  gl.BindTexture('TEXTURE_2D', texture[2])
  gl.TexParameter('TEXTURE_2D','TEXTURE_MIN_FILTER','LINEAR')
  gl.TexParameter('TEXTURE_2D','TEXTURE_MAG_FILTER','LINEAR')

  gl.TexImage(0, crate)

  -- Create MipMapped Texture
  gl.BindTexture('TEXTURE_2D', texture[3])
  gl.TexParameter('TEXTURE_2D','TEXTURE_MIN_FILTER','LINEAR_MIPMAP_NEAREST')
  gl.TexParameter('TEXTURE_2D','TEXTURE_MAG_FILTER','LINEAR')

  glu.Build2DMipmaps(crate)

end

function cnv:map_cb()
  iup.GLMakeCurrent(self)
  gl.Enable('TEXTURE_2D')            -- Enable Texture Mapping ( NEW )

  LoadGLTextures()

  gl.ShadeModel('SMOOTH')            -- Enable Smooth Shading
  gl.ClearColor(0, 0, 0, 0.5)        -- Black Background
  gl.ClearDepth(1.0)                 -- Depth Buffer Setup
  gl.Enable('DEPTH_TEST')            -- Enables Depth Testing
  gl.DepthFunc('LEQUAL')             -- The Type Of Depth Testing To Do
  gl.Hint('PERSPECTIVE_CORRECTION_HINT','NICEST')

  gl.Light('LIGHT1', 'AMBIENT', LightAmbient)        -- Setup The Ambient Light
  gl.Light('LIGHT1', 'DIFFUSE', LightDiffuse)        -- Setup The Diffuse Light
  gl.Light('LIGHT1', 'POSITION', LightPosition)      -- Position The Light

  gl.Enable('LIGHT1')

end              

dlg = iup.dialog{cnv; title="LuaGL Test Application 07"}

dlg:show()
cnv.rastersize = nil -- reset minimum limitation
timer.run = "YES"

if (not iup.MainLoopLevel or iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
