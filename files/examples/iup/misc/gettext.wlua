require 'iuplua'

iup.SetLanguage("ENGLISH")
res = iup.GetText("Give me your name","")

if res ~= "" then
	iup.Message("Thanks!",res)
end


