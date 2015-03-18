-----------------------------------------------------------------------------
-- Name:        controls.wx.lua
-- Purpose:     Controls wxLua sample
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

frame       = nil
textCtrl    = nil
taskbarIcon = nil -- The wxTaskBarIcon that we install

-- wxBitmap to use for controls that need one
bmp = wx.wxArtProvider.GetBitmap(wx.wxART_INFORMATION, wx.wxART_TOOLBAR, wx.wxSize(16, 16))

-- wxImageList for any controls that need them
imageList = wx.wxImageList(16, 16)
imageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
imageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
imageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_PRINT, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
imageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_FLOPPY, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
colorList = { wx.wxColour(255, 100, 100), wx.wxColour(100, 100, 255), wx.wxColour(100, 255, 100), wx.wxWHITE }

-- wxImageList for the wxListCtrl that shows the events
listImageList = wx.wxImageList(16, 16)
listImageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_CROSS_MARK, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
listImageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_TICK_MARK, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))
listImageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_ERROR, wx.wxART_TOOLBAR, wx.wxSize(16, 16)))

bindingList = wxlua.GetBindings() -- Table of {wxLuaBinding functions}

controlTable   = {} -- Table of { win_id = "win name" }
ignoreControls = {} -- Table of { win_id = "win name" } of controls to ignore events from

-- IDs for the windows that we show
ID_PARENT_SCROLLEDWINDOW = 1000
ID_EVENT_LISTCTRL = 5000
ID_CONTROL_LISTCTRL = 5001

ID_ANIMATIONCTRL    = 1001
ID_BITMAPBUTTON     = 1002
ID_BITMAPCOMBOBOX   = 1003
ID_BUTTON           = 1004
ID_CALENDARCTRL     = 1005
ID_CHECKBOX         = 1006
ID_CHECKLISTBOX     = 1007
ID_CHOICE           = 1008
ID_CHOICEBOOK       = 1009
ID_COLLAPSIBLEPANE  = 1010
ID_COMBOBOX         = 1011
ID_CONTROL          = 1012
ID_DIRPICKERCTRL    = 1013
ID_FILEPICKERCTRL   = 1014
ID_FONTPICKERCTRL   = 1015
ID_GAUGE            = 1016
ID_GENERICDIRCTRL   = 1017
ID_GRID             = 1018
ID_HYPERLINKCTRL    = 1019
ID_LISTBOX          = 1020
ID_LISTBOOK         = 1021
ID_LISTCTRL         = 1022
ID_NOTEBOOK         = 1023
ID_PANEL            = 1024
ID_RADIOBOX         = 1025
ID_RADIOBUTTON      = 1026
ID_SASHLAYOUTWINDOW = 1027
ID_SASHWINDOW       = 1028
ID_SCROLLBAR        = 1029
ID_SCROLLEDWINDOW   = 1030
ID_SLIDER           = 1031
ID_SPINBUTTON       = 1032
ID_SPINCTRL         = 1033
ID_SPLITTERWINDOW   = 1034
ID_STATICBITMAP     = 1035
ID_STATICBOX        = 1036
ID_STATICLINE       = 1037
ID_TEXTCTRL         = 1038
ID_TOGGLEBUTTON     = 1039
ID_TOOLBAR          = 1040
ID_TOOLBOOK         = 1041
ID_TREEBOOK         = 1042
ID_TREECTRL         = 1043
ID_WINDOW           = 1044

-- ---------------------------------------------------------------------------
-- Gather up some data from the bindings
-- ---------------------------------------------------------------------------

wxLuaBinding_wx = nil

do
    local bindTable = wxlua.GetBindings()
    for n = 1, #bindTable do
        if bindTable[n].name == "wx" then
            wxLuaBinding_wx = bindTable[n].binding
            break
        end
    end
end


-- Turn the array from the binding into a lookup table by event type
wxEVT_Array = bindingList[1].GetEventArray
for i = 2, #bindingList do
    local evtArr = bindingList[i].GetEventArray
    for j = 1, #evtArr do
        table.insert(wxEVT_Array, evtArr[j])
    end
end

wxEVT_List  = {}
wxEVT_TableByType = {}
for i = 1, #wxEVT_Array do
    wxEVT_TableByType[wxEVT_Array[i].eventType] = wxEVT_Array[i]
    table.insert(wxEVT_List, {wxlua.typename(wxEVT_Array[i].wxluatype), wxEVT_Array[i].name})
end
table.sort(wxEVT_List, function(t1, t2) return t1[1] > t2[1] end)

-- Turn the array from the binding into a lookup table by class name
wxCLASS_Array = bindingList[1].GetClassArray
for i = 2, #bindingList do
    local classArr = bindingList[i].GetClassArray
    for j = 1, #classArr do
        table.insert(wxCLASS_Array, classArr[j])
    end
end

wxCLASS_TableByName = {}
for i = 1, #wxCLASS_Array do
    wxCLASS_TableByName[wxCLASS_Array[i].name] = wxCLASS_Array[i]
end

-- ---------------------------------------------------------------------------
-- wxEventTypes that we don't want to initially handle
-- ---------------------------------------------------------------------------

ignoreEVTs = {
    ["wxEVT_CREATE"]           = true,
    ["wxEVT_DESTROY"]          = true,
    ["wxEVT_ENTER_WINDOW"]     = true,
    ["wxEVT_ERASE_BACKGROUND"] = true,
    ["wxEVT_IDLE"]             = true,
    ["wxEVT_LEAVE_WINDOW"]     = true,
    ["wxEVT_LEFT_DOWN"]        = true,
    ["wxEVT_LEFT_UP"]          = true,
    ["wxEVT_MOTION"]           = true,
    ["wxEVT_MOVE"]             = true,
    ["wxEVT_PAINT"]            = true,
    ["wxEVT_RIGHT_DOWN"]       = true,
    ["wxEVT_RIGHT_UP"]         = true,
    ["wxEVT_SET_CURSOR"]       = true,
    ["wxEVT_SHOW"]             = true,
    ["wxEVT_SIZE"]             = true,
    ["wxEVT_TIMER"]            = true,
    ["wxEVT_UPDATE_UI"]        = true,
}

