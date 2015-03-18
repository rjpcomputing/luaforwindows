--
-- IupGetColor Example in IupLua 
--
-- Creates a predefined color selection dialog which returns the
-- selected color in the RGB format.
--

require( "iuplua" )
require( "iupluacontrols" )

r, g, b = iup.GetColor(100, 100, 255, 255, 255)
if (r) then
  print("r="..r.." g="..g.." b="..b)               
end

