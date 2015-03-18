-----------------------------------------------------------------------------
-- Name:        bindings.wx.lua
-- Purpose:     Show wxLua bindings in a wxListCtrl or dump them using print
-- Author:      john Labenski
-- Modified by:
-- Created:     5/7/2007
-- RCS-ID:
-- Copyright:   (c) John Labenski
-- Licence:     wxWidgets licence
-----------------------------------------------------------------------------

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- Brute force dump of the binding info using print statements for debugging
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

function ColumnDumpTable(t, keys)

    local lens = {}

    for i = 1, #keys do
        lens[i] = string.len(keys[i])
    end

    for i = 1, #t do
        local u = t[i]
        for k = 1, #keys do
            local len = string.len(tostring(u[keys[k]]))
            if (len > lens[k]) then
                lens[k] = len
            end
        end
    end

    local s = ""
    for k = 1, #keys do
        local val = tostring(keys[k])
        local buf = string.rep(" ", lens[k] - string.len(val) + 1)
        s = s..val..buf
    end
    print(s)

    for i = 1, #t do
        local u = t[i]
        local s = ""
        for k = 1, #keys do
            local val = tostring(u[keys[k]])
            local buf = string.rep(" ", lens[k] - string.len(val) + 1)
            s = s..val..buf
        end
        print(s)
    end
end

function DumpBindingInfo(binding)

    print("GetBindingName  : "..tostring(binding.GetBindingName))
    print("GetLuaNamespace : "..tostring(binding.GetLuaNamespace))

    print("GetClassCount    : "..tostring(binding.GetClassCount))
    print("GetNumberCount   : "..tostring(binding.GetNumberCount))
    print("GetStringCount   : "..tostring(binding.GetStringCount))
    print("GetEventCount    : "..tostring(binding.GetEventCount))
    print("GetObjectCount   : "..tostring(binding.GetObjectCount))
    print("GetFunctionCount : "..tostring(binding.GetFunctionCount))

    if true then
        print("\nDUMPING binding.GetClassArray ==================================\n")
        local keys = { "name", "wxluamethods", "wxluamethods_n", "classInfo", "wxluatype", "baseclassNames", "baseBindClasses", "enums", "enums_n" }
        ColumnDumpTable(binding.GetClassArray, keys)
    end

    if true then
        print("\nDUMPING binding.GetFunctionArray ==================================\n")
        local keys = { "name", "type", "wxluacfuncs", "wxluacfuncs_n", "basemethod" }
        ColumnDumpTable(binding.GetFunctionArray, keys)
    end

    if true then
        print("\nDUMPING binding.GetNumberArray ==================================\n")
        local keys = { "name", "value" }
        ColumnDumpTable(binding.GetNumberArray, keys)
    end

    if true then
        print("\nDUMPING binding.GetStringArray ==================================\n")
        local keys = { "name", "value" }
        ColumnDumpTable(binding.GetStringArray, keys)
    end

    if true then
        print("\nDUMPING binding.GetEventArray ==================================\n")
        local keys = { "name", "eventType", "wxluatype" }
        ColumnDumpTable(binding.GetEventArray, keys)
    end

    if true then
        print("\nDUMPING binding.GetObjectArray ==================================\n")
        local keys = { "name", "object", "wxluatype" }
        ColumnDumpTable(binding.GetObjectArray, keys)
    end

end

-- Call DumpBindingInfo(...) on the binding you want to show

--DumpBindingInfo(wxlua.GetBindings()[1])

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
-- A wxLua program to view the bindings in a wxListCtrl
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

frame       = nil
listCtrl    = nil

ID_LISTCTRL                 = 1000  -- id of the listctrl
ID_VIEW_BASECLASS_FUNCTIONS = 1001
ID_STACK_DIALOG             = 1002

list_images = {
    ["normal"]  = 0, -- file image
    ["folder"]  = 1, -- folder
    ["sort_dn"] = 2, -- down arrow
    ["sort_up"] = 3, -- up arrow
}

list_colors = {
    ["purple"] = wx.wxColour("purple"),
    ["green"]  = wx.wxColour(0, 180, 0),
}


listColWidths = {}  -- stored by "object_type" name

