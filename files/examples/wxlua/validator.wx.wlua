-----------------------------------------------------------------------------
-- Name:        validator.wx.lua
-- Purpose:     wxLua validator test program
-- Author:      John Labenski
-- Modified by:
-- Created:     6/10/2007
-- RCS-ID:
-- Copyright:   (c) 2001 John Labenski
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-- NOTES about validators!
-- The controls apparently must be in a wxDialog and they must also
-- be direct children of the dialog. You CANNOT put any controls that
-- you want to use wxGenericValidators with on a panel that's a child of
-- the dialog.

-- You cannot seem to set a wxGenericValidator to a control and then
-- check the value of the wxLuaObject that the validator uses at any
-- time either since the validator only updates it's value when the
-- function TransferDataFromWindow() is called. You cannot set a
-- wxGenericValidator to a wxCheckBox and then call TransferDataFromWindow()
-- on the validator to force it to update as this apparently does nothing.

-- Finally, it appears that you need to have an wxID_OK button for the
-- TransferDataTo/FromWindow() functions to be automatically called by the
-- dialog.


frame = nil

ID_TEST_VALIDATORS  = 1000
ID_CHECKBOX         = 1001
ID_COMBOBOX         = 1002
ID_TEXTCTRL         = 1003
ID_SCROLLBAR        = 1004
ID_CHECKLBOX        = 1005
ID_TEXTCTRL_TVAL_NUM = 1006

-- Set up the initial values for the validators, we use the wxLuaObjects
-- as proxies for the wxGenericValidators to pass the *int *bool, *string, etc,
-- pointers from the validators to and from to lua.
check_val  = true
combo_val  = "Select Item"
text_val   = "Enter text"
scroll_val = 10
checkl_val = { 0, 2 }
text_alpha_val = "DeleteSpace OnlyAlphabetCharsAllowed"

checkObj  = wxlua.wxLuaObject(check_val)
comboObj  = wxlua.wxLuaObject(combo_val)
textObj   = wxlua.wxLuaObject(text_val)
scrollObj = wxlua.wxLuaObject(scroll_val)
checklObj = wxlua.wxLuaObject(checkl_val)
checklObj = wxlua.wxLuaObject(checkl_val)
textAlphaObj = wxlua.wxLuaObject(text_alpha_val)

function CreateDialog()
    dialog = wx.wxDialog(frame, wx.wxID_ANY, "Test Validators")

    checkBox = wx.wxCheckBox(dialog, ID_CHECKBOX, "Check me!",
                            wx.wxDefaultPosition, wx.wxDefaultSize, 0,
                            wx.wxGenericValidatorBool(checkObj))

    comboBox = wx.wxComboBox(dialog, ID_COMBOBOX, "THIS WILL BE OVERWRITTEN",
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            {"Item0", "Item1", "Item2"}, 0,
                            wx.wxGenericValidatorString(comboObj))

    textCtrl = wx.wxTextCtrl(dialog, ID_TEXTCTRL, "THIS WILL BE OVERWRITTEN",
                            wx.wxDefaultPosition, wx.wxDefaultSize, 0,
                            wx.wxGenericValidatorString(textObj))

    scrollBar = wx.wxScrollBar(dialog, ID_SCROLLBAR,
                            wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxSB_HORIZONTAL,
                            wx.wxGenericValidatorInt(scrollObj))
    scrollBar:SetScrollbar(0, 10, 100, 5)

    checklBox = wx.wxCheckListBox(dialog, ID_CHECKLBOX,
                                  wx.wxDefaultPosition, wx.wxDefaultSize,
                                  {"Check 0", "Check 1", "Check 2", "Check 3"}, 0,
                                  wx.wxGenericValidatorArrayInt(checklObj))

    textAlphaCtrl = wx.wxTextCtrl(dialog, ID_TEXTCTRL, "THIS WILL BE OVERWRITTEN",
                            wx.wxDefaultPosition, wx.wxSize(400, -1), 0,
                            wx.wxTextValidator(wx.wxFILTER_ALPHA, textAlphaObj))


    okButton = wx.wxButton(dialog, wx.wxID_OK, "Ok") -- NEED this for validators to work
    okButton:SetDefault()

    flexSizer = wx.wxFlexGridSizer(12, 1, 0, 0)
    flexSizer:AddGrowableCol(0)
    flexSizer:Add(checkBox,  1, wx.wxEXPAND+wx.wxALL, 5)
    flexSizer:Add(comboBox,  1, wx.wxEXPAND+wx.wxALL, 5)
    flexSizer:Add(textCtrl,  1, wx.wxEXPAND+wx.wxALL, 5)
    flexSizer:Add(scrollBar, 1, wx.wxEXPAND+wx.wxALL, 5)
    flexSizer:Add(checklBox, 1, wx.wxEXPAND+wx.wxALL, 5)
    flexSizer:Add(textAlphaCtrl,  1, wx.wxEXPAND+wx.wxALL, 5)

    flexSizer:Add(okButton,  1, wx.wxEXPAND+wx.wxALL, 5)

    dialog:SetSizer(flexSizer)
    flexSizer:SetSizeHints(dialog)

    dialog:ShowModal()
