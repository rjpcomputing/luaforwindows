require"iuplua"

dlg = iup.messagedlg{
  dialogtype = "ERROR",
  title = "Error!",
  value = "This is an error message"
  }

dlg:popup()
dlg:destroy()
