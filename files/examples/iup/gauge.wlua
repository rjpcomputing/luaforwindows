require( "iuplua" )
require( "iupluacontrols" )

function idle_cb()
  local value = gauge.value
  value = value + 0.0001;
  if value > 1.0 then
    value = 0.0
  end
  gauge.value = value
  return iup.DEFAULT
end

gauge = iup.gauge{}
gauge.show_text = "YES"

dlg = iup.dialog{gauge; title = "IupGauge"}
dlg.size = "QUARTERxEIGHTH"

-- Registers idle callback
iup.SetIdle(idle_cb)

dlg:showxy(iup.CENTER, iup.CENTER)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
