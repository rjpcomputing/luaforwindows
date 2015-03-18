-- IupFill Example in IupLua 
-- Uses the Fill element to horizontally centralize a button and to 
-- justify it to the left and right.

require( "iuplua" )

-- Creates frame with left aligned button
frame_left = iup.frame
{
  iup.hbox
  {
    iup.button{ title = "Ok" },
    iup.fill{},
  }; title = "Left aligned" -- Sets frame's title
}

-- Creates frame with centered button
frame_center = iup.frame
{
  iup.hbox
  {
    iup.fill{},
    iup.button{ title = "Ok" },
    iup.fill{},
  } ; title = "Centered" -- Sets frame's title
}

-- Creates frame with right aligned button 
frame_right = iup.frame
{
  iup.hbox
  {
    iup.fill {},
    iup.button { title = "Ok" },
      
  } ; title = "Right aligned" -- Sets frame's title
}

-- Creates dialog with these three frames 
dialog = iup.dialog 
{
  iup.vbox{frame_left, frame_center, frame_right,}; 
    size = 120, title = "IupFill"
}

-- Shows dialog in the center of the screen
dialog:showxy(iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
