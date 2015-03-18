require"cdlua"

STYLE_SIZE = 10
pattern = cd.CreatePattern(STYLE_SIZE, STYLE_SIZE)
stipple = cd.CreateStipple(STYLE_SIZE, STYLE_SIZE)

for p = 0, STYLE_SIZE*STYLE_SIZE-1 do
  pattern[p] = cd.WHITE
end

pattern[11] = cd.RED   
pattern[21] = cd.RED                  
pattern[31] = cd.RED                  
pattern[41] = cd.RED                  
pattern[51] = cd.RED                  
pattern[12] = cd.RED                                            
pattern[22] = cd.RED                                            
pattern[32] = cd.RED                                            
pattern[42] = cd.RED                                            
pattern[52] = cd.RED                                            
pattern[13] = cd.RED                                            
pattern[23] = cd.RED                                            
pattern[33] = cd.RED                                            
pattern[43] = cd.RED                                            
pattern[53] = cd.RED                                            
pattern[14] = cd.RED   pattern[15] = cd.RED
pattern[24] = cd.RED   pattern[25] = cd.RED
pattern[34] = cd.RED   pattern[35] = cd.RED
pattern[44] = cd.RED   pattern[45] = cd.RED
pattern[54] = cd.RED   pattern[55] = cd.RED

pattern[26] = cd.BLUE  pattern[37] = cd.BLUE
pattern[36] = cd.BLUE  pattern[47] = cd.BLUE
pattern[46] = cd.BLUE  pattern[57] = cd.BLUE
pattern[56] = cd.BLUE  pattern[67] = cd.BLUE

pattern[48] = cd.BLUE  pattern[62] = cd.GREEN
pattern[58] = cd.BLUE  pattern[63] = cd.GREEN
pattern[68] = cd.BLUE  pattern[64] = cd.GREEN
pattern[78] = cd.BLUE  pattern[65] = cd.GREEN
                       pattern[66] = cd.GREEN

pattern[73] = cd.GREEN pattern[84] = cd.GREEN
pattern[74] = cd.GREEN pattern[85] = cd.GREEN
pattern[75] = cd.GREEN pattern[86] = cd.GREEN
pattern[76] = cd.GREEN pattern[87] = cd.GREEN
pattern[77] = cd.GREEN pattern[88] = cd.GREEN

-- initialize the stipple buffer with cross pattern
for l = 0, STYLE_SIZE-1 do
  for c = 0, STYLE_SIZE-1 do
    if ((c % 4) == 0) then
      stipple[l*STYLE_SIZE + c] = 1
    else
      stipple[l*STYLE_SIZE + c] = 0
    end
  end
end

IMAGE_SIZE = 100
imagergba = cd.CreateImageRGBA(IMAGE_SIZE, IMAGE_SIZE)

-- initialize the alpha image buffer with a degrade from transparent to opaque
for l = 0, IMAGE_SIZE-1 do
  for c = 0, IMAGE_SIZE-1 do
    if (l == 0 or l == IMAGE_SIZE-1 or c == 0 or c == IMAGE_SIZE-1) then
      imagergba.r[l*IMAGE_SIZE + c] = 0
      imagergba.g[l*IMAGE_SIZE + c] = 0
      imagergba.b[l*IMAGE_SIZE + c] = 0
    else
      if (l > IMAGE_SIZE/2) then
        imagergba.r[l*IMAGE_SIZE + c] = 95
        imagergba.g[l*IMAGE_SIZE + c] = 143
        imagergba.b[l*IMAGE_SIZE + c] = 95
      else
        imagergba.r[l*IMAGE_SIZE + c] = 255
        imagergba.g[l*IMAGE_SIZE + c] = 95
        imagergba.b[l*IMAGE_SIZE + c] = 95
      end
    end
  
    imagergba.a[l*IMAGE_SIZE + c] = (c*255)/(IMAGE_SIZE-1);
  end
end


