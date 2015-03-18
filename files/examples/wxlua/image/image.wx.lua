--[[
///////////////////////////////////////////////////////////////////////////////
// Name:        samples/image/image.cpp
// Purpose:     sample showing operations with wxImage
// Author:      Robert Roebling
// Modified by:
// Created:     1998
// RCS-ID:      $Id: image.wx.lua,v 1.3 2008/01/22 04:45:39 jrl1 Exp $
// Copyright:   (c) 1998-2005 Robert Roebling
// License:     wxWindows licence
///////////////////////////////////////////////////////////////////////////////
--]]

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
wx = require("wx")


USE_QUITE_SLOW = true

-- A simple function to implement "cond ? A : B", eg "result = iff(cond, A, B)"
--   note all terms must be able to be evaluated
local function iff(cond, A, B) if cond then return A else return B end end

--// MyCanvas ---------------------------------------------------------------
local wx = wx
local module = module
local setmetatable = setmetatable
local require = require
local table = table
local string = string
local print = print
local USE_QUITE_SLOW = USE_QUITE_SLOW
module"MyCanvas"

--#include "smile.xbm"
local smile_width = 32
local smile_height = 32
local smile_bits = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x03, 0x00, 0x00, 0x1c, 0x1c, 0x00,
   0x00, 0x03, 0x60, 0x00, 0x80, 0x00, 0x80, 0x00, 0x60, 0x00, 0x00, 0x03,
   0x20, 0x00, 0x00, 0x04, 0x10, 0x08, 0x08, 0x04, 0x08, 0x14, 0x14, 0x08,
   0x08, 0x22, 0x22, 0x10, 0x04, 0x01, 0x40, 0x10, 0x04, 0x08, 0x08, 0x10,
   0x04, 0x08, 0x08, 0x10, 0x02, 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x20,
   0x02, 0x00, 0x00, 0x20, 0x02, 0x00, 0x00, 0x20, 0x02, 0x02, 0x20, 0x20,
   0x04, 0x0e, 0x38, 0x10, 0x04, 0x3e, 0x3e, 0x10, 0x04, 0xf4, 0x1b, 0x10,
   0x08, 0xd8, 0x0a, 0x10, 0x08, 0xb0, 0x07, 0x08, 0x10, 0xc0, 0x01, 0x04,
   0x20, 0x00, 0x00, 0x04, 0x60, 0x00, 0x00, 0x03, 0x80, 0x00, 0x80, 0x00,
   0x00, 0x03, 0x60, 0x00, 0x00, 0x1c, 0x1c, 0x00, 0x00, 0xe0, 0x03, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }

local C = string.char
smile_bits_str = {}
for i = 1, #smile_bits do
    smile_bits_str[i] = C(smile_bits[i]) -- turn into ASCII chars
end
smile_bits_str = table.concat(smile_bits_str) -- turn into a string


--#include "smile.xpm"
local smile_xpm = {
--/* columns rows colors chars-per-pixel */
"32 32 4 1",
". c Black",
"X c #FFFF00",
"  c None",
"o c #C00000",
--/* pixels */
"                                ",
"             .....              ",
"          ...XXXXX...           ",
"        ..XXXXXXXXXXX..         ",
"       .XXXXXXXXXXXXXXX.        ",
"     ..XXXXXXXXXXXXXXXXX..      ",
"     .XXXXXXXXXXXXXXXXXXXX.     ",
"    .XXXXXX.XXXXXXX.XXXXXX.     ",
"   .XXXXXX.X.XXXXX.X.XXXXXX.    ",
"   .XXXXX.XXX.XXX.XXX.XXXXXX.   ",
"  .XXXXX.XXXXXXXXXXXXX.XXXXX.   ",
"  .XXXXXXXX.XXXXXXX.XXXXXXXX.   ",
"  .XXXXXXXX.XXXXXXX.XXXXXXXX.   ",
" .XXXXXXXXXXXXXXXXXXXXXXXXXXX.  ",
" .XXXXXXXXXXXXXXXXXXXXXXXXXXX.  ",
" .XXXXXXXXXXXXXXXXXXXXXXXXXXX.  ",
" .XXXXXXXXXXXXXXXXXXXXXXXXXXX.  ",
" .XXXXXXX.XXXXXXXXXXX.XXXXXXX.  ",
"  .XXXXXX...XXXXXXX...XXXXXX.   ",
"  .XXXXXX.oo..XXX..oo.XXXXXX.   ",
"  .XXXXXXX.ooo...ooo.XXXXXXX.   ",
"   .XXXXXXX.ooooooo.XXXXXXXX.   ",
"   .XXXXXXXX..ooo..XXXXXXXX.    ",
"    .XXXXXXXXX...XXXXXXXXX.     ",
"     .XXXXXXXXXXXXXXXXXXXX.     ",
"     ..XXXXXXXXXXXXXXXXX..      ",
"       .XXXXXXXXXXXXXXX.        ",
"        ..XXXXXXXXXXX..         ",
"          ...XXXXX...           ",
"             .....              ",
"                                ",
"                                "}

local _T = function(s) return s end
local wxT = function(s) return s end

