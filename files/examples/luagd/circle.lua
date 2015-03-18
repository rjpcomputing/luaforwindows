#!/usr/bin/env lua

require "gd"

im = gd.createTrueColor(100, 100)

white = im:colorAllocate(255, 255, 255)
blue = im:colorAllocate(0, 0, 255)

im:filledRectangle(0, 0, 100, 100, white)
im:stringFTCircle(50, 50, 40, 10, 0.9, "./Vera.ttf", 24, "Powered", "by Lua", blue)

im:png("out.png")
os.execute("out.png")