list_level  = 1     -- where are we in the listData
listData    = {}    -- store the table currently displayed by the listCtrl
                    -- {{"col val 1", "val2", ... ["icon"] = list_images.normal, ["color"] = wx.wxBLUE },
                    --  {"col val 1", "val2", ... ["col_icons"] = {["col#"] = true, ...}},
                    --  {"col val 1", "val2", ... ["data"] = {["col#"] = some data, ...}},
                    --  {"col val 1", "val2", ... icon, color, col_icons, data are optional },
                    --  { ... these are numbered items for the rows },
                    --  ["col_labels"] = { "col label 1", "col label 2", ...},
                    --  ["object_type"] = "wxLuaBindClass",  -- or something else readable
                    --  ["list_item"] = last selected list item or nil if not set

bindingList = wxlua.GetBindings() -- Table of {wxLuaBinding functions}

-- ----------------------------------------------------------------------------
-- Function to simulate var = cond ? a : b
-- ----------------------------------------------------------------------------

function iff(cond, a, b) if cond then return a else return b end end

-- ----------------------------------------------------------------------------
-- Save the current listctrl settings into the listColWidths table
-- ----------------------------------------------------------------------------
function SaveListColWidths(level)
    local object_type = listData[level].object_type

    if not listColWidths[object_type] then
        listColWidths[object_type] = {}
    end

    for col = 1, listCtrl:GetColumnCount() do
        listColWidths[object_type][col] = listCtrl:GetColumnWidth(col-1)
    end
end

-- ----------------------------------------------------------------------------
-- Go to a binding level which already must exist in the listData table
-- ----------------------------------------------------------------------------
function GotoBindingLevel(listCtrl, level)
    wx.wxBeginBusyCursor();

    local data = listData[level]

    -- Do we calculate what widths to use for the cols or use previous values?
    local auto_col_widths = false
    if listColWidths[data.object_type] == nil then
        auto_col_widths = true
        listColWidths[data.object_type] = {}
    end

    local function AutoColWidth(col, txt)
        if auto_col_widths and txt then
            local w = listCtrl:GetTextExtent(txt)
            if w > (listColWidths[data.object_type][col] or 0) - 25 then
                if w > 400 then w = 400 end
                listColWidths[data.object_type][col] = w + 25
            end
        end
    end

    -- Wipe items and extra cols
    listCtrl:DeleteAllItems()

    while #data.col_labels < listCtrl:GetColumnCount() do
        listCtrl:DeleteColumn(0)
    end

    -- Add the cols
    for col = 1, #data.col_labels do
        if col > listCtrl:GetColumnCount() then
            listCtrl:InsertColumn(col-1, data.col_labels[col], wx.wxLIST_FORMAT_LEFT, -1)
        else
            local li = wx.wxListItem()
            li:SetText(data.col_labels[col])
            li:SetImage(-1)
            listCtrl:SetColumn(col-1, li)
        end

        if data.col_sorted and data.col_sorted[col] then
            listCtrl:SetColumnImage(col-1, data.col_sorted[col])
        end

        AutoColWidth(col, data.col_labels[col])
    end

    -- Add the items
    local lc_item = 0

    for i = 1, #data do
        local d = data[i]

        local li = wx.wxListItem()
        li:SetId(lc_item+1)
        li:SetText(tostring(d[1] or ""))
        li:SetData(i) -- key into the listData table for sorting

        if (d.icon)  then li:SetImage(d.icon) end
        if (d.color) then li:SetTextColour(d.color) end

        lc_item = listCtrl:InsertItem(li)

        AutoColWidth(1, tostring(d[1]))

        for col = 2, #listData[level].col_labels do
            listCtrl:SetItem(lc_item, col-1, tostring(d[col] or ""))

            if d.col_icons and d.col_icons[col] then
                listCtrl:SetItemColumnImage(lc_item, col-1, d.col_icons[col])
            end

            AutoColWidth(col, tostring(d[col]))
        end
    end

    -- Set the column widths
    if listColWidths[data.object_type] then
        for col = 1, #listColWidths[data.object_type] do
            listCtrl:SetColumnWidth(col-1, listColWidths[data.object_type][col])
        end
    end

    -- Try to reselect the item if we're going up a level
    if data.list_item and (data.list_item < listCtrl:GetItemCount()) then
        listCtrl:SetItemState(data.list_item, wx.wxLIST_STATE_FOCUSED, wx.wxLIST_STATE_FOCUSED);
        listCtrl:SetItemState(data.list_item, wx.wxLIST_STATE_SELECTED, wx.wxLIST_STATE_SELECTED);
        listCtrl:EnsureVisible(data.list_item)
    end

    -- Finally set the status text of where we are
    local s = {}
    for i = 1, level do
        table.insert(s, listData[i].object_type)
    end
    frame:SetStatusText(table.concat(s, "->"))

    wx.wxEndBusyCursor();
end

-- ----------------------------------------------------------------------------
-- Convert the wxLuaMethod_Type enum into a readable string
-- ----------------------------------------------------------------------------
function CreatewxLuaMethod_TypeString(t_)
    local s = {}
    local t = t_

    local function HasBit(val, bit, tbl, name)
        if (val - bit) >= 0 then
            val = val - bit
            if tbl then table.insert(tbl, name) end
        end
        return val
    end

    -- subtract values from high to low value
    t = HasBit(t, wxlua.WXLUAMETHOD_CHECKED_OVERLOAD, nil, nil) -- nobody should care about this
    t = HasBit(t, wxlua.WXLUAMETHOD_DELETE,      s, "Delete")
    t = HasBit(t, wxlua.WXLUAMETHOD_STATIC,      s, "Static")
    t = HasBit(t, wxlua.WXLUAMETHOD_SETPROP,     s, "SetProp")
    t = HasBit(t, wxlua.WXLUAMETHOD_GETPROP,     s, "GetProp")
    t = HasBit(t, wxlua.WXLUAMETHOD_CFUNCTION,   s, "CFunc")
    t = HasBit(t, wxlua.WXLUAMETHOD_METHOD,      s, "Method")
    t = HasBit(t, wxlua.WXLUAMETHOD_CONSTRUCTOR, s, "Constructor")

    assert(t == 0, "The wxLuaMethod_Type is not handled correctly, remainder "..tostring(t).." of "..tostring(t_))

    -- remove this, nobody should care and it'll probably be confusing
    t = HasBit(t_, wxlua.WXLUAMETHOD_CHECKED_OVERLOAD, nil, nil)

    return string.format("0x%04X (%s)", t, table.concat(s, ", "))
end

-- ----------------------------------------------------------------------------
-- Convert the argtypes table into a readable string
-- ----------------------------------------------------------------------------
function CreateArgTagsString(args_table, wxlua_type)
    local arg_names = {}

    for j = 1, #args_table do
        local s = wxlua.typename(args_table[j])

        -- The first arg for a class member function is the self
        if (j == 1) and
           (bit.band(wxlua_type, wxlua.WXLUAMETHOD_CFUNCTION) == 0) and
           (bit.band(wxlua_type, wxlua.WXLUAMETHOD_CONSTRUCTOR) == 0) and
           (bit.band(wxlua_type, wxlua.WXLUAMETHOD_STATIC) == 0) then
           s = s.."(self)"
        end

        table.insert(arg_names, s)
    end

    return table.concat(arg_names, ", ")
end

-- ----------------------------------------------------------------------------
-- Create a list table from a wxLuaBindClass struct table
-- ----------------------------------------------------------------------------
function CreatewxLuaBindClass(tbl)
    local t = {
        {"..", ["icon"] = list_images.folder},
        ["col_labels"] = { "Class Name", "# Methods", "wxClassInfo", "Class Tag", "Base Class Names", "# Enums" },
        ["object_type"] = "wxLuaBindClass"
    }

    -- items in table from binding.GetClassArray are these
    -- { "name", "wxluamethods", "wxluamethods_n", "classInfo", "wxluatype", "baseclassNames", "baseBindClasses", "enums", "enums_n" }

    local function GetClassInfoStr(classInfo)
        local s = ""

        if type(classInfo) == "userdata" then
            s  = classInfo:GetClassName()
            local b1 = classInfo:GetBaseClassName1()
            local b2 = classInfo:GetBaseClassName2()

            if (string.len(b1) > 0) then
                s = s.." ("..b1..")"
            end
            if (string.len(b2) > 0) then
                s = s.."("..b2..")"
            end
        end

        return s
    end

    t.col_numbers = {}
    t.col_numbers[2] = true
    t.col_numbers[4] = true
    t.col_numbers[6] = true

    --{ "name"[data], "wxluamethods_n", "classInfo", "wxluatype", "baseclassNames"[data], "enums_n"[data] }
    for i = 1, #tbl do
        local item = {
            tbl[i].name,
            tbl[i].wxluamethods_n,
            GetClassInfoStr(tbl[i].classInfo),
            tbl[i].wxluatype,
            table.concat(tbl[i].baseclassNames or {}, ","),
            tbl[i].enums_n,
            ["col_icons"] = {},
            ["data"] = {}
        }

        -- This class has methods and can be expanded
        if (type(tbl[i].wxluamethods) == "table") then
            item.icon = list_images.folder
            item.data[1] = tbl[i].wxluamethods
        end

        -- This class has a baseclass and can be expanded
        if (type(tbl[i].baseBindClasses) == "table") then
            item.col_icons[5] = list_images.folder
            item.data[5] = tbl[i].baseBindClasses
        end

        -- This class has enums and can be expanded
        if (type(tbl[i].enums) == "table") then
            item.col_icons[6] = list_images.folder
            item.data[6] = tbl[i].enums
        end

        -- some sanity checks to make sure the bindings are working
        if (tbl[i].wxluamethods_n > 0) and (type(tbl[i].wxluamethods) ~= "table") then
            print(tbl[i].name, "is missing methods table, please report this.")
        end
        if (tbl[i].baseclassNames) and (type(tbl[i].baseBindClasses) ~= "table") then
            print(tbl[i].name, "is missing baseclass userdata, please report this.")
        end
        if (tbl[i].enums_n > 0) and (type(tbl[i].enums) ~= "table") then
            print(tbl[i].name, "is missing enums table, please report this.")
        end

        table.insert(t, item)
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Create a list table from a wxLuaBindMethod struct table
-- ----------------------------------------------------------------------------
function CreatewxLuaBindMethod(tbl, classname)
    local t = {
        {"..", ["icon"] = list_images.folder},
        ["col_labels"] = { "name", "method_type", "function", "basemethod", "minargs", "maxargs", "argtype_names", "argtypes" },
        ["object_type"] = "wxLuaBindMethod"
    }

    -- items in table are
    -- { "name", "type", "wxluacfuncs", "wxluacfuncs_n", "basemethod" }

    t.col_numbers = {}
    t.col_numbers[3] = true
    t.col_numbers[5] = true
    t.col_numbers[6] = true

    for i = 1, #tbl do
        local class_name = ""
        if tbl[i].class_name then 
            class_name = tbl[i].class_name.."::" 
        end
        if classname then 
            class_name = classname.."::" 
        end

        -- keys for CFunc = { "lua_cfunc", "type", "minargs", "maxargs", "argtype_names", "argtypes" }
        local cfunc_t = CreatewxLuaBindCFunc(tbl[i].wxluacfuncs)
        for j = 2, #cfunc_t do
            local cft = {
                class_name..tbl[i].name,
                cfunc_t[j][2], 
                tostring(cfunc_t[j][1]), 
                "", 
                cfunc_t[j][3], 
                cfunc_t[j][4], 
                cfunc_t[j][5], 
                cfunc_t[j][6],
                ["icon"] = nil,
                ["col_icons"] = {},
                ["data"] = {}
            }

            if string.find(cfunc_t[j][2], "Overload", 1, 1) then 
                cft.color = list_colors.green 
            end
            if #cfunc_t > 2 then 
                cft[1] = cft[1].." "..tostring(j-1) 
            end

            -- This method has a basemethod and can be expanded
            if type(tbl[i].basemethod) == "userdata" then
                cft[4] = tbl[i].basemethod.class_name
                cft.data[4] = tbl[i].basemethod
                cft.col_icons[4] = list_images.folder
            end

            table.insert(t, cft)
        end
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Create a list table from a wxLuaBindNumber struct table
-- ----------------------------------------------------------------------------
function CreatewxLuaBindNumber(tbl)
    local keys = { "name", "value" }
    local t = CreatewxLuaBindTable(tbl, keys, "wxLuaBindNumber")

    t.col_numbers = {}
    t.col_numbers[2] = true

    -- these are often enums or flags, it's easier to see them as hex
    table.insert(t.col_labels, "hex")

    for i = 2, #t do
        t[i][3] = string.format("0x%X", t[i][2])
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Create a list table from a wxLuaBindString struct table
-- ----------------------------------------------------------------------------
function CreatewxLuaBindString(tbl)
    local keys = { "name", "value" }
    return CreatewxLuaBindTable(tbl, keys, "wxLuaBindString")
end

-- ----------------------------------------------------------------------------
-- Create a list table from a wxLuaBindEvent struct table
-- ----------------------------------------------------------------------------
function CreatewxLuaBindEvent(tbl)
    local keys = { "name", "eventType", "wxluatype", "wxLuaBindClass" }
    local t = CreatewxLuaBindTable(tbl, keys, "wxLuaBindEvent")

    t.col_numbers = {}
    t.col_numbers[2] = true

    -- Add the class tag name for the event
    for i = 2, #t do
        t[i][3] = wxlua.typename(t[i][3]).." ("..t[i][3]..")"
        -- if t[i-1][2] == t[i][2] then t[i].color = wx.wxRED end -- see if there's dups, there's a couple, but they're right

        -- Set the wxLuaBindClass for this event type
        if type(t[i][4]) == "userdata" then
            local c = t[i][4]
            t[i][4] = c.name
            t[i].data = {}
            t[i].data[4] = c
            t[i].col_icons = {}
            t[i].col_icons[4] = list_images.folder
        end
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Create a list table from a wxLuaBindObject struct table
-- ----------------------------------------------------------------------------
function CreatewxLuaBindObject(tbl)
    local keys = { "name", "object", "wxluatype", "wxLuaBindClass" }
    local t = CreatewxLuaBindTable(tbl, keys, "wxLuaBindObject")

    -- Add the class tag name for the user data
    for i = 2, #t do
        t[i][3] = wxlua.typename(t[i][3]).." ("..t[i][3]..")"

        -- Set the wxLuaBindClass for this object
        if type(t[i][4]) == "userdata" then
            local c = t[i][4]
            t[i][4] = c.name
            t[i].data = {}
            t[i].data[4] = c
            t[i].col_icons = {}
            t[i].col_icons[4] = list_images.folder
        end
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Create a list table from a wxLuaBindCFunc struct table
-- ----------------------------------------------------------------------------
function CreatewxLuaBindCFunc(tbl)
    local keys = { "lua_cfunc", "method_type", "minargs", "maxargs", "argtypes" }
    local t = CreatewxLuaBindTable(tbl, keys, "wxLuaBindCFunc")

    t.col_labels[5] ="argtype_names" -- swap these two
    t.col_labels[6] ="argtypes"

    t.col_numbers = {}
    t.col_numbers[3] = true
    t.col_numbers[4] = true

    -- we don't want to show the table, just show the values
    for i = 2, #t do
        local args = t[i][5]
        t[i][5] = CreateArgTagsString(args, t[i][2]) -- swap these two
        t[i][6] = table.concat(args, ", ")

        t[i][2] = CreatewxLuaMethod_TypeString(t[i][2])
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Generically Create a list table from a wxLuaBindXXX struct table
-- ----------------------------------------------------------------------------
function CreatewxLuaBindTable(tbl, cols, object_type)
    local t = {
        {"..", ["icon"] = list_images.folder},
        ["col_labels"] = cols,
        ["object_type"] = object_type
    }

    --local keys = {} -- used to find dups

    for i = 1, #tbl do
        local item = {}
        for c = 1, #cols do
            -- we need to force there to be something in each col, use ""
            local val = tbl[i][cols[c]]
            if val ~= nil then
                table.insert(item, val)
            else
                table.insert(item, "")
            end
        end

        --if keys[tbl[i]] then item.color = wx.wxRED end -- check dup keys
        --keys[tbl[i]] = true

        table.insert(t, item)
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Sort items in the listctrl based on the column (0 based) and also the data table
-- ----------------------------------------------------------------------------
function SortListItems(col)
    local data = listData[list_level]

    local sorted = false
    if data.col_sorted and data.col_sorted[col+1] then
        sorted = data.col_sorted[col+1] == list_images.sort_dn
    end

    local function SortListItems(item1, item2, col)
        local data1 = data[item1]
        local data2 = data[item2]

        if data1[1] == ".." then return -1 end
        if data2[1] == ".." then return  1 end

        local i1 = data1[col]
        local i2 = data2[col]

        if data.col_numbers and data.col_numbers[col] then
            -- sort on the real numbers, but treat "" as lower
            if (i1 == "") and (i2 == "") then
                i1, i2 = 0, 0
            elseif (i1 == "") then
                i1, i2 = 0, 1
            elseif (i2 == "") then
                i1, i2 = 1, 0
            else
                i1 = tonumber(i1)
                i2 = tonumber(i2)
            end
        else
            i1 = tostring(data1[col])
            i2 = tostring(data2[col])
        end

        if sorted then
            if i1 < i2 then return  1 end
            if i1 > i2 then return -1 end
        else
            if i1 < i2 then return -1 end
            if i1 > i2 then return  1 end
        end

        return 0
    end

    listCtrl:SortItems(SortListItems, col+1)
    data.col_sorted = {} -- we only remember the last col sorted
    if not sorted then
        data.col_sorted[col+1] = list_images.sort_dn
    else
        data.col_sorted[col+1] = list_images.sort_up
    end

    -- now make the table of data match what's in the listctrl so when you
    -- go up a level it'll stay sorted the same way
    -- Note: it seems faster to let the listctrl sort and then match the lua table
    --       rather than sort table, clear listctrl, and add it back.
    local t = {}
    for i = 1, listCtrl:GetItemCount() do
        local d = listCtrl:GetItemData(i-1) -- old table indexes
        table.insert(t, data[d])            -- table with listctrl order
    end

    for i = 1, #t do
        listData[list_level][i] = t[i] -- update original table
        listCtrl:SetItemData(i-1, i)   -- fix itemdata to match table indexes
    end

    -- put the arrow in the col header that we've sorted this col and clear others
    for c = 1, listCtrl:GetColumnCount() do
        if c ~= col+1 then
            listCtrl:SetColumnImage(c-1, -1)
        elseif not sorted then
            listCtrl:SetColumnImage(col, list_images.sort_dn)
        else
            listCtrl:SetColumnImage(col, list_images.sort_up)
        end
    end

end

-- ----------------------------------------------------------------------------
-- Handle the wxEVT_COMMAND_LIST_ITEM_ACTIVATED event when the mouse is clicked
-- ----------------------------------------------------------------------------
function OnListItemActivated(event)
    local index      = event:GetIndex() -- note: 0 based, lua tables start at 1
    local data_index = event:GetData()  -- this is the table index
    local itemText   = listCtrl:GetItemText(index)

    local data = listData[list_level]

    listData[list_level].list_item = index -- last clicked
    SaveListColWidths(list_level) -- remember user's col widths

    -- -----------------------------------------------------------------------
    -- Find what column we're in
    -- local col = event:GetColumn() -- both of these don't work in MSW & GTK
    -- local pt = event:GetPoint()

    local mousePos = wx.wxGetMousePosition() -- mouse pos on screen
    local clientPos = listCtrl:ScreenToClient(mousePos)
    local scrollPos = listCtrl:GetScrollPos(wx.wxHORIZONTAL) -- horiz scroll pos

    -- The wxGenericListCtrl (used in GTK at least) actually scrolls by 15
    genlistClassInfo = wx.wxClassInfo.FindClass("wxGenericListCtrl")
    if genlistClassInfo and listCtrl:GetClassInfo():IsKindOf(genlistClassInfo) then
        scrollPos = scrollPos * 15
    end

    local x = clientPos:GetX() + scrollPos
    local w = 0
    local col = 0

    --print(col, x, mousePos:GetX(), clientPos:GetX(), scrollPos)

    for c = 1, listCtrl:GetColumnCount() do
        w = w + listCtrl:GetColumnWidth(c-1)
        if x < w then
            col = c-1
            break
        end
    end

    -- Handle the different lists we may show
    if (itemText == "..") then
        list_level = list_level - 1
        GotoBindingLevel(listCtrl, list_level)
    elseif (list_level == 1) then
        if itemText == "wxLua Types" then
            list_level = list_level + 1
            listData[list_level] = CreatewxLuaTypeTable()
            GotoBindingLevel(listCtrl, list_level)
        elseif itemText == "All wxLua Classes" then
            list_level = list_level + 1
            listData[list_level] = CreateAllClassesTable()
            GotoBindingLevel(listCtrl, list_level)
        elseif itemText == "All wxWidgets wxClassInfo" then
            list_level = list_level + 1
            listData[list_level] = CreatewxClassInfoTable()
            GotoBindingLevel(listCtrl, list_level)
        elseif itemText == "Overloaded Baseclass Functions" then
            list_level = list_level + 1
            listData[list_level] = CreateOverloadedBasecassFunctionsTable()
            GotoBindingLevel(listCtrl, list_level)
        else
            local binding = data[data_index].binding

            listData[2] = {
                {"..", ["icon"] = list_images.folder},
                {"GetBindingName",   tostring(binding.GetBindingName)},
                {"GetLuaNamespace",  tostring(binding.GetLuaNamespace)},

                {"GetClassArray",    "GetClassCount : "..tostring(binding.GetClassCount), ["icon"] = list_images.folder},
                {"GetFunctionArray", "GetFunctionCount : "..tostring(binding.GetFunctionCount), ["icon"] = list_images.folder},
                {"GetNumberArray",   "GetNumberCount : "..tostring(binding.GetNumberCount), ["icon"] = list_images.folder},
                {"GetStringArray",   "GetStringCount : "..tostring(binding.GetStringCount), ["icon"] = list_images.folder},
                {"GetEventArray",    "GetEventCount : "..tostring(binding.GetEventCount), ["icon"] = list_images.folder},
                {"GetObjectArray",   "GetObjectCount : "..tostring(binding.GetObjectCount), ["icon"] = list_images.folder},

                ["col_labels"] = {"Function Name", "Value"},
                ["binding"] = binding,
                ["object_type"] = "wxLuaBinding"
            }

            list_level = list_level + 1
            GotoBindingLevel(listCtrl, list_level)
        end
    elseif (list_level == 2) then
        local binding = listData[2].binding
        local t = nil

        if (itemText == "GetClassArray") then
            t = CreatewxLuaBindClass(binding.GetClassArray)
        elseif (itemText == "GetFunctionArray") then
            t = CreatewxLuaBindMethod(binding.GetFunctionArray)
        elseif (itemText == "GetNumberArray") then
            t = CreatewxLuaBindNumber(binding.GetNumberArray)
        elseif (itemText == "GetStringArray") then
            t = CreatewxLuaBindString(binding.GetStringArray)
        elseif (itemText == "GetEventArray") then
            t = CreatewxLuaBindEvent(binding.GetEventArray)
        elseif (itemText == "GetObjectArray") then
            t = CreatewxLuaBindObject(binding.GetObjectArray)
        end

        if t ~= nil then
            list_level = list_level + 1
            listData[list_level] = t
            GotoBindingLevel(listCtrl, list_level)
        end
    elseif (data_index > 1) and (data.object_type == "wxLuaBindClass") then
        local t = nil

        if (col == 0) and (type(data[data_index].data[1]) == "table") then
            t = CreatewxLuaBindMethod(data[data_index].data[1], data[data_index][1])

            if frame:GetMenuBar():IsChecked(ID_VIEW_BASECLASS_FUNCTIONS) then
                print("hi")
                local ct = data[data_index].data[5]
                
                local function recurse_baseclasstable(ct, t)
                    for i, c in ipairs(ct) do
                        print(c.name)
                        local tt = CreatewxLuaBindMethod(c.wxluamethods, c.name)
                        for i = 2, #tt do -- skip ".."
                            if not (string.find(tt[i][2], "Constructor", 1, 1) or
                                    string.find(t[i][1], "delete", 1, 1)) then
                                    --string.find(t[i][1], "::"..c.name, 1, 1)) then
                                table.insert(t, tt[i])
                            end
                        end
                        
                        if c.baseBindClasses then
                            recurse_baseclasstable(c.baseBindClasses, t)
                        end
                    end
                end
                
                if type(ct) == "table" then
                    recurse_baseclasstable(ct, t)
                end
                
                --while type(ct) == "table" do
                --    local tt = CreatewxLuaBindMethod(c.wxluamethods, c.name)
                --    for i = 2, #tt do -- skip ".."
                --        if not (string.find(tt[i][2], "Constructor", 1, 1) or
                --                string.find(t[i][1], "delete", 1, 1)) then
                --                --string.find(t[i][1], "::"..c.name, 1, 1)) then
                --            table.insert(t, tt[i])
                --        end
                --   end
                --    c = c.baseclass
                --end
            end
        elseif (col == 4) and (type(data[data_index].data[col+1]) == "table") then
            t = CreatewxLuaBindClass(data[data_index].data[col+1])
        elseif (col == 5) and (type(data[data_index].data[col+1]) == "table") then
            t = CreatewxLuaBindNumber(data[data_index].data[col+1])
        end

        if t ~= nil then
            t.class_name = listCtrl:GetItemText(index)

            list_level = list_level + 1
            listData[list_level] = t
            GotoBindingLevel(listCtrl, list_level)
        end
    elseif (data_index > 1) and (data.object_type == "wxLuaBindMethod") then
        local t = nil

        if (col == 3) and (type(data[data_index].data[col+1]) == "userdata") then
            t = CreatewxLuaBindMethod({data[data_index].data[col+1]})
            t.class_name = data[data_index][col+1].class_name
        end

        if t ~= nil then
            list_level = list_level + 1
            listData[list_level] = t
            GotoBindingLevel(listCtrl, list_level)
        end

    elseif (data_index > 1) and (data.object_type == "wxLuaBindEvent") then
        local t = nil

        if (col == 3) and (type(data[data_index].data[col+1]) == "userdata") then
            t = CreatewxLuaBindClass({data[data_index].data[col+1]})       
        end

        if t ~= nil then
            t.class_name = listCtrl:GetItemText(index)

            list_level = list_level + 1
            listData[list_level] = t
            GotoBindingLevel(listCtrl, list_level)
        end
    elseif (data_index > 1) and (data.object_type == "wxLuaBindObject") then
        local t = nil

        if (col == 3) and (type(data[data_index].data[col+1]) == "userdata") then
            t = CreatewxLuaBindClass({data[data_index].data[col+1]})       
        end

        if t ~= nil then
            t.class_name = listCtrl:GetItemText(index)

            list_level = list_level + 1
            listData[list_level] = t
            GotoBindingLevel(listCtrl, list_level)
        end
    end

    event:Skip();

