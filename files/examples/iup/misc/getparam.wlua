require( "iuplua" )
require( "iupluacontrols" )

iup.SetLanguage("ENGLISH")

res, name = iup.GetParam("Title", nil,
	"Give your name: %s\n","")

iup.Message("Hello!",name)