local function OnPaint(T, event )
    local dc = wx.wxPaintDC(T)
    T:PrepareDC( dc )

    dc:DrawText( _T("Loaded image"), 30, 10 )
    if (T.my_square:Ok()) then
        dc:DrawBitmap( T.my_square, 30, 30, false)
    end

    dc:DrawText( _T("Drawn directly"), 150, 10 )
    dc:SetBrush( wx.wxBrush( wxT("orange"), wx.wxSOLID ) )
    dc:SetPen( wx.wxBLACK_PEN )
    dc:DrawRectangle( 150, 30, 100, 100 )
    dc:SetBrush( wx.wxWHITE_BRUSH )
    dc:DrawRectangle( 170, 50, 60, 60 )

    if (T.my_anti:Ok()) then
        dc:DrawBitmap( T.my_anti, 280, 30, false)
    end

    dc:DrawText( _T("PNG handler"), 30, 135 )
    if (T.my_horse_png:Ok()) then
        dc:DrawBitmap( T.my_horse_png, 30, 150, false)
        local rect = wx.wxRect(0,0,100,100)
        local sub = wx.wxBitmap( T.my_horse_png:GetSubBitmap(rect) )
        dc:DrawText( _T("GetSubBitmap()"), 280, 175 )
        dc:DrawBitmap( sub, 280, 195, false)
        sub:delete()
    end

    dc:DrawText( _T("JPEG handler"), 30, 365 )
    if (T.my_horse_jpeg:Ok()) then
        dc:DrawBitmap( T.my_horse_jpeg, 30, 380, false)
    end

    dc:DrawText( _T("Green rotated to red"), 280, 365 )
    if (T.colorized_horse_jpeg:Ok()) then
        dc:DrawBitmap( T.colorized_horse_jpeg, 280, 380, false)
    end

    dc:DrawText( _T("CMYK JPEG image"), 530, 365 )
    if (T.my_cmyk_jpeg:Ok()) then
        dc:DrawBitmap( T.my_cmyk_jpeg, 530, 380, false )
    end

    dc:DrawText( _T("GIF handler"), 30, 595 )
    if (T.my_horse_gif:Ok()) then
        dc:DrawBitmap( T.my_horse_gif, 30, 610, false )
    end

    dc:DrawText( _T("PCX handler"), 30, 825 )
    if (T.my_horse_pcx:Ok()) then
        dc:DrawBitmap( T.my_horse_pcx, 30, 840, false )
    end

    dc:DrawText( _T("BMP handler"), 30, 1055 )
    if (T.my_horse_bmp:Ok()) then
        dc:DrawBitmap( T.my_horse_bmp, 30, 1070, false )
    end

    dc:DrawText( _T("BMP read from memory"), 280, 1055 )
    if (T.my_horse_bmp2:Ok()) then
        dc:DrawBitmap( T.my_horse_bmp2, 280, 1070, false )
    end

    dc:DrawText( _T("PNM handler"), 30, 1285 )
    if (T.my_horse_pnm:Ok()) then
        dc:DrawBitmap( T.my_horse_pnm, 30, 1300, false )
    end

    dc:DrawText( _T("PNM handler (ascii grey)"), 280, 1285 )
    if (T.my_horse_asciigrey_pnm:Ok()) then
        dc:DrawBitmap( T.my_horse_asciigrey_pnm, 280, 1300, false )
    end

    dc:DrawText( _T("PNM handler (raw grey)"), 530, 1285 )
    if (T.my_horse_rawgrey_pnm:Ok()) then
        dc:DrawBitmap( T.my_horse_rawgrey_pnm, 530, 1300, false )
    end

    dc:DrawText( _T("TIFF handler"), 30, 1515 )
    if (T.my_horse_tiff:Ok()) then
        dc:DrawBitmap( T.my_horse_tiff, 30, 1530, false )
    end

    dc:DrawText( _T("TGA handler"), 30, 1745 )
    if (T.my_horse_tga:Ok()) then
        dc:DrawBitmap( T.my_horse_tga, 30, 1760, false )
    end

    dc:DrawText( _T("XPM handler"), 30, 1975 )
    if (T.my_horse_xpm:Ok()) then
        dc:DrawBitmap( T.my_horse_xpm, 30, 2000, false )
    end


    --// toucans
    if T.my_toucan:Ok() then
        local x,y,yy = 750,10,170

        dc:DrawText(wxT("Original toucan"), x+50, y)
        dc:DrawBitmap(T.my_toucan, x, y+15, true)
        y = y+yy
        dc:DrawText(wxT("Flipped horizontally"), x+50, y);
        dc:DrawBitmap(T.my_toucan_flipped_horiz, x, y+15, true);
        y = y+yy
        dc:DrawText(wxT("Flipped vertically"), x+50, y);
        dc:DrawBitmap(T.my_toucan_flipped_vert, x, y+15, true);
        y = y+yy
        dc:DrawText(wxT("Flipped both h&v"), x+50, y);
        dc:DrawBitmap(T.my_toucan_flipped_both, x, y+15, true);
        y = y+yy
        dc:DrawText(wxT("In greyscale"), x+50, y);
        dc:DrawBitmap(T.my_toucan_grey, x, y+15, true);
        y = y+yy
        dc:DrawText(wxT("Toucan's head"), x+50, y);
        dc:DrawBitmap(T.my_toucan_head, x, y+15, true);
        y = y+yy
        dc:DrawText(wxT("Scaled with normal quality"), x+50, y);
        dc:DrawBitmap(T.my_toucan_scaled_normal, x, y+15, true);
        y = y+yy
        dc:DrawText(wxT("Scaled with high quality"), x+50, y);
        dc:DrawBitmap(T.my_toucan_scaled_high, x, y+15, true);
        y = y+yy
        dc:DrawText(wxT("Blured"), x+50, y);
        dc:DrawBitmap(T.my_toucan_blur, x, y+15, true);
    end

    if (T.my_smile_xbm:Ok()) then
        local x,y = 300,1800

        dc:DrawText( _T("XBM bitmap"), x, y )
        dc:DrawText( _T("(green on red)"), x, y + 15 )
        dc:SetTextForeground( wx.wxColour(_T("GREEN")) )
        dc:SetTextBackground( wx.wxColour(_T("RED")) )
        dc:DrawBitmap( T.my_smile_xbm, x, y + 30, false )

        dc:SetTextForeground( wx.wxBLACK )
        dc:DrawText( _T("After wxImage conversion"), x + 120, y )
        dc:DrawText( _T("(red on white)"), x + 120, y + 15 )
        dc:SetTextForeground( wx.wxColour(wxT("RED")) )
        local i = T.my_smile_xbm:ConvertToImage()
        i:SetMaskColour( 255, 255, 255 )
        i:Replace( 0, 0, 0,
               wx.wxRED_PEN:GetColour():Red(),
               wx.wxRED_PEN:GetColour():Green(),
               wx.wxRED_PEN:GetColour():Blue() )
        dc:DrawBitmap( wx.wxBitmap(i), x + 120, y + 30, true )
        dc:SetTextForeground( wx.wxBLACK )
    end


    local mono = wx.wxBitmap( 60,50,1 )
    local memdc = wx.wxMemoryDC()
    memdc:SelectObject( mono )
    memdc:SetPen( wx.wxBLACK_PEN )
    memdc:SetBrush( wx.wxWHITE_BRUSH )
    memdc:DrawRectangle( 0,0,60,50 )
    memdc:SetTextForeground( wx.wxBLACK )
--#ifndef __WXGTK20__
    --// I cannot convince GTK2 to draw into mono bitmaps
    memdc:DrawText( _T("Hi!"), 5, 5 )
