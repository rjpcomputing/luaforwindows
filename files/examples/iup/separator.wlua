-- IupSeparator Example in IupLua 
-- Creates a dialog with a menu and some items. 
-- A IupSeparator was used to separate the menu items. 

require( "iuplua" )

-- Creates a text, sets its value and turns on text readonly mode 
text = iup.text {value = "This text is here only to compose", expand = "YES"}

-- Creates six items
item_new = iup.item {title = "New"}
item_open = iup.item {title = "Open"}
item_close = iup.item {title = "Close"}
item_pagesetup = iup.item {title = "Page Setup"}
item_print = iup.item {title = "Print"}
item_exit = iup.item {title = "Exit", action="return iup.CLOSE"}

-- Creates file menus
menu_file = iup.menu {item_new, item_open, item_close, iup.separator{}, item_pagesetup, item_print, iup.separator{}, item_exit }

-- Creates file submenus
submenu_file = iup.submenu {menu_file; title="File"}

-- Creates main menu with file submenu
menu = iup.menu {submenu_file}
                                
-- Creates dialog with a text, sets its title and associates a menu to it 
dlg = iup.dialog {text
      ; title ="IupSeparator Example", menu = menu, size = "QUARTERxEIGHTH"}

-- Shows dialog in the center of the screen 
dlg:showxy(iup.CENTER,iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
