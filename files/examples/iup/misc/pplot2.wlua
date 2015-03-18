require( "iuplua" )
require( "iupluacontrols" )
require( "iuplua_pplot"  )

--MARGINBOTTOM="20"

plot = iup.pplot{TITLE = "Sine and Cosine",
                    MARGINBOTTOM="35",
                    MARGINLEFT="35",
                    AXS_XLABEL="X",
                    AXS_YLABEL="Y",
                    --AXS_YMIN = -1.1,AXS_YAUTOMIN="NO",
                    LEGENDSHOW="YES"
                    }

iup.PPlotBegin(plot,0)
for x = -2,2,0.01 do
    iup.PPlotAdd(plot,x,math.sin(x))
end
iup.PPlotEnd(plot)

iup.PPlotBegin(plot,0)
for x = -2,2,0.01 do
    iup.PPlotAdd(plot,x,math.cos(x))
end
iup.PPlotEnd(plot)
plot.DS_LINEWIDTH = 3

--~ plot.REDRAW="YES"

--~ plot["USE_GDI+"] = "YES" ??

function plot:predraw_cb ()
    print(plot.AXS_YMIN)
--~     plot.AXS_YAUTOMIN = "NO"
--~     plot.AXS_YMIN = plot.AXS_YMIN - 0.1
end

dlg = iup.dialog{plot; title="Two Series",size="QUARTERxQUARTER"}

dlg:show()

iup.MainLoop()
