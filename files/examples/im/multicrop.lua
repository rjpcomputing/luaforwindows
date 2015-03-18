-- lua5.1 multicrop.lua 100 500 100 500 *.jpg

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

x1 = arg[1]
x2 = arg[2]
y1 = arg[3]
y2 = arg[4]
filename1 = arg[5]
if (not x1 or not x2 or not y1 or not y2 or not filename1) then
  print("Must have the rectangle coordinates and at least one file name as parameters.")
  print("  Can have more than one file name as parameters and can use wildcards.")
  print("  Usage:")
  print("    lua multicrop.lua x1 x2 y1 y2 filename1 filename2 ...")
  return
end

print(">>> Crop of multiple images <<<")
print("")

function ProcessImageFile(file_name)
  print("Loading File: "..file_name)
  image, err = im.FileImageLoad(file_name);

  if (err and err ~= im.ERR_NONE) then
    error(err_msg[err+1])
  end

  new_image = im.ProcessCropNew(image, x1, x2, y1, y2)

  new_image:Save(file_name, "JPEG");

  new_image:Destroy()
  image:Destroy()
  print("Done File.")
  print("")
end

file_count = 0
for index,value in ipairs(arg) do
  if (index > 4) then
    ProcessImageFile(arg[index])
    file_count = file_count + 1
  end
end

if (file_count > 1) then
  print("Processed "..file_count.." Files.")
end
