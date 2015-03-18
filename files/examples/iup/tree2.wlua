--IupTree Example in IupLua
--Creates a tree with some branches and leaves. Uses a Lua Table to define the IupTree structure.

require( "iuplua" )
require( "iupluacontrols" )

tree = iup.tree{}
dlg = iup.dialog{tree ; title = "TableTree result", size = "200x200"}
dlg:showxy(iup.CENTER,iup.CENTER)

t = {
  {
    "Horse",
    "Whale";
    branchname = "Mammals"
  },
  {
    "Shrimp",
    "Lobster";
    branchname = "Crustaceans"
  };
  branchname = "Animals"
}
iup.TreeAddNodes(tree, t)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
