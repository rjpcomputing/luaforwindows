------------------------------------------------------------------
-- A simple TGA loader.
-- Loads the TGA file with the given fileName. 
-- Supports only 24 or 32 bits color TGAs with no compression.
------------------------------------------------------------------
function LoadTGA(fileName)
  local file = io.open(fileName, "rb")

  if file == nil then
    return nil, "Unnable to open file '" .. fileName .. "'."
  end

  local texture = {}
  local header = file:read(18)
  
  if header == nil then
    return nil, "Error loading header data."
  end

  texture.components = header:byte(17) / 8
  texture.width      = header:byte(14) * 256 + header:byte(13)
  texture.height     = header:byte(16) * 256 + header:byte(15)
  texture.target     = "TEXTURE_2D"
  texture.type       = "UNSIGNED_BYTE"
  texture.format     = (texture.components == 4) and "RGBA" or "RGB"

  if header:byte(3) ~= 2 then
    return nil, "Unsupported tga type. Only 24/32 bits uncompressed images are supported."
  end

  for j=1, texture.height do
    local line = {}
    for i=1, texture.width do
      data = file:read(texture.components)

      if data == nil then
        return nil, "Error loading data."
      end
      table.insert(line, data:byte(3))
      table.insert(line, data:byte(2))
      table.insert(line, data:byte(1))
      if texture.components == 4 then table.insert(line, data:byte(4)) end
    end
    table.insert(texture, line)
  end

  file:close()
  return texture
end
