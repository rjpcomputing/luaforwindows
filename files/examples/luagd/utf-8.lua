#!/usr/bin/env lua
-- -*- coding: utf-8 -*-

-- UTF-8 encoded unicode text. You must use an UTF-8 compatible text editor
-- to change this and a compatible Unicode font (FreeSerif is a good one).
--
-- WARNING: Windows Notepad will add some prefixes, making this file an
-- invalid Lua script.

require "gd"

local text = [[
⌠ ☾ Lua-GD
⌡ Unicode/UTF-8
↺↻⇒✇☢☣☠
♜♞♝♛♚♝♞♜
♟♟♟♟♟♟♟♟
♙♙♙♙♙♙♙♙
♖♘♗♕♔♗♘♖
]]

local fontname = "FreeSerif"    -- Common on Unix systems
-- local fontname = "Arial Unicode" -- Common on Windows systems

gd.useFontConfig(true)

im = gd.createTrueColor(180, 180)
white = im:colorAllocate(255, 255, 255)
black = im:colorAllocate(0, 0, 0)
x, y = im:sizeXY()
im:filledRectangle(0, 0, x, y, white)
im:stringFT(black, fontname, 16, 0, 10, 30, text)

im:png("utf-8.png")
os.execute("utf-8.png")
