require( "iuplua" )
require( "iupluacontrols" )

mat= iup.matrix{numlin=3, numcol=3}
mat:setcell(1,1,"Only numbers")
mat["mask1:1"] = "/d*"
dg = iup.dialog{mat}
dg:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
