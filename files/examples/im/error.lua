require"imlua"

local filename = "lena.jpg"
local image = im.FileImageLoad(filename)
local image2 = im.ImageCreate(image:Width(), image:Height(), im.GRAY, im.USHORT)

-- Both calls will signal an error because of incompatible parameters

--im.ConvertDataType(image, image2, im.CPX_REAL, im.GAMMA_LINEAR, 0, im.CAST_MINMAX)
im.ConvertColorSpace(image, image2, im.CPX_REAL, im.GAMMA_LINEAR, 0, im.CAST_MINMAX)