--#endif
    memdc:SetBrush( wx.wxBLACK_BRUSH )
    memdc:DrawRectangle( 33,5,20,20 )
    memdc:SetPen( wx.wxRED_PEN )
    memdc:DrawLine( 5, 42, 50, 42 )
    memdc:SelectObject( wx.wxNullBitmap )
    memdc:delete()

    if (mono:Ok()) then
        local x,y = 300,1900

        dc:DrawText( _T("Mono bitmap"), x, y )
        dc:DrawText( _T("(red on green)"), x, y + 15 )
        dc:SetTextForeground( wx.wxRED )
        dc:SetTextBackground( wx.wxGREEN )
        dc:DrawBitmap( mono, x, y + 30, false )

        dc:SetTextForeground( wx.wxBLACK )
        dc:DrawText( _T("After wxImage conversion"), x + 120, y )
        dc:DrawText( _T("(red on white)"), x + 120, y + 15 )
        dc:SetTextForeground( wx.wxRED )
        local i = mono:ConvertToImage()
        i:SetMaskColour( 255,255,255 )
        i:Replace( 0,0,0,
               wx.wxRED_PEN:GetColour():Red(),
               wx.wxRED_PEN:GetColour():Green(),
               wx.wxRED_PEN:GetColour():Blue() )
        dc:DrawBitmap( wx.wxBitmap(i), x + 120, y + 30, true )
        dc:SetTextForeground( wx.wxBLACK )
    end
    mono:delete()

    --// For testing transparency
    dc:SetBrush( wx.wxRED_BRUSH )
    dc:DrawRectangle( 20, 2220, 560, 68 )

    dc:DrawText(_T("XPM bitmap"), 30, 2230 )
    if ( T.m_bmpSmileXpm:Ok() ) then
        dc:DrawBitmap(T.m_bmpSmileXpm, 30, 2250, true)
    end

    dc:DrawText(_T("XPM icon"), 110, 2230 )
    if ( T.m_iconSmileXpm:Ok() ) then
        dc:DrawIcon(T.m_iconSmileXpm, 110, 2250)
    end

    --// testing icon -> bitmap conversion
    --local to_blit = wx.wxBitmap( T.m_iconSmileXpm )
    local to_blit = wx.wxBitmap()
    to_blit:CopyFromIcon( T.m_iconSmileXpm )
    if (to_blit:Ok()) then
        dc:DrawText( _T("SubBitmap"), 170, 2230 )
        local sub = to_blit:GetSubBitmap( wx.wxRect(0,0,15,15) )
        if (sub:Ok()) then
            dc:DrawBitmap( sub, 170, 2250, true )
        end
        sub:delete()

        dc:DrawText( _T("Enlarged"), 250, 2230 )
        dc:SetUserScale( 1.5, 1.5 )
        dc:DrawBitmap( to_blit, (250/1.5), (2250/1.5), true )
        dc:SetUserScale( 2, 2 )
        dc:DrawBitmap( to_blit, (300/2), (2250/2), true )
        dc:SetUserScale( 1.0, 1.0 )

        dc:DrawText( _T("Blit"), 400, 2230)
        local blit_dc = wx.wxMemoryDC()
        blit_dc:SelectObject( to_blit )
        dc:Blit( 400, 2250, to_blit:GetWidth(), to_blit:GetHeight(), blit_dc, 0, 0, wx.wxCOPY, true )
        dc:SetUserScale( 1.5, 1.5 )
        dc:Blit( (450/1.5), (2250/1.5), to_blit:GetWidth(), to_blit:GetHeight(), blit_dc, 0, 0, wx.wxCOPY, true )
        dc:SetUserScale( 2, 2 )
        dc:Blit( (500/2), (2250/2), to_blit:GetWidth(), to_blit:GetHeight(), blit_dc, 0, 0, wx.wxCOPY, true )
        dc:SetUserScale( 1.0, 1.0 )
        blit_dc:SelectObject( wx.wxNullBitmap )
        blit_dc:delete()
    end
    to_blit:delete()

    dc:DrawText( _T("ICO handler (1st image)"), 30, 2290 )
    if (T.my_horse_ico32:Ok()) then
        dc:DrawBitmap( T.my_horse_ico32, 30, 2330, true )
    end

    dc:DrawText( _T("ICO handler (2nd image)"), 230, 2290 )
    if (T.my_horse_ico16:Ok()) then
        dc:DrawBitmap( T.my_horse_ico16, 230, 2330, true )
    end

    dc:DrawText( _T("ICO handler (best image)"), 430, 2290 )
    if (T.my_horse_ico:Ok()) then
        dc:DrawBitmap( T.my_horse_ico, 430, 2330, true )
    end

    dc:DrawText( _T("CUR handler"), 30, 2390 )
    if (T.my_horse_cur:Ok()) then
        dc:DrawBitmap( T.my_horse_cur, 30, 2420, true )
        dc:SetPen (wx.wxRED_PEN)
        dc:DrawLine (T.xH-10,T.yH,T.xH+10,T.yH)
        dc:DrawLine (T.xH,T.yH-10,T.xH,T.yH+10)
    end

    dc:DrawText( _T("ANI handler"), 230, 2390 )
    for i=0, T.m_ani_images-1 do
        if (T.my_horse_ani[i]:Ok()) then
            dc:DrawBitmap( T.my_horse_ani[i], 230 + i * 2 * T.my_horse_ani[i]:GetWidth() , 2420, true )
        end
    end

    dc:delete()
end

