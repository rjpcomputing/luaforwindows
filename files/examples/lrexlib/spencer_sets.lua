-- See Copyright Notice in the file LICENSE

local luatest = require "luatest"
local N = luatest.NT

local function norm(a) return a==nil and N or a end

local function get_gsub (lib)
  return lib.gsub or
    function (subj, pattern, repl, n)
      return lib.new (pattern) : gsub (subj, repl, n)
    end
end

local function set_f_gsub1 (lib, flg)
  local subj, pat = "abcdef", "[abef]+"
  return {
    Name = "Function gsub, set1",
    Func = get_gsub (lib),
  --{ s,       p,    f,   n,    res1,  res2, res3 },
    { {"a\0c", ".",  "#"   },   {"###",   3, 3} }, -- subj contains nuls
  }
end

local function set_f_find (lib, flg)
return {
  Name = "Function find",
  Func = lib.find,
  --{subj,   patt,      st,cf,ef},           { results }
  { {"a\0c", ".+"},                          { 1,3 }   }, -- subj contains nul
  { {"a\0c", "a\0c",    N,flg.PEND},         { 1,3 }   }, -- subj and patt contain nul
}
end

local function set_f_match (lib, flg)
return {
  Name = "Function match",
  Func = lib.match,
  --{subj,   patt,      st,cf,ef},           { results }
  { {"a\0c", ".+"},                          {"a\0c"} }, -- subj contains nul
  { {"a\0c", "a\0c",    N,flg.PEND},         {"a\0c"} }, -- subj and patt contain nul
}
end

local function set_f_gmatch (lib, flg)
  -- gmatch (s, p, [cf], [ef])
  local function test_gmatch (subj, patt)
    local out, guard = {}, 10
    for a, b in lib.gmatch (subj, patt) do
      table.insert (out, { norm(a), norm(b) })
      guard = guard - 1
      if guard == 0 then break end
    end
    return unpack (out)
  end
  return {
    Name = "Function gmatch",
    Func = test_gmatch,
  --{  subj             patt         results }
    { {"a\0c",          "." },       {{"a",N},{"\0",N},{"c",N}} },--nuls in subj
  }
end

local function set_f_split (lib, flg)
  -- split (s, p, [cf], [ef])
  local function test_split (subj, patt)
    local out, guard = {}, 10
    for a, b, c in lib.split (subj, patt) do
      table.insert (out, { norm(a), norm(b), norm(c) })
      guard = guard - 1
      if guard == 0 then break end
    end
    return unpack (out)
  end
  return {
    Name = "Function split",
    Func = test_split,
  --{  subj             patt      results }
    { {"a,\0,c",        ","},     {{"a",",",N},{"\0",",",N},{"c",N,N},   } },--nuls in subj
  }
end

local function set_m_exec (lib, flg)
return {
  Name = "Method exec",
  Method = "exec",
--  {patt,cf},         {subj,st,ef}           { results }
  { {".+"},            {"a\0c"},              {1,3,{}} }, -- subj contains nul
  { {"a\0c",flg.PEND}, {"a\0c"},              {1,3,{}} }, -- subj and patt contain nul
}
end

local function set_m_tfind (lib, flg)
return {
  Name = "Method tfind",
  Method = "tfind",
--  {patt,cf},         {subj,st,ef}           { results }
  { {".+"},            {"a\0c"},              {1,3,{}} }, -- subj contains nul
  { {"a\0c",flg.PEND}, {"a\0c"},              {1,3,{}} }, -- subj and patt contain nul
}
end

return function (libname)
  local lib = require (libname)
  local flags = lib.flags ()
  return {
    set_f_match  (lib, flags),
    set_f_find   (lib, flags),
    set_f_gmatch (lib, flags),
    set_f_gsub1  (lib, flags),
    set_m_exec   (lib, flags),
    set_m_tfind  (lib, flags),
  }
end

