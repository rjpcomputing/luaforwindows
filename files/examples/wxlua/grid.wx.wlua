-----------------------------------------------------------------------------
-- Name:        grid.wx.lua
-- Purpose:     wxGrid wxLua sample
-- Author:      J Winwood
-- Created:     January 2002
-- Copyright:   (c) 2002 Lomtick Software. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxLua wxGrid Sample",
                         wx.wxPoint(25, 25), wx.wxSize(350, 250))

local fileMenu = wx.wxMenu("", wx.wxMENU_TEAROFF)
fileMenu:Append(wx.wxID_EXIT, "E&xit\tCtrl-X", "Quit the program")

local helpMenu = wx.wxMenu("", wx.wxMENU_TEAROFF)
helpMenu:Append(wx.wxID_ABOUT, "&About\tCtrl-A", "About the Grid wxLua Application")

local menuBar = wx.wxMenuBar()
menuBar:Append(fileMenu, "&File")
menuBar:Append(helpMenu, "&Help")

frame:SetMenuBar(menuBar)

frame:CreateStatusBar(1)
frame:SetStatusText("Welcome to wxLua.")

frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        frame:Close()
    end )

frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        wx.wxMessageBox('This is the "About" dialog of the wxGrid wxLua sample.\n'..
                        wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                        "About wxLua",
                        wx.wxOK + wx.wxICON_INFORMATION,
                        frame )
    end )

grid = wx.wxGrid(frame, wx.wxID_ANY)

grid:CreateGrid(10, 8)
grid:SetColSize(3, 200)
grid:SetRowSize(4, 45)
grid:SetCellValue(0, 0, "First cell")
grid:SetCellValue(1, 1, "Another cell")
grid:SetCellValue(2, 2, "Yet another cell")
grid:SetCellFont(0, 0, wx.wxFont(10, wx.wxROMAN, wx.wxITALIC, wx.wxNORMAL))
grid:SetCellTextColour(1, 1, wx.wxRED)
grid:SetCellBackgroundColour(2, 2, wx.wxCYAN)

frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
