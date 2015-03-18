--IupTuio Example in Lua 

require( "iuplua" )
require( "iupluatuio" )

cv     = iup.canvas {size="300x100", xmin=0, xmax=99, posx=0, dx=10}
dg     = iup.dialog{iup.frame{cv}; title="IupCanvas"}
tuio	 = iup.tuioclient{}

function cv:motion_cb(x, y, r)
  --print(x, y, r)
end

function cv:touch_cb(id, x, y, status)
	print(id, x, y, status)
end

tuio.connect = "YES"
tuio.targetcanvas = cv

dg:showxy(iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
