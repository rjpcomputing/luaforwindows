-------------------------------------------------------------------------=---
-- Name:        htmlwin.wx.lua
-- Purpose:     wxHtmlWindow wxLua sample
-- Author:      J Winwood
-- Created:     May 2002
-- Copyright:   (c) 2002 Lomtick Software. All rights reserved.
-- Licence:     wxWidgets licence
-------------------------------------------------------------------------=---

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame = nil -- the main frame of the program
html  = nil -- the wxLuaHtmlWindow child of the frame (subclassed wxHtmlWindow)

htmlTextPage =
[[<html>
    <head>
    <title>wxLua Bound Widget demonstration</title>
    </head>
    <body>
        <h3>wxHtmlWidgetCell demonstration</h3>
        There are three bound widgets below.
        <hr>
        <center>
            <lua text="first widget"
                x=100 y=70>
        </center>
        <hr>
        <lua text="small widget"
                x=60 y=50>
        <hr>
        <lua text="widget with floating width"
            float=y x=70 y=40>
    </body>
</html>]]

function CreateBoundWindow(event)
    local ax, ay, rc
    local fl = 0

    -- parse the X parameter in the custom lua tag
    rc, ax = event.HtmlTag:GetParamAsInt("X")
    -- parse the Y parameter
    rc, ay = event.HtmlTag:GetParamAsInt("Y")
    -- if there is a float tag set the float
    if event.HtmlTag:HasParam("FLOAT") then
        fl = ax
    end

    -- create the control to embed
    local parent = nil
    if wx.wxCHECK_VERSION(2,7,0) then
        if event:GetHtmlParser() and event:GetHtmlParser():GetWindowInterface()
           and event:GetHtmlParser():GetWindowInterface():GetHTMLWindow() then

            parent = event:GetHtmlParser():GetWindowInterface():GetHTMLWindow()
        else
            print("FIXME: wxWidgets does not provide the html window for print previews?")
            print("1:", event:GetHtmlParser())
            print("2:", event:GetHtmlParser():GetWindowInterface())
            print("3:", event:GetHtmlParser():GetWindowInterface():GetHTMLWindow())
        end
    else
        parent = event.HtmlParser.Window
    end

    if parent then
        local wnd = wx.wxTextCtrl( parent, wx.wxID_ANY,
                                   event.HtmlTag:GetParam("TEXT"),
                                   wx.wxPoint(0, 0), wx.wxSize(ax, ay),
                                   wx.wxTE_MULTILINE )
        -- show the control
        wnd:Show(true)

        -- create the container widget cell
        local widget = wx.wxHtmlWidgetCell(wnd, fl)

        -- insert the cell into the document
        event.HtmlParser:OpenContainer():InsertCell(widget)
        event:SetParseInnerCalled(false)
    end
end


-- create the frame window
frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "wxLuaHtmlWindow Demo",
                    wx.wxDefaultPosition, wx.wxSize(450, 450),
                    wx.wxDEFAULT_FRAME_STYLE )


-- create a simple file menu
local fileMenu = wx.wxMenu()
fileMenu:Append(wx.wxID_PREVIEW, "Print Pre&view", "Preview the HTML document")
fileMenu:Append(wx.wxID_PRINT,   "&Print", "Print the HTML document")
fileMenu:Append(wx.wxID_EXIT,    "E&xit", "Quit the program")

-- create a simple help menu
local helpMenu = wx.wxMenu()
helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua wxHtmlWindow sample")

-- create a menu bar and append the file and help menus
local menuBar = wx.wxMenuBar()
menuBar:Append(fileMenu, "&File")
menuBar:Append(helpMenu, "&Help")

-- insert the menu bar into the frame using the %property binding tag (eg. SetMenubar function)
frame.MenuBar = menuBar

-- create a simple status bar
frame:CreateStatusBar(2)
frame:SetStatusText("Welcome to wxLua.")

frame:Connect(wx.wxID_PREVIEW, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        local printing = wx.wxHtmlEasyPrinting("HtmlWindow.wx.lua", frame)
        printing:PreviewText(htmlTextPage)
    end )

frame:Connect(wx.wxID_PRINT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        local printing = wx.wxHtmlEasyPrinting("HtmlWindow.wx.lua", frame)
        printing:PrintText(htmlTextPage)
    end )

-- connect the selection event of the exit menu item to an
-- event handler that closes the window
frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        frame:Close(true)
    end )

-- connect the selection event of the about menu item
frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        wx.wxMessageBox('This is the "About" dialog of the wxHtmlWindow wxLua sample.\n'..
                        wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                        "About wxLua",
                        wx.wxOK + wx.wxICON_INFORMATION,
                        frame )
    end)

-- create the html window
html = wx.wxLuaHtmlWindow(frame)

-- Override the virtual function
--    virtual void wxLuaHtmlWindow::OnSetTitle(const wxString& title)
html.OnSetTitle = function(self, title)
                       frame.Title = frame.Title.." - "..title
                  end

-- when a lua custom tag is parsed in the html, this event handler
-- will be invoked
wx.wxGetApp():Connect(wx.wxID_ANY, wx.wxEVT_HTML_TAG_HANDLER,
                      function (event) CreateBoundWindow(event) end)

-- set the frame window and status bar
html:SetRelatedFrame(frame, "wxHtmlWindow wxLua Sample : %s")
html:SetRelatedStatusBar(1)
-- load the document
html:SetPage(htmlTextPage)
--  html:LoadPage("testpage.html")

-- show the frame window
wx.wxGetApp().TopWindow = frame
frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
