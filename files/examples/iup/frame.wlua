-- IupFrame Example in IupLua 
-- Draws a frame around a button. Note that FGCOLOR is added to the frame but 
-- it is inherited by the button. 

require( "iuplua" )

-- Creates frame with a label
frame = iup.frame
          {
            iup.hbox
            {
              iup.fill{},
              iup.label{title="IupFrame Test"},
              iup.fill{},
              NULL
            }
          } ;

-- Sets label's attributes 
frame.fgcolor = "255 0 0"
frame.size    = EIGHTHxEIGHTH
frame.title   = "This is the frame"
frame.margin  = "10x10"

-- Creates dialog  
dialog = iup.dialog{frame};

-- Sets dialog's title 
dialog.title = "IupFrame"

dialog:showxy(iup.CENTER,iup.CENTER) -- Shows dialog in the center of the screen 

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
