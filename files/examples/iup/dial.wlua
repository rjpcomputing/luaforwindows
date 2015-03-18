--IupDial Example in IupLua 

require( "iuplua" )
require( "iupluacontrols" )

lbl_h = iup.label{title = "0", alignment = "ACENTER", size = "100x10"}
lbl_v = iup.label{title = "0", alignment = "ACENTER", size = "100x10"}
lbl_c = iup.label{title = "0", alignment = "ACENTER", size = "100x10"}

dial_v = iup.dial{"VERTICAL"; size="100x100"}
dial_h = iup.dial{"HORIZONTAL"; density=0.3}

function dial_v:mousemove_cb(a)
   lbl_v.title = a
   return iup.DEFAULT
end

function dial_h:mousemove_cb(a)
   lbl_h.title = a
   return iup.DEFAULT
end

dlg = iup.dialog
{
    iup.vbox
    {
      iup.vbox
      {
        dial_v,
        lbl_v,
      },
      iup.vbox
      { 
        dial_h,
        lbl_h,
      }; margin="10x10", gap="5"
    }; title="IupDial"
}

dlg:showxy(iup.CENTER,iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
