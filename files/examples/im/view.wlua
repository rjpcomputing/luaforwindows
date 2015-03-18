require"imlua"
require"cdlua"
require"cdluaim"
require"iuplua"
require"iupluacd"

function PrintError(func, err)
  local msg = {}
  msg[im.ERR_OPEN] = "Error Opening File."
  msg[im.ERR_MEM] = "Insuficient memory."
  msg[im.ERR_ACCESS] = "Error Accessing File."
  msg[im.ERR_DATA] = "Image type not Suported."
  msg[im.ERR_FORMAT] = "Invalid Format."
  msg[im.ERR_COMPRESS] = "Invalid or unsupported compression."
  
  if msg[err] then
    print(func..": "..msg[err])
  else
    print("Unknown Error.")
  end
end

function LoadImage(file_name)
  local image
  local ifile, err = im.FileOpen(file_name)
  if not ifile then
      PrintError("open", err)
      return
  end
  
  -- load the first image in the file.
  -- force the image to be converted to a bitmap
  image, err = ifile:LoadBitmap()
  if not image then
    PrintError("load", err)
    return
  end
    
  ifile:Close()
  return image
end


dlg = nil  -- only one dlg

function ShowImage(file_name)

  local image = LoadImage(file_name)
  if not image then
    return false
  end

  if dlg then
    local old_canvas = dlg.canvas
    local old_image = dlg.image

    if old_canvas ~= nil then old_canvas:Kill() end
    if old_image ~= nil then old_image:Destroy() end

    iup.Destroy(dlg)
  end

  cnv = iup.canvas{}
  
  function cnv:action()
    local canvas = dlg.canvas
    local image = dlg.image
    
    if (not canvas) then return end
    
    -- posy is top-down, CD is bottom-top.
    -- invert scroll reference (YMAX-DY - POSY).
    y = self.ymax-self.dy - self.posy
    if (y < 0) then y = 0 end
    

    canvas:Activate()
    canvas:Clear()
    x = -self.posx
    y = -y
    image:cdCanvasPutImageRect(canvas, x, y, image:Width(), image:Height(), 0, 0, 0, 0)
    canvas:Flush()
    
    return iup.DEFAULT
  end

  function cnv:button_cb()
    local file_name = "*.*"
    local err

    file_name, err = iup.GetFile(file_name)
    if err ~= 0 then
      return iup.DEFAULT
    end
    
    ShowImage(file_name)  
    return iup.DEFAULT
  end

  
  -- Set the Canvas inicial size (IUP will retain this value).
  w = image:Width()
  h = image:Height()
  if (w > 800) then w = 800 end
  if (h > 600) then h = 600 end
  cnv.rastersize = string.format("%dx%d", w, h)
  cnv.border = "no"
  cnv.scrollbar = "yes"  
  cnv.xmax = image:Width()-1
  cnv.ymax = image:Height()-1
  
  function cnv:resize_cb(w, h)
    self.dx = w
    self.dy = h
    self.posx = self.posx -- needed only in IUP 2.x
    self.posy = self.posy
  end
  
  dlg = iup.dialog{cnv}
  dlg.title = file_name
  dlg.cnv = cnv
  dlg.image = image
  
  function dlg:close_cb()
    local canvas = self.canvas
    local image = self.image

    if canvas then canvas:Kill() end
    if image then image:Destroy() end

    return iup.CLOSE
  end

  function dlg:map_cb()
    canvas = cd.CreateCanvas(cd.IUP, self.cnv)
    self.canvas = canvas
    self.posx = 0 -- needed only in IUP 2.x
    self.posy = 0
  end
  
  dlg:show()
  cnv.rastersize = nil -- to remove the minimum limit
  
  return true
end

function main(arg)
  local file_name = "*.*"
  local err
  
  -- Try to get a file name from the command line.
  if (arg == nil or table.getn(arg) < 2) then
    file_name, err = iup.GetFile(file_name)
    if err ~= 0 then
      return true
    end
  else   
    file_name = arg[1]
  end
                                   
  if not ShowImage(file_name) then
    local Try = true
    -- If ShowImage returns an error I will try to read another image.
    -- I can give up on File Open dlg choosing "Cancel".
    while Try do
      file_name = "*.*"
      
          file_name, err = iup.GetFile(file_name)
      if err ~= 0 then
        return true
      end
      
      if ShowImage(file_name) then
        Try = false
      end
    end
  end
  
  iup.MainLoop()  
  return true
end

main(arg)
