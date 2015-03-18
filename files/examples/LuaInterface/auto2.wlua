-- auto1.wlua
require "CLRForm"

data = {
	firstname = "steve",	
	lastname = "donovan",
	age = 16,
	title = "Mr",
	phone = "+27116481212",
	email = "steve.j.donovan@gmail.com"
}

form = AutoVarDialog { Text = "Please Supply Details", Object = data;
	"First Name:","firstname",NonBlank,
	"Last Name:","lastname",NonBlank,
	"Age:","age",Range(16,120),
	"Title:","title",{"Mr","Ms","Dr","Prof"},
	"Phone number:","phone",Match ('^%+%d+$',"Must be a valid phone number"),
	"E-mail Address:","email",Match ("%S+@%S+","Must be valid email address")
}

if form:ShowDialogOK() then
   print 'ok'
end

os.exit(0)


