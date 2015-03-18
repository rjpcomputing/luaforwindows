-----------------------------------------------------------------------------
-- Name:        mdi.wx.lua
-- Purpose:     wxMdi wxLua sample
-- Author:      J Winwood
-- Modified by:
-- Created:     16/11/2001
-- RCS-ID:      $Id: mdi.wx.lua,v 1.15 2008/01/22 04:45:39 jrl1 Exp $
-- Copyright:   (c) 2001 Lomtick Software. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame       = nil
childList   = {}
numChildren = 0

function CreateChild()
    local child = wx.wxMDIChildFrame( frame, wx.wxID_ANY, "" )
    child:SetSize(330,340)
    childList[child:GetId()] = child
    numChildren = numChildren + 1
    child:SetTitle("Child "..numChildren)

    function OnPaint(event)
        local id = event:GetId()
        local win = event:GetEventObject():DynamicCast("wxWindow")
        local dc = wx.wxPaintDC(win) -- or can use childList[id]
        dc:DrawRectangle(10, 10, 300, 300);
        dc:DrawRoundedRectangle(20, 20, 280, 280, 20);
        dc:DrawEllipse(30, 30, 260, 260);
        dc:DrawText("A test string for window Id "..tostring(win:GetId()), 50, 150);
        dc:delete() -- ALWAYS delete() any wxDCs created when done
    end
    child:Connect(wx.wxEVT_PAINT, OnPaint)
    child:Show(true)
end


frame = wx.wxMDIParentFrame( wx.NULL, wx.wxID_ANY, "wxLua MDI Demo",
                             wx.wxDefaultPosition, wx.wxSize(450, 450),
                             wx.wxDEFAULT_FRAME_STYLE )


local fileMenu = wx.wxMenu()
fileMenu:Append(wx.wxID_NEW,  "&New",  "Create a new child window")
fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

local helpMenu = wx.wxMenu()
helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua MDI Application")

local menuBar = wx.wxMenuBar()
menuBar:Append(fileMenu, "&File")
menuBar:Append(helpMenu, "&Help")

frame:SetMenuBar(menuBar)

frame:CreateStatusBar(1)
frame:SetStatusText("Welcome to wxLua.")

frame:Connect(wx.wxID_NEW, wx.wxEVT_COMMAND_MENU_SELECTED,
              function (event) CreateChild() end )

frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
              function (event) frame:Close() end )

frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        wx.wxMessageBox('This is the "About" dialog of the MDI wxLua sample.\n'..
                        wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                        "About wxLua",
                        wx.wxOK + wx.wxICON_INFORMATION,
                        frame )
    end )

frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
