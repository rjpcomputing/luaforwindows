require 'iuplua'
require 'iupluacontrols'
tree = iup.tree{}

function assoc (idx,value)
    iup.TreeSetTableId(tree,idx,{value})
end

function addbranch(self,label,value)
    self.addbranch = label
    assoc(1,value or label)
end

function addleaf(self,label,value)
    self.addleaf1 = label
    assoc(2,value or label)
end

tree.name = "Animals"
addbranch(tree,"Birds")
addbranch(tree,"Crustaceans")
addleaf(tree,"Shrimp")
addleaf(tree,"Lobster")
addbranch(tree,"Mammals")
addleaf(tree,"Horse")
addleaf(tree,"Whale")

function dump (tp,id)
    local t = iup.TreeGetTable(tree,id)
    print(tp,id,t and t[1])
end


function tree:branchopen_cb(id)
    dump('open',id)
end

function tree:selection_cb (id,woz)
    if woz == 1 then dump('select',id) end
end

f = iup.dialog{tree; title = "Tree Test"}

f:show()

iup.MainLoop()
