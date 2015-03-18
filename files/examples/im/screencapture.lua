require"imlua"
require"cdlua"
require"cdluaim"

local canvas = cd.CreateCanvas(cd.NATIVEWINDOW, nil)
canvas:Activate()
local w, h = canvas:GetSize()
local image = im.ImageCreate(w, h, im.RGB, im.BYTE)    
image:cdCanvasGetImage(canvas, 0, 0)
error = image:Save("screencapture.jpg", "JPEG")
image:Destroy()        
if (error) then print("error = "..error) end

