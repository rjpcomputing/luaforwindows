-- Set datatype.
module ("set", package.seeall)


-- Primitive methods (know about representation)
-- The representation is a table whose tags are the elements, and
-- whose values are true.

--- Say whether an element is in a set
-- @param s set
-- @param e element
-- @return <code>true</code> if e is in set, <code>false</code>
-- otherwise
function member (s, e)
  return rawget (s, e) == true
end

--- Insert an element into a set
-- @param s set
-- @param e element
function insert (s, e)
  rawset (s, e, true)
end

--- Delete an element from a set
-- @param s set
-- @param e element
function delete (s, e)
  rawset (s, e, nil)
end

--- Make a list into a set
-- @param l list
-- @return set
local metatable = {}
function new (l)
  local s = setmetatable ({}, metatable)
  for _, e in ipairs (l) do
    insert (s, e)
  end
  return s
end

--- Iterator for sets
-- TODO: Make the iterator return only the key
elements = pairs


-- High level methods (representation-independent)

--- Find the difference of two sets
-- @param s set
-- @param t set
-- @return s with elements of t removed
function difference (s, t)
  local r = new {}
  for e in elements (s) do
    if not member (t, e) then
      insert (r, e)
    end
  end
  return r
end

--- Find the symmetric difference of two sets
-- @param s set
-- @param t set
-- @return elements of s and t that are in s or t but not both
function symmetric_difference (s, t)
  return difference (union (s, t), intersection (t, s))
end

--- Find the intersection of two sets
-- @param s set
-- @param t set
-- @return set intersection of s and t
function intersection (s, t)
  local r = new {}
  for e in elements (s) do
    if member (t, e) then
      insert (r, e)
    end
  end
  return r
end

--- Find the union of two sets
-- @param s set
-- @param t set
-- @return set union of s and t
function union (s, t)
  local r = new {}
  for e in elements (s) do
    insert (r, e)
  end
  for e in elements (t) do
    insert (r, e)
  end
  return r
end

--- Find whether one set is a subset of another
-- @param s set
-- @param t set
-- @return <code>true</code> if s is a subset of t, <code>false</code>
-- otherwise
function subset (s, t)
  for e in elements (s) do
    if not member (t, e) then
      return false
    end
  end
  return true
end

--- Find whether one set is a proper subset of another
-- @param s set
-- @param t set
-- @return <code>true</code> if s is a proper subset of t, false otherwise
function propersubset (s, t)
  return subset (s, t) and not subset (t, s)
end

--- Find whether two sets are equal
-- @param s set
-- @param t set
-- @return <code>true</code> if sets are equal, <code>false</code>
-- otherwise
function equal (s, t)
  return subset (s, t) and subset (t, s)
end

--- Metamethods for sets
-- set:method ()
metatable.__index = _M
-- set + table = union
metatable.__add = union
-- set - table = set difference
metatable.__sub = difference
-- set * table = intersection
metatable.__mul = intersection
-- set / table = symmetric difference
metatable.__div = symmetric_difference
-- set <= table = subset
metatable.__le = subset
-- set < table = proper subset
metatable.__lt = propersubset
