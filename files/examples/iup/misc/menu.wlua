-- Showing off iupx.menu, a simplified way to build menus from a Lua table specification.
require( "iuplua" )
require( "iupx" )

function default ()
  iup.Message ("Warning", "Only Exit performs an operation")
  return iup.DEFAULT
end

function do_close ()
  return iup.CLOSE
end

local mmenu = {
	"File",{
		"New",default,
		"Open",default,
		"Close",default,
		"-",nil,
		"Exit",do_close,
	},
	"Edit",{
		"Copy",default,
		"Paste",default,
        "-",nil,
        "Format",{
            "DOS",default,
            "UNIX",default
        }
	}
}

-- Creates a text, sets its value and turns on text readonly mode
text = iup.text {value = "This text is here only to compose", expand = "YES"}

-- Creates dialog with a text, sets its title and associates a menu to it
dlg = iup.dialog {text; title ="IupSubmenu Example",
      menu = iupx.menu(mmenu), size = "QUARTERxEIGHTH"}

-- Shows dialog in the center of the screen
dlg:showxy (iup.CENTER,iup.CENTER)

iup.MainLoop()
