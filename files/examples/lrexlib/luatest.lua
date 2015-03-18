-- See Copyright Notice in the file LICENSE

module (..., package.seeall)

-- arrays: deep comparison
function eq (t1, t2, lut)
  if t1 == t2 then return true end
  if type(t1) ~= "table" or type(t2) ~= "table" or #t1 ~= #t2 then
    return false
  end

  lut = lut or {} -- look-up table: are these 2 arrays already compared?
  lut[t1] = lut[t1] or {}
  if lut[t1][t2] then return true end
  lut[t2] = lut[t2] or {}
  lut[t1][t2], lut[t2][t1] = true, true

  for k,v in ipairs (t1) do
    if not eq (t2[k], v, lut) then return false end -- recursion
  end
  return true
end

NT = {} -- a unique "nil table", to be used instead of nils in datasets

-- pack vararg in table, replacing nils with "NT" table
local function packNT (...)
  local t = {}
  for i=1, select ("#", ...) do
    local v = select (i, ...)
    t[i] = (v == nil) and NT or v
  end
  return t
end

-- unpack table into vararg, replacing "NT" items with nils
local function unpackNT (t)
  local len = #t
  local function unpack_from (i)
    local v = t[i]
    if v == NT then v = nil end
    if i == len then return v end
    return v, unpack_from (i+1)
  end
  if len > 0 then return unpack_from (1) end
end

-- print results (deep into arrays)
function print_results (val, indent, lut)
  indent = indent or ""
  lut = lut or {} -- look-up table
  local str = tostring (val)
  if type (val) == "table" then
    if val == NT then
      print (indent .. "nil")
    elseif lut[val] then
      print (indent .. str)
    else
      lut[val] = true
      print (indent .. str)
      for i,v in ipairs (val) do
        print_results (v, "  " .. indent, lut) -- recursion
      end
    end
  else
    print (indent .. str)
  end
end

-- returns: a table with "packed" results (or error message string)
function runtest_function (test, func)
  local t = packNT (pcall (func, unpackNT (test[1])))
  if t[1] then
    table.remove (t, 1)
    return t
  end
  return t[2] --> error_message
end

-- returns: a table with "packed" results (or err_num + error message string)
function runtest_method (test, constructor, name)
  local ok, r = pcall (constructor, unpackNT (test[1]))
  if not ok then
    return 1, r  --> 1, error_message
  end
  local t = packNT (pcall (r[name], r, unpackNT (test[2])))
  if t[1] then
    table.remove (t, 1)
    return t
  end
  return 2, t[2] --> 2, error_message
end

-- returns:
--  1) true, if success; false, if failure
--  2) test results table or error_message
function test_function (test, func)
  local res = runtest_function (test, func)
  if type (res) ~= type (test[2]) then
    return false, res
  end
  if type (res) == "string" or eq (res, test[2]) then
    return true, res -- allow error messages to differ
  end
  return false, res
end

-- returns:
--  1) true, if success; false, if failure
--  2) test results table or error_message
--  3) test results table or error_message
function test_method (test, constructor, name)
  local res1, res2 = runtest_method (test, constructor, name)
  if type (res1) ~= type (test[3]) then
    return false, res1, res2
  end
  if type (res1) == "number" then
    return (res1 == test[3]), res1, res2
  end
  return eq (res1, test[3]), res1, res2
end

-- returns: a list of failed tests
function test_set (set, lib)
  local list = {}

  if type (set.Func) == "function" then
    local func = set.Func
    for i,test in ipairs (set) do
      local ok, res = test_function (test, func)
      if not ok then
        table.insert (list, {i=i, res})
      end
    end

  elseif type (set.Method) == "string" then
    for i,test in ipairs (set) do
      local ok, res1, res2 = test_method (test, lib.new, set.Method)
      if not ok then
        table.insert (list, {i=i, res1, res2})
      end
    end

  else
    error ("neither set.Func nor set.Method is valid")
  end

  return list
end

