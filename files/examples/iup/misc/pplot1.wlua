require( "iuplua" )
require( "iupluacontrols" )
require( "iuplua_pplot"  )

plot = iup.pplot{TITLE = "A simple XY Plot",
                    MARGINBOTTOM="35",
                    MARGINLEFT="35",
                    AXS_XLABEL="X",
                    AXS_YLABEL="Y"
                    }

iup.PPlotBegin(plot,0)
iup.PPlotAdd(plot,0,0)
iup.PPlotAdd(plot,5,5)
iup.PPlotAdd(plot,10,7)
iup.PPlotEnd(plot)

dlg = iup.dialog{plot; title="Plot Example",size="QUARTERxQUARTER"}

dlg:show()

iup.MainLoop()
