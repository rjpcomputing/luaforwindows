--- Adds to the existing global functions
module ("base", package.seeall)

--- Functional forms of infix operators.
-- Defined here so that other modules can write to it.
-- @class table
-- @name _G.op
_G.op = {}

require "table_ext"
require "list"
require "string_ext"
--require "io_ext" FIXME: allow loops


--- Return given metamethod, if any, or nil.
-- @param x object to get metamethod of
-- @param n name of metamethod to get
-- @return metamethod function or nil if no metamethod or not a
-- function
function _G.metamethod (x, n)
  local _, m = pcall (function (x)
                        return getmetatable (x)[n]
                      end,
                      x)
  if type (m) ~= "function" then
    m = nil
  end
  return m
end

--- Turn tables into strings with recursion detection.
-- N.B. Functions calling render should not recurse, or recursion
-- detection will not work.
-- @see render_OpenRenderer, render_CloseRenderer
-- @see render_ElementRenderer, render_PairRenderer
-- @see render_SeparatorRenderer
-- @param x object to convert to string
-- @param open open table renderer
-- @param close close table renderer
-- @param elem element renderer
-- @param pair pair renderer
-- @param sep separator renderer
-- @return string representation
function _G.render (x, open, close, elem, pair, sep, roots)
  local function stop_roots (x)
    return roots[x] or render (x, open, close, elem, pair, sep, table.clone (roots))
  end
  roots = roots or {}
  if type (x) ~= "table" or metamethod (x, "__tostring") then
    return elem (x)
  else
    local s = strbuf.new ()
    s = s .. open (x)
    roots[x] = elem (x)
    local i, v = nil, nil
    for j, w in pairs (x) do
      s = s .. sep (x, i, v, j, w) .. pair (x, j, w, stop_roots (j), stop_roots (w))
      i, v = j, w
    end
    s = s .. sep(x, i, v, nil, nil) .. close (x)
    return s:tostring ()
  end
end

---
-- @class function
-- @name render_OpenRenderer
-- @param t table
-- @return open table string

---
-- @class function
-- @name render_CloseRenderer
-- @param t table
-- @return close table string

---
-- @class function
-- @name render_ElementRenderer
-- @param e element
-- @return element string

---
-- @class function
-- @name render_PairRenderer
-- N.B. the function should not try to render i and v, or treat
-- them recursively.
-- @param t table
-- @param i index
-- @param v value
-- @param is index string
-- @param vs value string
-- @return element string

---
-- @class function
-- @name render_SeparatorRenderer
-- @param t table
-- @param i preceding index (nil on first call)
-- @param v preceding value (nil on first call)
-- @param j following index (nil on last call)
-- @param w following value (nil on last call)
-- @return separator string

--- Extend <code>tostring</code> to work better on tables.
-- @class function
-- @name _G.tostring
-- @param x object to convert to string
-- @return string representation
_G._tostring = tostring -- make original tostring available
local _tostring = tostring
function _G.tostring (x)
  return render (x,
                 function () return "{" end,
                 function () return "}" end,
                 _tostring,
                 function (t, _, _, i, v)
                   return i .. "=" .. v
                 end,
                 function (_, i, _, j)
                   if i and j then
                     return ","
                   end
                   return ""
                 end)
end

--- Pretty-print a table.
-- @param t table to print
-- @param indent indent between levels ["\t"]
-- @param spacing space before every line
-- @return pretty-printed string
function _G.prettytostring (t, indent, spacing)
  indent = indent or "\t"
  spacing = spacing or ""
  return render (t,
                 function ()
                   local s = spacing .. "{"
                   spacing = spacing .. indent
                   return s
                 end,
                 function ()
                   spacing = string.gsub (spacing, indent .. "$", "")
                   return spacing .. "}"
                 end,
                 function (x)
                   if type (x) == "string" then
                     return string.format ("%q", x)
                   else
                     return tostring (x)
                   end
                 end,
                 function (x, i, v, is, vs)
                   local s = spacing .. "["
                   if type (i) == "table" then
                     s = s .. "\n"
                   end
                   s = s .. is
                   if type (i) == "table" then
                     s = s .. "\n"
                   end
                   s = s .. "] ="
                   if type (v) == "table" then
                     s = s .. "\n"
                   else
                     s = s .. " "
                   end
                   s = s .. vs
                   return s
                 end,
                 function (_, i)
                   local s = "\n"
                   if i then
                     s = "," .. s
                   end
                   return s
                 end)
end

--- Turn an object into a table according to __totable metamethod.
-- @param x object to turn into a table
-- @return table or nil
function _G.totable (x)
  local m = metamethod (x, "__totable")
  if m then
    return m (x)
  elseif type (x) == "table" then
    return x
  else
    return nil
  end
end

--- Convert a value to a string.
-- The string can be passed to dostring to retrieve the value.
-- <br>TODO: Make it work for recursive tables.
-- @param x object to pickle
-- @return string such that eval (s) is the same value as x
function _G.pickle (x)
  if type (x) == "string" then
    return string.format ("%q", x)
  elseif type (x) == "number" or type (x) == "boolean" or
    type (x) == "nil" then
    return tostring (x)
  else
    x = totable (x) or x
    if type (x) == "table" then
      local s, sep = "{", ""
      for i, v in pairs (x) do
        s = s .. sep .. "[" .. pickle (i) .. "]=" .. pickle (v)
        sep = ","
      end
      s = s .. "}"
      return s
    else
      die ("cannot pickle " .. tostring (x))
    end
  end
