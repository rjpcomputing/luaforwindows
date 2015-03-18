-- autoform.wlua
require "CLRForm"

tbl = {
	x = 2.3,	
	y = 10.2,
	z = "two",
	t = -1.0,
	file = "c:\\lang\\lua\\ilua.lua",
	outfile = "",
	res = true,
}

form = AutoVarDialog { Text = "Test AutoVar", Object = tbl;
	"First variable:","x", Range(0,4),
	"Second Variable:","y",
	"Domain name:","z", {"one","two","three"; Editable=true},
	"Blonheim's Little Adjustment:","t",
	"Input File:","file",FileIn "Lua (*.lua)|C# (*.cs)",
	"Output File:","outfile",FileOut "Text (*.txt)",
	"Make a Note?","res",
}

if form:ShowDialogOK() then
	print(tbl.x,tbl.z,tbl.res,tbl.file)
end

os.exit(0)
