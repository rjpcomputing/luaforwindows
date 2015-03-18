require"iuplua"

notepad = {}

-- Notepad Dialog

notepad.lastfilename = nil -- Last file open
notepad.mlCode = iup.multiline{expand="YES", size="200x120", font="Courier, 10"}
notepad.lblPosition = iup.label{title="Lin 0, Col 0", size="50x"}
notepad.lblFileName = iup.label{title="", size="50x", expand="HORIZONTAL"}

function notepad.mlCode:caret_cb(lin, col)
  notepad.lblPosition.title = "Lin ".. lin .. ", Col " .. col
end

function notepad.New()
  notepad.mlCode.value=''  
  notepad.lblFileName.title = ''  
  notepad.lastfilename = nil
end

notepad.butExecute = iup.button{size="50x15", title="Execute",
                                    action="iup.dostring(notepad.mlCode.value)"}
notepad.butNewCommands = iup.button{size="50x15", title="New", action=notepad.New}
notepad.butLoadFile = iup.button{size="50x15", title="Load..."}
notepad.butSaveasFile = iup.button{size="50x15", title="Save As..."}
notepad.butSaveFile = iup.button{size="50x15", title="Save"}

function notepad.butSaveFile:action()
  if (notepad.lastfilename == nil) then
    notepad.butSaveasFile:action()
  else
    newfile = io.open(notepad.lastfilename, "w+")
    if (newfile) then
      newfile:write(notepad.mlCode.value)
      newfile:close()
    else
      error ("Cannot Save file: "..filename)
    end
  end
end

function notepad.butSaveasFile:action()
  local fd = iup.filedlg{dialogtype="SAVE", title="Save File", 
                         nochangedir="NO", directory=notepad.last_directory,
                         filter="*.*", filterinfo="All files",allownew=yes}
                         
  fd:popup(iup.LEFT, iup.LEFT)
  
  local status = fd.status
  notepad.lastfilename = fd.value
  notepad.lblFileName.title = fd.value
  notepad.last_directory = fd.directory
  fd:destroy()
  
  if status ~= "-1" then
    if (notepad.lastfilename == nil) then
      error ("Cannot Save file "..filename)
    end
    local newfile=io.open(notepad.lastfilename, "w+")
    if (newfile) then
      newfile:write(notepad.mlCode.value)
      newfile:close(newfile)
    else
      error ("Cannot Save file")
    end
   end
end

function notepad.LoadFile(filename)
  local newfile = io.open (filename, "r")
  if (newfile == nil) then
    error ("Cannot load file "..filename)
  else
    notepad.mlCode.value=newfile:read("*a")
    newfile:close (newfile)
    notepad.lastfilename = filename
    notepad.lblFileName.title = notepad.lastfilename
  end
end

function notepad.butLoadFile:action()
  local fd=iup.filedlg{dialogtype="OPEN", title="Load File", 
                       nochangedir="NO", directory=notepad.last_directory,
                       filter="*.*", filterinfo="All Files", allownew="NO"}
  fd:popup(iup.CENTER, iup.CENTER)
  local status = fd.status
  local filename = fd.value
  notepad.last_directory = fd.directory
  fd:destroy()
  
  if (status == "-1") or (status == "1") then
    if (status == "1") then
      error ("Cannot load file "..filename)
    end
  else
    notepad.LoadFile(filename)
  end
end

notepad.vbxNotepad = iup.vbox
{
  iup.frame{iup.hbox{iup.vbox{notepad.butLoadFile,
                              notepad.butSaveFile,
                              notepad.butSaveasFile,
                              notepad.butNewCommands,
                              notepad.butExecute,
                              margin="0x0", gap="10"},
                     iup.vbox{notepad.lblFileName,
                              notepad.mlCode,
                              notepad.lblPosition,
                              alignment = "ARIGHT"},
                     alignment="ATOP"}, title="Commands"}
   ,alignment="ACENTER", margin="5x5", gap="5"
}

-- Main Menu Definition.

notepad.mnuMain = iup.menu
{
  iup.submenu
  {
    iup.menu
    {
      iup.item{title="Exit", action="return iup.CLOSE"}
    }, title="&File"
  },
--  iup.submenu{iup.menu
--  {
--    iup.item{title="Print Version Info...", action=notepad.print_version_info},
--    iup.item{title="About...", action="notepad.dlgAbout:popup(iup.CENTER, iup.CENTER)"}
--  },title="Help"}
}

-- Main Dialog Definition.

notepad.dlgMain = iup.dialog{notepad.vbxNotepad,
                                 title="Lua Notepad",
                                 menu=notepad.mnuMain,
                                 dragdrop = "YES",
                                 defaultenter=notepad.butExecute}

function notepad.dlgMain:dropfiles_cb(filename, num, x, y)
  if (num == 0) then -- only the first one
    notepad.LoadFile(filename)
  end
end

function notepad.dlgMain:close_cb()
  iup.ExitLoop()  -- should be removed if used inside a bigger application
  notepad.dlgMain:destroy()
  return iup.IGNORE
end

-- Displays the Main Dialog

notepad.dlgMain:show()
notepad.mlCode.size = nil -- reset initial size, allow resize to smaller values
iup.SetFocus(notepad.mlCode)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
