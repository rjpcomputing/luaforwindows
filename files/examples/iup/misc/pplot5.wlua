require "iupx" 

plot = iupx.pplot {TITLE = "Simple Data", AXS_BOUNDS={0,0,100,100}}
plot:AddSeries ({{0,0},{10,10},{20,30},{30,45}})
plot:AddSeries ({{40,40},{50,55},{60,60},{70,65}})
iupx.show_dialog{plot; title="Easy Plotting",size="QUARTERxQUARTER"}