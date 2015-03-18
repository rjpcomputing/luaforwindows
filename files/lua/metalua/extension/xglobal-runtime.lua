local _G = getfenv()
local _G_mt = getmetatable(_G)


-- Set the __globals metafield in the global environment's metatable,
-- if not already there.
if _G_mt then
   if _G_mt.__globals then return else
      print( "Warning: _G already has a metatable,"..
            " which might interfere with xglobals")
      _G_mt.__globals = { } 
   end
else 
   _G_mt = { __globals = { } }
   setmetatable(_G, _G_mt)
end

-- add a series of variable names to the list of declared globals
function _G_mt.__newglobal(...)
   local g = _G_mt.__globals
   for v in ivalues{...} do g[v]=true end
end

-- Try to set a global that's not in _G:
-- if it isn't declared, fail
function _G_mt.__newindex(_G, var, val)
   if not _G_mt.__globals[var] then
      error ("Setting undeclared global variable "..var)
   end
   rawset(_G, var, val)
end

-- Try to read a global that's not in _G:
-- if it isn't declared, fail
function _G_mt.__index(_G, var)
   if not _G_mt.__globals[var] then 
      error ("Reading undeclared global variable "..var) 
   end
   return nil
end

