require 'iuplua'

btn = iup.button{title = "Click me!"}

function btn:action ()
    iup.Message("Note","I have been clicked!")
    return iup.DEFAULT
end

dlg = iup.dialog{btn; title="Simple Dialog",size="QUARTERxQUARTER"}

dlg:show()

iup.MainLoop()
