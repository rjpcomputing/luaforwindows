require"imlua"
require"cdlua"
require"cdluaim"
require"iuplua"
require"iupluacd"

image = im.FileImageLoad("flower.jpg") -- directly load the image at index 0. it will open and close the file
cnv = iup.canvas{rastersize = image:Width().."x"..image:Height(), border = "NO"}
cnv.image = image -- store the new image in the IUP canvas as an attribute

function cnv:map_cb()       -- the CD canvas can only be created when the IUP canvas is mapped
  self.canvas = cd.CreateCanvas(cd.IUP, self)
end

function cnv:action()          -- called everytime the IUP canvas needs to be repainted
  self.canvas:Activate()
  self.canvas:Clear()
  self.image:cdCanvasPutImageRect(self.canvas, 0, 0, 0, 0, 0, 0, 0, 0) -- use default values
end

dlg = iup.dialog{cnv}

function dlg:close_cb()
  cnv.image:Destroy()
  cnv.canvas:Kill()
  self:destroy()
  return iup.IGNORE -- because we destroy the dialog
end

dlg:show()
iup.MainLoop()
