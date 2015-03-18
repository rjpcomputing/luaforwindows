-----------------------------------------------------------------------------
-- Name:        printing.wx.lua
-- Purpose:     Printing wxLua sample
-- Author:      J Winwood
-- Modified by:
-- Created:     4/7/2002
-- Modified
-- RCS-ID:      $Id: printing.wx.lua,v 1.19 2008/02/22 19:04:32 jrl1 Exp $
-- Copyright:   (c) 2002 J Winwood. All rights reserved.
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

local ID_PRINT        = wx.wxID_HIGHEST + 1
local ID_PRINTPREVIEW = wx.wxID_HIGHEST + 2
local ID_PRINTSETUP   = wx.wxID_HIGHEST + 3
local ID_PAGESETUP    = wx.wxID_HIGHEST + 4

frame               = nil
printData           = wx.wxPrintData()
pageSetupDialogData = wx.wxPageSetupDialogData()

-- Setup the printer data with some useful defaults
printData:SetPaperId(wx.wxPAPER_LETTER)
pageSetupDialogData:SetMarginTopLeft(wx.wxPoint(20, 20))
pageSetupDialogData:SetMarginBottomRight(wx.wxPoint(20, 20))

function DisplayFigure(dc, pageNumber)
    -- call some drawing functions
    dc:SetBrush(wx.wxTRANSPARENT_BRUSH)

    dc:SetPen(wx.wxRED_PEN)
    dc:DrawRectangle(10, 10, 300, 300)
    dc:SetPen(wx.wxBLACK_PEN)
    dc:DrawRoundedRectangle(20, 20, 280, 280, 20)
    dc:SetPen(wx.wxGREEN_PEN)
    dc:DrawEllipse(30, 30, 260, 260)

    if pageNumber then
        dc:DrawText("Test page "..pageNumber, 50, 150)
    else
        dc:DrawText("A test string", 50, 150)
    end
end

function ConnectPrintEvents(printOut)

    printOut.HasPage = function(self, pageNum)
                            return (pageNum == 1) or (pageNum == 2)
                       end

    -- These two functions are equivalent, you can either use SetPageInfo to
    -- set the number of pages or override GetPageInfo() as shown and return
    -- the number of pages

    printOut:SetPageInfo(1, 16, 2, 15) -- we override this using GetPageInfo

    printOut.GetPageInfo = function(self)
                               return 1, 2, 1, 2
                           end

    -- You MUST call the base class functions for OnBeginDocument(...) and
    -- OnEndDocument() if you override them in order for printing to work.
    -- If you don't override them then printing works as expected.

    printOut.OnBeginDocument = function(self, startPage, endPage)
                                   return self:_OnBeginDocument(startPage, endPage)
                               end

    printOut.OnEndDocument = function(self)
                                return self:_OnEndDocument()
                             end

    -- You don't have to call the base class functions of these since they do
    -- nothing anyway.
    printOut.OnBeginPrinting = function(self)
                               end

    printOut.OnEndPrinting = function(self)
                             end

    printOut.OnPreparePrinting = function(self)
                                 end

    -- This is the actual function that is called for each page to print
    printOut.OnPrintPage = function(self, pageNum)
        local dc = self:GetDC()

        local ppiScr_width, ppiScr_height = self:GetPPIScreen()
        local ppiPrn_width, ppiPrn_height = self:GetPPIPrinter()
        local ppi_scale_x = ppiPrn_width/ppiScr_width
        local ppi_scale_y = ppiPrn_height/ppiScr_height

        -- Get the size of DC in pixels and the number of pixels in the page
        local dc_width, dc_height = dc:GetSize()
        local pagepix_width, pagepix_height = self:GetPageSizePixels()

        local dc_pagepix_scale_x = dc_width/pagepix_width
        local dc_pagepix_scale_y = dc_height/pagepix_height

        -- If printer pageWidth == current DC width, then this doesn't
        -- change. But w might be the preview bitmap width, so scale down.
        local dc_scale_x = ppi_scale_x * dc_pagepix_scale_x
        local dc_scale_y = ppi_scale_y * dc_pagepix_scale_y

        -- calculate the pixels / mm (25.4 mm = 1 inch)
        local ppmm_x = ppiScr_width / 25.4
        local ppmm_y = ppiScr_height / 25.4

        -- Adjust the page size for the pixels / mm scaling factor
        local pageMM_width, pageMM_height = self:GetPageSizeMM()
        local pagerect_x, pagerect_y = 0, 0
        local pagerect_w, pagerect_h = pageMM_width * ppmm_x, pageMM_height * ppmm_y

        -- get margins informations and convert to printer pixels
        local topLeft     = pageSetupDialogData:GetMarginTopLeft()
        local bottomRight = pageSetupDialogData:GetMarginBottomRight()

        local top    = topLeft:GetY()     * ppmm_y
        local bottom = bottomRight:GetY() * ppmm_y
        local left   = topLeft:GetX()     * ppmm_x
        local right  = bottomRight:GetX() * ppmm_x

        local printrect_x, printrect_y = left, top
        local printrect_w, printrect_h = pagerect_w-(left+right), pagerect_h-(top+bottom)

        -- finally, setup the dc scaling and origin for margins
        dc:SetUserScale(dc_scale_x, dc_scale_y);
        dc:SetDeviceOrigin(printrect_x*dc_scale_x, printrect_y*dc_scale_y)
        -- draw our figure
        DisplayFigure(dc, pageNum)

        -- DON'T delete() this dc since we didn't create it

        return true
    end
end

