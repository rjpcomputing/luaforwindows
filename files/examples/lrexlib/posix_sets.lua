-- See Copyright Notice in the file LICENSE

local luatest = require "luatest"
local N = luatest.NT

local function set_f_find (lib, flg)
return {
  Name = "Function find",
  Func = lib.find,
  --{subj,   patt,      st,cf,ef},           { results }
  { {"abcd", ".+",      5},                  { N }     }, -- failing st
  { {"abc",  "aBC",     N, flg.ICASE},       { 1,3 }   }, -- cf
  { {"abc",  "^abc"},                        { 1,3 }   }, -- anchor
  { {"^abc", "^abc",    N,N,flg.NOTBOL},     { N }     }, -- anchor + ef
}
end

local function set_f_match (lib, flg)
return {
  Name = "Function match",
  Func = lib.match,
  --{subj,   patt,      st,cf,ef},           { results }
  { {"abcd", ".+",      5},                  { N }    }, -- failing st
  { {"abc",  "aBC",     N, flg.ICASE},       {"abc" } }, -- cf
  { {"abc",  "^abc"},                        {"abc" } }, -- anchor
  { {"^abc", "^abc",    N,N,flg.NOTBOL},     { N }    }, -- anchor + ef
}
end

local function set_m_exec (lib, flg)
return {
  Name = "Method exec",
  Method = "exec",
--  {patt,cf},         {subj,st,ef}           { results }
  { {".+"},            {"abcd",5},            { N }    }, -- failing st
  { {"aBC",flg.ICASE}, {"abc"},               {1,3,{}} }, -- cf
  { {"^abc"},          {"abc"},               {1,3,{}} }, -- anchor
  { {"^abc"},          {"^abc",N,flg.NOTBOL}, { N }    }, -- anchor + ef
}
end

local function set_m_tfind (lib, flg)
return {
  Name = "Method tfind",
  Method = "tfind",
--  {patt,cf},         {subj,st,ef}           { results }
  { {".+"},            {"abcd",5},            { N }    }, -- failing st
  { {"aBC",flg.ICASE}, {"abc"},               {1,3,{}} }, -- cf
  { {"^abc"},          {"abc"},               {1,3,{}} }, -- anchor
  { {"^abc"},          {"^abc",N,flg.NOTBOL}, { N }    }, -- anchor + ef
}
end

return function (libname)
  local lib = require (libname)
  local flags = lib.flags ()
  return {
    set_f_match  (lib, flags),
    set_f_find   (lib, flags),
    set_m_exec   (lib, flags),
    set_m_tfind  (lib, flags),
  }
end

