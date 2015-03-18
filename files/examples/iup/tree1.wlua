-- IupTree Example in IupLua 
-- Creates a tree with some branches and leaves. 
-- Two callbacks are registered: one deletes marked nodes when the Del key 
-- is pressed, and the other, called when the right mouse button is pressed, 
-- opens a menu with options.

require( "iuplua" )
require( "iupluacontrols" )

tree = iup.tree{}

-- Creates rename dialog
ok     = iup.button{title = "OK",size="EIGHTH"}
cancel = iup.button{title = "Cancel",size="EIGHTH"}

text   = iup.text{border="YES",expand="YES"}
dlg_rename = iup.dialog{iup.vbox{text,iup.hbox{ok,cancel}}; 
   defaultenter=ok,
   defaultesc=cancel,
   title="Enter node's name",
   size="QUARTER",
   startfocus=text}

-- Creates menu displayed when the right mouse button is pressed
addleaf = iup.item {title = "Add Leaf"}
addbranch = iup.item {title = "Add Branch"}
renamenode = iup.item {title = "Rename Node"}
menu = iup.menu{addleaf, addbranch, renamenode}

-- Callback of the right mouse button click
function tree:rightclick_cb(id)
  tree.value = id
  menu:popup(iup.MOUSEPOS,iup.MOUSEPOS)
end

-- Callback called when a node will be renamed
function tree:executeleaf_cb(id)
  text.value = tree.name

  dlg_rename:popup(iup.CENTER, iup.CENTER)
  iup.SetFocus(tree)
end

-- Callback called when the rename operation is cancelled
function cancel:action()
  return iup.CLOSE
end

-- Callback called when the rename operation is confirmed
function ok:action()
  tree.name = text.value

  return iup.CLOSE
end

function tree:k_any(c)
  if c == iup.K_DEL then tree.delnode = "MARKED" end
end

-- Callback called when a leaf is added
function addleaf:action()
  tree.addleaf = ""
end

-- Callback called when a branch is added
function addbranch:action()
  tree.addbranch = ""
end

-- Callback called when a branch will be renamed
function renamenode:action()
  tree:executeleaf_cb(tree.value)
end

function init_tree_nodes()
  tree.name = "Figures"
  tree.addbranch = "3D"
  tree.addbranch = "2D"
  tree.addbranch1 = "parallelogram"
  tree.addleaf2 = "diamond"
  tree.addleaf2 = "square"
  tree.addbranch1 = "triangle"
  tree.addleaf2 = "scalenus"
  tree.addleaf2 = "isoceles"
  tree.value = "6"
end

dlg = iup.dialog{tree; title = "IupTree", size = "QUARTERxTHIRD"} 
dlg:showxy(iup.CENTER,iup.CENTER)
init_tree_nodes()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
