-----------------------------------------------------------------------------
-- Name:        settings.wx.lua
-- Purpose:     Settings wxLua sample - show results of all informational functions
-- Author:      John Labenski
-- Modified by:
-- Created:     16/11/2001
-- RCS-ID:
-- Copyright:   (c) 2007 John Labenski
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame    = nil
listCtrl = nil

ID_LISTCTRL = 1000

-- ---------------------------------------------------------------------------
-- Add a list item with multiple col data
-- ---------------------------------------------------------------------------

function AddListItem(colTable)
    local lc_item = listCtrl:GetItemCount()

    lc_item = listCtrl:InsertItem(lc_item, colTable[1])
    listCtrl:SetItem(lc_item, 1, tostring(colTable[2]))

    return lc_item
end

-- ---------------------------------------------------------------------------
-- Fill the listctrl
-- ---------------------------------------------------------------------------

function FillListCtrl(listCtrl)

    listCtrl:InsertColumn(0, "Function Call", wx.wxLIST_FORMAT_LEFT, -1)
    listCtrl:InsertColumn(1, "Result",        wx.wxLIST_FORMAT_LEFT, -1)

    listCtrl:SetColumnWidth(0, 300)
    listCtrl:SetColumnWidth(1, 300)

    AddListItem({"wx.wxButton.GetDefaultSize()", tostring(wx.wxButton.GetDefaultSize():GetWidth())..", "..tostring(wx.wxButton.GetDefaultSize():GetHeight())})


    AddListItem({"", ""})
    AddListItem({"wx.wxCaret.GetBlinkTime()", wx.wxCaret.GetBlinkTime()})


    AddListItem({"", ""})
    AddListItem({"wx.wxDateSpan.Day():GetTotalDays()", wx.wxDateSpan.Day():GetTotalDays()})
    AddListItem({"wx.wxDateSpan.Month():GetTotalDays()", wx.wxDateSpan.Month():GetTotalDays()})
    AddListItem({"wx.wxDateSpan.Week():GetTotalDays()", wx.wxDateSpan.Week():GetTotalDays()})
    AddListItem({"wx.wxDateSpan.Year():GetTotalDays()", wx.wxDateSpan.Year():GetTotalDays()})


    AddListItem({"", ""})
    AddListItem({"wx.wxDisplay.GetCount()", wx.wxDisplay.GetCount()})


    AddListItem({"", ""})
    AddListItem({"wx.wxFileName.GetCwd()", wx.wxFileName.GetCwd()})
    AddListItem({"wx.wxFileName.GetForbiddenChars()", wx.wxFileName.GetForbiddenChars()})
    AddListItem({"wx.wxFileName.GetFormat()", wx.wxFileName.GetFormat()})
    AddListItem({"wx.wxFileName.GetHomeDir()", wx.wxFileName.GetHomeDir()})
    AddListItem({"wx.wxFileName.GetPathSeparator()", wx.wxFileName.GetPathSeparator()})
    AddListItem({"wx.wxFileName.GetPathSeparators()", wx.wxFileName.GetPathSeparators()})
    AddListItem({"wx.wxFileName.GetPathTerminators()", wx.wxFileName.GetPathTerminators()})
    AddListItem({"wx.wxFileName.GetVolumeSeparator()", wx.wxFileName.GetVolumeSeparator()})
    AddListItem({"wx.wxFileName.IsCaseSensitive()", wx.wxFileName.IsCaseSensitive()})
    AddListItem({"wx.wxFileName.GetVolumeSeparator()", wx.wxFileName.GetVolumeSeparator()})


    AddListItem({"", ""})
    AddListItem({"wx.wxFont.GetDefaultEncoding()", wx.wxFont.GetDefaultEncoding()})


    AddListItem({"", ""})
    AddListItem({"wx.wxFontMapper.GetDefaultConfigPath()", wx.wxFontMapper.GetDefaultConfigPath()})
    AddListItem({"wx.wxFontMapper.GetSupportedEncodingsCount()", wx.wxFontMapper.GetSupportedEncodingsCount()})
    AddListItem({"wx.wxFontMapper.GetDefaultConfigPath()", wx.wxFontMapper.GetDefaultConfigPath()})


    AddListItem({"", ""})
    AddListItem({"wx.wxIdleEvent.GetMode()", wx.wxIdleEvent.GetMode()})


    AddListItem({"", ""})
    AddListItem({"wx.wxJoystick.GetNumberJoysticks()", wx.wxJoystick.GetNumberJoysticks()})


    AddListItem({"", ""})
    AddListItem({"wx.wxLocale.GetSystemLanguage()", wx.wxLocale.GetSystemLanguage()})
    AddListItem({"wx.wxLocale.GetSystemEncoding()", wx.wxLocale.GetSystemEncoding()})
    AddListItem({"wx.wxLocale.GetSystemEncodingName()", wx.wxLocale.GetSystemEncodingName()})
    AddListItem({"wx.wxLocale.GetLanguageName(GetSystemLanguage())", wx.wxLocale.GetLanguageName(wx.wxLocale.GetSystemLanguage())})


    AddListItem({"", ""})
    AddListItem({"wx.wxLog.IsEnabled()", wx.wxLog.IsEnabled()})
    AddListItem({"wx.wxLog.GetRepetitionCounting()", wx.wxLog.GetRepetitionCounting()})
    AddListItem({"wx.wxLog.GetVerbose()", wx.wxLog.GetVerbose()})
    AddListItem({"wx.wxLog.GetTraceMask()", wx.wxLog.GetTraceMask()})
    AddListItem({"wx.wxLog.GetLogLevel()", wx.wxLog.GetLogLevel()})
    AddListItem({"wx.wxLog.GetTimestamp()", wx.wxLog.GetTimestamp()})


    AddListItem({"", ""})
    local plat = wx.wxPlatformInfo.Get()
    AddListItem({"wx.wxPlatformInfo:GetOSMajorVersion()", plat:GetOSMajorVersion()})
    AddListItem({"wx.wxPlatformInfo:GetOSMinorVersion()", plat:GetOSMinorVersion()})
    AddListItem({"wx.wxPlatformInfo:GetToolkitMajorVersion()", plat:GetToolkitMajorVersion()})
    AddListItem({"wx.wxPlatformInfo:GetToolkitMinorVersion()", plat:GetToolkitMinorVersion()})
    AddListItem({"wx.wxPlatformInfo:IsUsingUniversalWidgets()", plat:IsUsingUniversalWidgets()})
    AddListItem({"wx.wxPlatformInfo:GetOperatingSystemId()", plat:GetOperatingSystemId()})
    AddListItem({"wx.wxPlatformInfo:GetPortId()", plat:GetPortId()})
    AddListItem({"wx.wxPlatformInfo:GetArchitecture()", plat:GetArchitecture()})
    AddListItem({"wx.wxPlatformInfo:GetEndianness()", plat:GetEndianness()})
    AddListItem({"wx.wxPlatformInfo:GetOperatingSystemFamilyName()", plat:GetOperatingSystemFamilyName()})
    AddListItem({"wx.wxPlatformInfo:GetOperatingSystemIdName()", plat:GetOperatingSystemIdName()})
    AddListItem({"wx.wxPlatformInfo:GetPortIdName()", plat:GetPortIdName()})
    AddListItem({"wx.wxPlatformInfo:GetPortIdShortName()", plat:GetPortIdShortName()})
    AddListItem({"wx.wxPlatformInfo:GetArchName()", plat:GetArchName()})
    AddListItem({"wx.wxPlatformInfo:GetEndiannessName()", plat:GetEndiannessName()})


    AddListItem({"", ""})
    AddListItem({"wx.wxPrinter.GetLastError()", wx.wxPrinter.GetLastError()})


    AddListItem({"", ""})
    if wx.wxPostScriptDC then
        AddListItem({"wx.wxPostScriptDC.GetResolution()", wx.wxPostScriptDC.GetResolution()})
    else
        AddListItem({"wx.wxPostScriptDC.GetResolution()", "wxPostScriptDC not available"})
    end


    --AddListItem({"", ""})
    --AddListItem({"wx.wxSound.IsPlaying()", wx.wxSound.IsPlaying()}) -- not in MSW


    AddListItem({"", ""})
    local stdpaths = wx.wxStandardPaths.Get()
    AddListItem({"wx.wxStandardPaths:GetExecutablePath()", stdpaths:GetExecutablePath()})
    AddListItem({"wx.wxStandardPaths:GetConfigDir()", stdpaths:GetConfigDir()})
    AddListItem({"wx.wxStandardPaths:GetUserConfigDir()", stdpaths:GetUserConfigDir()})
    AddListItem({"wx.wxStandardPaths:GetDataDir()", stdpaths:GetDataDir()})
    AddListItem({"wx.wxStandardPaths:GetLocalDataDir()", stdpaths:GetLocalDataDir()})
    AddListItem({"wx.wxStandardPaths:GetUserDataDir()", stdpaths:GetUserDataDir()})
    AddListItem({"wx.wxStandardPaths:GetUserLocalDataDir()", stdpaths:GetUserLocalDataDir()})
    AddListItem({"wx.wxStandardPaths:GetPluginsDir()", stdpaths:GetPluginsDir()})
    AddListItem({"wx.wxStandardPaths:GetResourcesDir()", stdpaths:GetResourcesDir()})
    AddListItem({"wx.wxStandardPaths:GetLocalizedResourcesDir(\"\")", stdpaths:GetLocalizedResourcesDir("")})
    AddListItem({"wx.wxStandardPaths:GetDocumentsDir()", stdpaths:GetDocumentsDir()})
    AddListItem({"wx.wxStandardPaths:GetTempDir()", stdpaths:GetTempDir()})


    AddListItem({"", ""})
    AddListItem({"wx.wxStaticLine.GetDefaultSize()", wx.wxStaticLine.GetDefaultSize()})


    AddListItem({"", ""})
    AddListItem({"wx.wxSystemSettings.GetScreenType()", wx.wxSystemSettings.GetScreenType()})


    AddListItem({"", ""})
    AddListItem({"wx.wxTimeSpan.Week():Format()", wx.wxTimeSpan.Week():Format()})
    AddListItem({"wx.wxTimeSpan.Day():Format()", wx.wxTimeSpan.Day():Format()})
    AddListItem({"wx.wxTimeSpan.Hour():Format()", wx.wxTimeSpan.Hour():Format()})
    AddListItem({"wx.wxTimeSpan.Minute():Format()", wx.wxTimeSpan.Minute():Format()})
    AddListItem({"wx.wxTimeSpan.Second():Format()", wx.wxTimeSpan.Second():Format()})


    AddListItem({"", ""})
    AddListItem({"wx.wxUpdateUIEvent.GetMode()", wx.wxUpdateUIEvent.GetMode()})


    AddListItem({"", ""})
    AddListItem({"wx.wxValidator.IsSilent()", wx.wxValidator.IsSilent()})


    AddListItem({"", ""})
    AddListItem({"wx.wxWindow.FindFocus()", wx.wxWindow.FindFocus()})
    AddListItem({"wx.wxWindow.GetCapture()", wx.wxWindow.GetCapture()})

    -- -----------------------------------------------------------------------

    AddListItem({"", ""})
    AddListItem({"Functions below", "==========================="})

    AddListItem({"", ""})
    AddListItem({"wx.wxClientDisplayRect()", table.concat({wx.wxClientDisplayRect()}, ", ")})
    AddListItem({"wx.wxGetClientDisplayRect()", table.concat({wx.wxGetClientDisplayRect():GetX(), wx.wxGetClientDisplayRect():GetY(), wx.wxGetClientDisplayRect():GetWidth(), wx.wxGetClientDisplayRect():GetHeight()}, ", ")})
    AddListItem({"wx.wxDisplaySize()", table.concat({wx.wxDisplaySize()}, ", ")})
    AddListItem({"wx.wxGetDisplaySize()", table.concat({wx.wxGetDisplaySize():GetWidth(), wx.wxGetDisplaySize():GetHeight()}, ", ")})
    AddListItem({"wx.wxDisplaySizeMM()", table.concat({wx.wxDisplaySizeMM()}, ", ")})
    AddListItem({"wx.wxGetDisplaySizeMM()", table.concat({wx.wxGetDisplaySizeMM():GetWidth(), wx.wxGetDisplaySizeMM():GetHeight()}, ", ")})
    AddListItem({"wx.wxColourDisplay()", wx.wxColourDisplay()})
    AddListItem({"wx.wxDisplayDepth()", wx.wxDisplayDepth()})

    AddListItem({"", ""})
    AddListItem({"wx.wxGetActiveWindow()", wx.wxGetActiveWindow()})

    AddListItem({"", ""})
    AddListItem({"wx.wxGetCwd()", wx.wxGetCwd()})
    AddListItem({"wx.wxGetFreeMemory():ToLong()", wx.wxGetFreeMemory():ToLong()})
    AddListItem({"wx.wxGetHostName()", wx.wxGetHostName()})
    AddListItem({"wx.wxGetFullHostName()", wx.wxGetFullHostName()})
    AddListItem({"wx.wxGetHomeDir()", wx.wxGetHomeDir()})
    AddListItem({"wx.wxGetUserHome()", wx.wxGetUserHome()})
    AddListItem({"wx.wxGetUserId()", wx.wxGetUserId()})
    AddListItem({"wx.wxGetUserName()", wx.wxGetUserName()})
    AddListItem({"wx.wxGetEmailAddress()", wx.wxGetEmailAddress()})

    AddListItem({"", ""})
    AddListItem({"wx.wxNow()", wx.wxNow()})
    AddListItem({"wx.wxGetLocalTime()", wx.wxGetLocalTime()})
    AddListItem({"wx.wxGetLocalTimeMillis():ToDouble()", wx.wxGetLocalTimeMillis():ToDouble()})
    AddListItem({"wx.wxGetUTCTime()", wx.wxGetUTCTime()})

    AddListItem({"", ""})
    AddListItem({"wx.wxGetOsDescription()", wx.wxGetOsDescription()})
    AddListItem({"wx.wxGetOSDirectory()", wx.wxGetOSDirectory()})
    AddListItem({"wx.wxGetOsVersion()", table.concat({wx.wxGetOsVersion()}, ", ")})
    AddListItem({"wx.wxGetProcessId()", wx.wxGetProcessId()})

    AddListItem({"", ""})
    AddListItem({"wx.wxGetPowerType()", wx.wxGetPowerType()})
    AddListItem({"wx.wxGetBatteryState()", wx.wxGetBatteryState()})

    AddListItem({"", ""})
    AddListItem({"wx.wxGetMousePosition()", table.concat({wx.wxGetMousePosition():GetX(),wx.wxGetMousePosition():GetY()}, ", ")})
    AddListItem({"wx.wxGetMouseState()", wx.wxGetMouseState()})

    AddListItem({"", ""})
    AddListItem({"wx.wxNewId()", wx.wxNewId()})

    AddListItem({"", ""})
    AddListItem({"wx.wxSysErrorCode()", wx.wxSysErrorCode()})
    AddListItem({"wx.wxSysErrorMsg()", wx.wxSysErrorMsg()})

end

-- ---------------------------------------------------------------------------
-- Main entry into the program
-- ---------------------------------------------------------------------------
function main()

    -- create the wxFrame window
    frame = wx.wxFrame( wx.NULL,            -- no parent for toplevel windows
                        wx.wxID_ANY,          -- don't need a wxWindow ID
                        "wxLua Settings Demo", -- caption on the frame
                        wx.wxDefaultPosition, -- let system place the frame
                        wx.wxSize(450, 450),  -- set the size of the frame
                        wx.wxDEFAULT_FRAME_STYLE ) -- use default frame styles

    listCtrl = wx.wxListView(frame, ID_LISTCTRL,
                             wx.wxDefaultPosition, wx.wxDefaultSize,
                             wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL + wx.wxLC_HRULES + wx.wxLC_VRULES)

    FillListCtrl(listCtrl)

    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Minimal Application")

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
            wx.wxMessageBox('This is the "About" dialog of the Settings wxLua sample.\n'..
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
