-- IupList Example in IupLua 
-- Creates a dialog with three frames, each one containing a list. The first is a simple list, the second one is a multiple list and the last one is a drop-down list. The second list has a callback associated. 

require( "iuplua" )

-- Creates a list and sets items, initial item and size
list = iup.list {"Gold", "Silver", "Bronze", "None"
       ; value = 4, size = "EIGHTHxEIGHTH"}

-- Creates frame with simple list and sets its title
frm_medal = iup.frame {list ; title = "Best medal"}
  
-- Creates a list and sets its items, multiple selection, initial items and size
list_multiple = iup.list {"100m dash", "Long jump", "Javelin throw", "110m hurdlers", "Hammer throw", "High jump"
                ; multiple="YES", value="+--+--", size="EIGHTHxEIGHTH"}

-- Creates frame with multiple list and sets its title
frm_sport = iup.frame {list_multiple
            ; title = "Competed in"}

-- Creates a list and sets its items, dropdown and amount of visible items 
list_dropdown = iup.list {"Less than US$ 1000", "US$ 2000", "US$ 5000", "US$ 10000", "US$ 20000", "US$ 50000", "More than US$ 100000"
                ; dropdown="YES", visible_items=5}
  
-- Creates frame with dropdown list and sets its title
frm_prize = iup.frame {list_dropdown
            ; title = "Prizes won"}

-- Creates a dialog with the the frames with three lists and sets its title
dlg = iup.dialog {iup.hbox {frm_medal, frm_sport, frm_prize}
      ; title = "IupList Example"}

-- Shows dialog in the center of the screen
dlg:showxy(iup.CENTER, iup.CENTER)

function list_multiple:action(t, i, v)
  if v == 0 then 
    state = "deselected" 
  else 
    state = "selected" 
  end
  iup.Message("Competed in", "Item "..i.." - "..t.." - "..state)
  return iup.DEFAULT
end

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
