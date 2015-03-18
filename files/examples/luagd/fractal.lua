#!/usr/bin/env lua

-- Draws the famous Sierpinski triangle with lua-gd

require "gd"

size = 500

im = gd.createPalette(size, size)
white = im:colorAllocate(255, 255, 255)
black = im:colorAllocate(0, 0, 0)

m = {}
m[math.floor(size/2)] = true

for i = 1, size do
  n = {}
  for j = 1, size do
    if m[j] then
      im:setPixel(j, i, black)
      n[j+1] = not n[j+1]
      n[j-1] = not n[j-1]
    end
  end
  m = n
end

im:png("out.png")
os.execute("out.png")