function SimpleDraw()
  -- Get size in pixels to be used for computing coordinates. 
  w, h = canvas:GetSize() 

  -- Clear the background to be white 
  canvas:Background(cd.WHITE) 
  canvas:Clear() 
  
  -- Draw a reactangle and a polyline at the bottom-left area,
  -- using a thick line with transparency.
  -- Notice that transparency is only supported in a few drivers,
  -- and line join is not supported in the IMAGERGB driver. 
  canvas:LineWidth(3) 
  canvas:LineStyle(cd.CONTINUOUS) 
  canvas:Foreground(cd.EncodeAlpha(cd.DARK_MAGENTA, 128)) 
  canvas:Rect(100, 200, 100, 200) 
  canvas:Begin(cd.OPEN_LINES) 
  canvas:Vertex(300, 250) 
  canvas:Vertex(320, 270) 
  canvas:Vertex(350, 260) 
  canvas:Vertex(340, 200) 
  canvas:Vertex(310, 210) 
  canvas:End() 

  -- Draw the red diagonal line with a custom line style. 
  -- Notice that line styles are not supported in the IMAGERGB driver. 
  canvas:Foreground(cd.RED) 
  canvas:LineWidth(3) 
  dashes = {20, 15, 5, 5} 
  canvas:LineStyleDashes(dashes, 4) 
  canvas:LineStyle(cd.CUSTOM) 
  canvas:Line(0, 0, w-1, h-1) 
  
  -- Draw the blue diagonal line with a pre-defined line style.
  -- Notice that the pre-defined line style is dependent on the driver. 
  canvas:Foreground(cd.BLUE) 
  canvas:LineWidth(10) 
  canvas:LineStyle(cd.DOTTED) 
  canvas:Line(0, h-1, w-1, 0) 
  
  -- Reset line style and width 
  canvas:LineStyle(cd.CONTINUOUS) 
  canvas:LineWidth(1) 

  -- Draw an arc at bottom-left, and a sector at bottom-right.
  -- Notice that counter-clockwise orientation of both. 
  canvas:InteriorStyle(cd.SOLID) 
  canvas:Foreground(cd.MAGENTA) 
  canvas:Sector(w-100, 100, 100, 100, 50, 180) 
  canvas:Foreground(cd.RED) 
  canvas:Arc(100, 100, 100, 100, 50, 180) 
  
  -- Draw a solid filled rectangle at center. 
  canvas:Foreground(cd.YELLOW) 
  canvas:Box(w/2 - 100, w/2 + 100, h/2 - 100, h/2 + 100)
  
  -- Prepare font for text. 
  canvas:TextAlignment(cd.CENTER) 
  canvas:TextOrientation(70) 
  canvas:Font("Times", cd.BOLD, 24) 
  
  -- Draw text at center, with orientation, 
  -- and draw its bounding box. 
  -- Notice that in some drivers the bounding box is not precise. 
  irect = canvas:GetTextBounds(w/2, h/2, "cdMin Draw (згн)")
  canvas:Foreground(cd.RED) 
  canvas:Begin(cd.CLOSED_LINES) 
  canvas:Vertex(irect[1], irect[2]) 
  canvas:Vertex(irect[3], irect[4]) 
  canvas:Vertex(irect[5], irect[6]) 
  canvas:Vertex(irect[7], irect[8]) 
  canvas:End() 
  canvas:Foreground(cd.BLUE) 
  canvas:Text(w/2, h/2, "cdMin Draw (згн)") 
  
  -- Prepare World Coordinates 
  canvas:wViewport(0,w-1,0,h-1) 
  if (w>h) then
      canvas:wWindow(0,w/h,0,1) 
  else
      canvas:wWindow(0,1,0,h/w) 
  end
  
  -- Draw a filled blue rectangle in WC 
  canvas:wBox(0.20, 0.30, 0.40, 0.50) 
  canvas:Foreground(cd.RED) 
  
  -- Draw the diagonal of that rectangle in WC 
  canvas:wLine(0.20, 0.40, 0.30, 0.50) 
  
  -- Prepare Vector Text in WC. 
  canvas:wVectorCharSize(0.07) 
  
  -- Draw vector text, and draw its bounding box. 
  -- We also use this text to show when we are using a contextplus driver. 
  canvas:Foreground(cd.RED) 
  if (contextplus) then
      drect = canvas:wGetVectorTextBounds("WDj-Plus", 0.25, 0.35) 
  else
      drect = canvas:wGetVectorTextBounds("WDj", 0.25, 0.35)
  end
  canvas:Begin(cd.CLOSED_LINES) 
  canvas:wVertex(drect[1], drect[2]) 
  canvas:wVertex(drect[3], drect[4]) 
  canvas:wVertex(drect[5], drect[6]) 
  canvas:wVertex(drect[7], drect[8]) 
  canvas:End() 
  canvas:LineWidth(2) 
  canvas:LineStyle(cd.CONTINUOUS) 
  if (contextplus) then
      canvas:wVectorText(0.25, 0.35, "WDj-Plus") 
  else
      canvas:wVectorText(0.25, 0.35, "WDj") 
  end
  
  -- Reset line width 
  canvas:LineWidth(1) 
  
  -- Draw a filled path at center-right (looks like a weird fish). 
  -- Notice that in PDF the arc is necessarily a circle arc, and not an ellipse. 
  canvas:Foreground(cd.GREEN) 
  canvas:Begin(cd.PATH) 
  canvas:PathSet(cd.PATH_MOVETO) 
  canvas:Vertex(w/2 + 200, h/2) 
  canvas:PathSet(cd.PATH_LINETO) 
  canvas:Vertex(w/2 + 230, h/2 + 50) 
  canvas:PathSet(cd.PATH_LINETO) 
  canvas:Vertex(w/2 + 250, h/2 + 50) 
  canvas:PathSet(cd.PATH_CURVETO) 
  canvas:Vertex(w/2+150+150, h/2+200-50) -- control point for start 
  canvas:Vertex(w/2+150+180, h/2+250-50) -- control point for end 
  canvas:Vertex(w/2+150+180, h/2+200-50) -- end point 
  canvas:PathSet(cd.PATH_CURVETO) 
  canvas:Vertex(w/2+150+180, h/2+150-50)
  canvas:Vertex(w/2+150+150, h/2+100-50)
  canvas:Vertex(w/2+150+300, h/2+100-50)
  canvas:PathSet(cd.PATH_LINETO) 
  canvas:Vertex(w/2+150+300, h/2-50) 
  canvas:PathSet(cd.PATH_ARC) 
  canvas:Vertex(w/2+300, h/2) -- center 
  canvas:Vertex(200, 100) -- width, height 
  canvas:Vertex(-30*1000, -170*1000) -- start angle, end angle (degrees / 1000) 
  canvas:PathSet(cd.PATH_FILL) 
  canvas:End() 
  
  -- Draw 3 pixels at center left. 
  canvas:Pixel(10, h/2+0, cd.RED) 
  canvas:Pixel(11, h/2+1, cd.GREEN) 
  canvas:Pixel(12, h/2+2, cd.BLUE) 
  
  -- Draw 4 mark types, distributed near each corner. 
  canvas:Foreground(cd.RED) 
  canvas:MarkSize(30) 
  canvas:MarkType(cd.PLUS) 
  canvas:Mark(200, 200) 
  canvas:MarkType(cd.CIRCLE) 
  canvas:Mark(w - 200, 200) 
  canvas:MarkType(cd.HOLLOW_CIRCLE) 
  canvas:Mark(200, h - 200) 
  canvas:MarkType(cd.DIAMOND) 
  canvas:Mark(w - 200, h - 200) 
  
  -- Draw all the line style possibilities at bottom. 
  -- Notice that they have some small differences between drivers. 
  canvas:LineWidth(1) 
  canvas:LineStyle(cd.CONTINUOUS) 
  canvas:Line(0, 10, w, 10) 
  canvas:LineStyle(cd.DASHED) 
  canvas:Line(0, 20, w, 20) 
  canvas:LineStyle(cd.DOTTED) 
  canvas:Line(0, 30, w, 30) 
  canvas:LineStyle(cd.DASH_DOT) 
  canvas:Line(0, 40, w, 40) 
  canvas:LineStyle(cd.DASH_DOT_DOT) 
  canvas:Line(0, 50, w, 50) 
  
  -- Draw all the hatch style possibilities in the top-left corner.
  -- Notice that they have some small differences between drivers. 
  canvas:Hatch(cd.VERTICAL)
  canvas:Box(0, 50, h - 60, h) 
  canvas:Hatch(cd.FDIAGONAL)
  canvas:Box(50, 100, h - 60, h) 
  canvas:Hatch(cd.BDIAGONAL)
  canvas:Box(100, 150, h - 60, h) 
  canvas:Hatch(cd.CROSS)
  canvas:Box(150, 200, h - 60, h) 
  canvas:Hatch(cd.HORIZONTAL)
  canvas:Box(200, 250, h - 60, h) 
  canvas:Hatch(cd.DIAGCROSS)
  canvas:Box(250, 300, h - 60, h) 
  
  -- Draw 4 regions, in diamond shape,
  -- at top, bottom, left, right, 
  -- using different interior styles. 
  
  -- At top, not filled polygon, notice that the last line style is used. 
  canvas:Begin(cd.CLOSED_LINES) 
  canvas:Vertex(w/2, h - 100)
  canvas:Vertex(w/2 + 50, h - 150)
  canvas:Vertex(w/2, h - 200)
  canvas:Vertex(w/2 - 50, h - 150)
  canvas:End() 
  
  -- At left, hatch filled polygon 
  canvas:Hatch(cd.DIAGCROSS)
  canvas:Begin(cd.FILL) 
  canvas:Vertex(100, h/2)
  canvas:Vertex(150, h/2 + 50)
  canvas:Vertex(200, h/2)
  canvas:Vertex(150, h/2 - 50)
  canvas:End() 
  
  -- At right, pattern filled polygon 
  canvas:Pattern(pattern) 
  canvas:Begin(cd.FILL) 
  canvas:Vertex(w - 100, h/2)
  canvas:Vertex(w - 150, h/2 + 50)
  canvas:Vertex(w - 200, h/2)
  canvas:Vertex(w - 150, h/2 - 50)
  canvas:End() 

  -- At bottom, stipple filled polygon 
  canvas:Stipple(stipple) 
  canvas:Begin(cd.FILL) 
  canvas:Vertex(w/2, 100)
  canvas:Vertex(w/2 + 50, 150)
  canvas:Vertex(w/2, 200)
  canvas:Vertex(w/2 - 50, 150)
  canvas:End() 
  
  -- Draw two beziers at bottom-left 
  canvas:Begin(cd.BEZIER) 
  canvas:Vertex(100, 100)
  canvas:Vertex(150, 200)
  canvas:Vertex(180, 250)
  canvas:Vertex(180, 200)
  canvas:Vertex(180, 150)
  canvas:Vertex(150, 100)
  canvas:Vertex(300, 100)
  canvas:End() 
  
  -- Draw the image on the top-right corner but increasing its actual size, and uses its full area 
  canvas:PutImageRectRGBA(imagergba, w - 400, h - 310, 3*IMAGE_SIZE, 3*IMAGE_SIZE, 0, 0, 0, 0) 
  
  -- Adds a new page, or 
  -- flushes the file, or
  -- flushes the screen, or
  -- swap the double buffer. 
  canvas:Flush() 
end


canvas = cd.CreateCanvas(cd.SVG, "cd_svg.svg 270.933x198.543 4.72441")

SimpleDraw(canvas)

-- Destroys the canvas and releases internal memory, 
-- important for file based drivers to close the file.
canvas:Kill()
