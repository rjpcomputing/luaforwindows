require 'iuplua'
require 'iupluacontrols'
tree = iup.tree{}

local id = 0
local text
local ls = {}
function set (txt)
    text = txt
    table.insert(ls,1,text)
    return txt
end

function assoc ()
    for i,v in ipairs(ls) do
        iup.TreeSetTableId(tree,i-1,{v})
    end
end


tree.name = set "Animals"
tree.addbranch = set "Birds"
tree.addbranch = set "Crustaceans"
tree.addleaf1= set "Shrimp"
tree.addleaf1 = set "Lobster"
tree.addbranch = set "Mammals"
tree.addleaf1 = set "Horse"
tree.addleaf1 = set "Whale"
assoc()



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
