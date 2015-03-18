-----------------------------------------------------------------------------
-- Name:        minimal.wx.lua
-- Purpose:     Minimal wxLua sample
-- Author:      J Winwood
-- Modified by:
-- Created:     16/11/2001
-- RCS-ID:      $Id: minimal.wx.lua,v 1.11 2008/01/22 04:45:39 jrl1 Exp $
-- Copyright:   (c) 2001 J Winwood. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame = nil

-- paint event handler for the frame that's called by wxEVT_PAINT
function OnPaint(event)
    -- must always create a wxPaintDC in a wxEVT_PAINT handler
    local dc = wx.wxPaintDC(panel)
    -- call some drawing functions
    dc:DrawRectangle(10, 10, 300, 300);
    dc:DrawRoundedRectangle(20, 20, 280, 280, 20);
    dc:DrawEllipse(30, 30, 260, 260);
    dc:DrawText("A test string", 50, 150);
    -- the paint DC will be automatically destroyed by the garbage collector,
    -- however on Windows 9x/Me this may be too late (DC's are precious resource)
    -- so delete it here
    dc:delete() -- ALWAYS delete() any wxDCs created when done
end

-- Create a function to encapulate the code, not necessary, but it makes it
--  easier to debug in some cases.
function main()

    -- create the wxFrame window
    frame = wx.wxFrame( wx.NULL,            -- no parent for toplevel windows
                        wx.wxID_ANY,          -- don't need a wxWindow ID
                        "wxLua Minimal Demo", -- caption on the frame
                        wx.wxDefaultPosition, -- let system place the frame
                        wx.wxSize(450, 450),  -- set the size of the frame
                        wx.wxDEFAULT_FRAME_STYLE ) -- use default frame styles

    -- create a single child window, wxWidgets will set the size to fill frame
    panel = wx.wxPanel(frame, wx.wxID_ANY)

    -- connect the paint event handler function with the paint event
    panel:Connect(wx.wxEVT_PAINT, OnPaint)

    -- create a simple file menu
    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

    -- create a simple help menu
    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Minimal Application")

    -- create a menu bar and append the file and help menus
    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")

    -- attach the menu bar into the frame
    frame:SetMenuBar(menuBar)

    -- create a simple status bar
    frame:CreateStatusBar(1)
    frame:SetStatusText("Welcome to wxLua.")

    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
                  function (event) frame:Close(true) end )

    -- connect the selection event of the about menu item
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('This is the "About" dialog of the Minimal wxLua sample.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About wxLua",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )

    -- show the frame window
    frame:Show(true)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
