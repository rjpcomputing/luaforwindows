--- A Set class.
--
--     > Set = require 'pl.Set'
--     > = Set{'one','two'} == Set{'two','one'}
--     true
--     > fruit = Set{'apple','banana','orange'}
--     > = fruit['banana']
--     true
--     > = fruit['hazelnut']
--     nil
--     > colours = Set{'red','orange','green','blue'}
--     > = fruit,colours
--     [apple,orange,banana]   [blue,green,orange,red]
--     > = fruit+colours
--     [blue,green,apple,red,orange,banana]
--     > = fruit*colours
--     [orange]
--
-- Depdencies: `pl.utils`, `pl.tablex`, `pl.class`
-- @module pl.Set

local tablex = require 'pl.tablex'
local utils = require 'pl.utils'
local stdmt = utils.stdmt
local tmakeset,deepcompare,merge,keys,difference,tupdate = tablex.makeset,tablex.deepcompare,tablex.merge,tablex.keys,tablex.difference,tablex.update
local Map = require 'pl.Map'
local Set = stdmt.Set
local List = stdmt.List
local class = require 'pl.class'

-- the Set class --------------------
class(Map,nil,Set)

-- note: Set has _no_ methods!
Set.__index = nil

local function makeset (t)
    return setmetatable(t,Set)
end

--- create a set. <br>
-- @param t may be a Set, Map or list-like table.
-- @class function
-- @name Set
function Set:_init (t)
    local mt = getmetatable(t)
    if mt == Set or mt == Map then
        for k in pairs(t) do self[k] = true end
    else
        for _,v in ipairs(t) do self[v] = true end
    end
end

function Set:__tostring ()
    return '['..Set.values(self):join ','..']'
end

--- get a list of the values in a set.
-- @param self a Set
-- @function Set.values
Set.values = Map.keys

--- map a function over the values of a set.
-- @param self a Set
-- @param fn a function
-- @param ... extra arguments to pass to the function.
-- @return a new set
function Set.map (self,fn,...)
    fn = utils.function_arg(1,fn)
    local res = {}
    for k in pairs(self) do
        res[fn(k,...)] = true
    end
    return makeset(res)
end

--- union of two sets (also +).
-- @param self a Set
-- @param set another set
-- @return a new set
function Set.union (self,set)
    return merge(self,set,true)
end
Set.__add = Set.union

--- intersection of two sets (also *).
-- @param self a Set
-- @param set another set
-- @return a new set
function Set.intersection (self,set)
    return merge(self,set,false)
end
Set.__mul = Set.intersection

--- new set with elements in the set that are not in the other (also -).
-- @param self a Set
-- @param set another set
-- @return a new set
function Set.difference (self,set)
    return difference(self,set,false)
end
Set.__sub = Set.difference

-- a new set with elements in _either_ the set _or_ other but not both (also ^).
-- @param self a Set
-- @param set another set
-- @return a new set
function Set.symmetric_difference (self,set)
    return difference(self,set,true)
end
Set.__pow = Set.symmetric_difference

--- is the first set a subset of the second (also <)?.
-- @param self a Set
-- @param set another set
-- @return true or false
function Set.issubset (self,set)
    for k in pairs(self) do
        if not set[k] then return false end
    end
    return true
end
Set.__lt = Set.subset

--- is the set empty?.
-- @param self a Set
-- @return true or false
function Set.issempty (self)
    return next(self) == nil
end

--- are the sets disjoint? (no elements in common).
-- Uses naive definition, i.e. that intersection is empty
-- @param s1 a Set
-- @param s2 another set
-- @return true or false
function Set.isdisjoint (s1,s2)
    return Set.isempty(Set.intersection(s1,s2))
end

--- size of this set (also # for 5.2).
-- @param s a Set
-- @return size
-- @function Set.len
Set.len = tablex.size

Set.__len = Set.len

function Set.__eq (s1,s2)
    return Set.issubset(s1,s2) and Set.issubset(s2,s1)
end

return Set
