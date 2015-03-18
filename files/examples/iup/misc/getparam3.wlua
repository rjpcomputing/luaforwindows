require( "iuplua" )
require( "iupluacontrols" )

res, prof = iup.GetParam("Title", nil,
	"Give your profession: %l|Teacher|Explorer|Engineer|\n",1)
	
if res ~= 0 then	
	iup.Message("My Goodness!",prof)
end


	