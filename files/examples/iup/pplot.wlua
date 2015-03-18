require( "iuplua" )
require( "iupluacontrols" )
require( "iuplua_pplot"  )

plot = iup.pplot{
  TITLE = "Simple Line",
  MARGINBOTTOM="65",
  MARGINLEFT="65",
  AXS_XLABEL="X",
  AXS_YLABEL="Y",
  LEGENDSHOW="YES",
  LEGENDPOS="TOPLEFT",
}

iup.PPlotBegin(plot, 0)
iup.PPlotAdd(plot, 0, 0)
iup.PPlotAdd(plot, 1, 1)
iup.PPlotEnd(plot)

d = iup.dialog{plot, size="200x100", title="PPlot"}
d:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
