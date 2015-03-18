--A script to compose 9 photos, with 4/6 aspect ratio

require"imlua"
require"imlua_process"
require"iuplua"

function Confirm(title,msg)
  if continue then
    b=iup.Alarm(title, msg ,"Continue" ,"Exit")
    if b==2 then continue=false print("Script Aborted!") end
  end
end

function Create_Host_Image()
  if continue then
    local screenx=1024*3 screeny=684*3
    dst_photo = im.ImageCreate(screenx, screeny, im.RGB, im.BYTE)
    resize_photo = im.ImageCreate(1024, 684, im.RGB, im.BYTE) -- for resize
  end
end

function Create_Host_Name(name)
  if continue then
    i=0
    repeat
      i=i+1
      num=1000+i
      numstr=string.sub(tostring(num),-3)
--      path="D:/Composite/"
      path="D:/Downloads/Test/"
      ext=".jpg"
      Result=path..name..numstr..ext
      res,msg=io.open(Result)
      io.close()
    until not res
  end
end

function Get_Source_Photo()
  if continue then
--    path="D:/MyPictures/"
    path="D:/Downloads/Test/*.jpg"
    Source, err = iup.GetFile(path)
    print("Source: ", Source)
    if err<0 then continue=false end
  end
end

function Insert_Photo(num)
  if continue then
    title="Photo "..num.." of 9" msg=Source Confirm(title,msg)
    wd=dst_photo:Width()
    hd=dst_photo:Height()
    --print("Dst Size:",wd,hd)
    src_photo=im.FileImageLoadBitmap(Source)
    valuex=src_photo:Width()
    valuey=src_photo:Height()
    --print("Source Size:",valuex,valuey)
    panex={0,1024,2048,0,1024,2048,0,1024,2048}
    paney={0,0,0,684,684,684,1368,1368,1368}
    Xd=panex[num] 
    Yd=paney[num]
    Wd=1024 Hd=684
    -- extract a proportional rectangle from the source image
    if 1.5*valuey>valuex then
        Ws=valuex 
        Xs=0
        Hs=math.floor(valuex/1.5) 
        Ys=math.floor((valuey-Hs)/2)
      else
        Hs=valuey 
        Ys=0
        Ws=math.floor(1.5*Hs) 
        Xs=math.floor((valuex-Ws)/2)
       end
       
    --print("Crop Size:",Ws, Hs)
    --print("Crop Shift:",Xs,Ys)
    crop_photo = im.ImageCreate(Ws, Hs, im.RGB, im.BYTE)   
    im.ProcessCrop(src_photo, crop_photo, Xs,Ys)
    im.ProcessResize(crop_photo, resize_photo, 1) -- do bilinear interpolation
    im.ProcessInsert(dst_photo, resize_photo, dst_photo, Xd, Yd) -- insert resize in dst and place the result in dst
    crop_photo:Destroy()
    
    if num==9 then src_photo:CopyAttributes(dst_photo) end
  end
end

function Save_Composite_Photo()
  if continue then
    name="Composite"
    Create_Host_Name(name)
    dst_photo:Save(Result, "JPEG")
    os.execute(Result)
  end
end

--Script Starts
continue=true
title="9 Panel Composite" msg="Photos can be anysize." Confirm(title,msg)
Create_Host_Image()
for i=1,9 do
  num=i
  Get_Source_Photo()
  Insert_Photo(num)
  end
Save_Composite_Photo()
