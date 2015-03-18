-- IupGetFile Example in IupLua 
-- Shows a typical file-selection dialog. 

require( "iuplua" )

iup.SetLanguage("ENGLISH")
f, err = iup.GetFile("*.txt")
if err == 1 then 
  iup.Message("New file", f)
elseif err == 0 then 
  iup.Message("File already exists", f)	    
elseif err == -1 then 
  iup.Message("IupFileDlg", "Operation canceled")
elseif err == -2 then 
  iup.Message("IupFileDlg", "Allocation errr")
elseif err == -3 then 
  iup.Message("IupFileDlg", "Invalid parameter")
end