end

-- ----------------------------------------------------------------------------
-- Show the wxLua types vs. the lua_type()
-- ----------------------------------------------------------------------------
function CreatewxLuaTypeTable()
    local t = {
        {"..", ["icon"] = list_images.folder},
        ["col_labels"] = {"wxLua Type"},
        ["object_type"] = "wxLua Types"
    }

    local lua_types = {
        "LUA_TNONE",
        "LUA_TNIL",
        "LUA_TBOOLEAN",
        "LUA_TLIGHTUSERDATA",
        "LUA_TNUMBER",
        "LUA_TSTRING",
        "LUA_TTABLE",
        "LUA_TFUNCTION",
        "LUA_TUSERDATA",
        "LUA_TTHREAD"
    }

    for i = 1, #lua_types do
        table.insert(t.col_labels, lua_types[i].." "..tostring(wxlua[lua_types[i]]))
    end

    local wxltype_names = {
        "WXLUA_TNONE",
        "WXLUA_TNIL",
        "WXLUA_TBOOLEAN",
        "WXLUA_TLIGHTUSERDATA",
        "WXLUA_TNUMBER",
        "WXLUA_TSTRING",
        "WXLUA_TTABLE",
        "WXLUA_TFUNCTION",
        "WXLUA_TUSERDATA",
        "WXLUA_TTHREAD",
        "WXLUA_TINTEGER",
        "WXLUA_TCFUNCTION"
    }

    local tostr = { [1] = "X", [0] = "", [-1] = "?" }

    for i = 1, #wxltype_names do
        local wxltype = wxlua[wxltype_names[i]]
        local item = { wxltype_names[i].." "..tostring(wxltype) }
        for j = 1, #lua_types do
            local ltype = wxlua[lua_types[j]]
            local ok = wxlua.iswxluatype(ltype, wxltype)
            table.insert(item, tostr[ok])
        end
        table.insert(t, item)
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Show all classes that wxLua has wrapped
-- ----------------------------------------------------------------------------
function CreateAllClassesTable()
    local t = {
        {"..", ["icon"] = list_images.folder},
        ["col_labels"] = {"Binding", "wxLua Class Name (1st line) / wxClassInfo Name (2nd line)"},
        ["object_type"] = "All wxLua Classes"
    }

    local max_cols = 1

    -- These are classes that wxLua doesn't wrap since they're not necessary
    local unwrappedBaseClasses = {
        ["wxAnimationBase"] = 1,
        ["wxAnimationCtrlBase"] = 1,
        ["wxDCBase"] = 1,
        ["wxFileDialogBase"] = 1,
        ["wxGenericDirDialog"] = 1,
        ["wxGenericFileDialog"] = 1,
        ["wxGenericImageList"] = 1,
        ["wxGenericListCtrl"] = 1,
        ["wxGenericTreeCtrl"] = 1,
        ["wxPrinterBase"] = 1,
        ["wxPrintPreviewBase"] = 1,
        ["wxTextCtrlBase"] = 1,
        ["wxWindowBase"] = 1,

        ["wxLuaDebuggerBase"] = 1,
    }

    -- These are classes that wxLua has, but don't have wxClassInfo
    local wxwidgetsNoClassInfo = {
        ["wxBookCtrlBaseEvent"]     = "wxNotifyEvent",
        ["wxControlWithItems"]      = "wxControl",
        ["wxMirrorDC"]              = "wxDC",
        ["wxSplashScreenWindow"]    = "wxWindow",
        ["wxToolBarBase"]           = "wxControl",
    }

    -- These notes for classes that where the classinfo doesn't match
    -- the classname is the one that wxLua uses, not the one wxWidgets uses
    local classinfoNotes = {
        ["wxAutoBufferedPaintDC"]   = "(Platform dep. baseclass, wxDC is ok)",
        ["wxCursor"]                = "(Platform dep. baseclass, wxObject is ok)",
        ["wxHelpController"]        = "(Platform dep. typedef by wxWidgets)",
        ["wxLuaDebuggerServer"]     = "(Platform dep. typedef by wxLua)",
        ["wxMemoryDC"]              = "(Platform dep. baseclass, wxDC is ok)",
        ["wxPaintDC"]               = "(Platform dep. baseclass, wxWindowDC is ok)",
        ["wxScreenDC"]              = "(Platform dep. baseclass, wxDC is ok)",
    }

    local function BaseClassRecursor(baseBindClasses, c_table, c_table_pos)
        if not baseBindClasses then return end

        local bc_list = baseBindClasses
        local c_table_lens = {}
         
        for bc_i = 1, #bc_list do
            local bc = bc_list[bc_i]
            -- check for mistakes in the bindings
            if (not bc.classInfo) and wx.wxClassInfo.FindClass(bc.name) then
                print(bc.name.." is missing its wxClassInfo, please report this.")
            end

            -- make a new entry and copy the previous ones
            if bc_i > 1 then
                c_table[c_table_pos+bc_i-1] = {}
                for k, v in pairs(c_table[c_table_pos]) do
                    if (tonumber(k) == nil) then
                        c_table[c_table_pos+1][k] = v
                    elseif (k < c_table_lens[c_table_pos]) then
                        -- use "" to blank out 
                        c_table[c_table_pos+1][k] = v -- ""
                    end
                end
                
                c_table[c_table_pos+bc_i-1][1] = c_table[c_table_pos][1]..string.char(string.byte("a")+c_table_pos+bc_i-3)
                c_table[c_table_pos+bc_i-1][2] = c_table[c_table_pos][2]
            end
            table.insert(c_table[c_table_pos+bc_i-1], bc.name)
            
            for i = 1, #c_table do
                c_table_lens[i] = #c_table[i]
            end
            
            BaseClassRecursor(bc.baseBindClasses, c_table, c_table_pos+bc_i-1)
        end
    end

    for b = 1, #bindingList do
        local binding = bindingList[b]

        local classTable = binding.GetClassArray

        for i = 1, #classTable do
            -- this string is to force the wxLua classname and the wxClassInfo names
            -- to be together and the first char is to keep bindings together
            local a = string.format("%s %03d", binding.GetBindingName, i)

            local c = classTable[i]
            local c_table = {a, ["color"] = wx.wxBLUE}

            -- check for mistakes in the bindings
            if (not c.classInfo) and wx.wxClassInfo.FindClass(c.name) then
                print(c.name.." is missing its wxClassInfo, please report this.")
            end

            c_table = {c_table}

            -- traverse through the wxLua defined base classes
            BaseClassRecursor({c}, c_table, 1)

            for j = 1, #c_table do
                if max_cols < #c_table[j] then max_cols = #c_table[j] end
                table.insert(t, c_table[j])
            end

            -- now do wxWidgets base class info
            if c.classInfo then
                local ci = c.classInfo
                local c_table2 = {a.."wx"}

                while ci do
                    -- we don't bind some classes since we wouldn't need them
                    if unwrappedBaseClasses[ci:GetClassName()] then
                        c_table2[#c_table2] = c_table2[#c_table2].."("..ci:GetClassName()..")"
                    elseif c_table[#c_table2+1] and (wxwidgetsNoClassInfo[c_table[#c_table2+1]] == ci:GetClassName()) then
                        table.insert(c_table2, c_table[#c_table2+1].." - No wxClassInfo")
                        table.insert(c_table2, ci:GetClassName())
                    elseif c_table[#c_table2+1] and classinfoNotes[c_table[#c_table2+1]] then
                        c_table[#c_table2+1] = c_table[#c_table2+1]..classinfoNotes[c_table[#c_table2+1]]
                        table.insert(c_table2, ci:GetClassName())
                        c_table2.color = list_colors.purple
                    else
                        table.insert(c_table2, ci:GetClassName())
                        if ((c_table[#c_table2] ~= c_table2[#c_table2])) and
                           (c_table2.color == nil) then
                            c_table2.color = wx.wxRED
                        end
                    end

                    if ci:GetBaseClass2() then print(ci:GetClassName(), "Has two bases!") end
                    ci = ci:GetBaseClass1() -- FIXME handle two base classes, maybe?
                end

                if max_cols < #c_table2 then max_cols = #c_table2 end
                table.insert(t, c_table2)
            end

        end
    end

    -- Set the col labels after counting them
    for i = 3, max_cols do
        t.col_labels[i] = "Base class "..tostring(i-1)
    end

    -- Put "" strings where there is no base class
    for i = 1, #t do
        for j = 1, max_cols do
            if t[i][j] == nil then t[i][j] = "" end
        end
    end

    return t
end

-- ----------------------------------------------------------------------------
-- Load all the wxWidgets wxClassInfo
-- ----------------------------------------------------------------------------
function CreatewxClassInfoTable()

    -- gather up all of wxLua wrapped classes
    local wxluaClasses = {}

    for b = 1, #bindingList do
        local binding = bindingList[b]

        local classTable = binding.GetClassArray

        for i = 1, #classTable do
            wxluaClasses[classTable[i].name] = true
        end
    end

    -- create a table of tables of cols of the classname and baseclass names
    -- if there is a baseclass2 then the returned table will have > 1 tables
    local function GetBases(ci)
        local c = ci
        local t = {{}}

        while c do
            table.insert(t[1], c:GetClassName())

            if c:GetBaseClass2() then
                --print(c:GetClassName(), "Has Base2", c:GetBaseClass2())

                local baseTable2 = GetBases(c:GetBaseClass2())
                for i = 1, #baseTable2 do
                    -- insert back in the original info
                    for j = 1, #t do
                        table.insert(baseTable2[i], j, t[1][j])
                    end
                    baseTable2[i][1] = baseTable2[i][1].." (Multiple base classes "..tostring(i)..")" -- count # of base2s
                    table.insert(t, baseTable2[i])
                end
            end

            c = c:GetBaseClass1()
        end

        return t
    end

    local t = {
        {"..", ["icon"] = list_images.folder},
        ["col_labels"] = {"wxClassInfo::GetClassName() (wxLua wraps blue)"},
        ["object_type"] = "All wxWidgets wxClassInfo"
    }

    local ci = wx.wxClassInfo.GetFirst()
    local max_cols = 1

    while ci do
        local baseTable = GetBases(ci)
        for i = 1, #baseTable do
            if wxluaClasses[baseTable[i][1]] then
                baseTable[i].color = wx.wxBLUE
            end

            if max_cols < #baseTable[i] then max_cols = #baseTable[i] end
            table.insert(t, baseTable[i])
        end

        ci = ci:GetNext()
    end

    -- Fill remainder of items with "" string
    for i = 1, #t do
        for j = #t[i], max_cols do
            table.insert(t[i], "")
        end
    end

    -- Create col labels
    for i = 2, max_cols do
        table.insert(t.col_labels, "Base Class "..tostring(i-1))
    end

    table.sort(t, function(t1, t2) return t1[1] < t2[1] end)

    return t
end

-- ----------------------------------------------------------------------------
-- Show all functions that overload a baseclass function (for debugging bindings...)
-- ----------------------------------------------------------------------------
function CreateOverloadedBasecassFunctionsTable()
    local t = {
        {"..", ["icon"] = list_images.folder},
        ["col_labels"] = {"Function Name", "Class Name", "Args"},
        ["object_type"] = "Overloaded Baseclass Functions"
    }

    local max_cols = 2

    for b = 1, #bindingList do
        local binding = bindingList[b]

        local classTable = binding.GetClassArray

        for i = 1, #classTable do
            local wxluamethods = classTable[i].wxluamethods

            -- some classes don't have methods, wxBestHelpController for example
            for j = 1, classTable[i].wxluamethods_n do
                local m = wxluamethods[j]
                local m_table = {m.name}

                while m do
                    local wxluacfuncs = m.wxluacfuncs
                    local s = ""
                    for f = 1, m.wxluacfuncs_n do
                        s = s.."("..CreateArgTagsString(wxluacfuncs[f].argtypes, wxluacfuncs[f].method_type)..") "
                    end

                    table.insert(m_table, m.class_name)
                    table.insert(m_table, s)
                    m = m.basemethod
                end

                if #m_table > 3 then
                    if max_cols < #m_table then max_cols = #m_table end
                    table.insert(t, m_table)
                end
            end
        end
    end

    -- Set the col labels after counting them
    for i = 4, max_cols, 2 do
        t.col_labels[i] = "Base Class"
        t.col_labels[i+1] = "Args"
    end

    -- Put strings where there is no base class
    for i = 1, #t do
        for j = 1, max_cols do
            if t[i][j] == nil then t[i][j] = "" end
        end
    end

    return t
end

-- ----------------------------------------------------------------------------
-- The main program, call this to start the program
-- ----------------------------------------------------------------------------
function main()

    frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxLua Binding Browser")

    -- -----------------------------------------------------------------------
    -- Create the menu bar
    local fileMenu = wx.wxMenu()
    fileMenu:Append(wx.wxID_EXIT, "E&xit", "Quit the program")

    local viewMenu = wx.wxMenu()
    viewMenu:Append(ID_STACK_DIALOG, "Show lua stack dialog...", "View the current lua stack, stack top shows globals.")
    viewMenu:AppendSeparator()
    viewMenu:AppendCheckItem(ID_VIEW_BASECLASS_FUNCTIONS, "View baseclass functions", "View all baseclass functions for class methods.")

    local helpMenu = wx.wxMenu()
    helpMenu:Append(wx.wxID_ABOUT, "&About", "About the wxLua Binding Application")
    helpMenu:Append(wx.wxID_HELP,  "&Help", "How to use the wxLua Binding Application")

    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu, "&File")
    menuBar:Append(viewMenu, "&View")
    menuBar:Append(helpMenu, "&Help")
    frame:SetMenuBar(menuBar)
  
    -- -----------------------------------------------------------------------

    frame:Connect(wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            frame:Close(true)
        end )

    frame:Connect(ID_STACK_DIALOG, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local LocalVar1_InEventFn = 1
            local LocalVar2_InEventFn = "local to the event handler function"

            local function LocalFunction(var)
                local LocalVar1_InLocalFuncInEventFn = 3
                local LocalVar2_InLocalFuncInEventFn = "local to a local function in the event handler function"

                wxlua.LuaStackDialog()
            end

            LocalFunction(LocalStringVariable)
        end )

    -- connect the selection event of the about menu item
    frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox('This is the "About" dialog of the Bindings wxLua sample.\n'..
                            "You can view the C++ bindings by navigating the wxListCtrl.\n"..
                            wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                            "About wxLua Binding Browser",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )
    frame:Connect(wx.wxID_HELP, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            wx.wxMessageBox("Select the C++ bindings to view and then the items that\n"..
                            "have been wrapped. You can expand items that have a folder\n"..
                            "icon by double clicking on the item's column. \n"..
                            "Use the '..' to go up a level.\n"..
                            "Left-click column headers to sort.\n\n"..
                            "This data is from the structs declared in \n"..
                            "wxLua/modules/wxlua/include/wxlbind.h.",
                            "Help on wxLua Binding Browser",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            frame)
        end )

    -- -----------------------------------------------------------------------
    -- Create the toolbar
    
    toolbar = frame:CreateToolBar()
    
    local bmp = wx.wxArtProvider.GetBitmap(wx.wxART_GO_HOME, wx.wxART_TOOLBAR, wx.wxDefaultSize)
    toolbar:AddTool(wx.wxID_HOME, "Home", bmp, "Go to root level")
    bmp:delete()
    local bmp = wx.wxArtProvider.GetBitmap(wx.wxART_GO_BACK, wx.wxART_TOOLBAR, wx.wxDefaultSize)
    toolbar:AddTool(wx.wxID_BACKWARD, "Back", bmp, "Go back a level")
    bmp:delete()
    --local bmp = wx.wxArtProvider.GetBitmap(wx.wxART_GO_FORWARD, wx.wxART_TOOLBAR, wx.wxDefaultSize)
    --toolbar:AddTool(wx.wxID_FORWARD, "Forward", bmp, "Go forward a level")
    --bmp:delete()

    -- -----------------------------------------------------------------------

    frame:Connect(wx.wxID_HOME, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            list_level = 1
            GotoBindingLevel(listCtrl, list_level)
        end )

    frame:Connect(wx.wxID_BACKWARD, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if list_level > 1 then
                list_level = list_level - 1
                GotoBindingLevel(listCtrl, list_level)
            end
        end )

    -- -----------------------------------------------------------------------
    -- Create the status bar
    frame:CreateStatusBar(1)
    frame:SetStatusText("Welcome to wxLua.")

    -- -----------------------------------------------------------------------
    -- Create the windows
    panel = wx.wxPanel(frame, wx.wxID_ANY)
    listCtrl = wx.wxListView(panel, ID_LISTCTRL,
                             wx.wxDefaultPosition, wx.wxDefaultSize,
                             wx.wxLC_REPORT + wx.wxLC_SINGLE_SEL + wx.wxLC_HRULES + wx.wxLC_VRULES)

    imageList = wx.wxImageList(16, 16, true)
    imageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_MENU, wx.wxSize(16,16)))
    imageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_FOLDER, wx.wxART_MENU, wx.wxSize(16,16)))
    imageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_GO_DOWN, wx.wxART_MENU, wx.wxSize(16,16)))
    imageList:Add(wx.wxArtProvider.GetBitmap(wx.wxART_GO_UP, wx.wxART_MENU, wx.wxSize(16,16)))
    listCtrl:SetImageList(imageList, wx.wxIMAGE_LIST_SMALL);

    listCtrl:Connect(wx.wxEVT_COMMAND_LIST_ITEM_ACTIVATED, OnListItemActivated)
    listCtrl:Connect(wx.wxEVT_COMMAND_LIST_COL_CLICK,
            function (event)
                local col = event:GetColumn()
                SortListItems(col)
            end)

    list_level = 1
    listData[1] = {
        {"wxLua Types",  "Compare Lua's type to wxLua's type", ["icon"] = list_images.folder },
        {"All wxLua Classes", "Classes and their base classes (red may not indicate error)", ["icon"] = list_images.folder },
        {"All wxWidgets wxClassInfo", "All wxObjects having wxClassInfo and their base classes", ["icon"] = list_images.folder },
        {"Overloaded Baseclass Functions", "See all functions that also have a baseclass function", ["icon"] = list_images.folder },

        ["col_labels"] = { "Item to View", "Information"},
        ["object_type"] = " "
    }


    -- Add the binding that are installed {"wxLuaBinding_wx", "wx", ["icon"] = list_images.folder },
    for i = 1, #bindingList do
        table.insert(listData[1], { "Binding Name : "..bindingList[i].GetBindingName, "Namespace : "..bindingList[i].GetLuaNamespace, ["icon"] = list_images.folder, ["binding"] = bindingList[i] })
    end

    GotoBindingLevel(listCtrl, 1)

    -- -----------------------------------------------------------------------
    -- Create the sizer to layout the windows
    rootSizer = wx.wxBoxSizer(wx.wxVERTICAL);
    rootSizer:Add(listCtrl, 1, wx.wxEXPAND + wx.wxALL, 0);
    rootSizer:SetMinSize(600, 420);
    panel:SetSizer(rootSizer);
    rootSizer:SetSizeHints(frame);

    frame:Show(true)
end


main()

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
