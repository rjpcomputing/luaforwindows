require"cdlua"
require"iuplua"
require"iupluacd"

iupcdaux = {}
iupcdaux.count = 0

-- Function to easy create a new IUP dialog with an IUP canvas,
-- and a CD canvas pointing to that IUP canvas

function iupcdaux.new_dialog(w, h)

  -- defaul size
  w = w or 300
  h = h or 200
  
  cnv = iup.canvas { bgcolor="255 255 255", rastersize=w.."x"..h }
  dlg = iup.dialog { cnv; title="canvas_"..(iupcdaux.count+1) }

  function cnv:map_cb()
    canvas = cd.CreateCanvas(cd.IUP, self)
    self.canvas = canvas     -- store the CD canvas in a IUP attribute
  end
  
  function cnv:action()
    canvas = self.canvas     -- retrieve the CD canvas from the IUP attribute
    canvas:Activate()
    canvas:Clear()
    
    if (self.Draw) then
      self:Draw(canvas)
    end
  end

  function dlg:close_cb()
    cnv = self[1]
    canvas = cnv.canvas     -- retrieve the CD canvas from the IUP attribute
    canvas:Kill()
    self:destroy()
    return iup.IGNORE -- because we destroy the dialog
  end

  iupcdaux.count = iupcdaux.count + 1
  return dlg
end
