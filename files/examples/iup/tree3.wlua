-- IupTree Example in IupLua 
-- Creates a tree with some branches and leaves. 
-- Two callbacks are registered: one deletes marked nodes when the Del key 
-- is pressed, and the other, called when the right mouse button is pressed, 
-- opens a menu with options. 

require( "iuplua" )
require( "iupluacontrols" )

tree = iup.tree{}

function tree:showrename_cb(id)
  print("SHOWRENAME_CB")
end

function tree:rename_cb(id)
  print("RENAME_CB")
end

function tree:k_any(c)
  if c == iup.K_DEL then tree.delnode = "MARKED" end
end

function init_tree_atributes()
  tree.font = "COURIER_NORMAL_10"
  tree.markmode = "MULTIPLE"
  tree.addexpanded = "NO"
  tree.showrename = "YES"
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
init_tree_atributes()
dlg:showxy(iup.CENTER,iup.CENTER)
init_tree_nodes()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
