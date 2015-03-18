require "gd"

x, y = 140, 110

im = gd.createPalette(x, y)
white = im:colorAllocate(255, 255, 255)
black = im:colorAllocate(0, 0, 0)

im:string(gd.FONT_TINY, 10, 10, "gd.FONT_TINY", black)
im:string(gd.FONT_SMALL, 10, 20, "gd.FONT_SMALL", black)
im:string(gd.FONT_MEDIUM, 10, 35, "gd.FONT_MEDIUM", black)
im:string(gd.FONT_LARGE, 10, 48, "gd.FONT_LARGE", black)
im:string(gd.FONT_GIANT, 10, 65, "gd.FONT_GIANT", black)

im:line(60, 93, 70, 93, black)
im:string(gd.FONT_SMALL, 80, 86, "= 10 px", black)

im:png("stdfonts.png")

