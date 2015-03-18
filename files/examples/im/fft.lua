require"imlua"
require"imlua_process"
require"imlua_fftw"

local filename = "lena.jpg"
local image = im.FileImageLoad(filename)

local complex = im.ImageCreate(image:Width(), image:Height(), image:ColorSpace(), im.CFLOAT)
im.ProcessFFT(image, complex)

local c = complex[0][5][10] --  component=0(Red), y = 5 x =10
print(c[1], c[2])

complex[0][5][10] = { 2*c[1], c[2]/2 }

local c = complex[0][5][10]
print(c[1], c[2])
