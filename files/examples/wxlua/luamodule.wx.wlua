-----------------------------------------------------------------------------
-- Name:        luamodule.wx.lua
-- Purpose:     Minimal wxLua sample for use as a lua module using require
-- Author:      John Labenski
-- Modified by:
-- Created:     05/13/2006
-- RCS-ID:
-- Copyright:   (c) 2001 John Labenski. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- to make this sample script work out-of-the-box, we need to add
-- to the paths looked by require() all possible locations of the
-- wx.dll/.so module when this script is run from the samples dir.
-- Please also note that this sample can be executed only when
-- wxLua has been compiled in shared mode (--enable-shared on Unix,
-- SHARED=1 on Windows)
package.cpath = package.cpath..";;./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-- simple test of Non GUI elements
p = wx.wxPoint(1,2)
print("The point is", p:GetX(), p:GetY())

frame = wx.wxFrame(wx.NULL, -1, "wxLua module sample")

-- create a simple file menu so you can exit the program nicely
local fileMenu = wx.wxMenu()
fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")
local menuBar = wx.wxMenuBar()
menuBar:Append(fileMenu, "&File")
frame:SetMenuBar(menuBar)
frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
              function (event) frame:Close(true) end )

frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()

