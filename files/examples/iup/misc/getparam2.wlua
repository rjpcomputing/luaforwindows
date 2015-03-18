require( "iuplua" )
require( "iupluacontrols" )

res, age = iup.GetParam("Title", nil,
	"Give your age: %i\n",0)
	
if res ~= 0 then	
	iup.Message("Really?",age)
end


	