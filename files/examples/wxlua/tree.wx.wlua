-----------------------------------------------------------------------------
-- Name:        tree.wx.lua
-- Purpose:     wxTreeCtrl wxLua sample
-- Author:      J Winwood
-- Modified by:
-- Created:     16/11/2001
-- RCS-ID:
-- Copyright:   (c) 2001 J Winwood. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-- create a nice string using the wxTreeItemId and our table of "data"
function CreateLogString(treeitem_id)
    local value = treeitem_id:GetValue()
    local str = "wxTreeItemId:GetValue():"..tostring(value)
    str = str.." Data: '"..treedata[value].data.."'"
    return str
end

function main()
    frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "wxLua wxTreeCtrl Sample",
                        wx.wxDefaultPosition, wx.wxSize(450, 400),
                        wx.wxDEFAULT_FRAME_STYLE )

    -- create the menubar and attach it
    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")
    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua wxTreeCtrl Sample")

    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")

    frame:SetMenuBar(menuBar)

    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            frame:Close(true)
        end )

    -- connect the selection event of the about menu item
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('This is the "About" dialog of the wxLua wxTreeCtrl sample.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About wxLua",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )

    -- create our treectrl
    tree = wx.wxTreeCtrl( frame, wx.wxID_ANY,
                          wx.wxDefaultPosition, wx.wxSize(-1, 200),
                          wx.wxTR_LINES_AT_ROOT + wx.wxTR_HAS_BUTTONS )

    -- create our log window
    textCtrl = wx.wxTextCtrl( frame, wx.wxID_ANY, "",
                              wx.wxDefaultPosition, wx.wxSize(-1, 200),
                              wx.wxTE_READONLY + wx.wxTE_MULTILINE )

    rootSizer = wx.wxFlexGridSizer(0, 1, 0, 0)
    rootSizer:AddGrowableCol(0)
    rootSizer:AddGrowableRow(0)
    rootSizer:Add( tree, 0, wx.wxGROW+wx.wxALIGN_CENTER_HORIZONTAL, 0 )
    rootSizer:Add( textCtrl, 0, wx.wxGROW+wx.wxALIGN_CENTER_HORIZONTAL, 0 )
    frame:SetSizer( rootSizer )
    frame:Layout() -- help sizing the windows before being shown

    -- create a table to store any extra information for each node like this
    -- you don't have to store the id in the table, but it might be useful
    -- treedata[id] = { id=wx.wxTreeCtrlId, data="whatever data we want" }
    treedata = {}

    local root_id = tree:AddRoot( "Root" )
    treedata[root_id:GetValue()] = { id = root_id:GetValue(), data = "I'm the root item" }

    for idx = 0, 10 do
        local parent_id = tree:AppendItem( root_id, "Parent ("..idx..")" )
        treedata[parent_id:GetValue()] = { id = parent_id:GetValue(), data = "I'm the data for Parent ("..idx..")" }
        for jdx = 0, 5 do
            local child_id = tree:AppendItem( parent_id, "Child ("..idx..", "..jdx..")" )
            treedata[child_id:GetValue()] = { id = child_id:GetValue(), data = "I'm the child data for Parent ("..idx..", "..jdx..")" }
        end
        if (idx == 2) or (idx == 5) then
            tree:Expand(parent_id)
        end
    end

    -- connect to some events from the wxTreeCtrl
    tree:Connect( wx.wxEVT_COMMAND_TREE_ITEM_EXPANDING,
        function( event )
            local item_id = event:GetItem()
            local str = "Item expanding : "..CreateLogString(item_id).."\n"
            textCtrl:AppendText(str)
        end )
    tree:Connect( wx.wxEVT_COMMAND_TREE_ITEM_COLLAPSING,
        function( event )
            local item_id = event:GetItem()
            local str = "Item collapsing : "..CreateLogString(item_id).."\n"
            textCtrl:AppendText(str)
        end )
    tree:Connect( wx.wxEVT_COMMAND_TREE_ITEM_ACTIVATED,
        function( event )
            local item_id = event:GetItem()
            local str = "Item activated : "..CreateLogString(item_id).."\n"
            textCtrl:AppendText(str)
        end )
    tree:Connect( wx.wxEVT_COMMAND_TREE_SEL_CHANGED,
        function( event )
            local item_id = event:GetItem()
            local str = "Item sel changed : "..CreateLogString(item_id).."\n"
            textCtrl:AppendText(str)
        end )

    tree:Expand(root_id)
    wx.wxGetApp():SetTopWindow(frame)

    frame:Show(true)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
