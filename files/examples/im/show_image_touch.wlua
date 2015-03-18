require"imlua"
require"cdlua"
require"cdluaim"
require"iuplua"
require"iupluacd"
require"iupluatuio"

cnv = iup.canvas{rastersize = "1024x768", border = "NO", touch="Yes"}
img_x = 0
img_y = 0

-- comment this line to NOT use the TUIO client, only Windows 7 supports multi-touch
tuio = iup.tuioclient{}

function load_image(filename)
  local new_image = im.FileImageLoadBitmap(filename)
  if (not new_image) then
    iup.Message("Error", "LoadBitmap failed.")
  else
    if (image) then image:Destroy() end
    loaded = true
    image = new_image
    iup.Update(cnv)
  end
end

function cnv:map_cb()       -- the CD canvas can only be created when the IUP canvas is mapped
  canvas = cd.CreateCanvas(cd.IUP, self)
end

function cnv:action()          -- called everytime the IUP canvas needs to be repainted
  canvas:Activate()
  canvas:Clear()
  if (image) then
    if (loaded) then
      local cnv_w, cnv_h = canvas:GetSize()
      
      -- inicial zoom and position
      img_w = image:Width()
      img_h = image:Height()
      img_x = (cnv_w-img_w)/2
      img_y = (cnv_h-img_h)/2
      loaded = false
    end
    image:cdCanvasPutImageRect(canvas, img_x, img_y, img_w, img_h, 0, 0, 0, 0) -- use default values
  end
end

function cnv:multitouch_cb(count, pid, px, py, pstatus)
	if (count == 1) then
    if (pstatus[1] == string.byte('D')) then -- DOWN
      old_x = px[1]
      old_y = canvas:UpdateYAxis(py[1])
      translate = 1
    elseif (pstatus[1] == string.byte('U')) then -- UP
      if (translate == 1) then
        translate = 0
      end
    elseif (pstatus[1] == string.byte('M')) then -- MOVE
      if (translate == 1) then
        -- translate only
        local y = canvas:UpdateYAxis(py[1])
        local x = px[1]
        img_x = img_x + (x - old_x)
        img_y = img_y + (y - old_y)
        old_x = x
        old_y = y
        iup.Update(cnv)
      end
    end
  elseif (count == 2) then
    if (pstatus[1] == string.byte('D') or pstatus[2] == string.byte('D')) then -- DOWN
      diff_x = math.abs(px[2]-px[1])
      diff_y = math.abs(py[2]-py[1])
      ref_x = img_x+img_w/2 -- center of the image as reference
      ref_y = img_y+img_h/2
      old_angle = math.atan2(py[2]-py[1], px[2]-px[1])
      zoom = 1
    elseif (pstatus[1] == string.byte('U') or pstatus[2] == string.byte('U')) then -- UP
      if (zoom == 1) then
        zoom = 0
      end
    elseif (pstatus[1] == string.byte('M') or pstatus[2] == string.byte('M')) then -- MOVE
      if (zoom == 1) then
        -- zoom
        local new_diff_x = math.abs(px[2]-px[1])
        local new_diff_y = math.abs(py[2]-py[1])
        local angle = math.atan2(py[2]-py[1], px[2]-px[1])
      
        local abs_diff_x = new_diff_x-diff_x
        local abs_diff_y = new_diff_y-diff_y
        local diff = 0
        if (math.abs(abs_diff_y) > math.abs(abs_diff_x)) then 
          diff = abs_diff_y
        else
          diff = abs_diff_x
        end
        local prev_w = img_w
        local prev_h = img_h
        img_w = img_w + diff
        img_h = img_h + diff
        
        local str = string.format("%g %d %d", -(angle-old_angle)*cd.RAD2DEG, ref_x, ref_y)
        print("ROTATE=", str)
        canvas:SetAttribute("ROTATE", str)

        -- translate to maintain fixed the reference point
        local orig_x = ref_x - img_x
        local orig_y = ref_y - img_y
        orig_x = (img_w/prev_w)*orig_x
        orig_y = (img_h/prev_h)*orig_y
        img_x = ref_x - orig_x
        img_y = ref_y - orig_y
        
        diff_x = new_diff_x
        diff_y = new_diff_y
        iup.Update(cnv)
      end
    end
  end
end

function cnv:button_cb(button,pressed,x,y,status)
  -- start drag if button1 is pressed
  if button ==iup.BUTTON1 and pressed == 1 then
    y = canvas:UpdateYAxis(y)

    old_x = x
    old_y = y
    start_x = x
    start_y = y
    drag = 1
  else
    if (drag == 1) then
      drag = 0
    end
  end
end

function cnv:motion_cb(x,y,status)
  if (drag == 1) then
    y = canvas:UpdateYAxis(y)
   
    if (iup.iscontrol(status)) then
      -- zoom
      local diff_x = (x - old_x)
      local diff_y = (y - old_y)
      local diff = 0
      if (math.abs(diff_y) > math.abs(diff_x)) then 
        diff = diff_y
      else
        diff = diff_x
      end
      local prev_w = img_w
      local prev_h = img_h
      img_w = img_w + diff
      img_h = img_h + diff
      
      -- translate to maintain fixed the reference point
      local orig_x = start_x - img_x
      local orig_y = start_y - img_y
      orig_x = (img_w/prev_w)*orig_x
      orig_y = (img_h/prev_h)*orig_y
      img_x = start_x - orig_x
      img_y = start_y - orig_y
    else
      -- translate only
      img_x = img_x + (x - old_x)
      img_y = img_y + (y - old_y)
    end
    old_x = x
    old_y = y
    iup.Update(cnv)
  end
end

function cnv:k_any(c)
  if c == iup.K_q or c == iup.K_ESC then
    return iup.CLOSE
  end
  if c == iup.K_F1 then
    if fullscreen then
      fullscreen = false
      dlg.fullscreen = "No"
    else
      fullscreen = true
      dlg.fullscreen = "Yes"
    end
  end
  if c == iup.K_F2 then
    filename = iup.GetFile("*.*")
    if (filename) then
      load_image(filename)
    end
  end
 
end

dlg = iup.dialog{cnv}

function dlg:close_cb()
  if (image) then
    image:Destroy()
  end
  canvas:Kill()
  self:destroy()
  return iup.IGNORE -- because we destroy the dialog
end

if (tuio) then
  tuio.connect = "YES"
  tuio.targetcanvas = cnv
end

dlg:show()
cnv.rastersize = nil -- remove minimum size

if arg and arg[1] ~= nil then
  filename = arg[1]
else
  filename = iup.GetFile("*.*")
end
if (filename) then
  load_image(filename)
end

if (iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
