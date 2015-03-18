require "iuplua"

list = iup.list {"Horses","Dogs","Pigs","Humans"; expand="YES"}

function list:action(t,i,v)
	print(t,i,v)
end

dlg = iup.dialog{list; title="Lists"}
dlg:show()
iup.MainLoop()
