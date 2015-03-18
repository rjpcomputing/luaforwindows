require "iuplua"

timer = iup.timer{time=500}

btn = iup.button {title = "Stop",expand="YES"}

function btn:action ()
	if btn.title == "Stop" then
		timer.run = "NO"
		btn.title = "Start"
	else
		timer.run = "YES"
		btn.title = "Stop"
	end
end

function timer:action_cb()
	print 'timer!'
end

timer.run = "YES"

dlg = iup.dialog{btn; title="Timer!"}

dlg:show()

iup.MainLoop()