end

function main()

    frame = wx.wxFrame( wx.NULL,              -- no parent for toplevel windows
                        wx.wxID_ANY,          -- don't need a wxWindow ID
                        "wxLua Validator Demo", -- caption on the frame
                        wx.wxDefaultPosition, -- let system place the frame
                        wx.wxSize(450, 420),  -- set the size of the frame
                        wx.wxDEFAULT_FRAME_STYLE ) -- use default frame styles

    -- create a simple status bar
    frame:CreateStatusBar(1)
    frame:SetStatusText("Welcome to wxLua.")

    -- -----------------------------------------------------------------------

    local fileMenu = wx.wxMenu()
    fileMenu:Append(ID_TEST_VALIDATORS, "&Test Validators...", "Show dialog to test validators")
    fileMenu:AppendSeparator()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")
    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Minimal Application")

    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")
    frame:SetMenuBar(menuBar)

    -- connect the selection event of the exit menu item to an
    frame:Connect(ID_TEST_VALIDATORS, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                -- update original values we'll use for the validators
                check_val  = checkObj:GetObject()
                combo_val  = comboObj:GetObject()
                text_val   = textObj:GetObject()
                scroll_val = scrollObj:GetObject()
                checkl_val = checklObj:GetObject()
                text_alpha_val = textAlphaObj:GetObject()

                CreateDialog()

                local s = ""
                s = s.."wxCheckBox  : '"..tostring(checkObj:GetObject()).."'\nInitial value : '"..tostring(check_val).."'\n\n"
                s = s.."wxComboBox  : '"..tostring(comboObj:GetObject()).."'\nInitial value : '"..tostring(combo_val).."'\n\n"
                s = s.."wxTextCtrl  : '"..tostring(textObj:GetObject()).."'\nInitial value : '"..tostring(text_val).."'\n\n"
                s = s.."wxScrollBar : '"..tostring(scrollObj:GetObject()).."'\nInitial value : '"..tostring(scroll_val).."'\n\n"
                s = s.."wxCheckListBox : '"..table.concat(checklObj:GetObject(), ", ").."'\nInitial value : '"..table.concat(checkl_val, ", ").."'\n\n"

                s = s.."wxTextCtrl alpha chars only: '"..tostring(textAlphaObj:GetObject()).."'\nInitial value : '"..tostring(text_alpha_val).."'\n\n"

                frameText:SetValue(s)
            end )

    -- event handler that closes the window
    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event) frame:Close(true) end )

    -- connect the selection event of the about menu item
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('This is the "About" dialog of the Validator wxLua sample.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About wxLua",
                           wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )

    -- -----------------------------------------------------------------------

    frameText = wx.wxTextCtrl(frame, wx.wxID_ANY, "Output of the validator test dialog will be shown here.",
                              wx.wxDefaultPosition, wx.wxDefaultSize,
                              wx.wxTE_MULTILINE)


    -- show the frame window
    frame:Show(true)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
