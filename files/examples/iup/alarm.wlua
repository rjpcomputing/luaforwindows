-- IupAlarm Example in IupLua 
-- Shows a dialog similar to the one shown when you exit a program 
-- without saving. 

require( "iuplua" )

b = iup.Alarm("IupAlarm Example", "File not saved! Save it now?" ,"Yes" ,"No" ,"Cancel")
  
-- Shows a message for each selected button
if b == 1 then 
  iup.Message("Save file", "File saved successfully - leaving program")
elseif b == 2 then 
  iup.Message("Save file", "File not saved - leaving program anyway")
elseif b == 3 then 
  iup.Message("Save file", "Operation canceled") 
end