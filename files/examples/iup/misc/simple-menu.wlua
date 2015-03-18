require( "iuplua" )

-- Creates a text, sets its value and turns on text readonly mode
text = iup.text {readonly = "YES", value = "Selecting show or hide will affect this text"}

item_show = iup.item {title = "Show"}
item_hide = iup.item {title = "Hide"}
item_exit = iup.item {title = "Exit"}

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

menu = iup.menu {item_show,item_hide,item_exit}

-- Creates dialog with a text, sets its title and associates a menu to it
dlg = iup.dialog{text; title="IupMenu Example", menu=menu}

-- Shows dialog in the center of the screen
dlg:showxy(iup.CENTER,iup.CENTER)

iup.MainLoop()
