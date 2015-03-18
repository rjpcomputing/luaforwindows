-----------------------------------------------------------------------------
-- Name:        media.wx.lua
-- Purpose:     wxMediaCtrl wxLua sample
-- Author:      John Labenski
-- Modified by:
-- Created:     07/01/2007
-- RCS-ID:
-- Copyright:   (c) 2007 John Labenski. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame       = nil -- main wxFrame
mediaCtrl   = nil -- wxMediaCtrl player
playButton  = nil -- wxButton to "play"
pauseButton = nil -- wxButton to "pause"
stopButton  = nil -- wxButton to "stop"
timer       = nil -- wxTimer to update position in media

loadedMedia = false -- set to true if media is ok
fileName    = ""    -- Name of the loaded file

settingPos  = false -- true when pos slider is being changed by user

slider_range = 10000 -- all sliders have this range

ID_LOADFILE = 1000
ID_PLAY     = 1001
ID_PAUSE    = 1002
ID_STOP     = 1003
ID_VOLUME   = 1004
ID_POSITON  = 1005
ID_POSTEXT  = 1006

-- ---------------------------------------------------------------------------
-- Convert milliseconds to MM:SS
-- ---------------------------------------------------------------------------
function msToMMSS(ms)
    local m = math.floor(ms/(60*1000))
    local s = math.floor((ms - m*60*1000)/1000)
    return string.format("%02d:%02d", m, s)
end

-- ---------------------------------------------------------------------------
-- Update the GUI controls based on the mediaCtrl
-- ---------------------------------------------------------------------------
function UpdateButtons()
    local play_ok  = false
    local pause_ok = false
    local stop_ok  = false

    local state = mediaCtrl:GetState()

    if not loadedMedia then state = -1 end -- not valid to do anything

    if state == wx.wxMEDIASTATE_PLAYING then
        play_ok  = false
        pause_ok = true
        stop_ok  = true
    elseif state == wx.wxMEDIASTATE_PAUSED then
        play_ok  = true
        pause_ok = false
        stop_ok  = true
    else --if state == wx.wxMEDIASTATE_STOPPED then
        play_ok  = true
        pause_ok = false
        stop_ok  = false
    end

    playButton:Enable(play_ok)
    pauseButton:Enable(pause_ok)
    stopButton:Enable(stop_ok)

    volumeSlider:SetValue(mediaCtrl:GetVolume()*slider_range)
end

