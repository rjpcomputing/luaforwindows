-- Additional path that may be required
require("json")
local io = require("io")
local os = require("os")

require("lfs")

local success = true

local function getFileData(fileName)
	local f = io.open(fileName, 'rb')
	if not f then return end
	local data = f:read('*a')
	f:close()
	return data
end

local function putTempData(data)
	local name = os.tmpname()
	local f = assert(io.open(name, 'wb'))
	f:write(data)
	f:close()
	return name
end

-- Ensure that the encoder/decoder can round-trip valid JSON
local function RoundTripTest(parseFunc, encodeFunc, jsonData, luaData, fullRoundTrip, failRoundTrip)
	local success, dataString = pcall(encodeFunc, luaData)
	if failRoundTrip then
		assert(not success, "Round trip encoding test result not as expected")
		return true
	else
		assert(success, "Couldn't encode the lua data..." .. tostring(dataString))
	end
	local success, result = pcall(parseFunc, dataString)
	if not success then
		print("Could not parse the generated JSON of (", luaData)
		print("GENERATED: [[" .. dataString .. "]]")
		print("DATA STORED IN: ", putTempData(dataString))
		return
	end
	if fullRoundTrip then
		-- Ensure that whitespace is trimmed off ends
		dataString = dataString:match("^[%s]*(.-)[%s]*$")
		jsonData = jsonData:match("^[%s]*(.-)[%s]*$")
		if dataString ~= jsonData then
			print("Encoded values do not match")
			print("ORIGINAL: << " .. jsonData .. " >>")
			print("RE-ENCOD: << " .. dataString .. " >>")
			return
		end
	end
	return true
end

local function testFile(fileName, parseFunc, encodeFunc, expectSuccess, fullRoundTrip, failRoundTrip)
	local data = getFileData(fileName)
	if not data then return end
	io.write(".")
	local succeed, result = pcall(parseFunc, data)
	if expectSuccess ~= succeed then
		print("Wrongly " .. (expectSuccess and "Failed" or "Succeeded") .. " on : " .. fileName .. "(" .. tostring(result) .. ")")
		success = false
	elseif succeed then
		if not RoundTripTest(parseFunc, encodeFunc, data, result, fullRoundTrip, failRoundTrip) then
			print("FAILED TO ROUND TRIP: " .. fileName)
			success = false
		end
	end
end

local function testDirectories(parseFunc, encodeFunc, directories, ...)
	if not directories then return end
	for _,directory in ipairs(directories) do
		if lfs.attributes(directory, 'mode') == 'directory' then
			for f in lfs.dir(directory) do
				testFile(directory .. "/" .. f, parseFunc, encodeFunc, ...)
			end
		end
	end
	io.write("\n")
end

local function TestParser(parseFunc, encodeFunc, successNames, failNames, roundTripNames)
	testDirectories(parseFunc, encodeFunc, successNames, true, false)
	testDirectories(parseFunc, encodeFunc, failNames, false, false)
	testDirectories(parseFunc, encodeFunc, roundTripNames, true, true)
end
print("Testing lax/fast mode:")
TestParser(json.decode.getDecoder(), json.encode.getEncoder(), {"test/pass","test/fail_strict"}, {"test/fail_all"},{"test/roundtrip","test/roundtrip_lax"})

print("Testing (mostly) strict mode:")
local strict = json.util.merge({}, json.decode.strict, {
	number = {
		nan = false,
		inf = true,
		strict = true
	}
})
local strict_encode = json.util.merge({}, json.encode.strict, {
	number = {
		nan = false,
		inf = true,
		strict = true
	}
})
TestParser(json.decode.getDecoder(strict), json.encode.getEncoder(strict_encode), {"test/pass"}, {"test/fail_strict","test/fail_all"}, {"test/roundtrip"})

print("Testing (mostly) strict encoder with non-strict decodings")
testDirectories(json.decode.getDecoder(), json.encode.getEncoder(json.encode.strict), {"test/fail_strict_encode"}, true, true, true)

if not success then
	os.exit(1)
end
