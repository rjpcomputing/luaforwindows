-- IupGetParam Example in IupLua 
-- Shows a dialog with many possible fields. 

require( "iuplua" )
require( "iupluacontrols" )

function param_action(dialog, param_index)
  if (param_index == -1) then
    print("OK")
  elseif (param_index == -2) then
    print("Map")
  elseif (param_index == -3) then
    print("Cancel")
  else
    local param = iup.GetParamParam(dialog, param_index)
    print("PARAM"..param_index.." = "..param.value)
  end
  return 1
end

-- set initial values
pboolean = 1
pinteger = 3456
preal = 3.543
pinteger2 = 192
preal2 = 0.5
pangle = 90
pstring = "string text"
plist = 2
pstring2 = "second text\nsecond line"
  
ret, pboolean, pinteger, preal, pinteger2, preal2, pangle, pstring, plist, pstring2 = 
      iup.GetParam("Title", param_action,
                  "Boolean: %b\n"..
                  "Integer: %i\n"..
                  "Real 1: %r\n"..
                  "Sep1 %t\n"..
                  "Integer: %i[0,255]\n"..
                  "Real 2: %r[-1.5,1.5]\n"..
                  "Sep2 %t\n"..
                  "Angle: %a[0,360]\n"..
                  "String: %s\n"..
                  "List: %l|item1|item2|item3|\n"..
                  "Sep3 %t\n"..
                  "Multiline: %m\n",
                  pboolean, pinteger, preal, pinteger2, preal2, pangle, pstring, plist, pstring2)
if (not ret) then
  return
end

iup.Message("IupGetParam",
            "Boolean Value: "..pboolean.."\n"..
            "Integer: "..pinteger.."\n"..
            "Real 1: "..preal.."\n"..
            "Integer: "..pinteger2.."\n"..
            "Real 2: "..preal2.."\n"..
            "Angle: "..pangle.."\n"..
            "String: "..pstring.."\n"..
            "List Index: "..plist.."\n"..
            "String: "..pstring2)

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
