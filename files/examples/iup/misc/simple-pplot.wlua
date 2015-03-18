require "iuplua"
require "iupx" 

function least_squares (xx,yy)
    local xsum = 0.0
    local ysum = 0.0
    local xxsum = 0.0
    local yysum = 0.0
    local xysum = 0.0
    local n = #xx
    for i = 1,n do
        local x,y = xx[i], yy[i]
        xsum = xsum + x
        ysum = ysum + y
        xxsum = xxsum + x*x
        yysum = yysum + y*y
        xysum = xysum + x*y
    end
    local m = (xsum*ysum/n - xysum )/(xsum*xsum/n - xxsum)
    local c = (ysum - m*xsum)/n
    return m,c
end

local xx = {0,2,5,10}
local yy = {1,1.5,6,8}
local m,c = least_squares(xx,yy)

function eval (x) return m*x + c end

local plot = iupx.pplot {TITLE = "Simple Data",AXS_YMIN=0,GRID="YES"}

-- the original data
plot:AddSeries(xx,yy,{DS_MODE="MARK",DS_MARKSTYLE="CIRCLE"})
-- the least squares fit
local xmin,xmax = xx[1],xx[#xx]
plot:AddSeries({xmin,xmax},{eval(xmin),eval(xmax)})

iupx.show_dialog{plot; title="Easy Plotting",size="QUARTERxQUARTER"}

