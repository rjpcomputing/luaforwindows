require( "iuplua" )
require( "iupluacontrols" )

-- Creates boxes
vboxA = iup.vbox{iup.fill{}, iup.label{title="TABS AAA", expand="HORIZONTAL"}, iup.button{title="AAA"}}
vboxB = iup.vbox{iup.label{title="TABS BBB"}, iup.button{title="BBB"}}

-- Sets titles of the vboxes
vboxA.tabtitle = "AAAAAA"
vboxB.tabtitle = "BBBBBB"

-- Creates tabs 
tabs = iup.tabs{vboxA, vboxB}

-- Creates dialog
dlg = iup.dialog{iup.vbox{tabs; margin="10x10"}; title="Test IupTabs", size="150x80"}

-- Shows dialog in the center of the screen
dlg:showxy(iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
