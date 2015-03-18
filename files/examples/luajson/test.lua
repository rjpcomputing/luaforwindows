-- Additional path that may be required
require("json")

local testStrings = {
	[[{1:[1213.3e12, 123 , 123, "hello", [12, 2], {1:true /*test*/}]}]],
	[[{"username":"demo1","message":null,"password":""}]],
	[[{"challenge":"b64d-fnNQ6bRZ7CYiNIKwmdHoNgl9JR9MIYtzjBhpQzYXCFrgARt9mNmgUuO7FoODGr1NieT9yTeB2SLztGkvIA4NXmN9Bi27hqx1ybJIQq6S2L-AjQ3VTDClSmCsYFPOm9EMVZDZ0jhBX1fXw3o9VYj1j9KzSY5VCSAzGqYo-cBPY\n.b64","cert":"b64MIIGyjCCBbKgAwIBAgIKFAC1ZgAAAAAUYzANBgkqhkiG9w0BAQUFADBZMRUwEwYKCZImiZPyLGQBGRYFbG9tp8uQuFjWGS_KxTHXz9vkLNFjOoZY2bOwzsdEpshuYSdvX-9bRvHTQcoMNz8Q9nXG1aMl5x1nbV5byQNTCJlz4gzMJeNfeKGcipdCj7B6e_VpF-n2P-dFZizUHjxMksCVZ3nTr51x3Uw\n.b64","key":"D79B30BA7954DF520B44897A6FF58919"}]],
	[[{"key":"D79B30BA7954DF520B44897A6FF58919"}]],
	[[{"val":undefined}]],
	[[{
	"Image": {
		"Width":  800,
		"Height": 600,
		"Title":  "View from 15th Floor",
		"Thumbnail": {
			"Url":    "http://www.example.com/image/481989943",
			"Height": 125,
			"Width":  "100"
		},
		"IDs": [116, 943, 234, 38793]
	}
}]],
	[[ [
      {
         "precision": "zip",
         "Latitude":  37.7668,
         "Longitude": -122.3959,
         "Address":   "",
         "City":      "SAN FRANCISCO",
         "State":     "CA",
         "Zip":       "94107",
         "Country":   "US"
      },
      {
         "precision": "zip",
         "Latitude":  37.371991,
         "Longitude": -122.026020,
         "Address":   "",
         "City":      "SUNNYVALE",
         "State":     "CA",
         "Zip":       "94085",
         "Country":   "US"
      }
   ] ]],
	[[[null,true,[1,2,3],"hello\"],[world!"] ]],
	[[ [{"0":"tan\\\\","model\\\\":"sedan"},{"0":"red","model":"sports"}] ]],
	[[ {"1":"one","2":"two","5":"five"} ]],
	[=[ [[[[[[[[[[[[[[[[[[["Not too deep"]]]]]]]]]]]]]]]]]]] ]=]
}

for i, v in ipairs(testStrings) do
	print("Testing: #" .. i)
	local dec = json.decode(v)
	json.util.printValue(dec, "JSONVALUE")
	local reenc = json.encode(dec)
	print("RE_ENC: ", reenc)
	local redec = json.decode(reenc)
	json.util.printValue(redec, "REDECJSONVALUE")
end

local testValues = {
	{[300] = {nil, true, 1,2,3, nil, 3}}
}

for _, v in ipairs(testValues) do
	local ret = json.encode(v)
	print(ret)
	local dec = json.decode(ret)
	json.util.printValue(dec, "Encoded value")
	print("Re-encoded", json.encode(dec))
end
