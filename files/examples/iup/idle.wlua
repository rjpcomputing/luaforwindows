require( "iuplua" )

l = iup.label{title="1", size="200x"}

function idle_cb()
  local v = tonumber(l.title) + 1
  l.title = v
  if v == 10000 then
    iup.SetIdle(nil)
  end
  return iup.DEFAULT
end

dlg = iup.dialog{l; title = "Idle Test"}

dlg:showxy(iup.CENTER, iup.CENTER)

-- Registers idle callback
iup.SetIdle(idle_cb)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
