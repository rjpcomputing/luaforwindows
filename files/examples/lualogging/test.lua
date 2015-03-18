
local test = {
	"testConsole.lua",
	"testFile.lua",
	"testMail.lua",
	"testSocket.lua",
	"testSQL.lua",
}

print ("Start of Logging tests")
table.foreachi (test, function (i, filename)
	dofile(filename)
end)
print ("End of Logging tests")
