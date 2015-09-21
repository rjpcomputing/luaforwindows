#!/usr/bin/env lua
------------------
-- *strictness, a "strict" mode for Lua*.
-- Source on [Github](http://github.com/Yonaba/strictness)
-- @author Roland Yonaba
-- @copyright 2013-2014
-- @license MIT

local _LUA52 = _VERSION:match('Lua 5.2')
local setmetatable, getmetatable = setmetatable, getmetatable
local pairs, ipairs = pairs, ipairs
local rawget, rawget = rawget, rawget
local unpack = _LUA52 and table.unpack or unpack
local tostring, select, error = tostring, select, error
local getfenv = getfenv

local _MODULEVERSION = '0.2.0'

----------------------------- Private definitions -----------------------------

if _LUA52 then
  -- Provide a replacement for getfenv in Lua 5.2, using the debug library
  -- Taken from: http://lua-users.org/lists/lua-l/2010-06/msg00313.html
  -- Slightly modified to handle f being nil and return _ENV if f is global.
  getfenv = function(f)
      f = (type(f) == 'function' and f or debug.getinfo((f or 0) + 1, 'f').func)
      local name, val
      local up = 0
      repeat
          up = up + 1
          name, val = debug.getupvalue(f, up)
      until name == '_ENV' or name == nil
      return val~=nil and val or _ENV
  end
end

-- Lua reserved keywords
local is_reserved_keyword = {
  ['and']      = true, ['break'] = true, ['do']    = true, ['else']   = true, 
  ['elseif']   = true, ['end']   = true, ['false'] = true, ['for']    = true,
  ['function'] = true, ['if']    = true, ['in']    = true, ['local']  = true,
  ['nil']      = true, ['not']   = true, ['or']    = true, ['repeat'] = true, 
  ['return']   = true, ['then']  = true, ['true']  = true, ['until']  = true,
  ['while']    = true,
}; if _LUA52 then is_reserved_keyword['goto'] = true end

-- Throws an error if cond
local function complain_if(cond, msg, level) 
  return cond and error(msg, level or 3)
end

-- Checks if iden match an valid Lua identifier syntax
local function is_identifier(iden)
  return tostring(iden):match('^[%a_]+[%w_]*$') and 
    not is_reserved_keyword[iden]
end

-- Checks if all elements of vararg are valid Lua identifiers
local function validate_identifiers(...)
  local arg, varnames= {...}, {}
  for i, iden in ipairs(arg) do
    complain_if(not is_identifier(iden),
      ('varname #%d "<%s>" is not a valid Lua identifier.')
        :format(i, tostring(iden)),4)
  varnames[iden] = true
  end
  return varnames
end

-- add true keys in register all keys in t
local function add_allowed_keys(t,register)
  for key in pairs(t) do 
    if is_identifier(key) then register[key] = true end
  end
  return register
end

-- Checks if the given arg is callable
local function callable(f)
  return type(f) == 'function' or (getmetatable(f) and getmetatable(f).__call)
end

------------------------------- Module functions ------------------------------

--- Makes a given table strict. It mutates the passed-in table (or creates a 
-- new table) and returns it. The returned table is strict, indexing or 
-- assigning undefined fields will raise an error.
-- @function strictness.strict
-- @param[opt] t a table
-- @param[opt] ... a vararg list of allowed fields in the table.
-- @return the passed-in table `t` or a new table, patched to be strict.
-- @usage
-- local t = strictness.strict()
-- local t2 = strictness.strict({})
-- local t3 = strictness.strict({}, 'field1', 'field2')
local function make_table_strict(t, ...)
  t = t or {}
  local has_mt = getmetatable(t)
  complain_if(type(t) ~= 'table',
    ('Argument #1 should be a table, not %s.'):format(type(t)),3) 
  local mt = getmetatable(t) or {}
  complain_if(mt.__strict, 
    ('<%s> was already made strict.'):format(tostring(t)),3)
    
  local varnames = v
  mt.__allowed = add_allowed_keys(t, validate_identifiers(...))
  mt.__predefined_index = mt.__index
  mt.__predefined_newindex = mt.__newindex
  
  mt.__index = function(tbl, key)
    if not mt.__allowed[key] then
      if mt.__predefined_index then
        local expected_result = mt.__predefined_index(tbl, key)
        if expected_result then return expected_result end
      end
      complain_if(true,
        ('Attempt to access undeclared variable "%s" in <%s>.')
          :format(key, tostring(tbl)),3)
    end
    return rawget(tbl, key)
 end
  
  mt.__newindex = function(tbl, key, val)
    if mt.__predefined_newindex then
      mt.__predefined_newindex(tbl, key, val)
      if rawget(tbl, key) ~= nil then return end
    end
    if not mt.__allowed[key] then
      if val == nil then 
        mt.__allowed[key] = true
        return
      end
      complain_if(not mt.__allowed[key],
        ('Attempt to assign value to an undeclared variable "%s" in <%s>.')
          :format(key,tostring(tbl)),3)
      mt.__allowed[key] = true
    end
    rawset(tbl, key, val)
  end
  
  mt.__strict = true
  mt.__has_mt = has_mt
  return setmetatable(t, mt)
  
end

--- Checks if a given table is strict.
-- @function strictness.is_strict
-- @param t a table
-- @return `true` if the table is strict, `false` otherwise.
-- @usage
-- local is_strict = strictness.is_strict(a_table)
local function is_table_strict(t)
  complain_if(type(t) ~= 'table',
    ('Argument #1 should be a table, not %s.'):format(type(t)),3)
  return not not (getmetatable(t) and getmetatable(t).__strict)
end

--- Makes a given table non-strict. It mutates the passed-in table and 
-- returns it. The returned table is non-strict.
-- @function strictness.unstrict
-- @param t a table
-- @usage
-- local unstrict_table = strictness.unstrict(trict_table)
local function make_table_unstrict(t)
  complain_if(type(t) ~= 'table',
    ('Argument #1 should be a table, not %s.'):format(type(t)),3)
  if is_table_strict(t) then
    local mt = getmetatable(t)
    if not mt.__has_mt then
      setmetatable(t, nil)
    else
      mt.__index, mt.__newindex = mt.__predefined_index, mt.__predefined_newindex
      mt.__strict, mt.__allowed, mt.__has_mt = nil, nil, nil
      mt.__predefined_index, mt.__predefined_newindex = nil, nil
    end
  end
  return t
end

--- Creates a strict function. Wraps the given function and returns the wrapper. 
-- The new function will always run in strict mode in its environment, whether 
-- or not this environment is strict.
-- @function strictness.strictf
-- @param f a function, or a callable value.
-- @usage
-- local strict_f = strictness.strictf(a_function)
-- local result = strict_f(...)
local function make_function_strict(f)
  complain_if(not callable(f),
    ('Argument #1 should be a callable, not %s.'):format(type(f)),3)
  return function(...)
    local ENV = getfenv(f)
    local was_strict = is_table_strict(ENV)
    if not was_strict then make_table_strict(ENV) end
    local results = {f(...)}
    if not was_strict then make_table_unstrict(ENV) end
    return unpack(results)
  end
end

--- Creates a non-strict function. Wraps the given function and returns the wrapper. 
-- The new function will always run in non-strict mode in its environment, whether 
-- or not this environment is strict.
-- @function strictness.unstrictf
-- @param f a function, or a callable value.
-- @usage
-- local unstrict_f = strictness.unstrictf(a_function)
-- local result = unstrict_f(...)
local function make_function_unstrict(f)
  complain_if(not callable(f),
    ('Argument #1 should be a callable, not %s.'):format(type(f)),3)
  return function(...)
    local ENV = getfenv(f)
    local was_strict = is_table_strict(ENV)
    make_table_unstrict(ENV)
    local results = {f(...)}
    if was_strict then make_table_strict(ENV) end
    return unpack(results)
  end
end

--- Returns the result of a function call in strict mode.
-- @function strictness.run_strict
-- @param f a function, or a callable value.
-- @param[opt] ... a vararg list of arguments to function `f`.
-- @usage
-- local result = strictness.run_strict(a_function, arg1, arg2)
local function run_strict(f,...)
  complain_if(not callable(f),
    ('Argument #1 should be a callable, not %s.'):format(type(f)),3)
  return make_function_strict(f)(...)
end

--- Returns the result of a function call in non-strict mode.
-- @function strictness.run_unstrict
-- @param f a function, or a callable value.
-- @param[opt] ... a vararg list of arguments to function `f`.
-- @usage
-- local result = strictness.run_unstrict(a_function, arg1, arg2)
local function run_unstrict(f,...)
  complain_if(not callable(f),
    ('Argument #1 should be a callable, not %s.'):format(type(f)),3)
  return make_function_unstrict(f)(...)
end

return {
  strict       = make_table_strict,
  unstrict     = make_table_unstrict,
  is_strict    = is_table_strict,
  strictf      = make_function_strict,  
  unstrictf    = make_function_unstrict,
  run_strict   = run_strict,
  run_unstrict = run_unstrict,
  _VERSION     = 'strictness v'.._MODULEVERSION,
  _URL         = 'http://github.com/Yonaba/strictness',
  _LICENSE     = 'MIT <http://raw.githubusercontent.com/Yonaba/strictness/master/LICENSE>',
  _DESCRIPTION = 'Tracking accesses and assignments to undefined variables in Lua code'
}