local function CreateAntiAliasedBitmap(T)
    local bitmap = wx.wxBitmap( 300, 300 )
    local dc = wx.wxMemoryDC()
    dc:SelectObject( bitmap )
    dc:Clear()

    dc:SetFont( wx.wxFont( 24, wx.wxDECORATIVE, wx.wxNORMAL, wx.wxNORMAL) )
    dc:SetTextForeground( wx.wxRED )
    dc:DrawText( _T("This is anti-aliased Text."), 20, 5 )
    dc:DrawText( _T("And a Rectangle."), 20, 45 )

    dc:SetBrush( wx.wxRED_BRUSH )
    dc:SetPen( wx.wxTRANSPARENT_PEN )
    dc:DrawRoundedRectangle( 20, 85, 200, 180, 20 )

    local original= bitmap:ConvertToImage()
    local anti = wx.wxImage( 150, 150 )

    --/* This is quite slow, but safe. Use wxImage::GetData() for speed instead. */
    if USE_QUITE_SLOW then

    local orig_data = original:GetData() -- get the data as a RGBRGB.. string
    local w = original:GetWidth()

    for y = 1, 149-1 do
        for x = 1, 149-1 do

            local red, green, blue = 0, 0, 0

            if false then
                red = original:GetRed( x*2, y*2 ) +
                      original:GetRed( x*2-1, y*2 ) +
                      original:GetRed( x*2, y*2+1 ) +
                      original:GetRed( x*2+1, y*2+1 )
                red = red/4

                green = original:GetGreen( x*2, y*2 ) +
                        original:GetGreen( x*2-1, y*2 ) +
                        original:GetGreen( x*2, y*2+1 ) +
                        original:GetGreen( x*2+1, y*2+1 )
                green = green/4

                blue = original:GetBlue( x*2, y*2 ) +
                       original:GetBlue( x*2-1, y*2 ) +
                       original:GetBlue( x*2, y*2+1 ) +
                       original:GetBlue( x*2+1, y*2+1 )
                blue = blue/4
            else
                local i1 = ((x*2  ) + (y*2  )*w)*3 + 1 -- +1 for Lua string starting at 1
                local i2 = ((x*2-1) + (y*2  )*w)*3 + 1
                local i3 = ((x*2  ) + (y*2+1)*w)*3 + 1
                local i4 = ((x*2+1) + (y*2+1)*w)*3 + 1

                red   = string.byte(orig_data, i1  ) +
                        string.byte(orig_data, i2  ) +
                        string.byte(orig_data, i3  ) +
                        string.byte(orig_data, i4  )
                green = string.byte(orig_data, i1+1) +
                        string.byte(orig_data, i2+1) +
                        string.byte(orig_data, i3+1) +
                        string.byte(orig_data, i4+1)
                blue  = string.byte(orig_data, i1+2) +
                        string.byte(orig_data, i2+2) +
                        string.byte(orig_data, i3+2) +
                        string.byte(orig_data, i4+2)

                red   = red/4
                green = green/4
                blue  = blue/4
            end

            anti:SetRGB( x, y, red, green, blue )
        end
    end
    end
    T.my_anti = wx.wxBitmap(anti)

    original:delete()
    anti:delete()

    dc:delete()
    bitmap:delete()
end

local function create(parent, id, pos, size)
    local this = wx.wxScrolledWindow( parent, id, pos, size, wx.wxSUNKEN_BORDER )

    this.my_horse_png = wx.wxNullBitmap
    this.my_horse_jpeg = wx.wxNullBitmap
    this.my_horse_gif = wx.wxNullBitmap
    this.my_horse_bmp = wx.wxNullBitmap
    this.my_horse_bmp2 = wx.wxNullBitmap
    this.my_horse_pcx = wx.wxNullBitmap
    this.my_horse_pnm = wx.wxNullBitmap
    this.my_horse_tiff = wx.wxNullBitmap
    this.my_horse_tga = wx.wxNullBitmap
    this.my_horse_xpm = wx.wxNullBitmap
    this.my_horse_ico32 = wx.wxNullBitmap
    this.my_horse_ico16 = wx.wxNullBitmap
    this.my_horse_ico = wx.wxNullBitmap
    this.my_horse_cur = wx.wxNullBitmap
    this.my_smile_xbm = wx.wxNullBitmap
    this.my_square = wx.wxNullBitmap
    this.my_anti = wx.wxNullBitmap
    this.my_horse_asciigrey_pnm = wx.wxNullBitmap
    this.my_horse_rawgrey_pnm = wx.wxNullBitmap
    this.colorized_horse_jpeg = wx.wxNullBitmap
    this.my_cmyk_jpeg = wx.wxNullBitmap
    this.my_toucan = wx.wxNullBitmap
    this.my_toucan_flipped_horiz = wx.wxNullBitmap
    this.my_toucan_flipped_vert = wx.wxNullBitmap
    this.my_toucan_flipped_both = wx.wxNullBitmap
    this.my_toucan_grey = wx.wxNullBitmap
    this.my_toucan_head = wx.wxNullBitmap
    this.my_toucan_scaled_normal = wx.wxNullBitmap
    this.my_toucan_scaled_high = wx.wxNullBitmap
    this.my_toucan_blur = wx.wxNullBitmap

    this.m_bmpSmileXpm = wx.wxBitmap(smile_xpm)
    --this.m_iconSmileXpm = wx.wxIcon(smile_xpm)
    this.m_iconSmileXpm = wx.wxIcon()
    this.m_iconSmileXpm:CopyFromBitmap(this.m_bmpSmileXpm)

    this.my_horse_ani = {}
    this.m_ani_images = 0
    this.xH = 0
    this.yH = 0

    this.OnPaint = OnPaint
    this.CreateAntiAliasedBitmap = CreateAntiAliasedBitmap

    this:SetBackgroundColour(wx.wxWHITE)

    local bitmap = wx.wxBitmap( 100, 100 )

    local dc = wx.wxMemoryDC()
    dc:SelectObject( bitmap )
    dc:SetBrush( wx.wxBrush( "orange", wx.wxSOLID ) )
    dc:SetPen( wx.wxBLACK_PEN )
    dc:DrawRectangle( 0, 0, 100, 100 )
    dc:SetBrush( wx.wxWHITE_BRUSH )
    dc:DrawRectangle( 20, 20, 60, 60 )
    dc:SelectObject( wx.wxNullBitmap )
    dc:delete()

    --// try to find the directory with our images
    local dir
    if ( wx.wxFile.Exists("horse.png") ) then
        dir = ""
    elseif ( wx.wxFile.Exists("./image/horse.png") ) then
        dir = "./image/"
    elseif ( wx.wxFile.Exists("./samples/image/horse.png") ) then
        dir = "./samples/image/"
    elseif ( wx.wxFile.Exists("../samples/image/horse.png") ) then
        dir = "../samples/image/"
    elseif ( wx.wxFile.Exists("../../samples/image/horse.png") ) then
        dir = "../../samples/image/"
    else
        --wx.wxLogWarning("Can't find image files in either '.' or '..'!")
    end

    while (dir == nil) do
        dir = wx.wxDirSelector("Select path to image sample files, e.g. 'wxLua/samples/image/horse.png'", "", wx.wxDD_DIR_MUST_EXIST, wx.wxDefaultPosition, parent)
        if (dir == "") then
            parent:Close()
            return this
        end

        dir = dir.."/"

        if ( not wx.wxFile.Exists(dir.."horse.png") ) then
            dir = nil
        end
    end

    local image = bitmap:ConvertToImage()


