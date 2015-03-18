#!/usr/bin/env lua
-- counter.lua -- a web counter in Lua!
-- (c) 2004 Alexandre Erwin Ittner

require "gd"

datafile = "counter.txt"
fp = io.open(datafile, "r+")
if fp then
  cnt = tonumber(fp:read("*l")) or 0
  fp:seek("set", 0)
else
  cnt = 0
  fp = io.open(datafile, "w")
  assert(fp)
end
cnt = cnt + 1
fp:write(cnt .."\n")
fp:close()

sx = math.max(string.len(tostring(cnt)), 1) * 8
im = gd.create(sx, 15)
-- first allocated color defines the background.
white = im:colorAllocate(255, 255, 255)
im:colorTransparent(white)
black = im:colorAllocate(0, 0, 0)
im:string(gd.FONT_MEDIUM, 1, 1, cnt, black)

print("Content-type: image/png\n")
io.write(im:pngStr())
