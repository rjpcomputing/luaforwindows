-- IupZbox Example in IupLua 
-- An application of a zbox could be a program requesting several entries from the user according to a previous selection. In this example, a list of possible layouts ,each one consisting of an element, is presented, and according to the selected option the dialog below the list is changed. 

require( "iuplua" )

fill = iup.fill {}
text = iup.text {value = "Enter your text here", expand = "YES"}
lbl  = iup.label {title = "This element is a label"}
btn  = iup.button {title = "This button does nothing"}
zbox = iup.zbox
{
  fill,
  text,
  lbl,
  btn ;
  alignment = "ACENTER", value=text
}

list = iup.list { "fill", "text", "lbl", "btn"; value="2"}
ilist = {fill, text, lbl, btn}

function list:action (t, o, selected)
  if selected == 1 then
    -- Sets the value of the zbox to the selected element 
    zbox.value=ilist[o]
  end
  
  return iup.DEFAULT
end

frm = iup.frame
{
  iup.hbox
  {
    iup.fill{},
    list,
    iup.fill{}
  } ;
  title = "Select an element"
}

dlg = iup.dialog
{
  iup.vbox
  {
    frm,
    zbox
  } ;
  size = "QUARTER",
  title = "IupZbox Example"
}

dlg:showxy (0, 0)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
