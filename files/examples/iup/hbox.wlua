-- IupHbox Example in IupLua 
-- Creates a dialog with buttons placed side by side, with the purpose 
-- of showing the organization possibilities of elements inside an hbox. 
-- The ALIGNMENT attribute is explored in all its possibilities to obtain 
-- the given effect. 

require( "iuplua" )

fr1 = iup.frame
{
	iup.hbox
	{
		iup.fill{},
		iup.button{title="1", size="30x30"},
		iup.button{title="2", size="30x40"},
		iup.button{title="3", size="30x50"},
		iup.fill{};
		alignment = "ATOP"
	};
	title = "Alignment = ATOP"
}

fr2 = iup.frame
{
	iup.hbox
	{
		iup.fill{},
		iup.button{title="1", size="30x30", action=""},
		iup.button{title="2", size="30x40", action=""},
		iup.button{title="3", size="30x50", action=""},
		iup.fill{};
		alignment = "ACENTER"
	};
	title = "Alignment = ACENTER"
}

fr3 = iup.frame
{
	iup.hbox
	{
		iup.fill{},
		iup.button{title="1", size="30x30", action=""},
		iup.button{title="2", size="30x40", action=""},
		iup.button{title="3", size="30x50", action=""},
		iup.fill{};
		alignment = "ABOTTOM"
	};
	title = "Alignment = ABOTTOM"
}

dlg = iup.dialog
{
	iup.frame
	{
		iup.vbox
		{
			fr1,
			fr2,
			fr3
		}; title="HBOX",
	};
  title="Alignment",
  size=140
}
	
dlg:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
