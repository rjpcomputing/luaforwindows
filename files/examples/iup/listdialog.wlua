-- IupListDialog Example in IupLua 
-- Shows a color-selection dialog. 

require( "iuplua" )

iup.SetLanguage("ENGLISH")
size = 8 
marks = { 0,0,0,0,1,1,0,0 }
options = {"Blue", "Red", "Green", "Yellow", "Black", "White", "Gray", "Brown"} 
	  
error = iup.ListDialog(2,"Color selection",size,options,0,16,5,marks)

if error == -1 then 
  iup.Message("IupListDialog", "Operation canceled")
else
  local selection = ""
  local i = 1
	while i ~= size+1 do
    if marks[i] ~= 0 then
      selection = selection .. options[i] .. "\n"
    end
    i = i + 1
  end
  if selection == "" then
    iup.Message("IupListDialog","No option selected")
  else
    iup.Message("Selected options",selection)
  end
end