--if wx.wxUSE_LIBPNG then
    if ( not image:SaveFile( dir .. "test.png", wx.wxBITMAP_TYPE_PNG )) then
        wx.wxLogError("Can't save file")
    end

    image:Destroy()

    if ( image:LoadFile( dir .. "test.png" ) ) then
        this.my_square = wx.wxBitmap( image )
    end

    image:Destroy();

    if ( not image:LoadFile( dir .. "horse.png") ) then
        wx.wxLogError("Can't load PNG image")
    else
        this.my_horse_png = wx.wxBitmap( image )
    end

    if ( not image:LoadFile( dir .. "toucan.png" )) then
        wx.wxLogError("Can't load PNG image")
    else
        this.my_toucan = wx.wxBitmap(image)
    end

    this.my_toucan_flipped_horiz = wx.wxBitmap(image:Mirror(true))
    this.my_toucan_flipped_vert = wx.wxBitmap(image:Mirror(false))
    this.my_toucan_flipped_both = wx.wxBitmap(image:Mirror(true):Mirror(false))
    this.my_toucan_grey = wx.wxBitmap(image:ConvertToGreyscale())
    this.my_toucan_head = wx.wxBitmap(image:GetSubImage(wx.wxRect(40, 7, 80, 60)))
    this.my_toucan_scaled_normal = wx.wxBitmap(image:Scale(110,90,wx.wxIMAGE_QUALITY_NORMAL))
    this.my_toucan_scaled_high = wx.wxBitmap(image:Scale(110,90,wx.wxIMAGE_QUALITY_HIGH))
    this.my_toucan_blur = wx.wxBitmap(image:Blur(10))

--end --// wxUSE_LIBPNG

--if wx.wxUSE_LIBJPEG then
    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.jpg") ) then
        wx.wxLogError("Can't load JPG image")
    else
        this.my_horse_jpeg = wx.wxBitmap( image )

        --// Colorize by rotating green hue to red
        --local greenHSV = wx.wxImage:RGBtoHSV(wx.wxImage:RGBValue(0, 255, 0))
        local gh,gs,gv = wx.wxImage:RGBtoHSV(0, 255, 0)
        --local redHSV = wx.wxImage:RGBtoHSV(wx.wxImage:RGBValue(255, 0, 0))
        local rh,rs,rv = wx.wxImage:RGBtoHSV(255, 0, 0)
        --image:RotateHue(redHSV.hue - greenHSV.hue)
        image:RotateHue(rh - gh)
        this.colorized_horse_jpeg = wx.wxBitmap( image )
    end

    if ( not image:LoadFile( dir .. "cmyk.jpg") ) then
        wx.wxLogError("Can't load CMYK JPG image")
    else
        this.my_cmyk_jpeg = wx.wxBitmap(image)
    end
--end --// wxUSE_LIBJPEG

--if wx.wxUSE_GIF then
    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.gif") ) then
        wx.wxLogError("Can't load GIF image")
    else
        this.my_horse_gif = wx.wxBitmap( image )
    end
--end --// wx.wxUSE_GIF

--if wx.wxUSE_PCX then
    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.pcx", wx.wxBITMAP_TYPE_PCX ) ) then
        wx.wxLogError("Can't load PCX image")
    else
        this.my_horse_pcx = wx.wxBitmap( image )
    end
--end --// wx.wxUSE_PCX

    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.bmp", wx.wxBITMAP_TYPE_BMP ) ) then
        wx.wxLogError("Can't load BMP image")
    else
        this.my_horse_bmp = wx.wxBitmap( image )
    end

--if wx.wxUSE_XPM then
    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.xpm", wx.wxBITMAP_TYPE_XPM ) ) then
        wx.wxLogError("Can't load XPM image")
    else
        this.my_horse_xpm = wx.wxBitmap( image )
    end

    if ( not image:SaveFile( dir .. "test.xpm", wx.wxBITMAP_TYPE_XPM )) then
        wx.wxLogError("Can't save file")
    end
--end --// wx.wxUSE_XPM

--if wx.wxUSE_PNM then
    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.pnm", wx.wxBITMAP_TYPE_PNM ) ) then
        wx.wxLogError("Can't load PNM image")
    else
        this.my_horse_pnm = wx.wxBitmap( image )
    end

    image:Destroy()

    if ( not image:LoadFile( dir .. "horse_ag.pnm", wx.wxBITMAP_TYPE_PNM ) ) then
        wx.wxLogError("Can't load PNM image")
    else
        this.my_horse_asciigrey_pnm = wx.wxBitmap( image )
    end

    image:Destroy()

    if ( not image:LoadFile( dir .. "horse_rg.pnm", wx.wxBITMAP_TYPE_PNM ) ) then
        wx.wxLogError("Can't load PNM image")
    else
        this.my_horse_rawgrey_pnm = wx.wxBitmap( image )
    end
--end --// wx.wxUSE_PNM

--if wx.wxUSE_LIBTIFF then
    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.tif", wx.wxBITMAP_TYPE_TIF ) ) then
        wx.wxLogError("Can't load TIFF image")
    else
        this.my_horse_tiff = wx.wxBitmap( image )
    end
--end --// wx.wxUSE_LIBTIFF

--if wx.wxUSE_LIBTIFF then
    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.tga", wx.wxBITMAP_TYPE_TGA ) ) then
        wx.wxLogError("Can't load TGA image")
    else
        this.my_horse_tga = wx.wxBitmap( image )
    end
--end --// wx.wxUSE_LIBTIFF

    this:CreateAntiAliasedBitmap()

    this.my_smile_xbm = wx.wxBitmap( smile_bits_str, smile_width,
                                 smile_height, 1 )
    this.my_smile_xbm = wx.wxBitmap( smile_bits, smile_width,
                                 smile_height, 1 )

    --// demonstrates XPM automatically using the mask when saving
    if ( this.m_bmpSmileXpm:Ok() ) then
        this.m_bmpSmileXpm:SaveFile(dir .. "saved.xpm", wx.wxBITMAP_TYPE_XPM)
    end

