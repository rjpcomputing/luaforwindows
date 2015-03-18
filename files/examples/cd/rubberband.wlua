require("iupcdaux") -- utility module used in some samples

dlg = iupcdaux.new_dialog(w, h)
cnv = dlg[1]     -- retrieve the IUP canvas


function cnv:button_cb(button,pressed,x,y,r)
  canvas = self.canvas     -- retrieve the CD canvas from the IUP attribute

  -- start drag if button1 is pressed
  if button ==iup.BUTTON1 and pressed == 1 then
    y = canvas:UpdateYAxis(y)

    -- prepare for XOR
    canvas:Foreground(cd.WHITE)
    canvas:WriteMode(cd.XOR)

    xstart = x
    ystart = y
    drag = 1
    first = 1
  else
    if (drag == 1) then
      drag = 0
      canvas:Rect(xstart,xend,ystart,yend)
    end
  end
end


function cnv:motion_cb(x,y,r)
  canvas = self.canvas     -- retrieve the CD canvas from the IUP attribute

  if (drag == 1) then
    y = canvas:UpdateYAxis(y)

    if (first == 1) then
      first = 0
    else
      canvas:Rect(xstart,xend,ystart,yend)
    end

    canvas:Rect(xstart,x,ystart,y)

    xend = x
    yend = y
  end
end

first = 1
drag = 0

dlg:show()
iup.MainLoop()
