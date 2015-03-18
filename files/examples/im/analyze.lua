require"imlua"
require"imlua_process"

local filename = "rice.png" -- image must be im.GRAY and im.BYTE for this script

local image = im.FileImageLoad(filename)
local binary = im.ImageCreateBased(image, nil, nil, im.BINARY, nil)
local region = im.ImageCreateBased(image, nil, nil, nil, im.USHORT)

-- make it binary
im.ProcessPercentThreshold(image, binary, 70) --lots of background

-- search for closed regions, don't count objects that touches the image borders
local count = im.AnalyzeFindRegions(binary, region, 4, 0)
print("regions: ", count)

local area = im.AnalyzeMeasureArea(region, count)
local major_slope, major_length, minor_slope, minor_length = im.AnalyzeMeasurePrincipalAxis(region, area, nil, nil, count) 

print("object", "area", "major length", "minor length")
for r=1, count do
  print(r, area[r-1], string.format("%5.5g", major_length[r-1]), string.format("%5.5g", minor_length[r-1]))
end
