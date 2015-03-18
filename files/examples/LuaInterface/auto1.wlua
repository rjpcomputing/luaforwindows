-- auto1.wlua
require "CLRForm"

data = {
	firstname = "",	
	lastname = "",
	age = 0,
	title = "",
	phone = "",
	email = ""
}

form = AutoVarDialog { Text = "Please Supply Details", Object = data;
	"First Name:","firstname",
	"Last Name:","lastname",
	"Age:","age",
	"Title:","title",
	"Phone number:","phone",
	"E-mail Address:","email"
}

if form:ShowDialogOK() then
   print 'ok'
   os.exit(0)
end


