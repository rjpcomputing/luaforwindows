require "gd"

im = gd.createTrueColor(80, 80)
assert(im)

black = im:colorAllocate(0, 0, 0)
white = im:colorAllocate(255, 255, 255)

im:polygon( { { 10, 10 }, { 10, 20 }, { 20, 20 }, { 20, 10 } }, white)
im:filledPolygon( { { 30, 30 }, { 30, 40 }, { 40, 40 }, { 40, 30 } }, white)
im:openPolygon( { { 50, 50 }, { 50, 60 }, { 60, 60 }, { 60, 50 } }, white)

im:png("out.png")
print(os.execute("out.png"))
