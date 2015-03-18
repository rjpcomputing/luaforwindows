--- Tables as trees.
module ("tree", package.seeall)

require "list"


local metatable = {}
--- Make a table into a tree
-- @param t table
-- @return tree
function new (t)
  return setmetatable (t or {}, metatable)
end

--- Tree <code>__index</code> metamethod.
-- @param tr tree
-- @param i non-table, or list of indices <code>{i<sub>1</sub> ...
-- i<sub>n</sub>}</code>
-- @return <code>tr[i]...[i<sub>n</sub>]</code> if i is a table, or
-- <code>tr[i]</code> otherwise
function metatable.__index (tr, i)
  if type (i) == "table" then
    return list.foldl (op["[]"], tr, i)
  else
    return rawget (tr, i)
  end
end

--- Tree <code>__newindex</code> metamethod.
-- Sets <code>tr[i<sub>1</sub>]...[i<sub>n</sub>] = v</code> if i is a
-- table, or <code>tr[i] = v</code> otherwise
-- @param tr tree
-- @param i non-table, or list of indices <code>{i<sub>1</sub> ...
-- i<sub>n</sub>}</code>
-- @param v value
function metatable.__newindex (tr, i, v)
  if type (i) == "table" then
    for n = 1, #i - 1 do
      if type (tr[i[n]]) ~= "table" then
        tr[i[n]] = tree.new ()
      end
      tr = tr[i[n]]
    end
    rawset (tr, i[#i], v)
  else
    rawset (tr, i, v)
  end
end

--- Make a deep copy of a tree, including any metatables
-- @param t table
-- @param nometa if non-nil don't copy metatables
-- @return copy of table
function clone (t, nometa)
  local r = {}
  if not nometa then
    setmetatable (r, getmetatable (t))
  end
  local d = {[t] = r}
  local function copy (o, x)
    for i, v in pairs (x) do
      if type (v) == "table" then
        if not d[v] then
          d[v] = {}
          if not nometa then
            setmetatable (d[v], getmetatable (v))
          end
          o[i] = copy (d[v], v)
        else
          o[i] = d[v]
        end
      else
        o[i] = v
      end
    end
    return o
  end
  return copy (r, t)
end
