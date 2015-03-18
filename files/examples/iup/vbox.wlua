-- IupVbox Example in IupLua 
-- Creates a dialog with buttons placed one above the other, showing 
-- the organization possibilities of the elements inside a vbox. 
-- The ALIGNMENT attribute is explored in all its possibilities to obtain 
-- the effects. The attributes GAP, MARGIN and SIZE are also tested. 

require( "iuplua" )

-- Creates frame 1
frm_1 = iup.frame
{
  iup.hbox
  {
    iup.fill {},
    iup.vbox
    {
      iup.button {title = "1", size = "20x30", action = ""},
      iup.button {title = "2", size = "30x30", action = ""},
      iup.button {title = "3", size = "40x30", action = ""} ;
      -- Sets alignment and gap of vbox
      alignment = "ALEFT", gap = 10
    },
    iup.fill {}
  } ;
  -- Sets title of frame 1
  title = "ALIGNMENT = ALEFT, GAP = 10"
}

-- Creates frame 2
frm_2 = iup.frame
{
  iup.hbox
  {
    iup.fill {},
    iup.vbox
    {
      iup.button {title = "1", size = "20x30", action = ""},
      iup.button {title = "2", size = "30x30", action = ""},
      iup.button {title = "3", size = "40x30", action = ""} ;
      -- Sets alignment and margin of vbox
      alignment = "ACENTER",
    },
    iup.fill {}
  } ;
  -- Sets title of frame 1
  title = "ALIGNMENT = ACENTER"
}

-- Creates frame 3
frm_3 = iup.frame
{
  iup.hbox
  {
    iup.fill {},
    iup.vbox
    {
      iup.button {title = "1", size = "20x30", action = ""},
      iup.button {title = "2", size = "30x30", action = ""},
      iup.button {title = "3", size = "40x30", action = ""} ;
      -- Sets alignment and size of vbox
      alignment = "ARIGHT"
    },
    iup.fill {}
  } ;
  -- Sets title of frame 3
  title = "ALIGNMENT = ARIGHT"
}

dlg = iup.dialog
{
  iup.vbox
  {
    frm_1,
    frm_2,
    frm_3
  } ;
  title = "IupVbox Example", size = "QUARTER"
}

-- Shows dialog in the center of the screen
dlg:showxy (iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
