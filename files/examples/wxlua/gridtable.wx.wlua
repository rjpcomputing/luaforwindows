-----------------------------------------------------------------------------
-- Name:        gridtable.wx.lua
-- Purpose:     wxGridTable wxLua sample
-- Author:      Hakki Dogusan, Michael Bedward
-- Created:     January 2008
-- Copyright:   (c) 2008 Hakki Dogusan, Michael Bedward
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")



local function _(s) return s end
local function _T(s) return s end

local function connectvirtuals(gridtable)
    --enum Columns
    --{
    local Col_Id = 0
    local Col_Summary = 1
    local Col_Severity = 2
    local Col_Priority = 3
    local Col_Platform = 4
    local Col_Opened = 5
    local Col_Max = 6
    --};

    --enum Severity
    --{
    local Sev_Wish = 0
    local Sev_Minor = 1
    local Sev_Normal = 2
    local Sev_Major = 3
    local Sev_Critical = 4
    local Sev_Max = 5
    --};

    local --[[static const wxString]] severities =
    {
        _T("wishlist"),
        _T("minor"),
        _T("normal"),
        _T("major"),
        _T("critical"),
    };

    local --[[static struct BugsGridData
    {
        int id;
        wxChar summary[80];
        Severity severity;
        int prio;
        wxChar platform[12];
        bool opened;
    }]] gs_dataBugsGrid =
    {
        { id=18, summary=_T("foo doesn't work"), severity=Sev_Major, prio=1, platform=_T("wxMSW"), opened=true },
        { id=27, summary=_T("bar crashes"), severity=Sev_Critical, prio=1, platform=_T("all"), opened=false },
        { id=45, summary=_T("printing is slow"), severity=Sev_Minor, prio=3, platform=_T("wxMSW"), opened=true },
        { id=68, summary=_T("Rectangle() fails"), severity=Sev_Normal, prio=1, platform=_T("wxMSW"), opened=false },
    };

    --[[static const wxChar *headers[Col_Max] = ]]
    local headers =
    {
        _T("Id"),
        _T("Summary"),
        _T("Severity"),
        _T("Priority"),
        _T("Platform"),
        _T("Opened?"),
    };


    --wxString BugsGridTable::GetTypeName(int WXUNUSED(row), int col)
    gridtable.GetTypeName = function( self, row, col )
        if col == Col_Id or col == Col_Priority then
            return wx.wxGRID_VALUE_NUMBER
        elseif col == Col_Severity or col == Col_Summary then
            return string.format(_T("%s:80"), wx.wxGRID_VALUE_STRING)
        elseif col == Col_Platform then
            return string.format(_T("%s:all,MSW,GTK,other"), wx.wxGRID_VALUE_CHOICE)
        elseif col == Col_Opened then
            return wx.wxGRID_VALUE_BOOL
        end
        return wx.wxEmptyString
    end

    --int BugsGridTable::GetNumberRows()
    gridtable.GetNumberRows = function( self )
        return #gs_dataBugsGrid
    end

    --int BugsGridTable::GetNumberCols()
    gridtable.GetNumberCols = function( self )
        return Col_Max
    end

    --bool BugsGridTable::IsEmptyCell( int WXUNUSED(row), int WXUNUSED(col) )
    gridtable.IsEmptyCell = function( self, row, col )
        return false
    end

    --wxString BugsGridTable::GetValue( int row, int col )
    gridtable.GetValue = function( self, row, col )
        local function iff(cond, A, B) if cond then return A else return B end end

        local gd = gs_dataBugsGrid[row+1]
        if col == Col_Id then
            return string.format(_T("%d"), gd.id);
        elseif col == Col_Priority then
            return string.format(_T("%d"), gd.prio);
        elseif col == Col_Opened then
            return iff(gd.opened, _T("1"), _T("0"))
        elseif col == Col_Severity then
            return severities[gd.severity+1];
        elseif col == Col_Summary then
            return gd.summary;
        elseif col == Col_Platform then
            return gd.platform;
        end
        return wx.wxEmptyString;
    end

    --void BugsGridTable::SetValue( int row, int col, const wxString& value )
    gridtable.SetValue = function( self, row, col, value )
        local gd = gs_dataBugsGrid[row+1]
        if col == Col_Id or col == Col_Priority or col == Col_Opened then
            error(_T("unexpected column"))
        elseif col == Col_Severity then
            for n=1,#severities do
                if severities[n] == value then
                    gd.severity = n-1
                    return
                end
            end
            --Invalid severity value
            gd.severity = Sev_Normal
        elseif col == Col_Summary then
            gd.summary = value
        elseif col == Col_Platform then
            gd.platform = value
        end
    end

    --bool
    --BugsGridTable::CanGetValueAs(int WXUNUSED(row),
    --                             int col,
    --                             const wxString& typeName)
    gridtable.CanGetValueAs = function( self, row, col, typeName )
        if typeName == wx.wxGRID_VALUE_STRING then
            return true
        elseif typeName == wx.wxGRID_VALUE_BOOL then
            return col == Col_Opened
        elseif typeName == wx.wxGRID_VALUE_NUMBER then
            return col == Col_Id or col == Col_Priority or col == Col_Severity
        else
            return false
        end
    end

    --bool BugsGridTable::CanSetValueAs( int row, int col, const wxString& typeName )
    gridtable.CanSetValueAs = function( self, row, col, typeName )
        return self:CanGetValueAs(row, col, typeName)
    end

    --long BugsGridTable::GetValueAsLong( int row, int col )
    gridtable.GetValueAsLong = function( self, row, col )
        local gd = gs_dataBugsGrid[row+1]

        if col == Col_Id then
            return gd.id;
        elseif col == Col_Priority then
            return gd.prio;
        elseif col == Col_Severity then
            return gd.severity;
        else
            error(_T("unexpected column"));
            return -1;
        end
    end

    --bool BugsGridTable::GetValueAsBool( int row, int col )
    gridtable.GetValueAsBool = function( self, row, col )
        if col == Col_Opened then
            return gs_dataBugsGrid[row+1].opened;
        else
            error(_T("unexpected column"));
            return false;
        end
    end

    --void BugsGridTable::SetValueAsLong( int row, int col, long value )
    gridtable.SetValueAsLong = function( self, row, col, value )
        local gd = gs_dataBugsGrid[row+1]

        if col == Col_Priority then
            gd.prio = value;
        else
            error(_T("unexpected column"));
        end
    end

    --void BugsGridTable::SetValueAsBool( int row, int col, bool value )
    gridtable.SetValueAsBool = function( self, row, col, value )
        if col == Col_Opened then
            gs_dataBugsGrid[row+1].opened = value;
        else
            error(_T("unexpected column"));
        end
    end

    --wxString BugsGridTable::GetColLabelValue( int col )
    gridtable.GetColLabelValue = function( self, col )
        return headers[col+1];
    end