-- ---------------------------------------------------------------------------
-- wxEventTypes that we shouldn't ever handle because they cause problems
-- ---------------------------------------------------------------------------

skipEVTs = {
    ["wxEVT_PAINT"] = true, -- controls don't redraw if we connect to this in MSW, even if we Skip() it
}

-- ---------------------------------------------------------------------------
-- All wxEvent derived classes and their GetXXX functions (none modify event)
-- ---------------------------------------------------------------------------

function OnSplitterEvent(event)
    -- asserts if these are called inappropriately
    -- {"GetSashPosition", "GetX", "GetY", "GetWindowBeingRemoved"}
    local typ = event:GetEventType()
    local s = ""

    if (typ == wx.wxEVT_COMMAND_SPLITTER_SASH_POS_CHANGING) or (typ == wx.wxEVT_COMMAND_SPLITTER_SASH_POS_CHANGED) then
        s = s.."GetSashPosition="..tostring(event:GetSashPosition())
    end
    if (typ == wx.wxEVT_COMMAND_SPLITTER_DOUBLECLICKED) then
        s = s.." GetX="..tostring(event:GetX())
        s = s.." GetY="..tostring(event:GetY())
    end
    if (typ == wx.wxEVT_COMMAND_SPLITTER_UNSPLIT) then
        s = s.." GetWindowBeingRemoved="..tostring(event:GetWindowBeingRemoved())
    end

    return s
end

wxEvent_GetFuncs = {
    ["wxEvent"]                    = {"GetEventType", "GetId", "GetSkipped", "GetTimestamp", "IsCommandEvent", "ShouldPropagate"},
    ["wxActivateEvent"]            = {"GetActive"},
    ["wxBookCtrlBaseEvent"]        = {"GetOldSelection", "GetSelection"},
    ["wxCalculateLayoutEvent"]     = {"GetFlags", "GetRect"},
    ["wxCalendarEvent"]            = {"GetWeekDay"},
    ["wxChildFocusEvent"]          = {"GetWindow"},
    ["wxChoicebookEvent"]          = {},
    ["wxClipboardTextEvent"]       = {},
    ["wxCloseEvent"]               = {"CanVeto", "GetLoggingOff"},
    ["wxCollapsiblePaneEvent"]     = {"GetCollapsed"},
    ["wxColourPickerEvent"]        = {"GetColour"},
    ["wxCommandEvent"]             = {"GetExtraLong", "GetInt", "GetSelection", "GetString", "IsChecked", "IsSelection"},
    ["wxContextMenuEvent"]         = {"GetPosition"},
    ["wxDateEvent"]                = {"GetDate"},
    ["wxDisplayChangedEvent"]      = {"GetPosition", "GetNumberOfFiles", "GetFiles"},
    ["wxDropFilesEvent"]           = {},
    ["wxEraseEvent"]               = {},
    ["wxFileDirPickerEvent"]       = {"GetPath"},
    ["wxFindDialogEvent"]          = {"GetFlags", "GetFindString", "GetReplaceString", "GetDialog"},
    ["wxFocusEvent"]               = {"GetWindow"},
    ["wxFontPickerEvent"]          = {"GetFont"},
    ["wxGridEditorCreatedEvent"]   = {"GetRow", "GetCol", "GetControl"},
    ["wxGridEvent"]                = {"GetRow", "GetCol", "GetPosition", "Selecting", "ControlDown", "MetaDown", "ShiftDown", "AltDown"},
    ["wxGridRangeSelectEvent"]     = {"GetTopRow", "GetBottomRow", "GetLeftCol", "GetRightCol", "Selecting", "ControlDown", "MetaDown", "ShiftDown", "AltDown"},
    ["wxGridSizeEvent"]            = {"GetRowOrCol", "GetPosition", "ControlDown", "MetaDown", "ShiftDown", "AltDown"},
    ["wxHelpEvent"]                = {"GetLink", "GetPosition", "GetTarget", "GetOrigin"},
    ["wxHyperlinkEvent"]           = {"GetURL"},
    ["wxIconizeEvent"]             = {"Iconized"},
    ["wxIdleEvent"]                = {"GetMode", "MoreRequested"},
    ["wxInitDialogEvent"]          = {},
    ["wxJoystickEvent"]            = nil,
    ["wxKeyEvent"]                 = {"AltDown", "CmdDown", "ControlDown", "MetaDown", "ShiftDown", "HasModifiers", "GetModifiers", "GetKeyCode", "GetPosition"},
    ["wxListbookEvent"]            = {},
    ["wxListEvent"]                = {"GetKeyCode", "GetIndex", "GetColumn", "GetPoint", "GetLabel", "GetText", "GetImage", "GetData", "GetMask", "GetItem", "IsEditCancelled"}, -- "GetCacheFrom", "GetCacheTo", FIXME? do we want these?
    ["wxLuaHtmlWinTagEvent"]       = {"GetHtmlTag", "GetHtmlParser", "GetParseInnerCalled"},
    ["wxMaximizeEvent"]            = {},
    ["wxMenuEvent"]                = {"GetMenuId", "IsPopup", "GetMenu"},
    ["wxMouseCaptureChangedEvent"] = {"GetCapturedWindow"},
    ["wxMouseCaptureLostEvent"]    = {},
    ["wxMouseEvent"]               = {"GetPosition", "AltDown", "ButtonDClick", "ButtonDown", "ButtonUp", "CmdDown", "ControlDown", "Dragging", "Entering"},
    ["wxMoveEvent"]                = {"GetPosition"},
    ["wxNavigationKeyEvent"]       = {"GetDirection", "IsWindowChange", "IsFromTab", "GetCurrentFocus"},
    ["wxNotebookEvent"]            = {},
    ["wxNotifyEvent"]              = {"IsAllowed"},
    ["wxPaintEvent"]               = {},
    ["wxPaletteChangedEvent"]      = {"GetChangedWindow"},
    ["wxProcessEvent"]             = nil,
    ["wxQueryLayoutInfoEvent"]     = {"GetAlignment", "GetFlags", "GetOrientation", "GetRequestedLength", "GetSize"},
    ["wxQueryNewPaletteEvent"]     = {"GetPaletteRealized"},
    ["wxSashEvent"]                = {"GetEdge", "GetDragRect", "GetDragStatus"},
    ["wxScrollEvent"]              = {"GetOrientation", "GetPosition"},
    ["wxScrollWinEvent"]           = {"GetOrientation", "GetPosition"},
    ["wxSetCursorEvent"]           = {"GetX", "GetY", "HasCursor"},
    ["wxShowEvent"]                = {"GetShow"},
    ["wxSizeEvent"]                = {"GetSize"},
    ["wxSocketEvent"]              = nil,
    ["wxSpinEvent"]                = {"GetPosition"},
    ["wxSplitterEvent"]            = OnSplitterEvent, -- {"GetSashPosition", "GetX", "GetY", "GetWindowBeingRemoved"} asserts if these are called inappropriately
    ["wxSysColourChangedEvent"]    = {},
    ["wxTaskBarIconEvent"]         = {},
    ["wxTimerEvent"]               = {"GetInterval"},
    ["wxToolbookEvent"]            = {},
    ["wxTreebookEvent"]            = {},
    ["wxTreeEvent"]                = {"GetKeyCode", "GetItem", "GetOldItem", "GetLabel", "GetPoint", "IsEditCancelled"},
    ["wxUpdateUIEvent"]            = {"GetText", "GetChecked", "GetEnabled", "GetShown", "GetSetChecked", "GetSetEnabled", "GetSetShown", "GetSetText"},
    ["wxWindowCreateEvent"]        = {"GetWindow"},
    ["wxWindowDestroyEvent"]       = {"GetWindow"},
    ["wxWizardEvent"]              = {"GetDirection", "GetPage"}
}

