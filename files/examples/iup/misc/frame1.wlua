require "iupx"

edit1 = iup.multiline{expand="YES",value="Number 1"}
edit2 = iup.multiline{expand="YES",value="Number 2?"}

box = iup.hbox {iup.frame{edit1;Title="First"},iup.frame{edit2;Title="Second"}}

iupx.show_dialog {box; title="Frames!", size="QUARTERxQUARTER"}
