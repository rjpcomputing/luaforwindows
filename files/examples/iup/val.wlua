-- IupVal Example in IupLua 
-- Creates two Valuator controls, exemplifying the two possible types. 
-- When manipulating the Valuator, the label's value changes.

require( "iuplua" )
require( "iupluacontrols" )

if not string then
  string = {}
  string.format = format
end

function fbuttonpress(self)
  if(self.orientation == "VERTICAL") then
    lbl_v.fgcolor = "255 0 0"
  else
    lbl_h.fgcolor = "255 0 0"
  end
  return iup.DEFAULT
end

function fbuttonrelease(self)
  if(self.orientation == "VERTICAL") then
    lbl_v.fgcolor = "0 0 0"
  else
    lbl_h.fgcolor = "0 0 0"
  end
  return iup.DEFAULT
end

function fmousemove(self, val)
  local buffer = "iup.VALUE="..string.format('%.2f', val)
  if (self.orientation == "VERTICAL") then
    lbl_v.title=buffer
  else
    lbl_h.title=buffer
  end
  return iup.DEFAULT
end

val_v = iup.val{"VERTICAL"; min=0, max=1,	value="0.3", 
    mousemove_cb=fmousemove,
		button_press_cb=fbuttonpress,
		button_release_cb=fbuttonrelease
}

lbl_v = iup.label{title="VALUE=   ", size=70}

val_h = iup.val{"HORIZONTAL"; min=0, max=1,	value=0,	
    mousemove_cb=fmousemove,
		button_press_cb=fbuttonpress,
		button_release_cb=fbuttonrelease
}

lbl_h = iup.label{title="VALUE=   ", size=70}

dlg_val = iup.dialog
{
	iup.hbox
	{
		iup.frame
		{
			iup.vbox
			{
				val_v,
				lbl_v
			}
		},
		iup.frame
		{
			iup.vbox
			{
				val_h,
				lbl_h
			}
		}
	};
	title="Valuator Test"
}

dlg_val:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
