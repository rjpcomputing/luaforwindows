-- IupRadio Example in IupLua 
-- Creates a dialog for the user to select his/her gender. 
-- In this case, the radio element is essential to prevent the user from 
-- selecting both options. 

require( "iuplua" )

male = iup.toggle{title="Male",
  tip="Two state button - Exclusive - RADIO"}
female = iup.toggle{title="Female",
  tip="Two state button - Exclusive - RADIO"}
exclusive = iup.radio
{
  iup.vbox
  {
    male,
    female
  };
  value=female,
}

frame = iup.frame{exclusive; title="Gender"}

dialog = iup.dialog
{
  iup.hbox
  {
    iup.fill{},
    frame,
    iup.fill{}
  };
  title="IupRadio",
  size=140,
  resize="NO",
  minbox="NO",
  maxbox="NO"
}

dialog:show()

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
