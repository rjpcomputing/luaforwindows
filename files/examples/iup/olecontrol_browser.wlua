-- iupole-browser.lua
--
-- Duplicate the iupole_browser.cpp sample in pure lua

require "iuplua"
require "iupluaole"
require "luacom"

-- create the WebBrowser based on its ProgID
local control = iup.olecontrol{"Shell.Explorer.2"}

-- connect it to LuaCOM
control:CreateLuaCOM()

-- Sets production mode
control.designmode= "NO"

-- Create a dialog containing the OLE control

local addr = iup.text{
    expand="HORIZONTAL",
    tip="Type an URL here",
}

local bt = iup.button{
    title="Load",
    tip="Click to load the URL",
    action=function()
	control.com:Navigate(addr.value)
    end
}

local dlg = iup.dialog{
    title="IupOle",
    size="HALFxHALF",
    iup.vbox{
	iup.hbox{ addr, bt},
	control,
    }
}

-- Show the dialog and run the main loop
dlg:show()

if (not iup.MainLoopLevel or iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
