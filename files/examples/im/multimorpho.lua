-- multi-step morphological opening on a binarized image, with increasing structuring element (Se) size:
-- step 1 - 3x3 Se
-- step 2 - 5x5 Se
-- step 3 - 7x7 Se
-- Step n - (2n+1)x (2n+1) Se
-- after each step, a count of the objects (white items) in the opened image has to be performed, 
-- and the number of counted items to be saved in a .txt file for easy and fast exporting to excel

require"imlua"
require"imlua_process"

err_msg = {
  "No error.",
  "Error while opening the file.",
  "Error while accessing the file.",
  "Invalid or unrecognized file format.",
  "Invalid or unsupported data.",
  "Invalid or unsupported compression.",
  "Insufficient memory",
  "Interrupted by the counter",
}

colorspace_str = {
  "RGB", 
  "MAP",   
  "GRAY",  
  "BINARY",
  "CMYK",  
  "YCBCR", 
  "LAB",   
  "LUV",   
  "XYZ"    
}

num_step = arg[1]
file_name1 = arg[2]
if (not num_step or not file_name1) then
  print("Must have the number of steps and a file name as parameters.")
  print("  Can have more than one file name as parameters and can use wildcards.")
  print("  Usage:")
  print("    lua multimorpho.lua num_step filename1 filename2 ...")
  return
end

print(">>> Multi-step Morphological Opening <<<")
print("Number of Steps: "..num_step)
print("")

function ProcessImageFile(file_name, num_step)
  print("Loading File: "..file_name)
  image, err = im.FileImageLoad(file_name);

  if (err and err ~= im.ERR_NONE) then
    error(err_msg[err+1])
  end
    
  if (image:ColorSpace() ~= im.BINARY) then
    error("Invalid Image Color Space. Must be a Binary image [Color Space="..colorspace_str[image:ColorSpace()+1].."].")
  end

  file_name = file_name..".csv"
  print("Saving Log File: "..file_name)
  log = io.open(file_name, "w")

  morph_image = image:Clone()
  obj_image = im.ImageCreateBased(image, nil, nil, im.GRAY, im.USHORT)

  for step = 1, num_step do
    kernel_size = 2*step+1
    print("  Binary Morphology Open [Kernel Size="..kernel_size.."x"..kernel_size.."].")
    im.ProcessBinMorphOpen(image, morph_image, kernel_size, 1)  -- 1 interaction
    
    num_obj = im.AnalyzeFindRegions(morph_image, obj_image, 4, false)  -- 4 connected, ignore objects that touch the border
    print("    Objects Found: "..num_obj)
    log:write(kernel_size..";"..num_obj.."\n")
    
    if (num_obj == 0) then
      step = num_step
    end
    
    obj_image:Clear()
    morph_image:Clear()
  end
   
  log:close() 
  obj_image:Destroy()
  morph_image:Destroy()
  image:Destroy()
  print("Done File.")
  print("")
end

file_count = 0
for index,value in ipairs(arg) do
  if (index > 1) then
    ProcessImageFile(arg[index], num_step)
    file_count = file_count + 1
  end
end

if (file_count > 1) then
  print("Processed "..file_count.." Files.")
end
