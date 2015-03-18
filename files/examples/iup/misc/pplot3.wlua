require( "iuplua" )

function create_pplot (tbl)
    require( "iuplua_pplot" )

    -- if we explicitly supply ranges, then auto must be switched off for that direction.
    if tbl.AXS_YMIN then tbl.AXS_YAUTOMIN = "NO" end
    if tbl.AXS_YMAX then tbl.AXS_YAUTOMAX = "NO" end
    if tbl.AXS_XMIN then tbl.AXS_XAUTOMIN = "NO" end
    if tbl.AXS_XMAX then tbl.AXS_XAUTOMAX = "NO" end

    local plot = iup.pplot(tbl)

    function plot:AddSeries(xvalues,yvalues,options)
        -- are we given strings for the x values?
        local isstring = type(xvalues[1]) == 'string'
        if isstring then iup.PPlotBegin(plot,1) else iup.PPlotBegin(plot,0) end
        for i = 1,#xvalues do
            if isstring then
                iup.PPlotAddStr(plot,xvalues[i],yvalues[i])
            else
                iup.PPlotAdd(plot,xvalues[i],yvalues[i])
            end
        end
        iup.PPlotEnd(plot)
        -- set any series-specific plot attributes
        if options then
            -- mode must be set before any other attributes!
            if options.DS_MODE then
                plot.DS_MODE = options.DS_MODE
                options.DS_MODE = nil
            end
            for k,v in pairs(options) do
                plot[k] = v
            end
        end
    end
    function plot:Redraw()
        plot.REDRAW='YES'
    end
    return plot
end

function show_dialog (tbl)
    local dlg = iup.dialog(tbl)
    dlg:show()
    iup.MainLoop()
end


plot = create_pplot {TITLE = "Simple Data",MARGINBOTTOM="35",AXS_YMIN=0,GRID="YES"}
plot:AddSeries({0,5,10},{1,6,8},{DS_MARKSTYLE="CIRCLE",DS_MODE="MARKLINE"})

show_dialog{plot; title="Easy Plotting",size="QUARTERxQUARTER"}

