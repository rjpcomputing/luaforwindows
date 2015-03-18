-- IupTimer Example in Lua

require( "iuplua" )

timer1 = iup.timer{time=100}
timer2 = iup.timer{time=2000}

function timer1:action_cb()
  print("timer 1 called")
  return iup.DEFAULT
end

function timer2:action_cb()
  print("timer 2 called")
  return iup.CLOSE
end

-- can only be set after the time is created
timer1.run = "YES"
timer2.run = "YES"

dg = iup.dialog{iup.label{title="Wait..."}; title="Timer example"}
dg:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
