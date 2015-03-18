require"imlua"
require"cdlua"
require"cdluaim"

local image = im.ImageCreate(500, 500, im.RGB, im.BYTE)
image:AddAlpha()
local canvas = image:cdCreateCanvas()  -- Creates a CD_IMAGERGB canvas

canvas:Activate()

-- Use SetBackground instead of Background to avoid conflict with cd.QUERY
canvas:SetBackground(cd.EncodeAlpha(cd.EncodeColor(255, 255, 255), 0)) -- full transparent white
canvas:Clear()

fgcolor = cd.EncodeAlpha(cd.EncodeColor(255, 0, 0), 50) -- semi transparent red
canvas:Foreground(fgcolor)
canvas:Font("Times", cd.BOLD, 24)
canvas:Text(100, 100, "Test")
canvas:Line(0,0,100,100)

fgcolor = cd.EncodeColor(0, 0, 255)
canvas:Foreground(fgcolor)
canvas:Line(0,50,150,50)

canvas:Kill()

image:Save("new.png", "PNG")
