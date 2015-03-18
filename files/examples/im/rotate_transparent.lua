-- Contribution by Gustavo Lyrio
require"imlua"
require"imlua_process"
require"cdlua"
require"cdluaim"
require"iuplua"
require"iupluacd"

--IupCanvas Example in IupLua 
cv       = iup.canvas {rastersize="640x480"}
dg       = iup.dialog{iup.frame{cv}; title="Rotate Test"}

-- Simple parameters
width = 640
height = 480
screen_width = 1024
screen_height = 768

image = im.FileImageLoad("flower.jpg")
Timage = {}
--Timage.x0 = (width/2) - (image:Width()/2)
--Timage.y0 = (height/2) - (image:Height()/2)
Timage.x0 = 0
Timage.y0 = 0

function cv:action()
	canvas:Activate()
	canvas:Clear()
  if (image2) then
    image2:cdCanvasPutImageRect(canvas, Timage.x0, Timage.y0, image2:Width(), image2:Height(), 0,0,0,0)
  end
	return iup.DEFAULT
end

function cv:motion_cb(x, y, status)
	cd.Activate(canvas)
	y = cd.UpdateYAxis(y)
	if iup.isbutton1(status) == true then
	end
	return iup.DEFAULT
end

function cv:button_cb(but, pressed, x, y, status)
	if iup.isbutton1(status) == false then
	end
	return iup.DEFAULT
end

dg:map()
canvas = cd.CreateCanvas(cd.IUP, cv.handle)

dg:showxy(iup.CENTER, iup.CENTER)

-- Rotation Test
image:AddAlpha() -- option 1: to avoid a black background
image:SetAlpha(255)

local w, h = im.ProcessCalcRotateSize(image:Width(), image:Height(), math.cos(math.pi/4), math.sin(math.pi/4))
image2 = im.ImageCreateBased(image, w, h)

--image2 = im.ImageCreate(w, h, im.RGB, im.BYTE)   -- option 2: to avoid a black background
--im.ProcessRenderConstant(image2, {255, 255, 255})

im.ProcessRotate(image, image2, math.cos(math.pi/4), math.sin(math.pi/4), 1)

--image2 = image:Clone()  -- rotate and preserve size
--im.ProcessRotateRef(image, image2, math.cos(math.pi/4), math.sin(math.pi/4), image:Width()/2, image:Height()/2, false, 1)


canvas:Activate()
canvas:Clear()

--original
--image:cdCanvasPutImageRect(canvas, Timage.x0, Timage.y0, image:Width(), image:Height(), 0,0,0,0)

--processed
image2:cdCanvasPutImageRect(canvas, Timage.x0, Timage.y0, image2:Width(), image2:Height(), 0,0,0,0)

if (not iup.MainLoopLevel or iup.MainLoopLevel()==0) then
  iup.MainLoop()
end
