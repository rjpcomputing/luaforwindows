-- Contribution by Guy Mc Donald
-- adds jpg files to a tree
-- dynamically fills subdirectories in the tree

require 'iuplua'
require 'iupluacontrols'
require 'lfs'
require "imlua"
require "cdlua"
require "cdluaim"
require "iupluacd"

function View(name)
  local filename = name..".jpg"
  local image = im.FileImageLoad(filename)
  local height = 740
  local width = 1020
  local cnv = iup.canvas{rastersize =width.."x"..height, border = "NO"}
  cnv.image = image

  function cnv:map_cb()
    self.canvas = cd.CreateCanvas(cd.IUP, self)
  end

  function cnv:action()
    self.canvas:Activate()
    self.canvas:Clear()
    self.image:cdCanvasPutImageRect(self.canvas,0,0,width,height,0,0,0,0)
  end

  local dlg = iup.dialog{cnv, parentdialog="main"}
  dlg:show()
end

function get_dir (dir_path)
  local files = {}
  local dirs = {}
  for f in lfs.dir(dir_path) do
    if f ~= '.' and f ~= '..' then
      if lfs.attributes(dir_path..'/'..f,'mode') == 'file' then
        if string.upper(string.sub(f,-3))=="JPG" then
          table.insert(files,string.sub(f,1,string.len(f)-4)) 
        end
      else
        table.insert(dirs,f.."/")
      end
    end
  end
  return files,dirs
end

tree = iup.tree {}
tree.addexpanded = "no"

function set (id,value,attrib)
  iup.TreeSetUserId(tree,id,{value,attrib})
end

function get(id)
  return iup.TreeGetUserId(tree,id)
end

function fill (dir_path,id)
  local files,dirs = get_dir(dir_path)
  id = id + 1
  local state = "STATE"..id
  for i = #files,1,-1 do
    tree.addleaf = files[i]
    set(id,dir_path..'/'..files[i])
  end
  for i = #dirs,1,-1 do
    tree.addbranch = dirs[i]
    set(id,dir_path..'/'..dirs[i],'dir')
    tree['addleaf'..id] = "dummy" -- add a dummy node so branchopen_cb can be called
  end
end

function tree:executeleaf_cb(id)
  local t=get(id)  --*** Selected Photo ***
  if t[2]~='dir' then View(t[1]) end
end

function tree:branchopen_cb(id)
  tree.value = id
  local t = get(id)
  if t[2] == 'dir' then
    tree['delnode'..id+1] = 'selected' -- remove dummy
    fill(t[1],id)
    set(id,t[1],'xdir') -- mark branch as filled
  end
end

--Let's get started!
dir_path="D:/scuri/Media/Outras"

local dlg = iup.dialog{tree; title = "Photo Options"}
iup.SetHandle("main", dlg)
dlg:map()
fill(dir_path,0)
dlg:show()
iup.MainLoop()
