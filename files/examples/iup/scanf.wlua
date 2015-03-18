-- IupScanf Example in IupLua 
-- Shows a dialog with three fields to be filled. 
--   One receives a string, the other receives a real number and 
--   the last receives an integer number. 
-- Note: In Lua, the function does not return the number of successfully read characters. 

require( "iuplua" )

iup.SetLanguage("ENGLISH")
local integer = 12
local real = 1e-3
local text ="This is a vector of characters"
local fmt = "IupScanf\nText:%300.40%s\nReal:%20.10%g\nInteger:%20.10%d\n"

text, real, integer = iup.Scanf (fmt, text, real, integer)

if text then
  local string = "Text: "..text.."\nReal: "..real.."\nInteger: "..integer
  iup.Message("IupScanf", string)
else
  iup.Message("IupScanf", "Operation canceled");
end