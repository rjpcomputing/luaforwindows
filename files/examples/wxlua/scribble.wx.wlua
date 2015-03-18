-------------------------------------------------------------------------=---
-- Name:        scribble.wx.lua
-- Purpose:     'Scribble' wxLua sample
-- Author:      J Winwood, John Labenski
-- Modified by: Thanks to Peter Prade and Nick Trout for fixing
--              the bug in the for loop in DrawPoints()
-- Created:     16/11/2001
-- RCS-ID:      $Id: scribble.wx.lua,v 1.27 2009/05/14 05:06:21 jrl1 Exp $
-- Copyright:   (c) 2001 J Winwood. All rights reserved.
-- Licence:     wxWidgets licence
-------------------------------------------------------------------------=---

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

frame          = nil   -- the main wxFrame
scrollwin      = nil   -- the child of the frame
panel          = nil   -- the child wxPanel of the wxScrolledWindow to draw on
mouseDown      = false -- left mouse button is down
pointsList     = {}    -- list of the points added to the drawing
                       -- pointsList[segment] =
                       --   { pen = {colour = {r, g, b}, width = 1, style = N},
                       --     [n] = {x = x_pos, y = x_pos} }
isModified     = false -- has the drawing been modified
redrawRequired = true  -- redraw the image
lastDrawn      = 0     -- last segment that was drawn or 0 to redraw all
fileName       = ""    -- filename to save to
ID_SAVEBITMAP  = wx.wxID_HIGHEST + 1
ID_IMAGESIZE   = wx.wxID_HIGHEST + 2
ID_PENCOLOUR   = wx.wxID_HIGHEST + 3
ID_PENWIDTH    = wx.wxID_HIGHEST + 4
ID_PENSTYLE    = wx.wxID_HIGHEST + 5
ID_PENWIDTH_SPINCTRL = wx.wxID_HIGHEST + 6

currentPen     = wx.wxPen(wx.wxRED_PEN); currentPen:SetWidth(3)
penStyles      = { wx.wxSOLID, wx.wxDOT, wx.wxLONG_DASH, wx.wxSHORT_DASH,
                   wx.wxDOT_DASH, wx.wxBDIAGONAL_HATCH, wx.wxCROSSDIAG_HATCH,
                   wx.wxFDIAGONAL_HATCH, wx.wxCROSS_HATCH, wx.wxHORIZONTAL_HATCH,
                   wx.wxVERTICAL_HATCH }
penStyleNames  = { "Solid style", "Dotted style", "Long dashed style", "Short dashed style",
                   "Dot and dash style", "Backward diagonal hatch", "Cross-diagonal hatch",
                   "Forward diagonal hatch", "Cross hatch", "Horizontal hatch",
                   "Vertical hatch" }

screenWidth, screenHeight = wx.wxDisplaySize()
bitmap = wx.wxBitmap(screenWidth, screenHeight)

-- ---------------------------------------------------------------------------
-- Pen to table and back functions
-- ---------------------------------------------------------------------------
function PenToTable(pen)
    local c = pen:GetColour()
    local t = { colour = { c:Red(), c:Green(), c:Blue() }, width = pen:GetWidth(), style = pen:GetStyle() }
    c:delete()
    return t
end

function TableToPen(penTable)
    local c = wx.wxColour(unpack(penTable.colour))
    local pen = wx.wxPen(c, penTable.width, penTable.style)
    c:delete()
    return pen
end

-- ---------------------------------------------------------------------------
-- Drawing functions
-- ---------------------------------------------------------------------------
function DrawPoints(drawDC)
    if lastDrawn == 0 then
        drawDC:Clear()
    end

    local start_index = 1
    if lastDrawn > 1 then start_index = lastDrawn end

    for list_index = start_index, #pointsList do
        local listValue = pointsList[list_index]
        local pen = TableToPen(listValue.pen)
        drawDC:SetPen(pen)
        pen:delete()

        local point = listValue[1]
        local last_point = point
        for point_index = 2, #listValue do
            point = listValue[point_index]
            drawDC:DrawLine(last_point.x, last_point.y, point.x, point.y)
            last_point = point
        end
    end

    lastDrawn = #pointsList
    drawDC:SetPen(wx.wxNullPen)
end