end

--- Identity function.
-- @param ...
-- @return the arguments passed to the function
function _G.id (...)
  return ...
end

--- Turn a tuple into a list.
-- @param ... tuple
-- @return list
function _G.pack (...)
  return {...}
end

--- Partially apply a function.
-- @param f function to apply partially
-- @param ... arguments to bind
-- @return function with ai already bound
function _G.bind (f, ...)
  local fix = {...}
  return function (...)
           return f (unpack (list.concat (fix, {...})))
         end
end

--- Curry a function.
-- @param f function to curry
-- @param n number of arguments
-- @return curried version of f
function _G.curry (f, n)
  if n <= 1 then
    return f
  else
    return function (x)
             return curry (bind (f, x), n - 1)
           end
  end
end

--- Compose functions.
-- @param f1...fn functions to compose
-- @return composition of f1 ... fn
function _G.compose (...)
  local arg = {...}
  local fns, n = arg, #arg
  return function (...)
           local arg = {...}
           for i = n, 1, -1 do
             arg = {fns[i] (unpack (arg))}
           end
           return unpack (arg)
         end
end

--- Evaluate a string.
-- @param s string
-- @return value of string
function _G.eval (s)
  return loadstring ("return " .. s)()
end

--- An iterator like ipairs, but in reverse.
-- @param t table to iterate over
-- @return iterator function
-- @return the table, as above
-- @return #t + 1
function _G.ripairs (t)
  return function (t, n)
           n = n - 1
           if n > 0 then
             return n, t[n]
           end
         end,
  t, #t + 1
end

--- Tree iterator.
-- @see tree_Iterator
-- @param tr tree to iterate over
-- @return iterator function
function _G.nodes (tr)
  local function visit (n, p)
    if type (n) == "table" then
      coroutine.yield ("branch", p, n)
      for i, v in pairs (n) do
        table.insert (p, i)
        visit (v, p)
        table.remove (p)
      end
      coroutine.yield ("join", p, n)
    else
      coroutine.yield ("leaf", p, n)
    end
  end
  return coroutine.wrap (visit), tr, {}
end

---
-- @class function
-- @name tree_Iterator
-- @param n current node
-- @param p path to node within the tree
-- @return type ("leaf", "branch" (pre-order) or "join" (post-order))
-- @return path to node ({i1...ik})
-- @return node

--- Collect the results of an iterator.
-- @param i iterator
-- @return results of running the iterator on its arguments
function _G.collect (i, ...)
  local t = {}
  for e in i (...) do
    table.insert (t, e)
  end
  return t
end

--- Map a function over an iterator.
-- @param f function
-- @param i iterator
-- @return result table
function _G.map (f, i, ...)
  local t = {}
  for e in i (...) do
    local r = f (e)
    if r then
      table.insert (t, r)
    end
  end
  return t
end

--- Filter an iterator with a predicate.
-- @param p predicate
-- @param i iterator
-- @return result table containing elements e for which p (e)
function _G.filter (p, i, ...)
  local t = {}
  for e in i (...) do
    if p (e) then
      table.insert (t, e)
    end
  end
  return t
end

--- Fold a binary function into an iterator.
-- @param f function
-- @param d initial first argument
-- @param i iterator
-- @return result
function _G.fold (f, d, i, ...)
  local r = d
  for e in i (...) do
    r = f (r, e)
  end
  return r
end

--- Extend to allow formatted arguments.
-- @param v value to assert
-- @param f format
-- @param ... arguments to format
-- @return value
function _G.assert (v, f, ...)
  if not v then
    if f == nil then
      f = ""
    end
    error (string.format (f, ...))
  end
  return v
end

--- Give warning with the name of program and file (if any).
-- @param ... arguments for format
function _G.warn (...)
  if prog.name then
    io.stderr:write (prog.name .. ":")
  end
  if prog.file then
    io.stderr:write (prog.file .. ":")
  end
  if prog.line then
    io.stderr:write (tostring (prog.line) .. ":")
  end
  if prog.name or prog.file or prog.line then
    io.stderr:write (" ")
  end
  io.writeline (io.stderr, string.format (...))
end

--- Die with error.
-- @param ... arguments for format
function _G.die (...)
  warn (unpack (arg))
  error ()
end

-- Function forms of operators.
-- FIXME: Make these visible in LuaDoc (also list.concat in list)
_G.op["[]"] =
  function (t, s)
    return t[s]
  end

_G.op["+"] =
  function (a, b)
    return a + b
  end
_G.op["-"] =
  function (a, b)
    return a - b
  end
_G.op["*"] =
  function (a, b)
    return a * b
  end
_G.op["/"] =
  function (a, b)
    return a / b
  end
_G.op["and"] =
  function (a, b)
    return a and b
  end
_G.op["or"] =
  function (a, b)
    return a or b
  end
_G.op["not"] =
  function (a)
    return not a
  end
_G.op["=="] =
  function (a, b)
    return a == b
  end
_G.op["~="] =
  function (a, b)
    return a ~= b
  end
