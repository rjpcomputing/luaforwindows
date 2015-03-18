require 'iuplua'
require "iuplua_pplot"

iupxpplot = {}

function iupxpplot.pplot (tbl)

	if tbl.AXS_BOUNDS then
		local t = tbl.AXS_BOUNDS
		tbl.AXS_XMIN = t[1]
		tbl.AXS_YMIN = t[2]
		tbl.AXS_XMAX = t[3]
		tbl.AXS_YMAX = t[4]
	end

    -- the defaults for these values are too small, at least on my system!
    if not tbl.MARGINLEFT then tbl.MARGINLEFT = 30 end
    if not tbl.MARGINBOTTOM then tbl.MARGINBOTTOM = 35 end

    -- if we explicitly supply ranges, then auto must be switched off for that direction.
    if tbl.AXS_YMIN then tbl.AXS_YAUTOMIN = "NO" end
    if tbl.AXS_YMAX then tbl.AXS_YAUTOMAX = "NO" end
    if tbl.AXS_XMIN then tbl.AXS_XAUTOMIN = "NO" end
    if tbl.AXS_XMAX then tbl.AXS_XAUTOMAX = "NO" end

    local plot = iup.pplot(tbl)
    plot.End = iup.PPlotEnd
    plot.Add = iup.PPlotAdd
    function plot.Begin ()
        return iup.PPlotBegin(plot,0)
    end

    function plot:AddSeries(xvalues,yvalues,options)
        plot:Begin()
        if type(xvalues[1]) == "table" then
            options = yvalues
            for i,v in ipairs(xvalues) do
                plot:Add(v[1],v[2])
            end
        else
            for i = 1,#xvalues do
                plot:Add(xvalues[i],yvalues[i])
            end
        end
        plot:End()
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
