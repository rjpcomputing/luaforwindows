require("iupcdaux") -- utility module used in some samples

w = 100
h = 100

image_rgb = cd.CreateImageRGB(w, h)

size = w * h
i = 0
while i < size do

  if i < size/2 then
    image_rgb.r[i] = 255
    image_rgb.g[i] = 0
    image_rgb.b[i] = 0
  else
    image_rgb.r[i] = 0
    image_rgb.g[i] = 0
    image_rgb.b[i] = 255
  end

  i = i + 1
end

dlg = iupcdaux.new_dialog(w, h)
cnv = dlg[1]     -- retrieve the IUP canvas

-- custom function used in action callback
-- from the iupcdaux module
function cnv:Draw(canvas)
  canvas:PutImageRectRGB(image_rgb, 0, 0, w, h, 0, 0, 0, 0)
end

dlg:show()
iup.MainLoop()