-- ---------------------------------------------------------------------------
-- Format the values you can get from different event types
-- ---------------------------------------------------------------------------

function FuncsToString(event, funcTable, evtClassName)
    local t = {}

    for n = 1, #funcTable do
        local v = event[funcTable[n]](event) -- each item is a function name

        local s = funcTable[n].."="

        local typ_name, typ = wxlua.type(v)

        if typ == wxlua.WXLUA_TSTRING then
            s = s.."'"..tostring(v).."'"
        elseif typ == wxlua.WXLUA_TTABLE then
            s = s.."("..table.concat(v, ",")..")"
        elseif typ <= wxlua.WXLUA_T_MAX then -- the rest of generic lua types
            s = s..tostring(v)
        elseif typ_name == "wxPoint" then
            s = s..string.format("(%d, %d) ", v:GetX(), v:GetY())
        elseif typ_name == "wxSize" then
            s = s..string.format("(%d, %d) ", v:GetWidth(), v:GetHeight())
        elseif typ_name == "wxRect" then
            s = s..string.format("(%d, %d, %d, %d)", v:GetX(), v:GetY(), v:GetWidth(), v:GetHeight())
        elseif typ_name == "wxColour" then
            s = s..v:GetAsString()
            v:delete()
        elseif typ_name == "wxFont" then
            s = s..v:GetNativeFontInfoDesc()
            v:delete()
        elseif typ_name == "wxDateTime" then
            s = s..v:Format()
        elseif typ_name == "wxTreeItemId" then
            local tree = event:GetEventObject():DynamicCast("wxTreeCtrl")
            if v:IsOk() then
                s = s..typ_name.."(tree:GetItemText='"..tree:GetItemText(v).."')"
            else
                s = s..typ_name.."!IsOk"
            end
        elseif typ_name == "wxListItem" then
            s = s..typ_name.."(GetId='"..v:GetId().."')"
        elseif typ_name == "wxWindow" then
            s = s..typ_name.."(GetName="..v:GetName()..")"
        else
            s = s..tostring(v)
            --v:delete()
            -- If we haven't handled it yet, we probably should
            print("Unhandled wxLua data type in FuncsToString from ", wxlua.type(event), typ_name, s, evtClassName)
        end

        table.insert(t, s)
    end

    return table.concat(t, ", ")
end

-- ---------------------------------------------------------------------------
-- Handle all wxEvents
-- ---------------------------------------------------------------------------

