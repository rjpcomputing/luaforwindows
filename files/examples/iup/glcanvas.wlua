-- Example IupGLCanvas in Lua
-- Creates a OpenGL canvas and draws a line in it.
-- This example uses gllua binding of OpenGL to Lua.

require("iuplua")
require("iupluagl")
require("luagl")

cnv = iup.glcanvas{buffer="DOUBLE", rastersize = "300x300"}

function cnv:action(x, y)
  iup.GLMakeCurrent(self)
  gl.ClearColor(1.0, 1.0, 1.0, 1.0)
  gl.Clear(gl.COLOR_BUFFER_BIT)
  gl.Clear(gl.DEPTH_BUFFER_BIT)
  gl.MatrixMode( gl.PROJECTION )
  gl.Viewport(0, 0, 300, 300)
  gl.LoadIdentity()
  gl.Begin( gl.LINES )
  gl.Color(1.0, 0.0, 0.0)
  gl.Vertex(0.0, 0.0)
  gl.Vertex(10.0, 10.0)
  gl.End()
  iup.GLSwapBuffers(self)
end

dlg = iup.dialog{cnv; title="IupGLCanvas Example"}

function cnv:k_any(c)
  if c == iup.K_q or c == iup.K_Esc then
    return iup.CLOSE
  else
    return iup.DEFAULT
  end
end


dlg:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
