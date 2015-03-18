require 'iuplua'

btn1 = iup.button{title = "Click me!"}
btn2 = iup.button{title = "and me!"}

function btn1:action ()
    iup.Message("Note","I have been clicked!")
end

function btn2:action ()
    iup.Message("Note","Me too!")
end

box = iup.hbox {btn1,btn2; gap=4}

dlg = iup.dialog{box; title="Simple Dialog",size="QUARTERxQUARTER"}

dlg:show()

iup.MainLoop()
