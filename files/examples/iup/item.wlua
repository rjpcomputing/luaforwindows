require( "iuplua" )

text = iup.text {value = "This is an empty text"}

item_save = iup.item {title = "Save\tCtrl+S", key = "K_cS", active = "NO"}
item_autosave = iup.item {title = "Auto Save", key = "K_a", value = "ON"}
item_exit = iup.item {title = "Exit", key = "K_x"}

menu_file = iup.menu {item_save, item_autosave, item_exit}

submenu_file = iup.submenu{menu_file; title = "File"}

menu = iup.menu {submenu_file}
                                
dlg = iup.dialog{text; title ="IupItem", menu = menu}

dlg:showxy(iup.CENTER, iup.CENTER)

function item_autosave:action()
  if item_autosave.value == "ON" then
    iup.Message("Auto Save", "OFF")
    item_autosave.value = "OFF"
  else
    iup.Message("Auto Save", "ON")
    item_autosave.value = "ON"
  end
  
  return iup.DEFAULT 
end

function item_exit:action()
-- return iup.CLOSE
  dlg:hide()
end

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