function Print()
    local printDialogData = wx.wxPrintDialogData(printData)
    local printer  = wx.wxPrinter(printDialogData)
    local printout = wx.wxLuaPrintout("wxLua Test Print")
    ConnectPrintEvents(printout)

    if printer:Print(frame, printout, true) == false then
        if printer:GetLastError() == wx.wxPRINTER_ERROR then
            wx.wxMessageBox("There was a problem printing.\nPerhaps your current printer is not set correctly?",
                            "Printing.wx.lua",
                            wx.wxOK)
        else
            wx.wxMessageBox("You cancelled printing",
                            "Printing.wx.lua",
                            wx.wxOK)
        end
    else
        printData = printer:GetPrintDialogData():GetPrintData():Copy()
    end
end

function PrintPreview()
    local printerPrintout = wx.wxLuaPrintout("wxLua Test Print")
    ConnectPrintEvents(printerPrintout)

    local previewPrintout = wx.wxLuaPrintout("wxLua Test Print Preview")
    ConnectPrintEvents(previewPrintout)

    local printDialogData = wx.wxPrintDialogData(printData):GetPrintData()
    local preview         = wx.wxPrintPreview(printerPrintout, previewPrintout, printDialogData)
    local result = preview:Ok()
    if result == false then
        wx.wxMessageBox("There was a problem previewing.\nPerhaps your current printer is not set correctly?",
                        "Printing.wx.lua",
                        wx.wxOK)
    else
        local previewFrame = wx.wxPreviewFrame(preview, frame,
                                               "Test Print Preview",
                                               wx.wxDefaultPosition,
                                               wx.wxSize(600, 650))

        previewFrame:Connect(wx.wxEVT_CLOSE_WINDOW,
                function (event)
                    previewFrame:Destroy()
                    event:Skip()
                end )

        previewFrame:Centre(wx.wxBOTH)
        previewFrame:Initialize()
        previewFrame:Show(true)
    end
end

function PrintSetup()
    -- NOTE : this function crashes in wxWidgets GTK wxWidgets 2.8.2
    local printDialogData = wx.wxPrintDialogData(printData)
    local printerDialog   = wx.wxPrintDialog(frame, printDialogData)
    --printerDialog:GetPrintDialogData():SetSetupDialog(true)
    printerDialog:ShowModal()
    printData = printerDialog:GetPrintDialogData():GetPrintData():Copy()
end

function PageSetup()
    printData = pageSetupDialogData:GetPrintData():Copy()
    local pageSetupDialog = wx.wxPageSetupDialog(frame, pageSetupDialogData)
    pageSetupDialog:ShowModal()
    printData           = pageSetupDialog:GetPageSetupDialogData():GetPrintData():Copy()
    pageSetupDialogData = pageSetupDialog:GetPageSetupDialogData():Copy()
    pageSetupDialog:delete()
end

function main()
    -- create the frame window
    frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "wxLua Printing Demo",
                        wx.wxDefaultPosition, wx.wxSize(450, 450),
                        wx.wxDEFAULT_FRAME_STYLE )

    -- paint event handler
    function Paint(event)
        -- create the paint DC
        local dc = wx.wxPaintDC(frame)
        -- clear the window
        dc:SetPen(wx.wxTRANSPARENT_PEN)
        dc:SetBrush(wx.wxWHITE_BRUSH)
        local w, h = frame:GetClientSizeWH()
        dc:DrawRectangle(0, 0, w, h)
        -- draw our figure
        DisplayFigure(dc)
        -- the paint DC will be destroyed by the garbage collector,
        -- however on Windows 9x/Me this may be too late (DC's are precious resource)
        -- so delete it here
        dc:delete() -- ALWAYS delete() any wxDCs created when done
    end

    -- connect the paint event handler with the paint event
    frame:Connect(wx.wxEVT_PAINT, Paint)

    -- create a simple file menu
    local fileMenu = wx.wxMenu()
    fileMenu:Append(ID_PAGESETUP,    "Page S&etup...", "Set up the page")
    fileMenu:Append(ID_PRINTSETUP,   "Print &Setup...", "Set up the printer")
    fileMenu:Append(ID_PRINTPREVIEW, "Print Pre&view...", "Preview the test print")
    fileMenu:Append(ID_PRINT,        "&Print...", "Print the test print")
    fileMenu:Append(wx.wxID_EXIT,    "E&xit", "Quit the program")

    -- create a simple help menu
    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About...", "About the wxLua Printing Application")

    -- create a menu bar and append the file and help menus
    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(helpMenu, "&Help")

    -- insert the menu bar into the frame
    frame:SetMenuBar(menuBar)

    -- create a simple status bar
    frame:CreateStatusBar(1)
    frame:SetStatusText("Welcome to wxLua.")

    frame:Connect(ID_PAGESETUP, wx.wxEVT_COMMAND_MENU_SELECTED,
                  function (event) PageSetup() end )

    frame:Connect(ID_PRINTSETUP, wx.wxEVT_COMMAND_MENU_SELECTED,
                  function (event) PrintSetup() end )

    frame:Connect(ID_PRINTPREVIEW, wx.wxEVT_COMMAND_MENU_SELECTED,
                  function (event) PrintPreview() end )

    frame:Connect(ID_PRINT, wx.wxEVT_COMMAND_MENU_SELECTED,
                  function (event) Print() end )

    -- connect the selection event of the exit menu item to an
    -- event handler that closes the window
    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
                  function (event) frame:Close(true) end )

    -- connect the selection event of the about menu item
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                wx.wxMessageBox('This is the "About" dialog of the Printing wxLua sample.\n'..
                                wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                                "About wxLua",
                                wx.wxOK + wx.wxICON_INFORMATION,
                                frame )
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
