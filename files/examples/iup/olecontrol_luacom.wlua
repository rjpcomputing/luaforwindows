-- IpuOle and LuaCom example contributed by Kommit <kommit@gmail.com>

require "iuplua"
require "iupluaole"
require "luacom"

local control = iup.olecontrol{"MsComCtlLib.ListViewCtrl"}

-- Connect it to LuaCOM
control:CreateLuaCOM()

-- Sets production mode
control.designmode= "NO"

control.bgcolor = "255 255 255"

-- Create a dialog containing the OLE control

local dlg = iup.dialog{
    title="IupOle",
    size="150x80",
    iup.vbox{
    control,
    }
}

control.com.View = 3  -- Report View

control.com.FullRowSelect = 1
control.com.ColumnHeaders:Add(nil, nil, "Name")
control.com.ColumnHeaders:Add(nil, nil, "Score")

-- First column
control.com.ListItems:Add(nil, nil, "Daimon")
control.com.ListItems:Add(nil, nil, "Andy")
control.com.ListItems:Add(nil, nil, "Chris")
control.com.ListItems:Add(nil, nil, "Billy")

-- Second column
control.com.ListItems:Item(1).ListSubItems:Add(nil, nil, 16)
control.com.ListItems:Item(2).ListSubItems:Add(nil, nil, 17)
control.com.ListItems:Item(3).ListSubItems:Add(nil, nil, 24)
control.com.ListItems:Item(4).ListSubItems:Add(nil, nil, 11)


-- Add events to to the control
list_events = {}

-- Callback function
function list_events:ColumnClick(column)
    control.com.Sorted = 1

    iCur = column.Index - 1
    if iCur == iLast then
        if control.com.SortOrder == 0 then
            control.com.SortOrder = 1
        else
            control.com.SortOrder = 0
        end
    end
    control.com.SortKey = iCur
    iLast = iCur
end

luacom.Connect(control.com, list_events)

-- Show the dialog and run the main loop
dlg:show()

if (not iup.MainLoopLevel or iup.MainLoopLevel()==0) then
  iup.MainLoop()
end