-- ---------------------------------------------------------------------------
-- Entry point into the program
-- ---------------------------------------------------------------------------
function main()

    -- create the wxFrame window
    frame = wx.wxFrame( wx.NULL,              -- no parent for toplevel windows
                        wx.wxID_ANY,          -- don't need a wxWindow ID
                        "wxLua Media Demo",   -- caption on the frame
                        wx.wxDefaultPosition, -- let system place the frame
                        wx.wxSize(450, 450),  -- set the size of the frame
                        wx.wxDEFAULT_FRAME_STYLE ) -- use default frame styles

    frame:Connect(wx.wxEVT_CLOSE_WINDOW,
            function (event)
                event:Skip()
                if timer then
                    timer:Stop() -- always stop before exiting or deleting it
                    timer:delete()
                    timer = nil
                end
            end)

    -- -----------------------------------------------------------------------

    -- create a simple file menu
    local fileMenu = wx.wxMenu()
    fileMenu:Append(ID_LOADFILE, "Load media...\tCtrl+O", "Load a file to play...")
    fileMenu:AppendSeparator()
    fileMenu:Append(wx.wxID_EXIT, "E&xit\tCtrl+Q", "Quit the program")

    -- create a simple help menu
    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Media Application")

    -- create a menu bar and append the file and help menus
    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")

    -- attach the menu bar into the frame
    frame:SetMenuBar(menuBar)

    -- create a simple status bar
    frame:CreateStatusBar(1)
    frame:SetStatusText("Welcome to wxLua.")

    -- -----------------------------------------------------------------------

    panel = wx.wxPanel(frame, wx.wxID_ANY)

    mediaCtrl = wx.wxMediaCtrl(panel, wx.wxID_ANY, "",
                               wx.wxDefaultPosition, wx.wxSize(200, 200))

    playButton   = wx.wxButton(panel, ID_PLAY,  "Play")
    pauseButton  = wx.wxButton(panel, ID_PAUSE, "Pause")
    stopButton   = wx.wxButton(panel, ID_STOP,  "Stop")
    volumeSlider = wx.wxSlider(panel, ID_VOLUME,  slider_range, 0, slider_range)

    buttonSizer = wx.wxFlexGridSizer(1, 5, 5, 5)
    buttonSizer:AddGrowableCol(4)
    buttonSizer:Add(playButton, 0, 0)
    buttonSizer:Add(pauseButton, 0, 0)
    buttonSizer:Add(stopButton, 0, 0)
    buttonSizer:Add(wx.wxStaticText(panel, wx.wxID_ANY, "Volume : "), 0, wx.wxALIGN_CENTER_VERTICAL)
    buttonSizer:Add(volumeSlider, 1, wx.wxEXPAND)

    posSlider = wx.wxSlider(panel, ID_POSITON, 0, 0, slider_range)
    posText   = wx.wxStaticText(panel, ID_POSTEXT, "Position 00:00/00:00 ")
    posSizer = wx.wxFlexGridSizer(1, 5, 5, 5)
    posSizer:AddGrowableCol(1)
    posSizer:Add(posText, 0, wx.wxALIGN_CENTER_VERTICAL)
    posSizer:Add(posSlider, 1, wx.wxEXPAND)

    mainSizer = wx.wxFlexGridSizer(2, 1, 5, 5)
    mainSizer:AddGrowableRow(0)
    mainSizer:AddGrowableCol(0)
    mainSizer:Add(mediaCtrl, 1, wx.wxEXPAND, 0)
    mainSizer:Add(buttonSizer, 0, wx.wxEXPAND, 0)
    mainSizer:Add(posSizer, 0, wx.wxEXPAND, 0)

    panel:SetSizer(mainSizer)
    mainSizer:SetSizeHints(frame)

    UpdateButtons()

    -- -----------------------------------------------------------------------

    panel:Connect(ID_PLAY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function (event)
                local ok = mediaCtrl:Play()

                if not ok then
                    wx.wxMessageBox(string.format("Unable to play %s: Unsupported format?", fileName),
                                    "wxLua Media Demo",
                                    wx.wxICON_ERROR + wx.wxOK)
                end
            end )
    panel:Connect(ID_PAUSE, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function (event)
                local ok = mediaCtrl:Pause()

                if not ok then
                    wx.wxMessageBox(string.format("Unable to pause %s: Unsupported format?", fileName),
                                    "wxLua Media Demo",
                                    wx.wxICON_ERROR + wx.wxOK)
                end
            end )
    panel:Connect(ID_STOP, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function (event)
                local ok = mediaCtrl:Stop()

                if not ok then
                    wx.wxMessageBox(string.format("Unable to stop %s: Unsupported format?", fileName),
                                    "wxLua Media Demo",
                                    wx.wxICON_ERROR + wx.wxOK)
                end
            end )

    panel:Connect(ID_VOLUME, wx.wxEVT_SCROLL_THUMBRELEASE,
            function (event)
                local pos = event:GetPosition()
                mediaCtrl:SetVolume(pos/slider_range)
            end )

    panel:Connect(ID_POSITON, wx.wxEVT_SCROLL_THUMBTRACK,
            function (event) settingPos = true end)

    panel:Connect(ID_POSITON, wx.wxEVT_SCROLL_THUMBRELEASE,
            function (event)
                if loadedMedia then
                    local pos = event:GetPosition()
                    local len = mediaCtrl:Length()
                    local ok = mediaCtrl:Seek(len*pos/slider_range)
                    if ok == wx.wxInvalidOffset then
                        wx.wxMessageBox(string.format("Unable to seek in %s: Unsupported format?", fileName),
                                        "wxLua Media Demo",
                                        wx.wxICON_ERROR + wx.wxOK)
                    end
                end

                settingPos = false
            end )

    mediaCtrl:Connect(wx.wxEVT_MEDIA_STATECHANGED,
            function (event)
                UpdateButtons()
            end)

    -- -----------------------------------------------------------------------

    timer = wx.wxTimer(panel)
    panel:Connect(wx.wxEVT_TIMER,
            function (event)
                local len = 1 -- avoid /0
                local pos = 0
                local str = "Position 00:00/00:00"

                if loadedMedia then
                    len = mediaCtrl:Length()
                    pos = mediaCtrl:Tell()
                    str = string.format("Position %s/%s", msToMMSS(pos), msToMMSS(len))
                end

                if not settingPos then
                    posSlider:SetValue(slider_range*pos/len)
                end

                if posText:GetLabel() ~= str then
                    posText:SetLabel(str)
                end
            end)

    timer:Start(300)

    -- -----------------------------------------------------------------------

    frame:Connect(ID_LOADFILE, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local dlg = wx.wxFileDialog(frame, "Choose a media file",
                                            wx.wxGetCwd(), "", "All Files (*)|*|MP3 Music Files (*.mp3)|*.mp3|MPG Video Files (*.mpg)|*.mpg|AVI Movie Files (*.avi)|*.avi",
                                            wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST + wx.wxFD_CHANGE_DIR )
                if dlg:ShowModal() == wx.wxID_OK then
                    local filepath = dlg:GetPath()
                    loadedMedia = false
                    fileName = ""

                    if not mediaCtrl:Load(filepath) then
                        wx.wxMessageBox(string.format("Unable to load %s: Unsupported format?", filepath),
                                        "wxLua Media Demo",
                                        wx.wxICON_ERROR + wx.wxOK)
                    else
                        posSlider:SetValue(0)
                        loadedMedia = true
                        fileName = dlg:GetFilename()
                        local ms = mediaCtrl:Length()
                        local s = mediaCtrl:GetBestSize()
                        frame:SetStatusText(string.format("Loaded: '%s' Length %s Size %dx%d", fileName, msToMMSS(ms), s:GetWidth(), s:GetHeight()))
                        mediaCtrl:SetInitialSize()
                        panel:GetSizer():Layout()
                    end
                end
                dlg:Destroy()
                UpdateButtons()
            end )

    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event) frame:Close(true) end )

    -- connect the selection event of the about menu item
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('This is the "About" dialog of the Media wxLua sample.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About wxLua Media",
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