--~     gridtable.GetAttr = function(self,row,col,kind )
--~         --[[
--~         %enum wxGridCellAttr::wxAttrKind
--~         Any
--~         Default
--~         Cell
--~         Row
--~         Col
--~         Merged
--~         --]]
--~         local attr=wx.wxGridCellAttr()
--~         if row==0 and col==0 then
--~             attr:SetTextColour(wx.wxRED)
--~         elseif row==0 and col==1 then
--~             attr:SetBackgroundColour(wx.wxCYAN)
--~         elseif row==0 and col==2 then
--~             attr:SetReadOnly(true)
--~         end
--~         return attr
--~     end
end


local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxLua wxGrid Sample",
                         wx.wxPoint(25, 25), wx.wxSize(350, 250))

local fileMenu = wx.wxMenu("", wx.wxMENU_TEAROFF)
fileMenu:Append(wx.wxID_EXIT, "E&xit\tCtrl-X", "Quit the program")

local helpMenu = wx.wxMenu("", wx.wxMENU_TEAROFF)
helpMenu:Append(wx.wxID_ABOUT, "&About\tCtrl-A", "About the Grid wxLua Application")

local menuBar = wx.wxMenuBar()
menuBar:Append(fileMenu, "&File")
menuBar:Append(helpMenu, "&Help")

frame:SetMenuBar(menuBar)

frame:CreateStatusBar(1)
frame:SetStatusText("Welcome to wxLua.")

frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        frame:Close()
    end )

frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event)
        wx.wxMessageBox('This is the "About" dialog of the wxGrid wxLua sample.\n'..
                        wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                        "About wxLua",
                        wx.wxOK + wx.wxICON_INFORMATION,
                        frame )
    end )

grid = wx.wxGrid(frame, wx.wxID_ANY)
local gridtable = wx.wxLuaGridTableBase()
connectvirtuals(gridtable)
gridtable:SetView( grid )
local rc = grid:SetTable(gridtable)

--~ grid:CreateGrid(10, 8)
--~ grid:SetColSize(3, 200)
--~ grid:SetRowSize(4, 45)
--~ grid:SetCellValue(0, 0, "First cell")
--~ grid:SetCellValue(1, 1, "Another cell")
--~ grid:SetCellValue(2, 2, "Yet another cell")
--~ grid:SetCellFont(0, 0, wx.wxFont(10, wx.wxROMAN, wx.wxITALIC, wx.wxNORMAL))
--~ grid:SetCellTextColour(1, 1, wx.wxRED)
--~ grid:SetCellBackgroundColour(2, 2, wx.wxCYAN)

frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
