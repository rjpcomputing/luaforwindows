-----------------------------------------------------------------------------
-- Name:        picker.wx.lua
-- Purpose:     Picker wxLua sample
-- Author:      John Labenski
-- Modified by:
-- Created:     6/19/2007
-- RCS-ID:
-- Copyright:   (c) 2007 John Labenski
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame    = nil
textCtrl = nil

ID_COLOURPICKER1 = 1001
ID_COLOURPICKER2 = 1002
ID_COLOURPICKER3 = 1003

ID_DATEPICKER1 = 2001
ID_DATEPICKER2 = 2002
ID_DATEPICKER3 = 2003
ID_DATEPICKER4 = 2004
ID_DATEPICKER5 = 2005

ID_DIRPICKER1  = 3001
ID_DIRPICKER2  = 3002
ID_DIRPICKER3  = 3003
ID_DIRPICKER4  = 3004

ID_FILEPICKER1 = 4001
ID_FILEPICKER2 = 4002
ID_FILEPICKER3 = 4003
ID_FILEPICKER4 = 4004
ID_FILEPICKER5 = 4005

ID_FONTPICKER1 = 5001
ID_FONTPICKER2 = 5002
ID_FONTPICKER3 = 5003
ID_FONTPICKER4 = 5004
ID_FONTPICKER5 = 5005

-- ---------------------------------------------------------------------------
-- Gather up all of the wxEVT_XXX names and hash by their value
-- ---------------------------------------------------------------------------
wxEVT_Names = {}
for k, v in pairs(wx) do
    if string.find(k, "wxEVT_", 1, 1) == 1 then
        wxEVT_Names[v] = k
    end
end

-- ---------------------------------------------------------------------------
-- Handle all wxColourPickerEvents
-- ---------------------------------------------------------------------------
function OnColourPicker(event)
    local evt_type = event:GetEventType()
    local c = event:GetColour()
    local val = c:GetAsString()
    c:delete() -- delete all wxColours when done

    local s = string.format("%s wxColourPickerEvent type: %s=%d id: %d GetColour = '%s'\n\n", wx.wxNow(), wxEVT_Names[evt_type], evt_type, event:GetId(), val)
    textCtrl:AppendText(s)
end

-- ---------------------------------------------------------------------------
-- Handle all wxDateEvents
-- ---------------------------------------------------------------------------
function OnDatePicker(event)
    local evt_type = event:GetEventType()
    local val = event:GetDate():Format()

    local s = string.format("%s wxDateEvent type: %s=%d id: %d GetDate = '%s'\n\n", wx.wxNow(), wxEVT_Names[evt_type], evt_type, event:GetId(), val)
    textCtrl:AppendText(s)
end

-- ---------------------------------------------------------------------------
-- Handle all wxFileDirPickerEvents
-- ---------------------------------------------------------------------------
function OnFileDirPicker(event)
    local evt_type = event:GetEventType()
    local val = event:GetPath()

    local s = string.format("%s wxFileDirPickerEvent type: %s=%d id: %d GetPath = '%s'\n\n", wx.wxNow(), wxEVT_Names[evt_type], evt_type, event:GetId(), val)
    textCtrl:AppendText(s)
end

-- ---------------------------------------------------------------------------
-- Handle all wxFontPickerEvents
-- ---------------------------------------------------------------------------
function OnFontPicker(event)
    local evt_type = event:GetEventType()
    local f = event:GetFont()
    local val = f:GetNativeFontInfoDesc()
    f:delete() -- delete all wxFonts when done

    local s = string.format("%s wxFontPickerEvent type: %s=%d id: %d GetFont = '%s'\n\n", wx.wxNow(), wxEVT_Names[evt_type], evt_type, event:GetId(), val)
    textCtrl:AppendText(s)
end