function OnEvent(event)
    local skip = true
    local evtClassName = wxlua.typename(wxEVT_TableByType[event:GetEventType()].wxluatype)
    local evtTypeStr   = wxEVT_TableByType[event:GetEventType()].name

    -- You absolutely must create a wxPaintDC for a wxEVT_PAINT in MSW
    -- to clear the region to be updated, otherwise you'll keep getting them
    -- Note: we always skip this anyway, see skipEVTs, but just to be sure...
    if event:GetEventType() == wx.wxEVT_PAINT then
        local dc = wx.wxPaintDC(event:GetEventObject():DynamicCast("wxWindow"))
        dc:delete()
    end

    -- during shutdown, we nil textCtrl since events are sent and we don't want them anymore
    if (not textCtrl) or ignoreEVTs[evtTypeStr] or ignoreControls[event:GetId()] then
        event:Skip(skip)
        return
    end

    --print(evtClassName, wxEVT_TableByType[event:GetEventType()].name)

    -- try to figure out where this came from using the GetEventObject()
    local obj_str = "nil"
    if event:GetEventObject() then
        local classInfo = event:GetEventObject():GetClassInfo()
        if classInfo then
            obj_str = classInfo:GetClassName()
        else
            obj_str = "No wxClassInfo"
        end
    end

    local s = string.format("%s %s(%s) GetEventObject=%s", wx.wxNow(), evtClassName, evtTypeStr, obj_str)

    -- Gather up all the info from the functions for the event and it's base classes
    while wxEvent_GetFuncs[evtClassName] do
        if type(wxEvent_GetFuncs[evtClassName]) == "table" then
            s = s.."\n\t"..evtClassName.." - "..FuncsToString(event, wxEvent_GetFuncs[evtClassName], evtClassName)
        else
            s = s.."\n\t"..evtClassName.." - "..wxEvent_GetFuncs[evtClassName](event)
        end
        evtClassName = wxCLASS_TableByName[evtClassName].baseclassName
    end

    -- for debugging, this means we need to add it to the wxEvent_GetFuncs table
    if evtClassName ~= "wxObject" then
        print("Unhandled wxEventXXX type in OnEvent:", evtClassName)
    end

    textCtrl:AppendText(s.."\n\n")

    event:Skip(skip)
end

