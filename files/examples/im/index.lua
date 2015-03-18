require"imlua"

local filename = "lena.jpg"
local image = im.FileImageLoad(filename)

local r = image[0]
local g = image[1]
local b = image[2]

for row = 0, image:Height() - 1, 10 do
	for column = 0, image:Width() - 1, 10 do
		r[row][column] = 0
		g[row][column] = 0
		b[row][column] = 0
	end
end

image:Save("lena_indexing.bmp", "BMP")
