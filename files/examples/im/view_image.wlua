require"imlua"
require"cdlua"
require"cdluaim"
require"iuplua"
require"iupluacd"

iup.key_open()

function View_Image(image, title)
  ret = false

  cnv = iup.canvas{}
  
  function cnv:action()
    local canvas = dlg.canvas
    local image = dlg.image
    
    if (not canvas) then return end
    
    canvas:Activate()
    cw, ch = canvas:GetSize()
    iw = image:Width()
    ih = image:Height()
    
    if (iw > ih) then
      h = iw/iw * ch
      y = (ch-h)/2
      x = 0
      w = cw
    else
      w = iw/ih * ch
      x = (cw-w)/2
      y = 0
      h = ch
    end
    
    canvas:Clear()
    image:cdCanvasPutImageRect(canvas, x, y, w, h, 0, 0, 0, 0)
  end

  function cnv:button_cb()
    dlg:close_cb()
    ret = true
    return iup.CLOSE
  end
  
  dlg = iup.dialog{iup.vbox{cnv, iup.label{title="Click to accept or press Esc to abort."}}}
  dlg.placement="maximized"
  dlg.title = title
  dlg.cnv = cnv
  dlg.image = image
  
  function dlg:k_any(c)
  print("K_any("..c..")")
    if (c == iup.K_ESC) then
      dlg:close_cb()
      return iup.CLOSE
    end
  end

  function dlg:close_cb()
    local canvas = self.canvas
    if canvas then canvas:Kill() end
  end

  function dlg:map_cb()
    canvas = cd.CreateCanvas(cd.IUP, self.cnv)
    self.canvas = canvas
  end
  
  dlg:show()
  iup.MainLoop()
  dlg:destroy()
  
  return ret
end