-- ---------------------------------------------------------------------------
-- Create the window with the controls
-- ---------------------------------------------------------------------------
function CreateControlsWindow(parent)

    local scrollWin = wx.wxScrolledWindow(parent, ID_PARENT_SCROLLEDWINDOW,
                                    wx.wxDefaultPosition, wx.wxDefaultSize,
                                    wx.wxHSCROLL + wx.wxVSCROLL)

    -- Give the scrollwindow enough size so sizer works when calling Fit()
    scrollWin:SetScrollbars(15, 15, 400, 1000, 0, 0, false)

    -- try to slightly change the background colour, doesn't work in GTK
    if false then
        local c = scrollWin:GetBackgroundColour()
        local d = 20
        if (c:Red() >= 255-d) and (c:Green() >= 255-d) and (c:Blue() >= 255-d) then
            d = -d
        end

        local c2 = wx.wxColour(c:Red()+d, c:Green()+d, c:Blue()+d)
        scrollWin:SetBackgroundColour(c2)
        c:delete()
        c2:delete()
    end

    local flexSizer = wx.wxFlexGridSizer(50, 2, 5, 5)
    flexSizer:AddGrowableCol(1)

    local control = nil -- not used outside of this function

    -- -----------------------------------------------------------------------

    -- Connect ALL events to the window
    local function ConnectEvents(control)
        -- Note this is the same as doing this, but we connect all of them
        -- win:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_BUTTON_CLICKED, OnCommandEvent)

        for i = 1, #wxEVT_Array do
            if not skipEVTs[wxEVT_Array[i].name] then
                control:Connect(wx.wxID_ANY, wxEVT_Array[i].eventType, OnEvent)
            end
        end
    end

    -- -----------------------------------------------------------------------

    local function AddControl(txt, control, real_control)
        local statText = wx.wxStaticText(scrollWin, wx.wxID_ANY, txt)

        flexSizer:Add(statText, 0, wx.wxALIGN_CENTER_VERTICAL+wx.wxALL, 5)
        flexSizer:Add(control, 0, wx.wxALIGN_LEFT+wx.wxALL, 5)

        flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 0, wx.wxEXPAND+wx.wxALL, 5)
        flexSizer:Add(wx.wxStaticLine(scrollWin, wx.wxID_ANY), 0, wx.wxEXPAND+wx.wxALL, 5)

        ConnectEvents(real_control or control) -- connect to the real control

        local a = string.find(txt, "\n", 1, 1)
        if a then txt = string.sub(txt, 1, a-1) end

        if real_control and real_control:IsKindOf(wx.wxClassInfo.FindClass("wxWindow")) then
            controlTable[real_control:GetId()] = txt
        else
            controlTable[control:GetId()] = txt
        end
    end

    -- -----------------------------------------------------------------------

    local function CreateBookPage(parent, num)
        local p = wx.wxPanel(parent, wx.wxID_ANY)
        local s = wx.wxBoxSizer(wx.wxVERTICAL)
        local t = wx.wxStaticText(p, wx.wxID_ANY, "Window "..num)
        s:Add(t, 0, wx.wxCENTER, 5)
        s:SetMinSize(200,200) -- force it to be some reasonable size
        p:SetSizer(s)

        p:SetBackgroundColour(colorList[num]) -- make them easy to find

        return p
    end

    local function SetupBook(control)
        -- Note we can't just use a static text here since it does not obey
        -- any set size, set min size calls and always shrinks to the
        -- size that just fits the text

        control:SetImageList(imageList)
        control:AddPage(CreateBookPage(control, 1), "Page 1", true, 0)
        control:AddPage(CreateBookPage(control, 2), "Page 2", false, 1)
        control:AddPage(CreateBookPage(control, 3), "Page 3", false, 2)
    end

    -- -----------------------------------------------------------------------

    local path = nil
    local paths = {"throbber.gif", "../art/throbber.gif", "../../art/throbber.gif", "../../../art/throbber.gif"}
    for n = 1, #paths do
        if wx.wxFileExists(paths[n]) then path = paths[n]; break; end
    end

    if wx.wxAnimation and path then
        local ani = wx.wxAnimation() -- note cannot load from constuctor in GTK
        ani:LoadFile(path)

        control = wx.wxAnimationCtrl(scrollWin, ID_ANIMATIONCTRL, ani,
                                            wx.wxDefaultPosition, wx.wxDefaultSize)
        control:Play()
        ani:delete()
    else
        control = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxAnimation is missing or unable to load [../art/]throbber.gif")
    end
    AddControl("wxAnimationCtrl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxBitmapButton(scrollWin, ID_BITMAPBUTTON, bmp,
                                         wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxBitmapButton", control)

    -- -----------------------------------------------------------------------

    control = wx.wxBitmapComboBox(scrollWin, ID_BITMAPCOMBOBOX, "wxBitmapComboBox",
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         {"Item 1", "Item 2", "Item 3 text is long to check default size"},
                                         wx.wxTE_PROCESS_ENTER) -- generates event when enter is pressed
    control:Append("Appended w/ bitmap", bmp)
    control:Insert("Inserted at 0 w/ bitmap", bmp, 0)
    control:SetItemBitmap(2, bmp)
    AddControl("wxBitmapComboBox", control)

    -- -----------------------------------------------------------------------

    control = wx.wxButton(scrollWin, ID_BUTTON, "wxButton",
                          wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxButton", control)

    -- -----------------------------------------------------------------------

    do
    -- Note: the wxCalendar control needs some help since it is made up of
    -- separate controls, put in on a panel first and that way the sizer that
    -- lays out all of these windows doesn't have a problem
    local p = wx.wxPanel(scrollWin, wx.wxID_ANY)
    local s = wx.wxBoxSizer(wx.wxVERTICAL)

    control = wx.wxCalendarCtrl(p, ID_CALENDARCTRL, wx.wxDefaultDateTime,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxCAL_SHOW_HOLIDAYS+wx.wxCAL_BORDER_SQUARE)
    s:Add(control, 1, wx.wxEXPAND, 5)
    p:SetSizer(s)
    s:SetSizeHints(p)
    AddControl("wxCalendarCtrl", p, control)
    end

    -- -----------------------------------------------------------------------

    control = wx.wxCheckBox(scrollWin, ID_CHECKBOX, "wxCheckBox",
                                         wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxCheckBox", control)

    -- -----------------------------------------------------------------------

    control = wx.wxCheckListBox(scrollWin, ID_CHECKLISTBOX,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         {"Item 1", "Item 2", "Item 3"})
    AddControl("wxCheckListBox", control)

    -- -----------------------------------------------------------------------

    control = wx.wxChoice(scrollWin, ID_CHOICE,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         {"Item 1", "Item 2", "Item 3"})
    AddControl("wxChoice", control)

    -- -----------------------------------------------------------------------

    control = wx.wxChoicebook(scrollWin, ID_CHOICEBOOK,
                                         wx.wxDefaultPosition, wx.wxDefaultSize)
    SetupBook(control)
    AddControl("wxChoicebook", control)

    -- -----------------------------------------------------------------------

    control = wx.wxCollapsiblePane(scrollWin, ID_COLLAPSIBLEPANE, "wxCollapsiblePane",
                                         wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxCollapsiblePane", control)

    -- -----------------------------------------------------------------------

    control = wx.wxComboBox(scrollWin, ID_COMBOBOX, "wxComboBox",
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         {"Item 1", "Item 2", "Item 3 text is long to check default size"},
                                         wx.wxTE_PROCESS_ENTER) -- generates event when enter is pressed
    control:Append("Appended item")
    control:Insert("Inserted at 0", 0)
    AddControl("wxComboBox", control)

    -- -----------------------------------------------------------------------

    control = wx.wxControl(scrollWin, ID_CONTROL,
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            wx.wxSUNKEN_BORDER)
    AddControl("wxControl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxDirPickerCtrl(scrollWin, ID_DIRPICKERCTRL, wx.wxGetCwd(), "I'm the message parameter",
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxDIRP_USE_TEXTCTRL)
    AddControl("wxDirPickerCtrl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxFilePickerCtrl(scrollWin, ID_FILEPICKERCTRL, wx.wxGetCwd(), wx.wxFileSelectorPromptStr, wx.wxFileSelectorDefaultWildcardStr,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFLP_USE_TEXTCTRL)
    AddControl("wxFilePickerCtrl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxFontPickerCtrl(scrollWin, ID_FONTPICKERCTRL, wx.wxITALIC_FONT,
                                         wx.wxDefaultPosition, wx.wxDefaultSize,
                                         wx.wxFNTP_USEFONT_FOR_LABEL)
    AddControl("wxFontPickerCtrl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxGauge(scrollWin, ID_GAUGE, 100,
                            wx.wxDefaultPosition, wx.wxDefaultSize)
    control:SetValue(30)
    AddControl("wxGauge", control)

    -- -----------------------------------------------------------------------

    control = wx.wxGenericDirCtrl(scrollWin, ID_GENERICDIRCTRL, wx.wxDirDialogDefaultFolderStr,
                            wx.wxDefaultPosition, wx.wxSize(200,200))
    AddControl("wxGenericDirCtrl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxGrid(scrollWin, ID_GRID,
                            wx.wxDefaultPosition, wx.wxSize(200,200))
    control:CreateGrid(10, 20)
    AddControl("wxGrid", control)

    -- -----------------------------------------------------------------------

    control = wx.wxStaticText(scrollWin, wx.wxID_ANY, "TODO - wxHtml windows")
    AddControl("wxHtml", control)

    -- -----------------------------------------------------------------------

    control = wx.wxHyperlinkCtrl(scrollWin, ID_HYPERLINKCTRL,
                            "Goto wxlua.sourceforge.net", "http://wxlua.sourceforge.net",
                            wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxHyperlinkCtrl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxListBox(scrollWin, ID_LISTBOX,
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            {"Item 1", "Item 2", "Item 3"},
                            wx.wxLB_EXTENDED)
    AddControl("wxListBox", control)

    -- -----------------------------------------------------------------------

    control = wx.wxListCtrl(scrollWin, ID_LISTCTRL,
                            wx.wxDefaultPosition, wx.wxSize(200, 200),
                            wx.wxLC_REPORT)
    control:InsertColumn(0, "Col 1")
    control:InsertColumn(1, "Col 2")
    control:InsertItem(0, "Item 1")
    control:InsertItem(1, "Item 2")
    control:InsertItem(2, "Item 3")
    AddControl("wxListCtrl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxListView is a wxListCtrl with a couple of methods added")
    AddControl("wxListView", control)

    -- -----------------------------------------------------------------------

    control = wx.wxListbook(scrollWin, ID_LISTBOOK,
                                         wx.wxDefaultPosition, wx.wxSize(200,200))
    SetupBook(control)
    AddControl("wxListbook", control)

    -- -----------------------------------------------------------------------

    -- wxMediaCtrl

    -- -----------------------------------------------------------------------

    do
    -- Note: The wxNotebook in GTK will not draw it's tabs correctly if placed
    -- directly on the scrolled window, put it in a panel first.
    local p = wx.wxPanel(scrollWin, wx.wxID_ANY)
    local s = wx.wxBoxSizer(wx.wxVERTICAL)

    control = wx.wxNotebook(p, ID_NOTEBOOK,
                                         wx.wxDefaultPosition, wx.wxSize(200,200))
    SetupBook(control)

    s:Add(control, 1, wx.wxEXPAND)
    s:SetMinSize(200,200)
    p:SetSizer(s)
    s:SetSizeHints(p)
    AddControl("wxNotebook", p, control)
    end

    -- -----------------------------------------------------------------------

    control = wx.wxPanel(scrollWin, ID_PANEL,
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            wx.wxSUNKEN_BORDER)
    AddControl("wxPanel", control)

    -- -----------------------------------------------------------------------

    control = wx.wxRadioBox(scrollWin, ID_RADIOBOX, "wxRadioBox",
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            {"Item 1", "Item 2", "Item 3"}, 1,
                            wx.wxSUNKEN_BORDER)
    AddControl("wxRadioBox", control)

    -- -----------------------------------------------------------------------

    control = wx.wxRadioButton(scrollWin, ID_RADIOBUTTON, "wxRadioButton",
                            wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxRadioButton", control)

    -- -----------------------------------------------------------------------

    control = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxSashLayoutWindow must have a top level window as parent")
    AddControl("wxSashLayoutWindow", control)

    -- -----------------------------------------------------------------------

    control = wx.wxStaticText(scrollWin, wx.wxID_ANY, "wxSashWindow must have a top level window as parent")
    AddControl("wxSashWindow", control)

    -- -----------------------------------------------------------------------

    control = wx.wxScrollBar(scrollWin, ID_SCROLLBAR,
                            wx.wxDefaultPosition, wx.wxSize(200, -1))
    control:SetScrollbar(10, 10, 100, 20)
    AddControl("wxScrollBar\n range=100\n thumb=10\n pageSize=20", control)

    -- -----------------------------------------------------------------------

    control = wx.wxScrolledWindow(scrollWin, ID_SCROLLEDWINDOW,
                            wx.wxDefaultPosition, wx.wxSize(200, 200))
    control:SetScrollbars(10, 10, 100, 100)
    control:SetBackgroundColour(colorList[1])
    wx.wxButton(control, wx.wxID_ANY, "Child button of wxScrolledWindow", wx.wxPoint(50, 50))
    AddControl("wxScrolledWindow\n pixelsPerUnit=10\n noUnits=100", control)
    flexSizer:SetItemMinSize(control, 200, 200)

    -- -----------------------------------------------------------------------

    control = wx.wxSlider(scrollWin, ID_SLIDER, 10, 0, 100,
                            wx.wxDefaultPosition, wx.wxSize(200, -1))
    AddControl("wxSlider", control)

    -- -----------------------------------------------------------------------

    control = wx.wxSpinButton(scrollWin, ID_SPINBUTTON,
                            wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxSpinButton", control)

    -- -----------------------------------------------------------------------

    control = wx.wxSpinCtrl(scrollWin, ID_SPINCTRL, "wxSpinCtrl",
                            wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxSpinCtrl", control)

    -- -----------------------------------------------------------------------

    do
    -- Note: putting the splitter window directly on the scrolled window
    -- and in it's sizer makes the sash undraggable, put it in a panel first
    local p = wx.wxPanel(scrollWin, wx.wxID_ANY)
    local s = wx.wxBoxSizer(wx.wxVERTICAL)

    control = wx.wxSplitterWindow(p, ID_SPLITTERWINDOW,
                            wx.wxDefaultPosition, wx.wxSize(300, 200))
    control:SplitVertically(CreateBookPage(control, 1),
                            CreateBookPage(control, 2),
                            100)
    s:SetMinSize(300, 200)
    p:SetSizer(s)
    s:SetSizeHints(p)

    AddControl("wxSplitterWindow", p, control)
    end

    -- -----------------------------------------------------------------------

    control = wx.wxStaticBitmap(scrollWin, ID_STATICBITMAP, bmp,
                            wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxStaticBitmap", control)

    -- -----------------------------------------------------------------------

    control = wx.wxStaticBox(scrollWin, ID_STATICBOX, "wxStaticBox",
                            wx.wxDefaultPosition, wx.wxSize(200, 100))
    control:SetBackgroundColour(colorList[1])
    AddControl("wxStaticBox", control)

    -- -----------------------------------------------------------------------

    control = wx.wxStaticLine(scrollWin, ID_STATICLINE,
                            wx.wxDefaultPosition, wx.wxSize(200, -1))
    AddControl("wxStaticLine", control)

    -- -----------------------------------------------------------------------

    do
    local p = wx.wxStaticText(scrollWin, wx.wxID_ANY, "See taskbar for icon")
    taskbarIcon = wx.wxTaskBarIcon()
    local icon = wx.wxIcon()
    icon:CopyFromBitmap(bmp)
    taskbarIcon:SetIcon(icon, "Tooltop for wxTaskBarIcon from controls.wx.lua")
    icon:delete()
    AddControl("wxTaskBarIcon", p, taskbarIcon)
    end

    -- -----------------------------------------------------------------------

    control = wx.wxTextCtrl(scrollWin, ID_TEXTCTRL, "wxTextCtrl",
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            wx.wxTE_PROCESS_ENTER)
    AddControl("wxTextCtrl", control)

    -- -----------------------------------------------------------------------

    control = wx.wxToggleButton(scrollWin, ID_TOGGLEBUTTON, "wxToggleButton",
                            wx.wxDefaultPosition, wx.wxDefaultSize)
    AddControl("wxToggleButton", control)

    -- -----------------------------------------------------------------------

    control = wx.wxToolBar(scrollWin, ID_TOOLBAR,
                            wx.wxDefaultPosition, wx.wxDefaultSize)
    control:AddTool(wx.wxID_ANY, "A tool 1", bmp, "Help for a tool 1", wx.wxITEM_NORMAL)
    control:AddTool(wx.wxID_ANY, "A tool 2", bmp, "Help for a tool 2", wx.wxITEM_NORMAL)
    control:AddSeparator()
    control:AddCheckTool(wx.wxID_ANY, "A check tool 1", bmp, wx.wxNullBitmap, "Short help for checktool 1", "Long help for checktool ")
    control:AddCheckTool(wx.wxID_ANY, "A check tool 2", bmp, wx.wxNullBitmap, "Short help for checktool 2", "Long help for checktool 2")
    AddControl("wxToolBar", control)

    -- -----------------------------------------------------------------------

    control = wx.wxToolbook(scrollWin, ID_TOOLBOOK,
                                         wx.wxDefaultPosition, wx.wxSize(200,200))
    SetupBook(control)
    AddControl("wxToolbook", control)

    -- -----------------------------------------------------------------------

    control = wx.wxTreebook(scrollWin, ID_TREEBOOK,
                                         wx.wxDefaultPosition, wx.wxSize(200,200))
    SetupBook(control)
    -- Now add special pages for the treebook
    control:AddSubPage(CreateBookPage(control, 4), "Subpage 1", false, 3)
    AddControl("wxTreebook", control)

    -- -----------------------------------------------------------------------

    do
    control = wx.wxTreeCtrl(scrollWin, ID_TREECTRL,
                            wx.wxDefaultPosition, wx.wxSize(200, 200),
                            wx.wxTR_HAS_BUTTONS+wx.wxTR_MULTIPLE)
    control:SetImageList(imageList)
    local item = control:AddRoot("Root Note", 0)
    control:AppendItem(item, "Item 1", 1)
    control:AppendItem(item, "Item 2")
    item = control:AppendItem(item, "Item 3", 2)
    item = control:AppendItem(item, "Item 3:1")
    item = control:AppendItem(item, "Item 3:2", 3)

    AddControl("wxTreeCtrl", control)
    end

    -- -----------------------------------------------------------------------

    control = wx.wxWindow(scrollWin, ID_WINDOW,
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            wx.wxSUNKEN_BORDER)
    AddControl("wxWindow", control)

    -- -----------------------------------------------------------------------

    scrollWin:SetSizer(flexSizer)
    flexSizer:Fit(scrollWin)

    return scrollWin
end

-- ---------------------------------------------------------------------------
-- Main function of the program
-- ---------------------------------------------------------------------------
function main()

    frame = wx.wxFrame( wx.NULL,              -- no parent needed for toplevel windows
                        wx.wxID_ANY,          -- don't need a wxWindow ID
                        "wxLua Controls Demo",-- caption on the frame
                        wx.wxDefaultPosition, -- let system place the frame
                        wx.wxSize(550, 450),  -- set the size of the frame
                        wx.wxDEFAULT_FRAME_STYLE ) -- use default frame styles

    frame:Connect(wx.wxEVT_CLOSE_WINDOW,
            function(event)
                event:Skip();
                textCtrl = nil -- stop processing events
                imageList:delete()
                if taskbarIcon then
                    --if taskbarIcon:IsIconInstalled() then
                    --    taskbarIcon:RemoveIcon()
                    --end

                    taskbarIcon:delete() -- must delete() it for program to exit in MSW
                end
            end)

    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Controls Application")

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
            wx.wxMessageBox('This is the "About" dialog of the Controls wxLua sample.\n'..
                            'Check or uncheck events you want shown.\n'..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About wxLua",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )

    -- -----------------------------------------------------------------------
    splitter = wx.wxSplitterWindow(frame, wx.wxID_ANY)
    splitter:SetMinimumPaneSize(50) -- don't let it unsplit
    splitter:SetSashGravity(.8)

    splitter2 = wx.wxSplitterWindow(splitter, wx.wxID_ANY)
    splitter2:SetMinimumPaneSize(50) -- don't let it unsplit
    splitter2:SetSashGravity(.1)

    -- -----------------------------------------------------------------------

    noteBook = wx.wxNotebook(splitter2, wx.wxID_ANY)

    -- -----------------------------------------------------------------------
    eventListCtrl = wx.wxListCtrl(noteBook, ID_EVENT_LISTCTRL,
                                  wx.wxDefaultPosition, wx.wxDefaultSize,
                                  wx.wxLC_REPORT)
    eventListCtrl:SetImageList(listImageList, wx.wxIMAGE_LIST_SMALL)
    eventListCtrl:InsertColumn(0, "wxEvent Class")
    eventListCtrl:InsertColumn(1, "wxEventType")

    -- Add all the initial items and find the best fitting col widths
    local li = 0
    local col_widths = {200, 300}
    for n = 1, #wxEVT_List do
        local img = 1
        if     skipEVTs[wxEVT_List[n][2]]   then img = 2
        elseif ignoreEVTs[wxEVT_List[n][2]] then img = 0 end

        li = eventListCtrl:InsertItem(li, wxEVT_List[n][1], img)
        eventListCtrl:SetItem(li, 1, wxEVT_List[n][2])

        for i = 1, #col_widths do
            local w = eventListCtrl:GetTextExtent(wxEVT_List[n][i])
            if w > col_widths[i] + 16 then w = col_widths[i] + 16 end
        end
    end
    for i = 1, #col_widths do
        eventListCtrl:SetColumnWidth(i-1, col_widths[i])
    end

    -- Handle selecting or deselecting events
    function OnCheckListCtrl(event)
        local listCtrl = event:GetEventObject():DynamicCast("wxListCtrl")
        local win_id = event:GetId()
        event:Skip(false)
        local ignored_count = 0
        local sel = {}

        -- Find all the selected items
        for n = 1, listCtrl:GetItemCount() do
            local s = listCtrl:GetItemState(n-1, wx.wxLIST_STATE_SELECTED)
            if s ~= 0 then
                local litem = wx.wxListItem()
                litem:SetId(n-1)
                litem:SetMask(wx.wxLIST_MASK_IMAGE)
                listCtrl:GetItem(litem)
                if litem:GetImage() < 2 then -- skipEVTs
                    if litem:GetImage() == 0 then
                        ignored_count = ignored_count + 1
                    end

                    litem:SetMask(wx.wxLIST_MASK_TEXT)
                    litem:SetColumn(1)
                    listCtrl:GetItem(litem)
                    table.insert(sel, {n-1, litem:GetText()})
                end
            end
        end

        local img = 0
        if (#sel) < 2*ignored_count then img = 1 end

        for n = 1, #sel do
            listCtrl:SetItemImage(sel[n][1], img)

            if win_id == ID_EVENT_LISTCTRL then
                if img == 0 then
                    ignoreEVTs[sel[n][2]] = true
                else
                    ignoreEVTs[sel[n][2]] = nil
                end
            elseif win_id == ID_CONTROL_LISTCTRL then
                print(sel[n][2], type(sel[n][2]))
                if img == 0 then
                    ignoreControls[tonumber(sel[n][2])] = true
                else
                    ignoreControls[tonumber(sel[n][2])] = nil
                end
            end
        end
    end

    eventListCtrl:Connect(wx.wxEVT_COMMAND_LIST_KEY_DOWN,
            function(event)
                if event:GetKeyCode() == wx.WXK_SPACE then
                    OnCheckListCtrl(event)
                else
                    event:Skip()
                end
            end)
    eventListCtrl:Connect(wx.wxEVT_COMMAND_LIST_ITEM_ACTIVATED, OnCheckListCtrl)

    -- -----------------------------------------------------------------------

    controlListCtrl = wx.wxListCtrl(noteBook, ID_CONTROL_LISTCTRL,
                                  wx.wxDefaultPosition, wx.wxDefaultSize,
                                  wx.wxLC_REPORT)
    controlListCtrl:SetImageList(listImageList, wx.wxIMAGE_LIST_SMALL)
    controlListCtrl:InsertColumn(0, "wxWindow Class")
    controlListCtrl:InsertColumn(1, "wxWindowID")

    -- We add the items after creating all the controls

    controlListCtrl:Connect(wx.wxEVT_COMMAND_LIST_KEY_DOWN,
            function(event)
                if event:GetKeyCode() == wx.WXK_SPACE then
                    OnCheckListCtrl(event)
                else
                    event:Skip()
                end
            end)
    controlListCtrl:Connect(wx.wxEVT_COMMAND_LIST_ITEM_ACTIVATED, OnCheckListCtrl)

    -- -----------------------------------------------------------------------

    noteBook:AddPage(eventListCtrl, "wxEvents")
    noteBook:AddPage(controlListCtrl, "wxWindows")

    -- -----------------------------------------------------------------------

    controlsWin = CreateControlsWindow(splitter2)

    -- Add all the initial items and find the best fitting col widths
    local li = 0
    local col_widths = {200, 300}
    local cTable = {}
    for k, v in pairs(controlTable) do table.insert(cTable, { k, v }) end
    table.sort(cTable, function(t1, t2) return t1[2] > t2[2] end)
    for n = 1, #cTable do
        local img = 1

        li = controlListCtrl:InsertItem(li, cTable[n][2], img)
        controlListCtrl:SetItem(li, 1, tostring(cTable[n][1]))

        for i = 1, #col_widths do
            local w = controlListCtrl:GetTextExtent(tostring(cTable[n][i]))
            if w > col_widths[i] + 16 then w = col_widths[i] + 16 end
        end
    end
    for i = 1, #col_widths do
        controlListCtrl:SetColumnWidth(i-1, col_widths[i])
    end

    -- -----------------------------------------------------------------------

    textCtrl = wx.wxTextCtrl(splitter, wx.wxID_ANY, "",
                             wx.wxDefaultPosition, wx.wxDefaultSize,
                             wx.wxTE_MULTILINE+wx.wxTE_DONTWRAP)

    -- -----------------------------------------------------------------------

    splitter:SplitHorizontally(splitter2, textCtrl, 300)
    splitter2:SplitVertically(noteBook, controlsWin, 300)

    -- -----------------------------------------------------------------------

    frame:Show(true) -- show the frame window
end

main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
