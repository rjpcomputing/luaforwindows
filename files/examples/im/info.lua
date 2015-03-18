require"imlua"
require"lfs"

function PrintError(error)
	local msg = {}
	msg[im.ERR_OPEN] = "Error Opening File."
	msg[im.ERR_MEM] = "Insuficient memory."
	msg[im.ERR_ACCESS] = "Error Accessing File."
	msg[im.ERR_DATA] = "Image type not Suported."
	msg[im.ERR_FORMAT] = "Invalid Format."
	msg[im.ERR_COMPRESS] = "Invalid or unsupported compression."
	
	if msg[error] then
		print(msg[error])
	else
		print("Unknown Error.")
	end
end

function FindZero(data)
 if (not data) then return false end
	for i = 1, table.getn(data) do
		if data[i] == 0 then
			return true
		end
	end	
	return false
end

function AttribData2Str(data, data_type)
	local data_str

	if data_type == im.BYTE then
		data_str = string.format("%3d", data[1])
	elseif data_type == im.USHORT then
		data_str = string.format("%5d", data[1])
	elseif data_type == im.INT then
		data_str = string.format("%5d", data[1])
	elseif data_type == im.FLOAT then
		data_str = string.format("%5.2f", data[1])
	elseif data_type == im.CFLOAT then
		data_str = string.format("%5.2f, %5.2f", data[1], data[2])
	end
	
	return data_str
end

function GetSizeDesc(size)
	local size_desc

	if size < 1024 then
		size_desc = "b"
	else
		size = size / 1024

		if size < 1024 then
			size_desc = "Kb"
		else
			size = size / 1024
			size_desc = "Mb"
		end
	end

	return size, size_desc
end

function FileSize(file_name)
  if lfs then
    local attr = lfs.attributes(file_name)
    return attr.size
  else
    return 0
  end
end

function PrintImageInfo(file_name)
	print("IM Info")
	print(string.format("  File Name:\n    %s", file_name))

	local ifile, error = im.FileOpen(file_name)
	if not ifile then
		PrintError(error)
		return nil
	end

	local file_size = FileSize(file_name)
	
	print(string.format("  File Size: %.2f %s", GetSizeDesc(file_size)))

	local format, compression, image_count = ifile:GetInfo()

	local error, format_desc = im.FormatInfo(format)
	print(string.format("  Format: %s - %s", format, format_desc))
	print(string.format("  Compression: %s", compression))
	print(string.format("  Image Count: %d", image_count))
	for i = 1, image_count do
		local error, width, height, color_mode, data_type = ifile:ReadImageInfo(i-1)
		if width == nil then
			PrintError(height)
			ifile:Close()
			return nil
		end

		print(string.format("  Image #%d", i))
		print(string.format("    Width: %d", width))
		print(string.format("    Height: %d", height))
		print(string.format("    Color Space: %s", im.ColorModeSpaceName(color_mode)))
		print(string.format("      Has Alpha: %s", im.ColorModeHasAlpha(color_mode) and "Yes" or "No"))
		print(string.format("      Is Packed: %s", im.ColorModeIsPacked(color_mode) and "Yes" or "No"))
		print(string.format("      Is Top Down: %s", im.ColorModeIsTopDown(color_mode) and "Yes" or "No"))
		print(string.format("    Data Type: %s", im.DataTypeName(data_type)))

		local image_size = im.ImageDataSize(width, height, color_mode, data_type)
		print(string.format("    Data Size: %.2f %s", GetSizeDesc(image_size)))

		local attrib_list = ifile:GetAttributeList()
		for a = 1, table.getn(attrib_list) do
			if a == 1 then
				print("    Attributes:")
			end

			local attrib_data, attrib_data_type = ifile:GetAttribute(attrib_list[a])

			if table.getn(attrib_data) == 1 then
				print(string.format("      %s: %s", attrib_list[a], AttribData2Str(attrib_data, attrib_data_type)))
			elseif attrib_data_type == im.BYTE and FindZero(attrib_data) then
        attrib_data = ifile:GetAttribute(attrib_list[a], true)
				print(string.format("      %s: %s", attrib_list[a], attrib_data))
			else
				print(string.format("      %s: %s ...", attrib_list[a], AttribData2Str(attrib_data, attrib_data_type)))
			end
		end
	end
    
	ifile:Close()
end

function main(arg)
  if (not arg or table.getn(arg) < 1) then
    print("Invalid number of arguments.")
    return nil
  end

  PrintImageInfo(arg[1])
  return 1
end

main(arg)
--PrintImageInfo("lena.jpg")
