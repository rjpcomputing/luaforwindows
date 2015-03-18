require"imlua"
require"imlua_process"

function save_histogram (hist, filename, format)
	local height = 200 -- altura da imagem
	local max = math.max(unpack(hist)) -- pega o maior valor do histograma
	local n = table.getn(hist) + 1 -- zero-based
	local image = im.ImageCreate(n, height, im.GRAY, im.BYTE) -- cria a imagem
	local white = 255
	local black = 0

	local render = function (x, y, d, param)
		local v = hist[x] / max
		local h = v * height
		if y <= h then return black end
		return white
	end

	im.ProcessRenderOp(image, render, "histogram", {}, 0)
	image:Save(filename, format)
end

local filename = "lena.jpg"

local image = im.FileImageLoad(filename)

save_histogram(im.CalcHistogram(image, 0, 0), "lena_histogram_R.gif", "GIF")
save_histogram(im.CalcHistogram(image, 1, 0), "lena_histogram_G.gif", "GIF")
save_histogram(im.CalcHistogram(image, 2, 0), "lena_histogram_B.gif", "GIF")
save_histogram(im.CalcGrayHistogram(image, 0), "lena_histogram_gray.gif", "GIF")

local r = im.ImageCreate(image:Width(), image:Height(), im.GRAY, image:DataType())
local g = im.ImageCreate(image:Width(), image:Height(), im.GRAY, image:DataType())
local b = im.ImageCreate(image:Width(), image:Height(), im.GRAY, image:DataType())
im.ProcessSplitComponents(image, { r, g, b})
r:Save("lena_r.jpg", "JPEG")
g:Save("lena_g.jpg", "JPEG")
b:Save("lena_b.jpg", "JPEG")

local rgb = image:Clone()
im.ProcessMergeComponents({r, g, b}, rgb)
rgb:Save("lena_rgb.jpg", "JPEG")

local replace = image:Duplicate()
im.ProcessReplaceColor(image, replace, { 146, 93, 145 }, { 255, 0, 255 })
replace:Save("lena_replace.jpg", "JPEG")

local bitmask = image:Duplicate()
im.ProcessBitMask(image, bitmask, "01111010", im.BIT_XOR)
bitmask:Save("lena_bitmask.jpg", "JPEG")
