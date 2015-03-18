require"iuplua"
require"iupluaimglib"

butt = iup.button{image= "IUP_FileNew"}
dlg = iup.dialog{butt,title="test"}

function dlg:close_cb()
  iup.ExitLoop()
  dlg:destroy()
  return iup.IGNORE
end

dlg:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
