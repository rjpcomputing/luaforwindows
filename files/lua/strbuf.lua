--- String buffers
module ("strbuf", package.seeall)

--- Create a new string buffer
local metatable = {}
function new ()
  return setmetatable ({}, metatable)
end

--- Add a string to a buffer
-- @param b buffer
-- @param s string to add
-- @return buffer
function concat (b, s)
  table.insert (b, s)
  return b
end

--- Convert a buffer to a string
-- @param b buffer
-- @return string
function tostring (b)
  return table.concat (b)
end

--- Metamethods for string buffers
-- buffer:method ()
metatable.__index = _M
-- buffer .. string
metatable.__concat = concat
-- tostring
metatable.__tostring = tostring