-- ---------------------------------------------------------------------------
-- Create the window with the picker controls
-- ---------------------------------------------------------------------------
function CreatePickerWindow(parent)

    local scrollWin = wx.wxScrolledWindow(parent, wx.wxID_ANY,
                                    wx.wxDefaultPosition, wx.wxDefaultSize,
                                    wx.wxHSCROLL + wx.wxVSCROLL)
    -- Give the scrollwindow enough size so sizer works when calling Fit()
    scrollWin:SetScrollbars(15, 15, 400, 600, 0, 0, false)

    local mainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    local flexSizer = wx.wxFlexGridSizer(20, 2, 5, 5)
    flexSizer:AddGrowableCol(1)

    local statText = nil -- not used outside of this function

    -- -----------------------------------------------------------------------

    local colourPicker = nil -- not used outside of this function

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxColourPickerCtrl + wxCLRP_DEFAULT_STYLE")
    colourPicker = wx.wxColourPickerCtrl(scrollWin, ID_COLOURPICKER1, wx.wxBLACK,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxCLRP_DEFAULT_STYLE)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(colourPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxColourPickerCtrl + wxCLRP_USE_TEXTCTRL")
    colourPicker = wx.wxColourPickerCtrl(scrollWin, ID_COLOURPICKER2, wx.wxBLACK,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxCLRP_USE_TEXTCTRL)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(colourPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxColourPickerCtrl + wxCLRP_SHOW_LABEL")
    colourPicker = wx.wxColourPickerCtrl(scrollWin, ID_COLOURPICKER3, wx.wxBLACK,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxCLRP_SHOW_LABEL)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(colourPicker, 1, wx.wxEXPAND)

    -- central event handler for all wxColourPickerEvent
    scrollWin:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_COLOURPICKER_CHANGED, OnColourPicker)

    -- -----------------------------------------------------------------------
    flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 1, wx.wxEXPAND)
    flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 1, wx.wxEXPAND)

    local datePicker = nil -- not used outside of this function

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDatePickerCtrl +  wxDP_DEFAULT")
    datePicker = wx.wxDatePickerCtrl(scrollWin, ID_DATEPICKER1, wx.wxDefaultDateTime,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDP_DEFAULT)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(datePicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDatePickerCtrl +  wxDP_SPIN")
    if wx.__WXMSW__ then
        datePicker = wx.wxDatePickerCtrl(scrollWin, ID_DATEPICKER2, wx.wxDefaultDateTime,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx. wxDP_SPIN)
    else
        datePicker = wx.wxStaticText(scrollWin, wx.wxID_ANY, "Supported in MSW only")
    end
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(datePicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDatePickerCtrl +  wxDP_DROPDOWN")
    datePicker = wx.wxDatePickerCtrl(scrollWin, ID_DATEPICKER3, wx.wxDefaultDateTime,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDP_DROPDOWN)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(datePicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDatePickerCtrl +  wxDP_ALLOWNONE")
    datePicker = wx.wxDatePickerCtrl(scrollWin, ID_DATEPICKER4, wx.wxDefaultDateTime,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDP_ALLOWNONE)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(datePicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDatePickerCtrl +  wxDP_SHOWCENTURY")
    datePicker = wx.wxDatePickerCtrl(scrollWin, ID_DATEPICKER5, wx.wxDefaultDateTime,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDP_SHOWCENTURY)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(datePicker, 1, wx.wxEXPAND)

    -- central event handler for all wxDatePickerCtrls
    scrollWin:Connect(wx.wxID_ANY, wx.wxEVT_DATE_CHANGED, OnDatePicker)

    -- -----------------------------------------------------------------------
    flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 1, wx.wxEXPAND)
    flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 1, wx.wxEXPAND)

    local dirPicker = nil -- not used outside of this function

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDirPickerCtrl +  wxDIRP_DEFAULT_STYLE")
    dirPicker = wx.wxDirPickerCtrl(scrollWin, ID_DIRPICKER1, wx.wxGetCwd(), wx.wxDirSelectorPromptStr,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDIRP_DEFAULT_STYLE)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(dirPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDirPickerCtrl +  wxDIRP_USE_TEXTCTRL")
    dirPicker = wx.wxDirPickerCtrl(scrollWin, ID_DIRPICKER2, wx.wxGetCwd(), "I'm the message parameter",
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDIRP_USE_TEXTCTRL)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(dirPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDirPickerCtrl +  wxDIRP_CHANGE_DIR")
    dirPicker = wx.wxDirPickerCtrl(scrollWin, ID_DIRPICKER3, wx.wxGetCwd(), wx.wxDirSelectorPromptStr,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDIRP_CHANGE_DIR)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(dirPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxDirPickerCtrl +  wxDIRP_DIR_MUST_EXIST")
    dirPicker = wx.wxDirPickerCtrl(scrollWin, ID_DIRPICKER4, wx.wxGetCwd(), wx.wxDirSelectorPromptStr,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDIRP_DIR_MUST_EXIST)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(dirPicker, 1, wx.wxEXPAND)

    -- central event handler for all wxDirPickerCtrl
    scrollWin:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_DIRPICKER_CHANGED, OnFileDirPicker)

    -- -----------------------------------------------------------------------
    flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 1, wx.wxEXPAND)
    flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 1, wx.wxEXPAND)

    local filePicker = nil -- not used outside of this function

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFilePickerCtrl +  wxFLP_DEFAULT_STYLE")
    filePicker = wx.wxFilePickerCtrl(scrollWin, ID_FILEPICKER1, wx.wxGetCwd(), "I'm the message parameter", "*",
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFLP_DEFAULT_STYLE)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(filePicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFilePickerCtrl + wxFLP_USE_TEXTCTRL")
    filePicker = wx.wxFilePickerCtrl(scrollWin, ID_FILEPICKER2, wx.wxGetCwd(), wx.wxFileSelectorPromptStr, wx.wxFileSelectorDefaultWildcardStr,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFLP_USE_TEXTCTRL)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(filePicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFilePickerCtrl + wxFLP_CHANGE_DIR")
    filePicker = wx.wxFilePickerCtrl(scrollWin, ID_FILEPICKER3, wx.wxGetCwd(), wx.wxFileSelectorPromptStr, wx.wxFileSelectorDefaultWildcardStr,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFLP_CHANGE_DIR)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(filePicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFilePickerCtrl + wxFLP_OPEN+wxFLP_FILE_MUST_EXIST")
    filePicker = wx.wxFilePickerCtrl(scrollWin, ID_FILEPICKER4, wx.wxGetCwd(), wx.wxFileSelectorPromptStr, wx.wxFileSelectorDefaultWildcardStr,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFLP_OPEN + wx.wxFLP_FILE_MUST_EXIST)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(filePicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFilePickerCtrl + wxFLP_SAVE+wxFLP_OVERWRITE_PROMPT")
    filePicker = wx.wxFilePickerCtrl(scrollWin, ID_FILEPICKER5, wx.wxGetCwd(), wx.wxFileSelectorPromptStr, wx.wxFileSelectorDefaultWildcardStr,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFLP_SAVE + wx.wxFLP_OVERWRITE_PROMPT)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(filePicker, 1, wx.wxEXPAND)

    -- central event handler for all wxDirPickerCtrl
    scrollWin:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_FILEPICKER_CHANGED, OnFileDirPicker)

    -- -----------------------------------------------------------------------
    flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 1, wx.wxEXPAND)
    flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 1, wx.wxEXPAND)

    local fontPicker = nil -- not used outside of this function

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFontPickerCtrl + wxFNTP_DEFAULT_STYLE, wxNullFont")
    fontPicker = wx.wxFontPickerCtrl(scrollWin, ID_FONTPICKER1, wx.wxNullFont,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFNTP_DEFAULT_STYLE)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(fontPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFontPickerCtrl + wxFNTP_USE_TEXTCTRL, wxNORMAL_FONT")
    fontPicker = wx.wxFontPickerCtrl(scrollWin, ID_FONTPICKER2, wx.wxNORMAL_FONT,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFNTP_USE_TEXTCTRL)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(fontPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFontPickerCtrl + wxFNTP_FONTDESC_AS_LABEL, wxSMALL_FONT")
    fontPicker = wx.wxFontPickerCtrl(scrollWin, ID_FONTPICKER3, wx.wxSMALL_FONT,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFNTP_FONTDESC_AS_LABEL)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(fontPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFontPickerCtrl + wxFNTP_USEFONT_FOR_LABEL, wxITALIC_FONT")
    fontPicker = wx.wxFontPickerCtrl(scrollWin, ID_FONTPICKER4, wx.wxITALIC_FONT,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFNTP_USEFONT_FOR_LABEL)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(fontPicker, 1, wx.wxEXPAND)

    statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxFontPickerCtrl + wxFNTP_USEFONT_FOR_LABEL, wxSWISS_FONT")
    fontPicker = wx.wxFontPickerCtrl(scrollWin, ID_FONTPICKER5, wx.wxSWISS_FONT,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFNTP_USEFONT_FOR_LABEL)
    flexSizer:Add(statText, 1, wx.wxALIGN_CENTER_VERTICAL)
    flexSizer:Add(fontPicker, 1, wx.wxEXPAND)

    -- central event handler for all wxDirPickerCtrl
    scrollWin:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_FONTPICKER_CHANGED, OnFontPicker)

    -- -----------------------------------------------------------------------

    mainSizer:Add(flexSizer, 1, wx.wxEXPAND)
    scrollWin:SetSizer(mainSizer)
    mainSizer:Fit(scrollWin)

    return scrollWin
end

-- ---------------------------------------------------------------------------
-- Main function of the program
-- ---------------------------------------------------------------------------
function main()

    frame = wx.wxFrame( wx.NULL,              -- no parent needed for toplevel windows
                        wx.wxID_ANY,          -- don't need a wxWindow ID
                        "wxLua Picker Demo",  -- caption on the frame
                        wx.wxDefaultPosition, -- let system place the frame
                        wx.wxSize(550, 450),  -- set the size of the frame
                        wx.wxDEFAULT_FRAME_STYLE ) -- use default frame styles

    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Picker Application")

    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")
    frame:SetMenuBar(menuBar)

    frame:CreateStatusBar(1)
    frame:SetStatusText("Welcome to wxLua.")

    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
                  function (event) frame:Close(true) end )

    -- connect the selection event of the about menu item
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('This is the "About" dialog of the Picker wxLua sample.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About wxLua",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )

    -- -----------------------------------------------------------------------
    splitter = wx.wxSplitterWindow(frame, wx.wxID_ANY)
    splitter:SetMinimumPaneSize(50) -- don't let it unsplit
    splitter:SetSashGravity(.8)

    pickerWin = CreatePickerWindow(splitter)

    textCtrl = wx.wxTextCtrl(splitter, wx.wxID_ANY, "",
                             wx.wxDefaultPosition, wx.wxDefaultSize,
                             wx.wxTE_READONLY+wx.wxTE_MULTILINE+wx.wxTE_DONTWRAP)

    splitter:SplitHorizontally(pickerWin, textCtrl, 300)

    -- -----------------------------------------------------------------------

    frame:Show(true) -- show the frame window
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
