require("iupcdaux") -- utility module used in some samples

--require"cdluacontextplus"
--cd.UseContextPlus(1)

dlg = iupcdaux.new_dialog(w, h)
cnv = dlg[1]     -- retrieve the IUP canvas

function DrawTextBox(canvas, x, y, text)
  canvas:Mark(x, y)
  canvas:Text(x, y, text)
  w, h = canvas:GetTextSize(text)
  xmin = x - w/2
  ymin = y - h/2
  xmax = x + w/2
  ymax = y + h/2
  canvas:Line(xmin, ymin, xmax, ymin)
  canvas:Line(xmin, ymin, xmin, ymax)
  canvas:Line(xmin, ymax, xmax, ymax)
  canvas:Line(xmax, ymin, xmax, ymax)
end

-- custom function used in action callback
-- from the iupcdaux module
function cnv:Draw(canvas)

  -- Available in ContextPlus drivers or in IMAGERGB driver
  -- canvas:SetAttribute("ANTIALIAS", "1")

  canvas:TextAlignment(cd.CENTER)
  canvas:MarkSize(40)

  canvas:Font("Courier", cd.PLAIN, 12)
  local aa = canvas:GetAttribute("ANTIALIAS")
  if (aa == "1") then
    DrawTextBox(canvas, 130, 30, "ANTIALIAS=1")
  else
    DrawTextBox(canvas, 130, 30, "ANTIALIAS=0")
  end

  canvas:Font("Courier", cd.ITALIC, 34)
  DrawTextBox(canvas, 130, 160, "xxxxxppx")

  canvas:Font("Times", cd.PLAIN, 12)
  DrawTextBox(canvas, 130, 290, "taaaa")

  canvas:Font("Times", cd.BOLD, 14)
  DrawTextBox(canvas, 130, 370, "gggggggg")
end


--tmpCanvas = cd.CreateCanvas(cd.PS, "cdtext.ps")
--tmpCanvas:Clear()
--cnv:Draw(tmpCanvas)
--tmpCanvas:Kill()


dlg:show()
iup.MainLoop()
