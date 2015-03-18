require"imlua"
require"imlua_capture"

im.VideoCaptureReloadDevices()

print("--- Devices ---")
local n = im.VideoCaptureDeviceCount()

for i = 0, n - 1 do
	desc = im.VideoCaptureDeviceDesc(i)
	print(desc)
end

local vc = im.VideoCaptureCreate()
print("connect: ", vc:Connect(0))
print()

print("--- Dialogs ---")

local dc = vc:DialogCount()
for i = 0, dc - 1 do
	desc = vc:DialogDesc(i)
	print(i, desc)
	vc:ShowDialog(i)
end
print()


print("--- Formats ---")

local fc = vc:FormatCount()
for i = 0, fc - 1 do
	local success, width, height, desc = vc:GetFormat(i)
	print(i, string.format("%dx%d", width, height), desc)
end
print()

print("--- Image Size ---")
local width, height = vc:GetImageSize()
print(width, height)
print()

print("--- Attributes ---")
attribs = vc:GetAttributeList()
for i, name in ipairs(attribs) do
	 local error, percent = vc:GetAttribute(name)
	 if error == 0 then percent = "get error" end
	 print(i, name, percent)
end
--vc:SetAttribute("FlipVertical", 1)
--vc:SetAttribute("FlipHorizontal", 1)
print()

print("--- Capture ---")
local image = im.ImageCreate(width, height, im.RGB, im.BYTE)
local res = vc:Live(1)
if (res > 0) then
	print("grabbing frame")
	print(vc:Frame(image, 3000))
end
image:Save("capture.jpg", "JPEG")

vc:Disconnect()
