

local core = require "alien.core"
local io = require "io"

local pairs, ipairs = pairs, ipairs
local setmetatable = setmetatable
local error = error
local pcall = pcall
local type = type
local rawset = rawset
local unpack = unpack
local math = math
local print = print

module "alien"

loaded = {}

local load_library, find_library = {}, {}

local function find_library_helper(libname, opt)
  local expr = '/[^() ]*lib' .. libname .. '\.so[^() ]*'
  local cmd = '/sbin/ldconfig ' .. opt .. 
    ' 2>/dev/null | egrep -o "' .. expr .. '"'
  local pipe = io.popen(cmd)
  if pipe then
    local res = pipe:read()
    pipe:close()
    return res and res:match("([^%s]*)")
  end
  return nil
end

function find_library.linux(libname)
  return find_library_helper(libname, "-p")
end

function find_library.bsd(libname)
  return find_library_helper(libname, "-r")
end

function find_library.darwin(libname)
  local ok, lib = pcall(core.load, libname .. ".dylib")
  if ok then return lib end
  ok, lib = pcall(core.load, libname .. ".framework/" .. libname)
  if ok then return lib end
  return nil
end

local function load_library_helper(libname, libext)
  if libname:match("/") or libname:match("%" .. libext) then
    return core.load(libname)
  else
    local ok, lib = pcall(core.load, "lib" .. libname .. libext)
    if not ok then
      ok, lib = pcall(core.load, "./lib" .. libname .. libext)
      if not ok then
	local name = find_library[core.platform](libname)
	if name then
	  lib = core.load(name)
	else
	  error("library " .. libname .. " not found")
	end
      end
    end
    return lib
  end
end

function load_library.linux(libname)
  return load_library_helper(libname, ".so")
end

load_library.bsd = load_library.linux

function load_library.darwin(libname)
  return load_library_helper(libname, ".dylib")
end

setmetatable(load_library, { __index = function (t, plat)
					 return core.load
				       end } )

function load_library.windows(libname)
  return core.load(libname)
end

setmetatable(loaded, { __index = function (t, libname)
				   local lib = 
				     load_library[core.platform](libname)
				   t[libname] = lib
				   return lib
				 end })

setmetatable(_M, { __index = loaded })

for name, f in pairs(core) do
  _M[name] = f
end

function load(libname)
  return loaded[libname]
end

function callback(f, ...)
  local cb = core.callback(f)
  cb.types(cb, ...)
  return cb
end

local array_methods = {}

local function array_next(arr, i)
   if i < arr.length then
      return i + 1, arr[i + 1]
   else
      return nil
   end
end

function array_methods:ipairs()
   return array_next, self, 0
end

local function array_get(arr, key)
  if type(key) == "number" then
    if key < 1 or key > arr.length then
      error("array access out of bounds")
    end
    local offset = (key - 1) * arr.size + 1
    return arr.buffer:get(offset, arr.type)
  else
    return array_methods[key]
  end
end

local function array_set(arr, key, val)
  if type(key) == "number" then
    if key < 1 or key > arr.length then
      error("array access out of bounds")
    end
    local offset = (key - 1) * arr.size + 1
    arr.buffer:set(offset, val, arr.type)
    if type(val) == "string" or type(val) == "userdata" then
      arr.pinned[key] = val
    end
  else
    rawset(arr, key, val)
  end
end

function array(t, length, init)
  local ok, size = pcall(core.sizeof, t)
  if not ok then
    error("type " .. t .. " does not exist")
  end
  if type(length) == "table" then
    init = length
    length = #length
  end
  local arr = { type = t, length = length, size = size, pinned = {} }
  setmetatable(arr, { __index = array_get, __newindex = array_set })
  if type(init) == "userdata" then
    arr.buffer = init
  else
    arr.buffer = core.buffer(size * length)
    if type(init) == "table" then
      for i = 1, length do
	arr[i] = init[i]
      end
    end
  end
  return arr
end

local function struct_new(s_proto, ptr)
  local buf = core.buffer(ptr or s_proto.size)
  local function struct_get(_, key)
    if s_proto.offsets[key] then
      return buf:get(s_proto.offsets[key] + 1, s_proto.types[key])
    else
      error("field " .. key .. " does not exist")
    end
  end
  local function struct_set(_, key, val)
    if s_proto.offsets[key] then
      buf:set(s_proto.offsets[key] + 1, val, s_proto.types[key])
    else
      error("field " .. key .. " does not exist")
    end
  end
  return setmetatable({}, { __index = struct_get, __newindex = struct_set,
			    __call = function () return buf end })
end

local function struct_byval(s_proto)
  local types = {}
  local size = s_proto.size
  for i = 0, size - 1, 4 do
    if size - i == 1 then
      types[#types + 1] = "char"
    elseif size - i == 2 then
      types[#types + 1] = "short"
    else
      types[#types + 1] = "int"
    end
  end
  return unpack(types)
end

function defstruct(t)
  local off = 0
  local names, offsets, types = {}, {}, {}
  for _, field in ipairs(t) do
    local name, type = field[1], field[2]
    names[#names + 1] = name
    off = math.ceil(off / core.align(type)) * core.align(type)
    offsets[name] = off
    types[name] = type
    off = off + core.sizeof(type)
  end
  return { names = names, offsets = offsets, types = types, size = off, new = struct_new,
	    byval = struct_byval }
end

function byval(buf)
  if buf.size then
    local size = buf.size
    local types = { "char", "short"}
    local vals = {}
    for i = 1, size, 4 do
      if size - i == 0 then
	vals[#vals + 1] = buf:get(i, "char")
      elseif size - i == 1 then
	vals[#vals + 1] = buf:get(i, "short")
      else
	vals[#vals + 1] = buf:get(i, "int")
      end
    end
    return unpack(vals)
  else
    error("this type of buffer can't be passed by value")
  end
end
