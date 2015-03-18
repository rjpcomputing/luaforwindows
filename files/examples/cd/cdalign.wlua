require("iupcdaux") -- utility module used in some samples

dlg = iupcdaux.new_dialog(w, h)
cnv = dlg[1]     -- retrieve the IUP canvas

function DrawText(canvas, x, y, text, align)
  canvas:TextAlignment(align)
  canvas:Mark(x, y)
  canvas:Text(x, y, text)
  xmin, xmax, ymin, ymax = canvas:GetTextBox(x, y, text)
  canvas:Rect(xmin, xmax, ymin, ymax)
end

text_aligment = {
 cd.NORTH,
 cd.SOUTH,
 cd.EAST,
 cd.WEST,
 cd.NORTH_EAST,
 cd.NORTH_WEST,
 cd.SOUTH_EAST,
 cd.SOUTH_WEST,
 cd.CENTER,
 cd.BASE_LEFT,
 cd.BASE_CENTER,
 cd.BASE_RIGHT
}

text_aligment_str = {
 "NORTH",
 "SOUTH",
 "EAST",
 "WEST",
 "NORTH EAST",
 "NORTH WEST",
 "SOUTH EAST",
 "SOUTH WEST",
 "CENTER",
 "BASE LEFT",
 "BASE CENTER",
 "BASE RIGHT"
}


-- custom function used in action callback
-- from the iupcdaux module
function cnv:Draw(canvas)
  canvas:MarkSize(40)
  canvas:Font("Courier", cd.PLAIN, 12)

  i = 1
  while (i <= 12) do
    DrawText(canvas, 100, 35*i + 30, text_aligment_str[i], text_aligment[i])
    i = i + 1
  end
end


--tmpCanvas = cd.CreateCanvas(cd.PS, "cdalign.ps")
--tmpCanvas:Clear()
--cnv:Draw(tmpCanvas)
--tmpCanvas:Kill()


dlg:show()
iup.MainLoop()

