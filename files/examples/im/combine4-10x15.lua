--A script to compose 4 images

require"imlua"
require"imlua_process"
require"iuplua"


function CombineImages(comb_image)
  local w = comb_image:Width()-offset
  local h = comb_image:Height()-offset
  local half_w = math.floor(w/2)
  local half_h = math.floor(h/2)
  local x = {0, 0,             half_w+offset, half_w+offset}
  local y = {0, half_h+offset, 0,             half_h+offset}
  
  for i = 1, 4 do
    local img_w = images[i]:Width()
    local img_h = images[i]:Height()
    
    if (img_w ~= half_w or img_h ~= half_h) then
      local rz_w, rz_h, img_aspect
      
      img_aspect = img_w/img_h
      
      -- keep image aspect ratio
      if (img_aspect ~= aspect) then
        if (img_aspect < aspect) then
          rz_h = half_h
          rz_w = math.floor(rz_h * img_aspect)
        else
          rz_w = half_w
          rz_h = math.floor(rz_w / img_aspect)
        end
      else
        rz_w = half_w
        rz_h = half_h
      end  
      
      if (img_w ~= rz_w or img_h ~= rz_h) then
        resize_image = im.ImageCreate(rz_w, rz_h, im.RGB, im.BYTE)
        im.ProcessResize(images[i], resize_image, 1) -- do bilinear interpolation
        images[i]:Destroy()
        images[i] = resize_image
      end
    end
    
    im.ProcessInsert(comb_image, images[i], comb_image, x[i], y[i]) -- insert resize in dst and place the result in dst
  end
end

function Save_Combine_Image(comb_image)
  local i=0
  local filename
  repeat
    i=i+1
    local num=1000+i
    numstr=string.sub(tostring(num),-3)
    filename = "..\\combine"..numstr..".jpg"
    -- check if exists
    local res,msg=io.open(filename)
    io.close()
  until not res
  print("Saving:", filename)
  comb_image:Save(filename, "JPEG")
  os.execute(filename)
end

function LoadImages()
  local max_w, max_h = 0, 0
  for i = 1, 4 do
    if (not files[i]) then
      error("Error, must drop 4 files.")
    end
    print("Loading:", files[i])
    images[i] = im.FileImageLoadBitmap(files[i])
    if (not images[i]) then
      error("Failed to load image: "..files[i])
    end
    local img_w = images[i]:Width()
    local img_h = images[i]:Height()
    if (img_w < img_h) then
      -- always landscape (w>h)
      local rot_image = im.ImageCreate(img_h, img_w, im.RGB, im.BYTE)
      im.ProcessRotate90(images[i], rot_image, true)
      images[i]:Destroy()
      images[i] = rot_image
      local t = img_w
      img_w = img_h
      img_h = t
    end
    if (max_w < img_w) then max_w = img_w end
    if (max_h < img_h) then max_h = img_h end
  end  
  return max_w, max_h
end

function ReleaseAll(comb_image)
  comb_image:Destroy()
  for i = 1, 4 do
    images[i]:Destroy()
    images[i] = nil
    files[i] = nil
  end
end

--Script Starts

files = {}
images = {}
aspect = 15/10
offset = 20

dlg = iup.dialog{
        iup.label{title="Drop here 4 photos."}, 
        title="Combine", 
        size="150x50"}

function dlg:dropfiles_cb(filename, num)
  files[num+1] = filename
  if (num == 0) then
    local max_w, max_h = LoadImages()
    local w, h = 2*max_w+offset, 2*max_h+offset
    
    if (w/h ~= aspect) then
      if (w/h < aspect) then
        w = h * aspect
      else
        h = w / aspect
      end
    end
    
    print("Combining...")
    local comb_image = im.ImageCreate(w, h, im.RGB, im.BYTE)
    -- white background
    im.ProcessRenderConstant(comb_image, {255, 255, 255})
    CombineImages(comb_image)
    
    Save_Combine_Image(comb_image)
    
    ReleaseAll(comb_image)
  end
end

dlg:show()
iup.MainLoop()