function DrawLastPoint(drawDC)
    if #pointsList >= 1 then
        local listValue = pointsList[#pointsList]
        local count = #listValue
        if count > 1 then
            local pen = TableToPen(listValue.pen)
            drawDC:SetPen(pen)
            pen:delete()

            local pt1 = listValue[count-1]
            local pt2 = listValue[count]
            drawDC:DrawLine(pt1.x, pt1.y, pt2.x, pt2.y)
        end
    end
end

function DrawBitmap(bmp)
    local memDC = wx.wxMemoryDC()       -- create off screen dc to draw on
    memDC:SelectObject(bmp)             -- select our bitmap to draw into

    DrawPoints(memDC)

    memDC:SelectObject(wx.wxNullBitmap) -- always release bitmap
    memDC:delete() -- ALWAYS delete() any wxDCs created when done
end

function OnPaint(event)
    -- ALWAYS create wxPaintDC in wxEVT_PAINT handler, even if unused
    local dc = wx.wxPaintDC(panel)

    if bitmap and bitmap:Ok() then
        if redrawRequired then
            DrawBitmap(bitmap)
            redrawRequired = false
        end

        dc:DrawBitmap(bitmap, 0, 0, false)
    end

    dc:delete() -- ALWAYS delete() any wxDCs created when done
end

function GetBitmap()
    local w, h = panel:GetClientSizeWH()
    local bmp = wx.wxBitmap(w, h)
    lastDrawn = 0 -- force redrawing all points
    DrawBitmap(bmp)
    lastDrawn = 0 -- force redrawing all points
    return bmp
end

-- ---------------------------------------------------------------------------
-- Mouse functions
-- ---------------------------------------------------------------------------

function OnLeftDown(event)
    local pointItem = {pen = PenToTable(currentPen), {x = event:GetX(), y = event:GetY()}}
    table.insert(pointsList, pointItem)

    if (not panel:HasCapture()) then panel:CaptureMouse() end
    mouseDown = true
    isModified = true
end

function OnLeftUp(event)
    if mouseDown then
        -- only add point if the mouse moved since DrawLine(1,2,1,2) won't draw anyway
        if (#pointsList[#pointsList] > 1) then
            local point = { x = event:GetX(), y = event:GetY() }
            table.insert(pointsList[#pointsList], point)
        else
            pointsList[#pointsList] = nil
        end

        if panel:HasCapture() then panel:ReleaseMouse() end
        mouseDown = false
        redrawRequired = true
        panel:Refresh()
    end
end

function OnMotion(event)
    frame:SetStatusText(string.format("%d, %d", event:GetX(), event:GetY()), 1)

    if event:LeftIsDown() then
        local point = { x = event:GetX(), y = event:GetY() }
        table.insert(pointsList[#pointsList], point)

        mouseDown = true

        -- draw directly on the panel, we'll draw on the bitmap in OnLeftUp
        local drawDC = wx.wxClientDC(panel)
        DrawLastPoint(drawDC)
        drawDC:delete()
    elseif panel:HasCapture() then -- just in case we lost focus somehow
        panel:ReleaseMouse()
        mouseDown = false
    end
end

-- ---------------------------------------------------------------------------
-- File functions
-- ---------------------------------------------------------------------------

function QuerySaveChanges()
    local dialog = wx.wxMessageDialog( frame,
                                       "Document has changed. Do you wish to save the changes?",
                                       "wxLua Scribble Save Changes?",
                                       wx.wxYES_NO + wx.wxCANCEL + wx.wxCENTRE + wx.wxICON_QUESTION )
    local result = dialog:ShowModal()
    dialog:Destroy()

    if result == wx.wxID_YES then
        if not SaveChanges() then return wx.wxID_CANCEL end
    end

    return result
end

function LoadScribbles(fileName)
    pointsList = {}
    lastDrawn = 0
    return ((pcall(dofile, fileName)) ~= nil)
end

-- modified from the lua sample save.lua
function savevar(fh, n, v)
    if v ~= nil then
        fh:write(n, "=")
        if type(v) == "string" then
            fh:write(format("%q", v))
        elseif type(v) == "table" then
            fh:write("{}\n")
            for r,f in pairs(v) do
                if type(r) == 'string' then
                    savevar(fh, n.."."..r, f)
                else
                    savevar(fh, n.."["..r.."]", f)
                end
            end
        else
            fh:write(tostring(v))
        end
        fh:write("\n")
    end
end

function SaveScribbles()
    local fh, msg = io.open(fileName, "w+")
    if fh then
        savevar(fh, "pointsList", pointsList)
        fh:close()
        return true
    else
        wx.wxMessageBox("Unable to save file:'"..fileName.."'.\n"..msg,
                        "wxLua Scribble Save error",
                        wx.wxOK + wx.wxICON_ERROR,
                        frame)
        return false
    end
end

function Open()
    local fileDialog = wx.wxFileDialog(frame,
                                       "Open wxLua scribble file",
                                       "",
                                       "",
                                       "Scribble files(*.scribble)|*.scribble|All files(*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    local result = false
    if fileDialog:ShowModal() == wx.wxID_OK then
        fileName = fileDialog:GetPath()
        result = LoadScribbles(fileName)
        if result then
            frame:SetTitle("wxLua Scribble - " .. fileName)
        end
    end
    fileDialog:Destroy()
    return result
end

function SaveAs()
    local fileDialog = wx.wxFileDialog(frame,
                                       "Save wxLua scribble file",
                                       "",
                                       "",
                                       "Scribble files(*.scribble)|*.scribble|All files(*)|*",
                                       wx.wxSAVE + wx.wxOVERWRITE_PROMPT)
    local result = false
    if fileDialog:ShowModal() == wx.wxID_OK then
        fileName = fileDialog:GetPath()
        result = SaveScribbles()
        if result then
            frame:SetTitle("wxLua Scribble - " .. fileName)
        end
    end
    fileDialog:Destroy()
    return result
end

function SaveChanges()
   local saved = false
   if fileName == "" then
       saved = SaveAs()
   else
       saved = SaveScribbles()
   end
   return saved
end

function SetBitmapSize()
    local w, h = bitmap:GetWidth(), bitmap:GetHeight()

    local ok = true
    repeat
        local s = wx.wxGetTextFromUser("Enter the image size to use as 'width height'", "Set new image size",
                                        string.format("%d %d", bitmap:GetWidth(), bitmap:GetHeight()), frame)
        if (#s == 0) then
            return false -- they canceled the dialog
        end
        w, h = string.match(s, "(%d+) (%d+)")

        w = tonumber(w)
        h = tonumber(h)
        if (w == nil) or (h == nil) or (w < 2) or (h < 2) or (w > 10000) or (h > 10000) then
            wx.wxMessageBox("Please enter two positive numbers < 10000 for the width and height separated by a space",
                            "Invalid image width or height", wx.wxOK + wx.wxCENTRE + wx.wxICON_ERROR, frame)
            ok = false
        end
    until ok

    -- resize all the drawing objects
    bitmap:delete()
    bitmap = wx.wxBitmap(w, h)
    panel:SetSize(w, h)
    scrollwin:SetScrollbars(1, 1, w, h)

    return true
end


-- ---------------------------------------------------------------------------
-- The main program
-- ---------------------------------------------------------------------------

function main()
    frame = wx.wxFrame( wx.NULL, wx.wxID_ANY, "wxLua Scribble",
                        wx.wxDefaultPosition, wx.wxSize(450, 450),
                        wx.wxDEFAULT_FRAME_STYLE )

    -- -----------------------------------------------------------------------
    -- Create the menubar
    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_NEW,    "&New...\tCtrl+N",    "Begin a new drawing")
    fileMenu:Append(wx.wxID_OPEN,   "&Open...\tCtrl+O",   "Open an existing drawing")
    fileMenu:AppendSeparator()
    fileMenu:Append(wx.wxID_SAVE,   "&Save\tCtrl+S",      "Save the drawing lines")
    fileMenu:Append(wx.wxID_SAVEAS, "Save &as...\tAlt+S", "Save the drawing lines to a new file")
    fileMenu:Append(ID_SAVEBITMAP,  "Save &bitmap...",    "Save the drawing as a bitmap file")
    fileMenu:AppendSeparator()
    fileMenu:Append(wx.wxID_EXIT,   "E&xit\tCtrl+Q",      "Quit the program")

    local editMenu = wx.wxMenu()
    editMenu:Append(ID_IMAGESIZE, "Set image size...", "Set the size of the image to draw on")
    editMenu:Append(ID_PENCOLOUR, "Set pen &color...\tCtrl+R", "Set the color of the pen to draw with")
    editMenu:Append(ID_PENWIDTH,  "Set pen &width...\tCtrl+T", "Set width of the pen to draw with")
    -- Pen styles really only work for long lines, when you change direction the styles
    --   blur into each other and just look like a solid line.
    --editMenu:Append(ID_PENSTYLE,  "Set &Style\tCtrl+Y", "Set style of the pen to draw with")
    editMenu:AppendSeparator()
    editMenu:Append(wx.wxID_COPY,  "Copy to clipboard\tCtrl-C", "Copy current image to the clipboard")
    editMenu:AppendSeparator()
    editMenu:Append(wx.wxID_UNDO,  "&Undo\tCtrl-Z", "Undo last drawn segment")

    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT,  "&About...", "About the wxLua Scribble Application")

    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(editMenu, "&Edit")
    menuBar:Append(helpMenu, "&Help")
    frame:SetMenuBar(menuBar)

    -- -----------------------------------------------------------------------
    -- Create the toolbar
    toolBar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
    -- Note: Ususally the bmp size isn't necessary, but the HELP icon is not the right size in MSW
    local toolBmpSize = toolBar:GetToolBitmapSize()
    -- Note: Each temp bitmap returned by the wxArtProvider needs to be garbage collected
    --       and there is no way to call delete() on them. See collectgarbage("collect")
    --       at the end of this function.
    toolBar:AddTool(wx.wxID_NEW,    "New",     wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_MENU, toolBmpSize), "Create an empty scribble")
    toolBar:AddTool(wx.wxID_OPEN,   "Open",    wx.wxArtProvider.GetBitmap(wx.wxART_FILE_OPEN, wx.wxART_MENU, toolBmpSize),   "Open an existing scribble")
    toolBar:AddTool(wx.wxID_SAVE,   "Save",    wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize),   "Save the current scribble")
    toolBar:AddTool(wx.wxID_SAVEAS, "Save as", wx.wxArtProvider.GetBitmap(wx.wxART_NEW_DIR, wx.wxART_MENU, toolBmpSize),     "Save the current scribble to a new file")
    toolBar:AddSeparator()
    toolBar:AddTool(wx.wxID_COPY,   "Copy",    wx.wxArtProvider.GetBitmap(wx.wxART_COPY, wx.wxART_MENU, toolBmpSize),        "Copy image to clipboard")
    toolBar:AddSeparator()
    toolBar:AddTool(wx.wxID_UNDO,   "Undo",    wx.wxArtProvider.GetBitmap(wx.wxART_UNDO, wx.wxART_MENU, toolBmpSize),        "Undo last line drawn")
    toolBar:AddSeparator()

    penWidthSpinCtrl = wx.wxSpinCtrl(toolBar, ID_PENWIDTH_SPINCTRL, tostring(currentPen:GetWidth()),
                                     wx.wxDefaultPosition, wx.wxDefaultSize,
                                     wx.wxSP_ARROW_KEYS, 1, 100, currentPen:GetWidth())
    local w, h = penWidthSpinCtrl:GetSizeWH()
    penWidthSpinCtrl:SetSize(3*h, -1)
    penWidthSpinCtrl:SetToolTip("Set pen width in pixels")
    toolBar:AddControl(penWidthSpinCtrl)
    toolBar:AddSeparator()

    local c = currentPen:GetColour()
    colourPicker = wx.wxColourPickerCtrl(toolBar, ID_PENCOLOUR, c,
                                         wx.wxDefaultPosition, toolBmpSize:op_sub(wx.wxSize(2,2)),
                                         wx.wxCLRP_DEFAULT_STYLE)
    c:delete()
    colourPicker:SetToolTip("Choose pen color")
    colourPicker:Connect(wx.wxEVT_COMMAND_COLOURPICKER_CHANGED,
            function(event)
                local c = event:GetColour()
                currentPen:SetColour(c)
                c:delete()
            end)

    toolBar:AddControl(colourPicker)
    toolBar:AddSeparator()

    -- Create a custom control to choose some common colours.
    local colourWin_height = math.floor(h/2)*2 -- round to be divisible by two
    local colourWin = wx.wxControl(toolBar, wx.wxID_ANY,
                                   wx.wxDefaultPosition, wx.wxSize(4*colourWin_height, colourWin_height),
                                   wx.wxBORDER_NONE)
    -- Need help in GTK to ensure that it's positioned correctly
    colourWin:SetMinSize(wx.wxSize(4*colourWin_height, colourWin_height))

    local colourWinColours = {
        "black", "grey",       "brown", "red",  "orange", "green",     "blue",     "violet",
        "white", "light grey", "tan",   "pink", "yellow", "turquoise", "sky blue", "maroon"
    }
    -- Note: this bitmap is local, but is used in the event handlers
    local colourWinBmp = wx.wxBitmap(4*colourWin_height, colourWin_height)
    do
        local memDC = wx.wxMemoryDC()
        memDC:SelectObject(colourWinBmp)
        memDC:SetPen(wx.wxBLACK_PEN)
        local w, h = colourWin:GetClientSizeWH()
        local w2 = math.floor(w/8)
        local h2 = math.floor(h/2)

        for j = 1, 2 do
            for i = 1, 8 do
                local colour = wx.wxColour(colourWinColours[i + 8*(j-1)])
                local brush  = wx.wxBrush(colour, wx.wxSOLID)
                memDC:SetBrush(brush)
                memDC:DrawRectangle(w2*(i-1), h2*(j-1), w2, h2)
                brush:delete()
                colour:delete()
            end
        end
        memDC:SelectObject(wx.wxNullBitmap)
        memDC:delete()
    end

    colourWin:Connect(wx.wxEVT_ERASE_BACKGROUND,
        function(event)
            local dc = wx.wxClientDC(colourWin)
            dc:DrawBitmap(colourWinBmp, 0, 0, false) -- this is our background
            dc:delete()
        end)
    colourWin:Connect(wx.wxEVT_LEFT_DOWN,
        function(event)
            local x, y = event:GetPositionXY()
            local w, h = colourWin:GetClientSizeWH()
            local i = math.floor(8*x/w)+1 + 8*math.floor(2*y/h)
            if colourWinColours[i] then
                local c = wx.wxColour(colourWinColours[i])
                currentPen:SetColour(c)
                colourPicker:SetColour(c)
                c:delete()
            end
        end)
    colourWin:Connect(wx.wxEVT_MOTION,
        function(event)
            local x, y = event:GetPositionXY()
            local w, h = colourWin:GetClientSizeWH()
            local i = math.floor(8*x/w)+1 + 8*math.floor(2*y/h)
            if colourWinColours[i] then
                local s = "Set pen color : "..colourWinColours[i]
                if colourWin:GetToolTip() ~= s then
                    colourWin:SetToolTip(s)
                end
            end
        end)
    toolBar:AddControl(colourWin)

    -- once all the tools are added, layout all the tools
    toolBar:Realize()

    -- -----------------------------------------------------------------------
    -- Create the statusbar
    local statusBar = frame:CreateStatusBar(2)
    local status_width = statusBar:GetTextExtent("88888, 88888")
    frame:SetStatusWidths({ -1, status_width })
    frame:SetStatusText("Welcome to wxLua Scribble.")

    -- Create a wxScrolledWindow to hold drawing window, it will fill the frame
    scrollwin = wx.wxScrolledWindow(frame, wx.wxID_ANY)
    scrollwin:SetScrollbars(1, 1, bitmap:GetWidth(), bitmap:GetHeight())

    -- Create the panel that's the correct size of the bitmap on the scrolled
    -- window so we don't have to worry about calculating the scrolled position
    -- for drawing and the mouse position.
    panel = wx.wxPanel(scrollwin, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxSize(bitmap:GetWidth(), bitmap:GetHeight()))

    panel:Connect(wx.wxEVT_PAINT, OnPaint)
    panel:Connect(wx.wxEVT_ERASE_BACKGROUND, function(event) end) -- do nothing
    panel:Connect(wx.wxEVT_LEFT_DOWN, OnLeftDown )
    panel:Connect(wx.wxEVT_LEFT_UP,   OnLeftUp )
    panel:Connect(wx.wxEVT_MOTION,    OnMotion )

    -- -----------------------------------------------------------------------
    -- File menu events

    frame:Connect(wx.wxID_NEW, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                if isModified and (QuerySaveChanges() == wx.wxID_CANCEL) then
                    return
                end

                local bmp_changed = SetBitmapSize()

                if bmp_changed then
                    fileName = ""
                    frame:SetTitle("wxLua Scribble")
                    pointsList = {}
                    lastDrawn = 0
                    redrawRequired = true
                    isModified = false
                    panel:Refresh()
                end
            end )

    frame:Connect(wx.wxID_OPEN, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                if isModified and (QuerySaveChanges() == wx.wxID_CANCEL) then
                    return
                end

                if Open() then
                    isModified = false
                end
                redrawRequired = true
                panel:Refresh()
            end )

    frame:Connect(wx.wxID_SAVE, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local saved = false
                if fileName == "" then
                    saved = SaveAs()
                else
                    saved = SaveScribbles()
                end
                if saved then
                    isModified = false
                end
            end )

    frame:Connect(wx.wxID_SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                if SaveAs() then
                    isModified = false
                end
            end )

    frame:Connect(ID_SAVEBITMAP, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local fileDialog = wx.wxFileDialog(frame,
                                       "Save wxLua scribble file as",
                                       "",
                                       "",
                                       "PNG (*.png)|*.png|PCX (*.pcx)|*.pcx|Bitmap (*.bmp)|*.bmp|Jpeg (*.jpg,*.jpeg)|*.jpg,*.jpeg|Tiff (*.tif,*.tiff)|*.tif,*.tiff",
                                       wx.wxSAVE + wx.wxOVERWRITE_PROMPT)
                if fileDialog:ShowModal() == wx.wxID_OK then
                    local bmp = GetBitmap()
                    local img = bmp:ConvertToImage()
                    if not img:SaveFile(fileDialog:GetPath()) then
                        wx.wxMessageBox("There was a problem saving the image file\n"..fileDialog:GetPath(),
                                        "Error saving image",
                                        wx.wxOK + wx.wxICON_ERROR,
                                        frame )
                    end

                    bmp:delete()
                    img:delete()
                end

                fileDialog:Destroy()
            end )

    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                frame:Close(true)
            end )

    -- -----------------------------------------------------------------------
    -- Edit menu events

    frame:Connect(ID_IMAGESIZE, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local bmp_changed = SetBitmapSize()
                lastDrawn = 0
                redrawRequired = true
                panel:Refresh()
            end )

    frame:Connect(ID_PENCOLOUR, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local oldColour = currentPen:GetColour()
                local c = wx.wxGetColourFromUser(frame, oldColour,
                                                 "wxLua Scribble")
                oldColour:delete()
                if c:Ok() then -- returns invalid colour if canceled
                    currentPen:SetColour(c)
                    colourPicker:SetColour(c)
                end
                c:delete()
            end )

    frame:Connect(ID_PENWIDTH, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local ret = wx.wxGetNumberFromUser("Select pen width in pixels", "Width", "wxLua Scribble",
                                                    currentPen:GetWidth(), 1, 100, frame)
                if ret > 0 then -- returns -1 if canceled
                    currentPen:SetWidth(ret)
                end
            end )
    frame:Connect(ID_PENWIDTH_SPINCTRL, wx.wxEVT_COMMAND_SPINCTRL_UPDATED,
            function (event)
                currentPen:SetWidth(event:GetInt())
            end )

    frame:Connect(ID_PENSTYLE, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local ret = wx.wxGetSingleChoice("Select pen style", "wxLua Scribble",
                                                 penStyleNames,
                                                 frame)
                for n = 1, #penStyleNames do
                    if penStyleNames[n] == ret then
                        currentPen:SetStyle(penStyles[n])
                        break
                    end
                end
            end )

    frame:Connect(wx.wxID_COPY, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local clipBoard = wx.wxClipboard.Get()
                if clipBoard and clipBoard:Open() then
                    local bmp = GetBitmap()
                    clipBoard:SetData(wx.wxBitmapDataObject(bmp))
                    bmp:delete()

                    clipBoard:Close()
                end
            end)

    frame:Connect(wx.wxID_UNDO, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                if #pointsList then
                    pointsList[#pointsList] = nil
                    lastDrawn = 0
                    redrawRequired = true
                    panel:Refresh()
                end

                if #pointsList == 0 then
                    isModified = false
                end
            end )

    -- -----------------------------------------------------------------------
    -- Help menu events

    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                wx.wxMessageBox('This is the "About" dialog of the Scribble wxLua Sample.\n'..
                                wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                                "About wxLua Scribble",
                                wx.wxOK + wx.wxICON_INFORMATION,
                                frame )
            end )

    -- -----------------------------------------------------------------------

    frame:Connect(wx.wxEVT_CLOSE_WINDOW,
            function (event)
                local isOkToClose = true
                if isModified then
                    local dialog = wx.wxMessageDialog( frame,
                                                       "Save changes before exiting?",
                                                       "Save Changes?",
                                                       wx.wxYES_NO + wx.wxCANCEL + wx.wxCENTRE + wx.wxICON_QUESTION )
                    local result = dialog:ShowModal()
                    dialog:Destroy()
                    if result == wx.wxID_CANCEL then
                        return
                    elseif result == wx.wxID_YES then
                        isOkToClose  = SaveChanges()
                    end
                end
                if isOkToClose then
                    -- prevent paint events using the memDC during closing
                    bitmap:delete()
                    bitmap = nil
                    -- ensure the event is skipped to allow the frame to close
                    event:Skip()
                end
            end )

    -- delete all locals vars like the temporary wxArtProvider bitmaps
    collectgarbage("collect")

    frame:Show(true)
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
