require "iupx"
require "iupluacontrols"

edit1 = iup.multiline{expand="YES",value="Number 1",tabtitle="First"}
edit2 = iup.multiline{expand="YES",value="Number 2?",tabtitle="Second"}

tabs = iup.tabs{edit1,edit2,expand='YES'}

iupx.show_dialog {tabs; title="Tabs!", size="QUARTERxQUARTER"}
