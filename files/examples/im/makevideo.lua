-- lua5.1 makevideo.lua newfile.wmv DSC0*.jpg

require"imlua"
require"imlua_wmv"

err_msg = {
  "No error.",
  "Error while opening the file.",
  "Error while accessing the file.",
  "Invalid or unrecognized file format.",
  "Invalid or unsupported data.",
  "Invalid or unsupported compression.",
  "Insuficient memory",
  "Interrupted by the counter",
}

-- Margin parameters
new_filename = arg[1]
filename1 = arg[2]
if (not new_filename or not filename1) then
  error("invalid parameters")
end

function ProcessImageFile(file_name, ifile)
  print("Loading File: "..file_name)
  local image, err = im.FileImageLoad(file_name);
  if (err and err ~= im.ERR_NONE) then
    error(err_msg[err+1])
  end

  err = ifile:SaveImage(image)
  if (err and err ~= im.ERR_NONE) then
    error(err_msg[err+1])
  end

  image:Destroy()
end

ifile = im.FileNew(new_filename, "WMV")

ifile:SetAttribute("FPS", im.FLOAT, {15}) -- Frames per second

file_count = 0
for index,value in ipairs(arg) do
  if (index > 5) then
    ProcessImageFile(arg[index], ifile)
    file_count = file_count + 1
  end
end

ifile:Close()

if (file_count > 1) then
  print("Processed "..file_count.." Files.")
end
print("Saved File: "..new_filename)
