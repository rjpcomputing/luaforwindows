-------------------------------------------------------------------------=---
-- Name:        choices.wx.lua
-- Purpose:     Tests wxRadioBox, wxNotebook controls
-- Author:      J Winwood, Francesco Montorsi
-- Created:     March 2002
-- Copyright:   (c) 2002-5 Lomtick Software. All rights reserved.
-- Licence:     wxWidgets licence
-------------------------------------------------------------------------=---

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame = nil

function HandleEvents(event)
    -- Note: event.GetEventObject() returns a wxObject, but we know that all
    --       events sent to this function will be from a wxWindow derived
    --       class, whose base class is a wxObject.
    --       Use DynamicCast to call functions from the wxWindow base class.
    local name = event:GetEventObject():DynamicCast("wxWindow"):GetName()
    frame:SetStatusText(string.format("%s - selected item %d '%s'", name, event:GetSelection(), event:GetString()), 0)
end

function main()
    -- create the hierarchy: frame -> notebook
    frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxLua Choices",
                       wx.wxDefaultPosition, wx.wxSize(550, 350))
    frame:CreateStatusBar(1)
    frame:SetStatusText("wxEvents from controls will be displayed here", 0)

    local notebook = wx.wxNotebook(frame, wx.wxID_ANY,
                                   wx.wxDefaultPosition, wx.wxSize(410, 300))
                                   --wx.wxNB_BOTTOM)

    local choices = {"one", "two", "three", "four"}

    -- create first panel in the notebook control
    local panel1 = wx.wxPanel(notebook, wx.wxID_ANY)
    local sizer1 = wx.wxBoxSizer(wx.wxVERTICAL)
    local radioBox = wx.wxRadioBox(panel1, wx.wxID_ANY, "wxRadioBox",
                                   wx.wxDefaultPosition, wx.wxDefaultSize,
                                   choices, 1, wx.wxRA_SPECIFY_ROWS)
    local listBox = wx.wxListBox(panel1, wx.wxID_ANY, wx.wxDefaultPosition,
                                 wx.wxDefaultSize, choices)

    local listBoxStaticBox = wx.wxStaticBox( panel1, wx.wxID_ANY, "wxListBox")
    local listBoxStaticBoxSizer = wx.wxStaticBoxSizer( listBoxStaticBox, wx.wxVERTICAL );
    listBoxStaticBoxSizer:Add(listBox, 1, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)

    sizer1:Add(radioBox, 1, wx.wxALL + wx.wxGROW, 5)
    sizer1:Add(listBoxStaticBoxSizer, 1, wx.wxALL + wx.wxGROW, 5)
    panel1:SetSizer(sizer1)
    sizer1:SetSizeHints(panel1)
    notebook:AddPage(panel1, "wxRadioBox and wxListBox")

    -- create second panel in the notebook control
    local panel2 = wx.wxPanel(notebook, wx.wxID_ANY)
    local sizer2 = wx.wxBoxSizer(wx.wxVERTICAL)

    local comboBox = wx.wxComboBox(panel2, wx.wxID_ANY, "Select a choice",
                                   wx.wxDefaultPosition, wx.wxDefaultSize,
                                   choices)
    -- Test the binding generator to properly overload
    --   wxComboBox::SetSelection(int from, int to) (to mark text) and
    --   wxControlWithItems::SetSelection(int sel)
    comboBox:SetSelection(2)
    comboBox:SetSelection(1, 3)
    local choice = wx.wxChoice(panel2, wx.wxID_ANY,
                               wx.wxDefaultPosition, wx.wxDefaultSize,
                               choices)
    local checkListBox = wx.wxCheckListBox(panel2, wx.wxID_ANY,
                                           wx.wxDefaultPosition, wx.wxDefaultSize,
                                           choices, wx.wxLB_MULTIPLE)

    local comboBoxStaticBox = wx.wxStaticBox( panel2, wx.wxID_ANY, "wxComboBox")
    local comboBoxStaticBoxSizer = wx.wxStaticBoxSizer( comboBoxStaticBox, wx.wxVERTICAL );
    comboBoxStaticBoxSizer:Add(comboBox, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)

    local choiceBoxStaticBox = wx.wxStaticBox( panel2, wx.wxID_ANY, "wxChoice")
    local choiceBoxStaticBoxSizer = wx.wxStaticBoxSizer( choiceBoxStaticBox, wx.wxVERTICAL );
    choiceBoxStaticBoxSizer:Add(choice, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)

    local checkListBoxStaticBox = wx.wxStaticBox( panel2, wx.wxID_ANY, "wxCheckListBox")
    local checkListBoxStaticBoxSizer = wx.wxStaticBoxSizer( checkListBoxStaticBox, wx.wxVERTICAL );
    checkListBoxStaticBoxSizer:Add(checkListBox, 1, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)

    sizer2:Add(comboBoxStaticBoxSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)
    sizer2:Add(choiceBoxStaticBoxSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)
    sizer2:Add(checkListBoxStaticBoxSizer, 1, wx.wxALL + wx.wxGROW, 5)
    panel2:SetSizer(sizer2)
    sizer2:SetSizeHints(panel2)
    notebook:AddPage(panel2, "wxComboBox, wxChoice, and wxCheckListBox")

    frame:SetSizeHints(notebook:GetBestSize():GetWidth(),
                       notebook:GetBestSize():GetHeight())

    -- typically you will give a control a specific window id and connect an
    -- event handler for that id, in this case respond to any id
    frame:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED, HandleEvents)

    frame:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_RADIOBOX_SELECTED, HandleEvents)
    frame:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_LISTBOX_SELECTED, HandleEvents)

    frame:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_COMBOBOX_SELECTED, HandleEvents)
    frame:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_CHOICE_SELECTED, HandleEvents)
    frame:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_CHECKLISTBOX_TOGGLED, HandleEvents)

    frame:Show(true)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
