require"imlua"
require"imlua_process"

local image = im.ImageCreate(500, 500, im.RGB, im.BYTE)

im.ProcessRenderRandomNoise(image)
image:Save("render_noise.bmp", "BMP")

im.ProcessRenderConstant(image, { 128.0, 0.0, 255.0 })
image:Save("render_constant.bmp", "BMP")

im.ProcessRenderWheel(image, 100, 200)
image:Save("render_wheel.bmp", "BMP")

im.ProcessRenderTent(image, 300, 200)
image:Save("render_tent.bmp", "BMP")

im.ProcessRenderRamp(image, 0, 500, 0)
image:Save("render_ramp.bmp", "BMP")

im.ProcessRenderBox(image, 200, 200)
image:Save("render_box.bmp", "BMP")

im.ProcessRenderSinc(image, 100.0, 100.0)
image:Save("render_sinc.bmp", "BMP")

im.ProcessRenderGaussian(image, 100.0)
image:Save("render_gaussian.bmp", "BMP")

im.ProcessRenderLapOfGaussian(image, 100.0)
image:Save("render_lapofgaussian.bmp", "BMP")

im.ProcessRenderCosine(image, 100.0, 100.0)
image:Save("render_cosine.bmp", "BMP")

im.ProcessRenderGrid(image, 100.0, 100.0)
image:Save("render_grid.bmp", "BMP")

im.ProcessRenderChessboard(image, 100.0, 100.0)
image:Save("render_chess.bmp", "BMP")

im.ProcessRenderCone(image, 200)
image:Save("render_cone.bmp", "BMP")

local render_func = function (x, y, d, param)
	return math.mod(x + y, 256)
end

im.ProcessRenderOp(image, render_func, "test", {}, 0)
image:Save("render_func.bmp", "BMP")
