-------------------------------------------------------------------------=---
-- Name:        coroutine.wx.lua
-- Purpose:     Tests coroutines and wxIDLE_EVENTS
-- Author:      Leandro Motta Barros
-- Created:     2006
-- Copyright:
-- Licence:     wxWidgets licence
-------------------------------------------------------------------------=---

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-------------------------------------------------------------------------------
-- ProgressWindow
-------------------------------------------------------------------------------

ProgressWindow = {
    -- The 'wxDialog' being encapsulated by this "class".
    dialog = nil,

    -- The label telling what's going on ("Processing 7/10...")
    label = nil,
}

-- The constructor for the progress dialog.
-- 'parent' is the parent window.
-- 'workCoroutine' is the coroutine used to process whatever is desired.
-- 'caption' is the caption to be used for this window.
-- 'initialLabel' is the string that will be initially shown in the window.
function ProgressWindow:new(parent, workCoroutine, caption, initialLabel)

    -- simple little sanity test to ensure that we can call binding functions
    -- fails on r:SetX if wx bindings aren't installed correctly for the coroutine
    local r = wx.wxRect(1,2,3,4)
    r:SetX(1)

    local o = { }
    setmetatable(o, self)
    self.__index = self

    -- Check input parameters
    assert(type(workCoroutine) == "thread")
    assert(type(caption) == "string")
    assert(type(initialLabel) == "string")

    -- Create dialog
    o.dialog = wx.wxDialog(parent, wx.wxID_ANY, caption,
                           wx.wxDefaultPosition, wx.wxDefaultSize,
                           wx.wxDEFAULT_DIALOG_STYLE)

    o.label = wx.wxTextCtrl(o.dialog, wx.wxID_ANY, "",
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            wx.wxTE_MULTILINE + wx.wxTE_READONLY)
    local mainSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    mainSizer:Add(o.label, 1, wx.wxGROW)
    o.dialog:SetSizer(mainSizer)

    -- Handle idle events: run the coroutine's next "step"
    o.dialog:Connect(wx.wxEVT_IDLE,
            function (event)
                if coroutine.status(workCoroutine) ~= "dead" then
                    local s, msg = coroutine.resume(workCoroutine)
                    if not msg then
                        o.dialog:Close()
                    else
                        o:setStatus(msg)
                    end
                    event:RequestMore()
                    event:Skip()
                end
            end)

    -- Voilà
    return o
end


-- Sets the ProgressWindow's "status". For now, this means "change the text"
-- being displayed in the window (usually something like "Doing this thing").
function ProgressWindow:setStatus(label)
    self.label:AppendText("\n"..label)
end


-------------------------------------------------------------------------------
-- The main frame
-------------------------------------------------------------------------------

local ID_THE_BUTTON = wx.wxID_HIGHEST + 100

frame = wx.wxFrame(wx.NULL, wx.wxID_ANY,
                    "wxLua Idle Events and Coroutines")

-- ----------------------------------------------------------------------------
-- create a simple file menu
local fileMenu = wx.wxMenu()
fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

-- create a simple help menu
local helpMenu = wx.wxMenu()
helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Coroutine Sample")

-- create a menu bar and append the file and help menus
local menuBar = wx.wxMenuBar()
menuBar:Append(fileMenu, "&File")
menuBar:Append(helpMenu, "&Help")

-- attach the menu bar into the frame
frame:SetMenuBar(menuBar)

-- connect the selection event of the exit menu item to an
-- event handler that closes the window
frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
              function (event) frame:Close(true) end )

-- connect the selection event of the about menu item
frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('This is the "About" dialog of the Coroutine wxLua sample.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About wxLua",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )

-- ----------------------------------------------------------------------------

panel = wx.wxPanel(frame, wx.wxID_ANY)
button = wx.wxButton(panel, ID_THE_BUTTON, "Perform some long operation")

frame:Connect(ID_THE_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function (event)
            local function workFunc()
                for i = 1, 10 do
                    coroutine.yield("Performing step "..tostring(i).."/10")
                    wx.wxSleep(1)
                end
            end

            local workCoroutine = coroutine.create(workFunc)

            local wndProgress =
                ProgressWindow:new(frame, workCoroutine,
                                   "Performing some long operation",
                                   "Performing step 1/many")
            wndProgress.dialog:ShowModal(true)

            wndProgress.dialog:Destroy()
        end)


-- Show the main frame
frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
