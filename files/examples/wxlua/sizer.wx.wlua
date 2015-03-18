-----------------------------------------------------------------------------
-- Name:        sizer.wx.lua
-- Purpose:     Shows using sizers in wxLua
-- Author:      Francis Irving
-- Created:     23/01/2002
-- RCS-ID:      $Id: sizer.wx.lua,v 1.8 2008/01/22 04:45:39 jrl1 Exp $
-- Copyright:   (c) 2002 Creature Labs. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame = wx.wxFrame(wx.NULL, wx.wxID_ANY,  "wxLua sizer test frame")

-- Create two controls (note that their parents are the _frame_ (not the sizer))
textEntry = wx.wxTextCtrl(frame, wx.wxID_ANY, "Enter URL");
button = wx.wxButton(frame, wx.wxID_ANY, "test")

-- Put them in a vertical sizer, with ratio 3 units for the text entry, 5 for button
-- and padding of 6 pixels.
sizerTop = wx.wxBoxSizer(wx.wxVERTICAL)
sizerTop:Add(textEntry, 3, wx.wxGROW + wx.wxALL, 6)
sizerTop:Add(button, 5, wx.wxGROW + wx.wxALL, 6)

-- Set up the frame to use that sizer to move/resize its children controls
frame:SetAutoLayout(true)
frame:SetSizer(sizerTop)

-- Optional - these will set an initial minimal size, just enough to hold the
-- controls (more useful for dialogs than a frame)
sizerTop:SetSizeHints(frame)
sizerTop:Fit(frame)

-- Start the application
wx.wxGetApp():SetTopWindow(frame)
frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
