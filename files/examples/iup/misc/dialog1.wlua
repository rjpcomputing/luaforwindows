require 'iuplua'

text = iup.multiline{expand = "YES"}

dlg = iup.dialog{text; title="Simple Dialog",size="QUARTERxQUARTER"}

dlg:show()

iup.MainLoop()
