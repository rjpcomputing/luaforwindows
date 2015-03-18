require "luacom"

local vt = luacom.CreateObject("Dragon.VTxtCtrl.1")
vt:Register("","luaorb")
print(vt.Speed)
print(vt.SpeedMin)
print(vt.SpeedMax)
vt:Speak("Oh Hi Manuel Roman")
vt:Speak("I am Hal.")
vt:Speak("I became operational in Urbana, Illinois, on November 5, 2001.")

