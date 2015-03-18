-- Extensions to the table module
module ("table", package.seeall)

--require "list" FIXME: allow require loops


local _sort = sort
--- Make table.sort return its result.
-- @param t table
-- @param c comparator function
-- @return sorted table
function sort (t, c)
  _sort (t, c)
  return t
end

--- Return whether table is empty.
-- @param t table
-- @return <code>true</code> if empty or <code>false</code> otherwise
function empty (t)
  return not next (t)
end

--- Find the number of elements in a table.
-- @param t table
-- @return number of elements in t
function size (t)
  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end

--- Make the list of indices of a table.
-- @param t table
-- @return list of indices
function indices (t)
  local u = {}
  for i, v in pairs (t) do
    insert (u, i)
  end
  return u
end

--- Make the list of values of a table.
-- @param t table
-- @return list of values
function values (t)
  local u = {}
  for i, v in pairs (t) do
    insert (u, v)
  end
  return u
end

--- Invert a table.
-- @param t table <code>{i=v, ...}</code>
-- @return inverted table <code>{v=i, ...}</code>
function invert (t)
  local u = {}
  for i, v in pairs (t) do
    u[v] = i
  end
  return u
end

--- Rearrange some indices of a table.
-- @param m table <code>{old_index=new_index, ...}</code>
-- @param t table to rearrange
-- @return rearranged table
function rearrange (m, t)
  local r = clone (t)
  for i, v in pairs (m) do
    r[v] = t[i]
    r[i] = nil
  end
  return r
end

--- Make a shallow copy of a table, including any metatable (for a
-- deep copy, use tree.clone).
-- @param t table
-- @param nometa if non-nil don't copy metatable
-- @return copy of table
function clone (t, nometa)
  local u = {}
  if not nometa then
    setmetatable (u, getmetatable (t))
  end
  for i, v in pairs (t) do
    u[i] = v
  end
  return u
end

--- Merge two tables.
-- If there are duplicate fields, u's will be used. The metatable of
-- the returned table is that of t.
-- @param t first table
-- @param u second table
-- @return merged table
function merge (t, u)
  local r = clone (t)
  for i, v in pairs (u) do
    r[i] = v
  end
  return r
end

--- Make a table with a default value for unset keys.
-- @param x default entry value (default: <code>nil</code>)
-- @param t initial table (default: <code>{}</code>)
-- @return table whose unset elements are x
function new (x, t)
  return setmetatable (t or {},
                       {__index = function (t, i)
                                    return x
                                  end})
end
