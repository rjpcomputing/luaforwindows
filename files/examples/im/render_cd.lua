require"imlua"
require"cdlua"
require"cdluaim"

local image = im.ImageCreate(500, 500, im.RGB, im.BYTE)
local canvas = image:cdCreateCanvas()  -- Creates a CD_IMAGERGB canvas

canvas:Activate()  
canvas:Background(cd.EncodeColor(255, 255, 255))
canvas:Clear()
fgcolor = cd.EncodeColor(255, 0, 0) -- red
fgcolor = cd.EncodeAlpha(fgcolor, 50) -- semi transparent
canvas:Foreground(fgcolor)
canvas:Font("Times", cd.BOLD, 24)
canvas:Text(100, 100, "Test")
canvas:Line(0,0,100,100)
canvas:Kill()

image:Save("new.bmp", "BMP")
