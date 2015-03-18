-- IupToggle Example in IupLua 
-- Creates 9 toggles: 
--   the first one has an image and an associated callback; 
--   the second has an image and is deactivated; 
--   the third is regular; 
--   the fourth has its foreground color changed; 
--   the fifth has its background color changed; 
--   the sixth has its foreground and background colors changed; 
--   the seventh is deactivated; 
--   the eight has its font changed; 
--   the ninth has its size changed. 

require( "iuplua" )

img1 = iup.image{
       {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,2,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,2,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,2,2,2,2,2,2,2,2,2,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
       colors = {"255 255 255", "0 192 0"}
}

img2 = iup.image{
       {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
       {1,1,1,1,2,2,2,2,2,2,1,1,1,1,1,1},
       {1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1},
       {1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1},
       {1,1,1,2,2,2,2,2,2,2,2,2,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
       {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
       colors = {"255 255 255", "0 192 0"}
}

toggle1 = iup.toggle{title = "", image = img1}
toggle2 = iup.toggle{title = "deactivated toggle with image", image = img2, active="NO"}
toggle3 = iup.toggle{title = "regular toggle"}
toggle4 = iup.toggle{title = "toggle with blue foreground color", fgcolor = BLUE }
toggle5 = iup.toggle{title = "toggle with red background color", bgcolor = RED }
toggle6 = iup.toggle{title = "toggle with black backgrounf color and green foreground color", fgcolor = GREEN, bgcolor = BLACK }
toggle7 = iup.toggle{title = "deactivated toggle", active = "NO" }
toggle8 = iup.toggle{title = "toggle with Courier 14 Bold font", font = "COURIER_BOLD_14" }
toggle9 = iup.toggle{title = "toggle with size EIGHTxEIGHT", size = "EIGHTHxEIGHTH" }

function toggle1:action(v)
   if v == 1 then estado = "pressed" else estado = "released" end
   iup.Message("Toggle 1",estado)
end

box = iup.vbox{ 
                 toggle1,
                 toggle2,
                 toggle3,
                 toggle4,
                 toggle5,
                 toggle6,
                 toggle7,
                 toggle8,
                 toggle9
               }
                
toggles = iup.radio{box; expand="YES"}
dlg = iup.dialog{toggles; title = "IupToggle", margin="5x5", gap="5", resize="NO"}
dlg:showxy(iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
