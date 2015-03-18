require 'iuplua'

canvas = iup.canvas{}

dlg = iup.dialog{canvas; title="Simple Dialog",size="QUARTERxQUARTER"}

dlg:show()

iup.MainLoop()
