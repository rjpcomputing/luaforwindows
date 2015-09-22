local Delaunay = require ('Delaunay')
local Point    = Delaunay.Point

math.randomseed(os.time())

local function newPoint()
  local x, y = math.random(), math.random()
  return Point(x * 1000, y * 1000)
end

local MAX_POINTS = arg[1] or 500
local N_TESTS    = arg[2] or 10

local function genPoints(n)
  local points = {}
  for i = 1, n do
    points[i] = newPoint()
  end
  return points
end

local function time(f, p)
  local start_time = os.clock()
  local result = f(unpack(p))
  local duration = (os.clock() - start_time) * 1000
  assert(result~=nil, 'Unexpected output, returned nil')
  return duration
end

local function main()
  for i = 1, N_TESTS do
    local p = genPoints(MAX_POINTS)
    local duration = time(Delaunay.triangulate, p)
    print(('Test %02d: triangulating %04d points in %.2f ms'):format(i, MAX_POINTS, duration))
  end
end

main()