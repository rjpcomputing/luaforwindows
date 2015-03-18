-- IupText Example in IupLua 
-- Allows the user to execute a Lua command

require( "iuplua" )

text = iup.text{value = "Write a text; press Ctrl-Q to exit"}

function text:k_any(c)
  if c == iup.K_cQ then 
    return iup.CLOSE 
  end
  return iup.DEFAULT
end

dlg = iup.dialog{text; title="IupText"}

dlg:showxy(iup.CENTER, iup.CENTER)
iup.SetFocus(text)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end

