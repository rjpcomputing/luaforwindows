--- Additions to the debug module
module ("debug", package.seeall)

require "debug_init"
require "io_ext"
require "string_ext"

--- To activate debugging set _DEBUG either to any true value
-- (equivalent to {level = 1}), or as documented below.
-- @class table
-- @name _DEBUG
-- @field level debugging level
-- @field call do call trace debugging
-- @field std do standard library debugging (run examples & test code)


--- Print a debugging message
-- @param n debugging level, defaults to 1
-- @param ... objects to print (as for print)
function say (n, ...)
  local level = 1
  local arg = {n, ...}
  if type (arg[1]) == "number" then
    level = arg[1]
    table.remove (arg, 1)
  end
  if _DEBUG and
    ((type (_DEBUG) == "table" and type (_DEBUG.level) == "number" and
      _DEBUG.level >= level)
       or level <= 1) then
    io.writeline (io.stderr, table.concat (list.map (tostring, arg), "\t"))
  end
end

---
-- debug.say is also available as the global function <code>debug</code>
-- @class function
-- @name debug
-- @see say
getmetatable (_M).__call =
   function (self, ...)
     say (...)
   end

--- Trace function calls
-- Use as debug.sethook (trace, "cr"), which is done automatically
-- when _DEBUG.call is set.
-- Based on test/trace-calls.lua from the Lua distribution.
-- @class function
-- @name trace
-- @param event event causing the call
local level = 0
function trace (event)
  local t = getinfo (3)
  local s = " >>> " .. string.rep (" ", level)
  if t ~= nil and t.currentline >= 0 then
    s = s .. t.short_src .. ":" .. t.currentline .. " "
  end
  t = getinfo (2)
  if event == "call" then
    level = level + 1
  else
    level = math.max (level - 1, 0)
  end
  if t.what == "main" then
    if event == "call" then
      s = s .. "begin " .. t.short_src
    else
      s = s .. "end " .. t.short_src
    end
  elseif t.what == "Lua" then
    s = s .. event .. " " .. (t.name or "(Lua)") .. " <" ..
      t.linedefined .. ":" .. t.short_src .. ">"
  else
    s = s .. event .. " " .. (t.name or "(C)") .. " [" .. t.what .. "]"
  end
  io.writeline (io.stderr, s)
end

-- Set hooks according to _DEBUG
if type (_DEBUG) == "table" and _DEBUG.call then
  sethook (trace, "cr")
end
