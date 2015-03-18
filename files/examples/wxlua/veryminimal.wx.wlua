-----------------------------------------------------------------------------
-- Name:        minimal.wx.lua
-- Purpose:     'Minimal' wxLua sample
-- Author:      J Winwood
-- Modified by:
-- Created:     16/11/2001
-- RCS-ID:      $Id: veryminimal.wx.lua,v 1.7 2008/01/22 04:45:39 jrl1 Exp $
-- Copyright:   (c) 2001 J Winwood. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame = nil

function main()

    -- create the frame window
    frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "wxLua Very Minimal Demo",
                        wx.wxDefaultPosition, wx.wxSize(450, 450),
                        wx.wxDEFAULT_FRAME_STYLE )

    -- show the frame window
    frame:Show(true)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
