-- IupLabel Example in IupLua 
-- Creates three labels, one using all attributes except for image, other 
-- with normal text and the last one with an image.. 

require( "iuplua" )

-- Defines a star image
img_star = iup.image {
  { 1,1,1,1,1,1,2,1,1,1,1,1,1 },
  { 1,1,1,1,1,1,2,1,1,1,1,1,1 },
  { 1,1,1,1,1,2,2,2,1,1,1,1,1 },
  { 1,1,1,1,1,2,2,2,1,1,1,1,1 },
  { 1,1,2,2,2,2,2,2,2,2,2,1,1 },
  { 2,2,2,2,2,2,2,2,2,2,2,2,2 },
  { 1,1,1,2,2,2,2,2,2,2,1,1,1 },
  { 1,1,1,1,2,2,2,2,2,1,1,1,1 },
  { 1,1,1,1,2,2,2,2,2,1,1,1,1 }, 
  { 1,1,1,2,2,1,1,2,2,2,1,1,1 },
  { 1,1,2,2,1,1,1,1,1,2,2,1,1 },
  { 1,2,2,1,1,1,1,1,1,1,2,2,1 },
  { 2,2,1,1,1,1,1,1,1,1,1,2,2 }
  -- Sets star image colors
  ; colors = { "0 0 0", "0 198 0" } 
}

-- Creates a label and sets all the attributes of label lbl, except for image
lbl = iup.label { title = "This label has the following attributes set:\nBGCOLOR = 255 255 0\nFGCOLOR = 0 0 255\nFONT = COURIER_NORMAL_14\nTITLE = All text contained here\nALIGNMENT = ACENTER", 
                  bgcolor = "255 255 0", 
                  fgcolor = "0 0 255", 
                  font = "COURIER_NORMAL_14", 
                  alignment = "ACENTER" }
  
-- Creates a label to explain that the label on the right has an image
lbl_explain = iup.label { title = "The label on the right has the image of a star" }

-- Creates a label whose title is not important, cause it will have an image
lbl_star = iup.label { title = "Does not matter", image = img_star }

-- Creates dialog with these three labels
dlg = iup.dialog { iup.vbox { lbl, iup.hbox { lbl_explain, lbl_star }; margin="10x10" }
      ; title = "IupLabel Example" }

-- Shows dialog in the center of the screen 
dlg:showxy ( iup.CENTER, iup.CENTER )

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