--if wx.wxUSE_ICO_CUR then
    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.ico", wx.wxBITMAP_TYPE_ICO, 0 ) ) then
        wx.wxLogError("Can't load first ICO image")
    else
        this.my_horse_ico32 = wx.wxBitmap( image )
    end

    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.ico", wx.wxBITMAP_TYPE_ICO, 1 ) ) then
        wx.wxLogError("Can't load second ICO image")
    else
        this.my_horse_ico16 = wx.wxBitmap( image )
    end

    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.ico" ) ) then
        wx.wxLogError("Can't load best ICO image")
    else
        this.my_horse_ico = wx.wxBitmap( image )
    end

    image:Destroy()

    if ( not image:LoadFile( dir .. "horse.cur", wx.wxBITMAP_TYPE_CUR ) ) then
        wx.wxLogError("Can't load best ICO image")
    else
        this.my_horse_cur = wx.wxBitmap( image )
        this.xH = 30 + image:GetOptionInt(wx.wxIMAGE_OPTION_CUR_HOTSPOT_X)
        this.yH = 2420 + image:GetOptionInt(wx.wxIMAGE_OPTION_CUR_HOTSPOT_Y)
    end

    this.m_ani_images = wx.wxImage.GetImageCount ( dir .. "horse3.ani", wx.wxBITMAP_TYPE_ANI )
    if (this.m_ani_images==0) then
        wx.wxLogError("No ANI-format images found")
    else
        this.my_horse_ani = {}
    end

    for i=0, this.m_ani_images-1 do
        image:Destroy()
        if (not image:LoadFile( dir .. "horse3.ani", wx.wxBITMAP_TYPE_ANI, i )) then
            local tmp = "Can't load image number " .. tostring(i)
            wx.wxLogError(tmp)
        else
            this.my_horse_ani [i] = wx.wxBitmap( image )
        end
    end
--end --// wxUSE_ICO_CUR

    image:Destroy()

    --// test image loading from stream
    local file = wx.wxFile(dir .. "horse.bmp")
    if ( file:IsOpened() ) then
        local len = file:Length()
        local dataSize = len

        local read_count, data = file:Read(dataSize)
        if ( read_count ~= len ) then
            wx.wxLogError(_T("Reading bitmap file failed"));
        else
            local mis = wx.wxMemoryInputStream(data, dataSize);
            if ( not image:LoadFile(mis) ) then
                wx.wxLogError(wxT("Can't load BMP image from stream"));
            else
                this.my_horse_bmp2 = wx.wxBitmap( image );
            end
        end
    end


    this:Connect(wx.wxEVT_PAINT, function(event) this:OnPaint(event) end)

    return this
end

function __call(self, ...)
    return create(...)
end
setmetatable(_M, _M)


--// MyImageFrame -----------------------------------------------------------
local wx = wx
local module = module
local setmetatable = setmetatable
local require = require
module"MyImageFrame"


local function OnSave(T, event)
--if wx.wxUSE_FILEDLG then
    local image = T.m_bitmap:ConvertToImage()

    local savefilename = wx.wxFileSelector( "Save Image",
                                            "", --wx.wxEmptyString,
                                            "", --wx.wxEmptyString,
                                            "",
                                            "BMP files (*.bmp)|*.bmp|"..
                                            "PNG files (*.png)|*.png|"..
                                            "JPEG files (*.jpg)|*.jpg|"..
                                            "GIF files (*.gif)|*.gif|"..
                                            "TIFF files (*.tif)|*.tif|"..
                                            "PCX files (*.pcx)|*.pcx|"..
                                            "ICO files (*.ico)|*.ico|"..
                                            "CUR files (*.cur)|*.cur",
                                            wx.wxFD_SAVE,
                                            T)

    if ( savefilename == "" ) then
        return
    end

    local path, name, extension = wx.wxFileName.SplitPath(savefilename)

    local saved = false
    if ( extension == "bmp" ) then
        local bppvalues =
        {
            wx.wxBMP_1BPP,
            wx.wxBMP_1BPP_BW,
            wx.wxBMP_4BPP,
            wx.wxBMP_8BPP,
            wx.wxBMP_8BPP_GREY,
            wx.wxBMP_8BPP_RED,
            wx.wxBMP_8BPP_PALETTE,
            wx.wxBMP_24BPP,
        }

        local bppchoices =
        {
            "1 bpp color",
            "1 bpp B&W",
            "4 bpp color",
            "8 bpp color",
            "8 bpp greyscale",
            "8 bpp red",
            "8 bpp own palette",
            "24 bpp",
        }

        local bppselection = wx.wxGetSingleChoiceIndex("Set BMP BPP",
                                                  "Image sample: save file",
                                                  bppchoices,
                                                  T)
        if ( bppselection ~= -1 ) then
            local formatt = bppvalues[bppselection]
            image:SetOption(wx.wxIMAGE_OPTION_BMP_FORMAT, formatt)

            if ( formatt == wx.wxBMP_8BPP_PALETTE ) then
                local cmap = "" --string.rep(256," ")
                for i = 0, 256-1 do
                    cmap = cmap .. string.byte(i)
                end
                image:SetPalette(wx.wxPalette(256, cmap, cmap, cmap))
            end
        end
    elseif ( extension == "png" ) then
        local pngvalues =
        {
            wx.wxPNG_TYPE_COLOUR,
            wx.wxPNG_TYPE_COLOUR,
            wx.wxPNG_TYPE_GREY,
            wx.wxPNG_TYPE_GREY,
            wx.wxPNG_TYPE_GREY_RED,
            wx.wxPNG_TYPE_GREY_RED,
        }

        local pngchoices =
        {
            "Colour 8bpp",
            "Colour 16bpp",
            "Grey 8bpp",
            "Grey 16bpp",
            "Grey red 8bpp",
            "Grey red 16bpp",
        }

        local sel = wx.wxGetSingleChoiceIndex("Set PNG format",
                                         "Image sample: save file",
                                         pngchoices,
                                         T)
        if ( sel ~= -1 ) then
            image:SetOption(wx.wxIMAGE_OPTION_PNG_FORMAT, pngvalues[sel])
            image:SetOption(wx.wxIMAGE_OPTION_PNG_BITDEPTH, iff(sel % 2, 16, 8))
        end
    elseif ( extension == "cur" ) then
        image:Rescale(32,32)
        image:SetOption(wx.wxIMAGE_OPTION_CUR_HOTSPOT_X, 0)
        image:SetOption(wx.wxIMAGE_OPTION_CUR_HOTSPOT_Y, 0)
        --// This shows how you can save an image with explicitly
        --// specified image format:
        saved = image:SaveFile(savefilename, wx.wxBITMAP_TYPE_CUR)
    end

    if ( not saved ) then
        --// This one guesses image format from filename extension
        --// (it may fail if the extension is not recognized):
        image:SaveFile(savefilename)
    end
