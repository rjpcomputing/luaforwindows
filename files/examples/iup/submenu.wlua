-- IupSubmenu Example in IupLua 
-- Creates a dialog with a menu with three submenus. One of the submenus has a submenu, which has another submenu. 

require( "iuplua" )

-- Creates a text, sets its value and turns on text readonly mode 
text = iup.text {value = "This text is here only to compose", expand = "YES"}

-- Creates items of menu file
item_new = iup.item {title = "New"}
item_open = iup.item {title = "Open"}
item_close = iup.item {title = "Close"}
item_exit = iup.item {title = "Exit"}

-- Creates items of menu edit
item_copy = iup.item {title = "Copy"}
item_paste = iup.item {title = "Paste"}

-- Creates items for menu triangle
item_equilateral = iup.item {title = "Equilateral"}
item_isoceles = iup.item {title = "Isoceles"}
item_scalenus = iup.item {title = "Scalenus"}

-- Creates menu triangle
menu_triangle = iup.menu {item_equilateral, item_isoceles, item_scalenus}

-- Creates submenu triangle
submenu_triangle = iup.submenu {menu_triangle; title = "Triangle"}

-- Creates items of menu create
item_line = iup.item {title = "Line"}
item_circle = iup.item {title = "Circle"}

-- Creates menu create
menu_create = iup.menu {item_line, item_circle, submenu_triangle}

-- Creates submenu create
submenu_create = iup.submenu {menu_create; title = "Create"}

-- Creates items of menu help
item_help = iup.item {title = "Help"}

-- Creates menus of the main menu
menu_file = iup.menu {item_new, item_open, item_close, iup.separator{}, item_exit }
menu_edit = iup.menu {item_copy, item_paste, iup.separator{}, submenu_create}
menu_help = iup.menu {item_help}

-- Creates submenus of the main menu
submenu_file = iup.submenu {menu_file; title = "File"}
submenu_edit = iup.submenu {menu_edit; title = "Edit"}
submenu_help = iup.submenu {menu_help; title = "Help"}

-- Creates main menu with file submenu
menu = iup.menu {submenu_file, submenu_edit, submenu_help}
                                
-- Creates dialog with a text, sets its title and associates a menu to it 
dlg = iup.dialog {text
      ; title ="IupSubmenu Example", menu = menu, size = "QUARTERxEIGHTH"}

-- Shows dialog in the center of the screen 
dlg:showxy (iup.CENTER,iup.CENTER)

function item_help:action ()
  iup.Message ("Warning", "Only Help and Exit items performs an operation")
  return iup.DEFAULT
end

function item_exit:action ()
  return iup.CLOSE
end

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
