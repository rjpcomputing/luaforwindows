-- Enhanced from a script written by Wim Langers

require'cdlua'
require'iuplua'
require'iupluacd'
require'cdluapdf'

function DrawInCanvas(canvas)
  -- If you want that your coordinates means the same thing independent from the driver
  -- then set the Window to be the your "world" coordinate system
  canvas:wWindow(0, 50, 0, 50)
  
  -- The you just have to choose how this "world" will be showed in the canvas by setting the Viewport
  -- Since you set a square world, set a square Viewport to keep the aspect ratio
  local width, height = canvas:GetSize()
  local square_size = width
  if (width > height) then square_size = height end
  canvas:wViewport(0, square_size, 0, square_size)
  
  -- The file drivers will have the same size all the time, but the dialog you can change its size
  -- since this is dinamically changed, the drawing will scale on screen when the dialog is resized
  -- if you do not want that, you can set wWindow and wViewport in another place in the code

  canvas:Foreground(cd.BLACK)
  canvas:TextAlignment(cd.CENTER)
  canvas:TextOrientation(0)
  
  -- size in mm actually do not depend on the transformation
  canvas:wFont('Courier', cd.BOLD, 3) -- size in mm
  canvas:wLineWidth(0.25) -- size in mm
  
  canvas:wRect(10,10 + 8,10 + 1,10 + 7)
  canvas:wText(10 + 2,10 + 2,'S')
  canvas:wText(10 + 2,10 + 5,'R')
  canvas:wText(10 + 6,10 + 5,'Q')
  canvas:wArc(10 + 9,10 + 2,2,2,0,360)
  canvas:wSector(20,20,2,2,0,360)
end

-- PS
canvas = cd.CreateCanvas(cd.PS,'test.ps -l0 -r0 -b0 -t0 -o') -- no margins, landscape as a rotation, default size A4, 300 DPI
DrawInCanvas(canvas)
cd.KillCanvas(canvas)

-- PDF
canvas = cd.CreateCanvas(cd.PDF,'test.pdf -o') -- landscape as just a swith between w and h, default size A4, 300 DPI
DrawInCanvas(canvas)
cd.KillCanvas(canvas)

-- SVG
canvas = cd.CreateCanvas(cd.SVG,'test.svg 50x50') -- size in mm, 96 DPI
DrawInCanvas(canvas)
cd.KillCanvas(canvas)



-- Screen
iupCanvas = iup.canvas{scrollbar = 'yes'}
dlg = iup.dialog{iupCanvas, title="Canvas Test", size="100x100"}
function iupCanvas:map_cb()
  canvas = cd.CreateCanvas(cd.IUP,self) -- store the CD canvas in a IUP attribute
end

function iupCanvas:action()
  canvas:Activate()
  canvas:Clear()
  DrawInCanvas(canvas)
end

dlg:show()
iup.MainLoop()
