require( "iuplua" )
require( "iupluagl" )
require( "luagl" )

canvas = iup.glcanvas{buffer="DOUBLE", rastersize = "640x480"}

function canvas:resize_cb(width, height)
  iup.GLMakeCurrent(self)

  gl.Viewport(0, 0, width, height)

  gl.MatrixMode('PROJECTION')
  gl.LoadIdentity()

  gl.MatrixMode('MODELVIEW')
  gl.LoadIdentity()

end

function canvas:action()
  iup.GLMakeCurrent(self)

  gl.MatrixMode("PROJECTION")
  gl.LoadIdentity()
  gl.Ortho(0, 1, 1, 0, -1.0, 1.0)
  gl.MatrixMode("MODELVIEW")
  gl.LoadIdentity()
  gl.PushMatrix()
  gl.Translate(0.25,0.5, 0)
  gl.Scale(0.2, 0.2, 1)

  gl.BlendFunc("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA")

  gl.ClearColor(0,0,0,1)
  gl.Clear("DEPTH_BUFFER_BIT,COLOR_BUFFER_BIT")
  gl.Enable("BLEND")

  -- draw rectangle
  gl.Color( {1, 1, 0, 0.8} )
  gl.Rect(-1,-1,1,1)
  
  --------------------------------------------------------
  -- Create List That Draws the Circle
  --------------------------------------------------------

  planet = 1
  orbit = 2
  pi = 

  gl.NewList(planet, "COMPILE")
    gl.Begin("POLYGON")
      for i=0, 100 do
        cosine = math.cos(i * 2 * math.pi/100.0)
        sine   = math.sin(i * 2 * math.pi/100.0)
        gl.Vertex(cosine,sine)
      end
    gl.End()
  gl.EndList()

  gl.NewList(orbit, "COMPILE")
    gl.Begin("LINE_LOOP")
      for i=0, 100 do
        cosine = math.cos(i * 2 * math.pi/100.0)
        sine   = math.sin(i * 2 * math.pi/100.0)
        gl.Vertex(cosine, sine)
      end
    gl.End()
  gl.EndList()

  --------------------------------------------------------

  gl.Color( {0, 0.5, 0, 0.8} )
  gl.CallList(planet)

  gl.Color( {0, 0, 0, 1} )
  lists = { orbit }
  gl.CallLists(lists)

  gl.EnableClientState ("VERTEX_ARRAY")
  
  vertices  = { {-3^(1/2)/2, 1/2}, {3^(1/2)/2, 1/2}, {0, -1}, {-3^(1/2)/2, -1/2}, {3^(1/2)/2, -1/2}, {0, 1} }
    
  gl.VertexPointer  (vertices)
  
  -- draw first triangle
  gl.Color( {0, 0, 1, 0.5} )

  gl.Begin("TRIANGLES")
    gl.ArrayElement (0)
    gl.ArrayElement (1)
    gl.ArrayElement (2)
  gl.End()

  -- draw second triangle
  gl.Color( {1, 0, 0, 0.5} )
  gl.VertexPointer  (vertices)
  gl.DrawArrays("TRIANGLES", 3, 3)

  -- draw triangles outline
  gl.Color(1,1,1,1)
  elements = { 0, 1, 2}   gl.DrawElements("LINE_LOOP", elements)
  elements = { 3, 4, 5}   gl.DrawElements("LINE_LOOP", elements)

  gl.DisableClientState ("VERTEX_ARRAY")

  gl.PopMatrix()
  gl.Translate(0.75,0.5, 0)
  gl.Scale(0.2, 0.2, 1)

  ----------------------------------------------------------------------------

  gl.BlendFunc("SRC_ALPHA", "ONE_MINUS_SRC_ALPHA")

  -- draw rectangle
  gl.Color( {1, 1, 0, 0.8} )
  
  gl.Begin("QUADS")
    gl.Vertex(-1,-1)
    gl.Vertex( 1,-1)
    gl.Vertex( 1, 1)
    gl.Vertex(-1, 1)
  gl.End()
  -------------------------------
  gl.Color( {0, 0.5, 0, 0.8} )
  gl.Begin("POLYGON")
    for i=0, 100 do
      cosine = math.cos(i * 2 * math.pi/100.0)
      sine   = math.sin(i * 2 * math.pi/100.0)
      gl.Vertex(cosine,sine)
    end
  gl.End()

  gl.Color( {0, 0, 0, 1} )
  gl.Begin("LINE_LOOP")
    for i=0, 100 do
      cosine = math.cos(i * 2 * math.pi/100.0)
      sine   = math.sin(i * 2 * math.pi/100.0)
      gl.Vertex(cosine, sine)
    end
  gl.End()

  -- draw first triangle
  gl.Color( {0, 0, 1, 0.5} )
  gl.Begin("TRIANGLES")
    gl.Vertex (vertices[1])
    gl.Vertex (vertices[2])
    gl.Vertex (vertices[3])
  gl.End()
  -- draw second triangle
  gl.Color( {1, 0, 0, 0.5} )
  gl.Begin("TRIANGLES")
    gl.Vertex (vertices[4])
    gl.Vertex (vertices[5])
    gl.Vertex (vertices[6])
  gl.End()
  -- draw triangles outline
  gl.Color(1,1,1,1)
  gl.Begin("LINE_LOOP")
    gl.Vertex (vertices[1])
    gl.Vertex (vertices[2])
    gl.Vertex (vertices[3])
  gl.End()
  gl.Begin("LINE_LOOP")
    gl.Vertex (vertices[4])
    gl.Vertex (vertices[5])
    gl.Vertex (vertices[6])
  gl.End()

  iup.GLSwapBuffers(self)
  gl.Flush()

end

dialog = iup.dialog{canvas; title="Lua GL Test Application"}
dialog:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
