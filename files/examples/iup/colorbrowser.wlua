-- Creates a IupColorBrowser control and updates, through 
-- callbacks, the values of texts representing the R, G and B 
-- components of the selected color.

require( "iuplua" )
require( "iupluacontrols" )

text_red = iup.text{}
text_green = iup.text{}
text_blue = iup.text{}

cb = iup.colorbrowser{}

function update(r, g, b)
  text_red.value = r
  text_green.value = g
  text_blue.value = b
end

function cb:drag_cb(r, g ,b)
  update(r,g,b)
end

function cb:change_cb(r, g ,b)
  update(r,g,b)
end

vbox = iup.vbox {
                 iup.fill {}, 
                 text_red, 
                 iup.fill {}, 
                 text_green, 
                 iup.fill {}, 
                 text_blue, 
                 iup.fill {}
               }

dlg = iup.dialog{iup.hbox {cb, iup.fill{}, vbox}; title = "ColorBrowser"}
dlg:showxy(iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
