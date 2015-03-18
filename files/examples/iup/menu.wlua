-- IupMenu Example in IupLua 
-- Creates a dialog with a menu with two submenus. 

require( "iuplua" )

-- Creates a text, sets its value and turns on text readonly mode 
text = iup.text {readonly = "YES", value = "Selecting show or hide will affect this text"}

-- Creates items, sets its shortcut keys and deactivates edit item
item_show = iup.item {title = "Show", key = "K_S"}
item_hide = iup.item {title = "Hide\tCtrl+H", key = "K_H"}
item_edit = iup.item {title = "Edit", key = "K_E", active = "NO"}
item_exit = iup.item {title = "Exit", key = "K_x"}

function item_show:action()
  text.visible = "YES"
  return iup.DEFAULT
end

function item_hide:action()
  text.visible = "NO"
  return iup.DEFAULT
end

function item_exit:action()
  return iup.CLOSE
end

-- Creates two menus
menu_file = iup.menu {item_exit}
menu_text = iup.menu {item_show, item_hide, item_edit}

-- Creates two submenus
submenu_file = iup.submenu {menu_file; title = "File"}
submenu_text = iup.submenu {menu_text; title = "Text"}

-- Creates main menu with two submenus
menu = iup.menu {submenu_file, submenu_text}
                                
-- Creates dialog with a text, sets its title and associates a menu to it 
dlg = iup.dialog{text; title="IupMenu Example", menu=menu}

-- Shows dialog in the center of the screen 
dlg:showxy(iup.CENTER,iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
