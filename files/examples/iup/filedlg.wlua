-- IupFileDlg Example in IupLua 
-- Shows a typical file-saving dialog. 

require( "iuplua" )

-- Creates a file dialog and sets its type, title, filter and filter info
filedlg = iup.filedlg{dialogtype = "SAVE", title = "File save", 
                      filter = "*.bmp", filterinfo = "Bitmap files",
                      directory="c:\\windows"} 

-- Shows file dialog in the center of the screen
filedlg:popup (iup.ANYWHERE, iup.ANYWHERE)

-- Gets file dialog status
status = filedlg.status

if status == "1" then 
  iup.Message("New file",filedlg.value)
elseif status == "0" then 
  iup.Message("File already exists", filedlg.value)
elseif status == "-1" then 
  iup.Message("IupFileDlg","Operation canceled")
end