--end --// wx.wxUSE_FILEDLG
end

local function OnPaint(T, event)
    local dc = wx.wxPaintDC(T)
    dc:DrawBitmap( T.m_bitmap, 0, 0, true --[[/* use mask */]] )
    dc:delete()
end

local function create(parent, bitmap)
    local this = wx.wxFrame(parent, wx.wxID_ANY, "Double click to save",
                  wx.wxDefaultPosition, wx.wxDefaultSize,
                  wx.wxCAPTION + wx.wxSYSTEM_MENU + wx.wxCLOSE_BOX)

    this.m_bitmap = bitmap
    this.OnPaint = OnPaint
    this.OnSave = OnSave

    this:Connect(wx.wxEVT_ERASE_BACKGROUND, function(event)
        --// do nothing here to be able to see how transparent images are shown
    end )
    this:Connect(wx.wxEVT_PAINT, function(event) this:OnPaint(event) end)
    this:Connect(wx.wxEVT_LEFT_DCLICK, function(event) this:OnSave(event) end)

    this:SetClientSize(bitmap:GetWidth(), bitmap:GetHeight())
    return this
end

function __call(self, ...)
    return create(...)
end
setmetatable(_M, _M)


--// MyRawBitmapFrame -------------------------------------------------------
if wx.wxHAVE_RAW_BITMAP then

local wx = wx
local module = module
local setmetatable = setmetatable
local require = require
module"MyRawBitmapFrame"

local BORDER = 15
local SIZE = 150
local REAL_SIZE = SIZE - 2*BORDER

local function InitAlphaBitmap(T)
--[[FIXME
    --// First, clear the whole bitmap by making it alpha
    do
        local data = wx.wxAlphaPixelData( T.m_alphaBitmap, wx.wxPoint(0,0), wx.wxSize(SIZE, SIZE) )
        if ( not data ) then
            wx.wxLogError("Failed to gain raw access to bitmap data")
            return
        end
        data:UseAlpha()
        local p = wx.wxAlphaPixelData.Iterator(data)
        for y = 0, SIZE-1 do
            local rowStart = p
            for x = 0, SIZE-1 do
                p.Alpha() = 0
                -- ++p; // same as p.OffsetX(1)
            end
            p = rowStart
            p.OffsetY(data, 1)
        end
    end

    --// Then, draw colourful alpha-blended stripes
    local data = wx.wxAlphaPixelData(T.m_alphaBitmap, wx.wxPoint(BORDER, BORDER),
                          wx.wxSize(REAL_SIZE, REAL_SIZE))
    if ( not data ) then
        wx.wxLogError("Failed to gain raw access to bitmap data")
        return
    end

    data.UseAlpha()
    local p = wx.wxAlphaPixelData.Iterator(data)

    for y = 0, REAL_SIZE-1 do
        wxAlphaPixelData::Iterator rowStart = p;

        int r = y < REAL_SIZE/3 ? 255 : 0,
            g = (REAL_SIZE/3 <= y) && (y < 2*(REAL_SIZE/3)) ? 255 : 0,
            b = 2*(REAL_SIZE/3) <= y ? 255 : 0;

        for x = 0, REAL_SIZE-1 do
            --// note that RGB must be premultiplied by alpha
            local a = (wxAlphaPixelData::Iterator::ChannelType)((x*255.)/REAL_SIZE)
            p.Red() = r * a / 256
            p.Green() = g * a / 256
            p.Blue() = b * a / 256
            p.Alpha() = a

            --FIXME ++p; --// same as p.OffsetX(1)
        end

        p = rowStart
        p.OffsetY(data, 1)
    end
--]]
end

local function InitBitmap(T)
    --// draw some colourful stripes without alpha
    local data = wx.wxNativePixelData(T.m_bitmap)
    if ( not data ) then
        wx.wxLogError("Failed to gain raw access to bitmap data")
        return
    end

    local p = wx.wxNativePixelData.Iterator(data)
    for y = 0, SIZE-1 do
        local rowStart = p

        local r = iff(y < SIZE/3, 255, 0)
        local g = iff((SIZE/3 <= y) and (y < 2*(SIZE/3)), 255, 0)
        local b = iff(2*(SIZE/3) <= y, 255, 0)

        for x = 0, SIZE-1 do
            p.Red = r
            p.Green = g
            p.Blue = b
            --FIXME ++p; // same as p.OffsetX(1)
        end

        p = rowStart
        p.OffsetY(data, 1)
    end
end

local function OnPaint(T, event)
    local dc = wx.wxPaintDC(T)
    dc:DrawText("This is alpha and raw bitmap test", 0, BORDER)
    dc:DrawText("This is alpha and raw bitmap test", 0, SIZE/2 - BORDER)
    dc:DrawText("This is alpha and raw bitmap test", 0, SIZE - 2*BORDER)
    dc:DrawBitmap( m_alphaBitmap, 0, 0, true --[[/* use mask */]] )

    dc:DrawText("Raw bitmap access without alpha", 0, SIZE+5)
    dc:DrawBitmap( m_bitmap, 0, SIZE+5+dc:GetCharHeight(), false)
    dc:delete()
end


local function create(parent)
    local this = wx.wxFrame(parent, wx.wxID_ANY, "Raw bitmaps (how exciting)")

    this.m_bitmap = wx.wxBitmap(SIZE, SIZE, 24)
    this.m_alphaBitmap = wx.wxBitmap(SIZE, SIZE, 32)
    this.InitAlphaBitmap = InitAlphaBitmap
    this.InitBitmap = InitBitmap
    this.OnPaint = OnPaint
    this:Connect(wx.wxEVT_PAINT, function(event) this:OnPaint(event) end)

    this:SetClientSize(SIZE, SIZE*2+25)
    this:InitAlphaBitmap()
    this:InitBitmap()
    return this
end

function __call(self, ...)
    return create(...)
