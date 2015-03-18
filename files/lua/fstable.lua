--- Tables mapped to the filing system
-- Only string keys are permitted; package.dirsep characters are
-- converted to underscores.
-- Values are stored as strings (converted by tostring).
-- As with disk operations, a table's elements must be set to nil
-- (deleted) before the table itself can be set to nil.
module ("fstable", package.seeall)

require "io_ext"
require "table_ext"

require "io_ext"
require "lfs"
require "posix"

local function fsnext (dir)
  local f
  repeat
    f = dir:next ()
  until f ~= "." and f ~= ".."
  return f  
end

-- Metamethods for persistent tables
local metatable = {}

metatable.__index =
function (t, k)
  local path = io.catfile (getmetatable (t).directory, k)
  local attrs = lfs.attributes (path)
  if attrs then
    if attrs.mode == "file" then
      local h = io.open (path)
      if h then
        local v = h:read ("*a")
        h:close ()
        return v
      end
    elseif attrs.mode == "directory" then
      return new (path)
    end
  end
  return attrs
end

metatable.__newindex =
function (t, k, v)
  local ty = type (v)
  if ty == "thread" or ty == "function" or ty == "userdata" then
    error ("cannot persist a " .. ty .. "")
  elseif type (k) ~= "string" then
    error ("keys of persistent tables must be of type string")
  else
    k = string.gsub (k, package.dirsep, "_")
    local path = io.catfile (getmetatable (t).directory, k)
    local vm = getmetatable (v)
    if v == nil then
      os.remove (path)
    elseif type (v) ~= "table" then
      local h = io.open (path, "w")
      h:write (tostring (v))
      h:close ()
    elseif type (vm) == "table" and vm.metatable == metatable then
      -- To match Lua semantics we'd hardlink, but that's not allowed for directories
      local ok, errmsg = posix.link (vm.directory, path, true)
    else
      local ok, errmsg = lfs.mkdir (path)
      if not ok then
        error (errmsg)
      end
      new (path, v)
    end
  end
end

metatable.__pairs =
function (t)
  local _, dir = lfs.dir (getmetatable (t).directory)
  return function (dir)
           local f = fsnext (dir)
           if f then
             return f, t[f]
           end
         end,
  dir
end

metatable.__ipairs =
function (t)
  local _, dir = lfs.dir (getmetatable (t).directory)
  return function (dir, i)
           local f = fsnext (dir)
           if f then
             return i + 1, f
           end
         end,
  dir, 0
end

--- Bind a directory to a table
-- @param path directory path
-- @param t table to merge with directory
-- @return table bound to directory
function new (path, t)
  if not path:find ("^" .. package.dirsep) then
    path = io.catfile (lfs.currentdir (), path)
  end
  if lfs.attributes (path, "mode") ~= "directory" then
    error ("`" .. path .. "' does not exist or is not a directory")
  end
  local m = table.clone (metatable)
  m.directory = path
  m.metatable = metatable
  local d = setmetatable ({}, m)
  if t then
    for i, v in pairs (t) do
      d[i] = v
    end
  end
  return d
end
