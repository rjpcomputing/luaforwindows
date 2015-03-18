require "gd"

im = gd.createFromJpeg("./bugs.jpg")
assert(im)

white = im:colorAllocate(255, 255, 255)
im:string(gd.FONT_MEDIUM, 10, 10, "Powered by", white)

imlua = gd.createFromPng("./lua-gd.png")
-- imlua:colorTransparent(imlua:getPixel(0, 0))

sx, sy = imlua:sizeXY()
gd.copy(im, imlua, 10, 25, 0, 0, sx, sy, sx, sy)
im:string(gd.FONT_MEDIUM, 10, 330, "http://lua-gd.luaforge.net/", white)

im:png("out.png")
os.execute("out.png")
