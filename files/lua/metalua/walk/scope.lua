--------------------------------------------------------------------------------
--
-- Scopes: this library helps keeping track of identifier scopes,
-- typically in code walkers.
--
-- * scope:new() returns a new scope instance s
--
-- * s:push() bookmarks the current set of variables, so the it can be
--   retrieved next time a s:pop() is performed.
--
-- * s:pop() retrieves the last state saved by s:push(). Calls to
--   :push() and :pop() can be nested as deep as one wants.
--
-- * s:add(var_list, val) adds new variable names (stirng) into the
--   scope, as keys. val is the (optional) value associated with them:
--   it allows to attach arbitrary information to variables, e.g. the
--   statement or expression that created them.
--
-- * s:push(var_list, val) is a shortcut for 
--   s:push(); s:add(var_list, val).
--
-- * s.current is the current scope, a table with variable names as
--   keys and their associated value val (or 'true') as value.
--
--------------------------------------------------------------------------------

scope = { }
scope.__index = scope

function scope:new()
   local ret = { current = { } }
   ret.stack = { ret.current }
   setmetatable (ret, self)
   return ret
end

function scope:push(...)
   table.insert (self.stack, table.shallow_copy (self.current))
   if ... then return self:add(...) end
end

function scope:pop()
   self.current = table.remove (self.stack)
end

function scope:add (vars, val)
   val = val or true
   for i, id in ipairs (vars) do
      assert(id.tag=='Id' or id.tag=='Dots' and i==#vars)
      if id.tag=='Id' then self.current[id[1]] = val end
   end
end

return scope