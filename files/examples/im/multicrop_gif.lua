-- lua multicrop_gif.lua 60 60 0 0 newfile.gif DSC003*.jpg

require"imlua"
require"imlua_process"

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
x1 = arg[1]
x2 = arg[2]
y1 = arg[3]
y2 = arg[4]
new_filename = arg[5]
filename1 = arg[6]
if (not x1 or not x2 or not y1 or not y2 or not new_filename or not filename1) then
  print("Must have the rectangle coordinates and at least one file name as parameters.")
  print("  Can have more than one file name as parameters and can use wildcards.")
  print("  Usage:")
  print("    lua multicrop_gif.lua x1 x2 y1 y2 new_filename filename1 filename2 ...")
  return
end

print(">>> Crop of multiple images <<<")

function ProcessImageFile(file_name, ifile)
  print("Loading File: "..file_name)
  local image, err = im.FileImageLoad(file_name);
  if (err and err ~= im.ERR_NONE) then
    error(err_msg[err+1])
  end

  local new_image = im.ProcessCropNew(image, x1, image:Width()-1-x2, y1, image:Height()-1-y2)
  local map_image = im.ImageCreateBased(new_image, nil, nil, im.MAP, im.BYTE)
  im.ConvertColorSpace(new_image, map_image)
  ifile:SaveImage(map_image)

  map_image:Destroy()
  new_image:Destroy()
  image:Destroy()
end

ifile = im.FileNew(new_filename, "GIF")

ifile:SetAttribute("Delay", im.USHORT, {30}) -- Time to wait betweed frames in 1/100 of a second.
ifile:SetAttribute("Iterations", im.USHORT, {0}) -- The number of times to repeat the animation. 0 means to repeat forever.

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
