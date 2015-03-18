require "gd"

im = gd.createPalette(80, 80)
assert(im)

black = im:colorAllocate(0, 0, 0)
white = im:colorAllocate(255, 255, 255)
im:gifAnimBegin("out.gif", true, 0)

for i = 1, 10 do
  tim = gd.createPalette(80, 80)
  tim:paletteCopy(im)
  tim:arc(40, 40, 40, 40, 36*(i-1), 36*i, white)
  tim:gifAnimAdd("out.gif", false, 0, 0, 5, gd.DISPOSAL_NONE)
end

gd.gifAnimEnd("out.gif")

print("Gif animation written to 'out.gif' file")