end
setmetatable(_M, _M)

end --// wx.wxHAVE_RAW_BITMAP


--// MyFrame ----------------------------------------------------------------
local wx = wx
local module = module
local setmetatable = setmetatable
local require = require
module"MyFrame"
local MyCanvas = require"MyCanvas"
local MyImageFrame = require"MyImageFrame"
if wx.wxHAVE_RAW_BITMAP then
local MyRawBitmapFrame = require"MyRawBitmapFrame"
end
local ID_QUIT  = wx.wxID_EXIT
local ID_ABOUT = wx.wxID_ABOUT
local ID_NEW = 100
local ID_SHOWRAW = 101

local function OnAbout(T, event)
  wx.wxMessageBox( "wxImage demo\n"..
                    "Robert Roebling (c) 1998,2000",
                    "About wxImage Demo", wx.wxICON_INFORMATION + wx.wxOK )
end

local function OnNewFrame(T, event)
--if wx.wxUSE_FILEDLG then
    local filename = wx.wxFileSelector("Select image file")
    if ( not filename ) then
        return
    end

    local image = wx.wxImage()
    if ( not image:LoadFile(filename) ) then
        wx.wxLogError("Couldn't load image from '%s'.", filename)
        return
    end

    MyImageFrame(T, wx.wxBitmap(image)):Show()
--end --// wxUSE_FILEDLG
end

if wx.wxHAVE_RAW_BITMAP then
local function OnTestRawBitmap(T, event)
    MyRawBitmapFrame(T):Show()
end
end --// wx.wxHAVE_RAW_BITMAP

local function OnQuit(T, event)
    T:Close( true )
end

--if wx.wxUSE_CLIPBOARD then
local function OnCopy(T, event)
    local dobjBmp = wx.wxBitmapDataObject()
    dobjBmp:SetBitmap(T.m_canvas.my_horse_png)

    local clipboard = wx.wxClipboard.Get()
    if not clipboard then
        wx.wxLogError("Failed to open clipboard")
        return
    end
    clipboard:Open()

    if ( not clipboard:SetData(dobjBmp) ) then
        wx.wxLogError("Failed to copy bitmap to clipboard")
    end

    clipboard:Close()
end

local function OnPaste(T, event)
    local dobjBmp = wx.wxBitmapDataObject()

    local clipboard = wx.wxClipboard.Get()
    if not clipboard then
        wx.wxLogError("Failed to open clipboard")
        return
    end
    clipboard:Open()
    if ( not clipboard:GetData(dobjBmp) ) then
        wx.wxLogMessage("No bitmap data in the clipboard")
    else
        MyImageFrame(T, dobjBmp:GetBitmap()):Show()
    end
    clipboard:Close()
end
--end --// wx.wxUSE_CLIPBOARD


local function create()
    local this = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxImage sample",
                  wx.wxPoint(20, 20), wx.wxSize(950, 700))

    this.OnAbout = OnAbout
    this.OnQuit = OnQuit
    this.OnNewFrame = OnNewFrame
if wx.wxHAVE_RAW_BITMAP then                -- FIXME add wxPixelData
    this.OnTestRawBitmap = OnTestRawBitmap
end --// wxHAVE_RAW_BITMAP
--if wx.wxUSE_CLIPBOARD then
    this.OnCopy = OnCopy
    this.OnPaste = OnPaste
--end --// wx.wxUSE_CLIPBOARD

    this:Connect(ID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) this:OnAbout(event) end)
    this:Connect(ID_QUIT, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) this:OnQuit(event) end)
    this:Connect(ID_NEW, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) this:OnNewFrame(event) end)
if wx.wxHAVE_RAW_BITMAP then
    this:Connect(ID_SHOWRAW, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) this:OnTestRawBitmap(event) end)
end
--if wx.wxUSE_CLIPBOARD then
    this:Connect(wx.wxID_COPY, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) this:OnCopy(event) end)
    this:Connect(wx.wxID_PASTE, wx.wxEVT_COMMAND_MENU_SELECTED, function(event) this:OnPaste(event) end)
--end --// wxUSE_CLIPBOARD

    local menu_bar = wx.wxMenuBar()

    local menuImage = wx.wxMenu()
    menuImage:Append( ID_NEW, "&Show any image...\tCtrl-O")

if wx.wxHAVE_RAW_BITMAP then
    menuImage:Append( ID_SHOWRAW, "Test &raw bitmap...\tCtrl-R")
end
    menuImage:AppendSeparator()
    menuImage:Append( ID_ABOUT, "&About...")
    menuImage:AppendSeparator()
    menuImage:Append( ID_QUIT, "E&xit\tCtrl-Q")
    menu_bar:Append(menuImage, "&Image")

--if wx.wxUSE_CLIPBOARD then
    local menuClipboard = wx.wxMenu()
    menuClipboard:Append(wx.wxID_COPY, "&Copy test image\tCtrl-C")
    menuClipboard:Append(wx.wxID_PASTE, "&Paste image\tCtrl-V")
    menu_bar:Append(menuClipboard, "&Clipboard")
--end --// wxUSE_CLIPBOARD

    this:SetMenuBar( menu_bar )

--if wx.wxUSE_STATUSBAR then
    this:CreateStatusBar(2)
    --local widths = { -1, 100 }
    --this:SetStatusWidths( 2, widths )
    this:SetStatusWidths({ -1, 100 })
--end --// wxUSE_STATUSBAR

    this.m_canvas = MyCanvas( this, wx.wxID_ANY, wx.wxPoint(0,0), wx.wxSize(10,10) )
    --// 500 width * 2750 height
    this.m_canvas:SetScrollbars( 10, 10, 50, 275 )

    return this
end

function __call(self, ...)
    return create(...)
end
setmetatable(_M, _M)



--// MyApp ------------------------------------------------------------------
local wx = wx
local module = module
local setmetatable = setmetatable
local require = require
module"MyApp"
local MyFrame = require"MyFrame"

local function OnInit(T)
    local frame = MyFrame()
    frame:Show( true )
    return true
end

local function create()
    local this = wx.wxGetApp()
    if not OnInit(this) then return nil end
    return this
end

function __call(self, ...)
    return create(...)
end
setmetatable(_M, _M)


-- // main program ----------------------------------------------------------
local require = require
local MyApp = require"MyApp"
MyApp():MainLoop()
-- EOF ----------------------------------------------------------------------


