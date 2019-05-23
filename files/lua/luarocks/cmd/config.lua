--- Module implementing the LuaRocks "config" command.
-- Queries information about the LuaRocks configuration.
local config_cmd = {}

local persist = require("luarocks.persist")
local cfg = require("luarocks.core.cfg")
local util = require("luarocks.util")
local deps = require("luarocks.deps")
local dir = require("luarocks.dir")
local fs = require("luarocks.fs")

config_cmd.help_summary = "Query information about the LuaRocks configuration."
config_cmd.help_arguments = "(<key> | <key> <value> --scope=<scope> | <key> --unset --scope=<scope> | )"
config_cmd.help = [[
* When given a configuration key, it prints the value of that key
  according to the currently active configuration (taking into account
  all config files and any command-line flags passed)

  Examples:
     luarocks config lua_interpreter
     luarocks config variables.LUA_INCDIR
     luarocks config lua_version

* When given a configuration key and a value,
  it overwrites the config file (see the --scope option below to determine which)
  and replaces the value of the given key with the given value.

  * `lua_dir` is a special key as it checks for a valid Lua installation
    (equivalent to --lua-dir) and sets several keys at once.
  * `lua_version` is a special key as it changes the default Lua version
    used by LuaRocks commands (eqivalent to passing --lua-version). 

  Examples:
     luarocks config variables.OPENSSL_DIR /usr/local/openssl
     luarocks config lua_dir /usr/local
     luarocks config lua_version 5.3

* When given a configuration key and --unset,
  it overwrites the config file (see the --scope option below to determine which)
  and deletes that key from the file.

  Example: luarocks config variables.OPENSSL_DIR --unset

* When given no arguments, it prints the entire currently active
  configuration, resulting from reading the config files from
  all scopes.

  Example: luarocks config

OPTIONS
--scope=<scope>   The scope indicates which config file should be rewritten.
                  Accepted values are "system", "user" or "project".
                  * Using a wrapper created with `luarocks init`,
                    the default is "project".
                  * Using --local (or when `local_by_default` is `true`),
                    the default is "user".
                  * Otherwise, the default is "system".

--json           Output as JSON
]]
config_cmd.help_see_also = [[
	https://github.com/luarocks/luarocks/wiki/Config-file-format
	for detailed information on the LuaRocks config file format.
]]

local function config_file(conf)
   print(dir.normalize(conf.file))
   if conf.found then
      return true
   else
      return nil, "file not found"
   end
end

local cfg_skip = {
   errorcodes = true,
   flags = true,
   platforms = true,
   root_dir = true,
   upload_servers = true,
}

local function should_skip(k, v)
   return type(v) == "function" or cfg_skip[k]
end

local function cleanup(tbl)
   local copy = {}
   for k, v in pairs(tbl) do
      if not should_skip(k, v) then
         copy[k] = v
      end
   end
   return copy
end

local function traverse_varstring(var, tbl, fn, missing_parent)
   local k, r = var:match("^%[([0-9]+)%]%.(.*)$")
   if k then
      k = tonumber(k)
   else
      k, r = var:match("^([^.[]+)%.(.*)$")
      if not k then
         k, r = var:match("^([^[]+)(%[.*)$")
      end
   end
   
   if k then
      if not tbl[k] and missing_parent then
         missing_parent(tbl, k)
      end

      if tbl[k] then
         return traverse_varstring(r, tbl[k], fn, missing_parent)
      else
         return nil, "Unknown entry " .. k
      end
   end

   local i = var:match("^%[([0-9]+)%]$")
   if i then
      var = tonumber(i)
   end
   
   return fn(tbl, var)
end

local function print_json(value)
   local json_ok, json = util.require_json()
   if not json_ok then
      return nil, "A JSON library is required for this command. "..json
   end

   print(json.encode(value))
   return true
end

local function print_entry(var, tbl, is_json)
   return traverse_varstring(var, tbl, function(t, k)
      if not t[k] then
         return nil, "Unknown entry " .. k
      end
      local val = t[k]

      if not should_skip(var, val) then
         if is_json then
            return print_json(val)
         elseif type(val) == "string" then
            print(val)
         else
            persist.write_value(io.stdout, val)
         end
      end
      return true
   end)
end

local function infer_type(var)
   local typ
   traverse_varstring(var, cfg, function(t, k)
      if t[k] ~= nil then
         typ = type(t[k])
      end
   end)
   return typ
end

local function write_entries(keys, scope, do_unset)
   if scope == "project" and not cfg.config_files.project then
      return nil, "Current directory is not part of a project. You may want to run `luarocks init`."
   end
   
   local tbl, err = persist.load_config_file_if_basic(cfg.config_files[scope].file, cfg)
   if not tbl then
      return nil, err
   end
   
   for var, val in util.sortedpairs(keys) do
      traverse_varstring(var, tbl, function(t, k)
         if do_unset then
            t[k] = nil
         else
            local typ = infer_type(var)
            local v
            if typ == "number" and tonumber(val) then
               v = tonumber(val)
            elseif typ == "boolean" and val == "true" then
               v = true
            elseif typ == "boolean" and val == "false" then
               v = false
            else
               v = val
            end
            t[k] = v
            keys[var] = v
         end
         return true
      end, function(p, k)
         p[k] = {}
      end)
   end

   local ok, err = persist.save_from_table(cfg.config_files[scope].file, tbl)
   if ok then
      print(do_unset and "Removed" or "Wrote")
      for var, val in util.sortedpairs(keys) do
         if do_unset then
            print(("\t%s"):format(var))
         else
            print(("\t%s = %q"):format(var, val))
         end
      end
      print(do_unset and "from" or "to")
      print("\t" .. cfg.config_files[scope].file)
      return true
   else
      return nil, err
   end
end

local function check_scope(flags)
   local scope = flags["scope"]
                 or (flags["local"] and "user")
                 or (flags["project-tree"] and "project")
                 or (cfg.local_by_default and "user")
                 or "system"
   if scope ~= "system" and scope ~= "user" and scope ~= "project" then
      return nil, "Valid values for scope are: system, user, project"
   end

   return scope
end

--- Driver function for "config" command.
-- @return boolean: True if succeeded, nil on errors.
function config_cmd.command(flags, var, val)
   deps.check_lua(cfg.variables)
   
   -- deprecated flags
   if flags["lua-incdir"] then
      print(cfg.variables.LUA_INCDIR)
      return true
   end
   if flags["lua-libdir"] then
      print(cfg.variables.LUA_LIBDIR)
      return true
   end
   if flags["lua-ver"] then
      print(cfg.lua_version)
      return true
   end
   if flags["system-config"] then
      return config_file(cfg.config_files.system)
   end
   if flags["user-config"] then
      return config_file(cfg.config_files.user)
   end
   if flags["rock-trees"] then
      for _, tree in ipairs(cfg.rocks_trees) do
      	if type(tree) == "string" then
      	   util.printout(dir.normalize(tree))
      	else
      	   local name = tree.name and "\t"..tree.name or ""
      	   util.printout(dir.normalize(tree.root)..name)
      	end
      end
      return true
   end

   if var == "lua_version" and val then
      local scope, err = check_scope(flags)
      if not scope then
         return nil, err
      end

      if scope == "project" and not cfg.config_files.project then
         return nil, "Current directory is not part of a project. You may want to run `luarocks init`."
      end

      local prefix = dir.dir_name(cfg.config_files[scope].file)
      local ok, err = persist.save_default_lua_version(prefix, val)
      if not ok then
         return nil, "could not set default Lua version: " .. err
      end
      print("Lua version will default to " .. val .. " in " .. prefix)
   end
   
   if var == "lua_dir" and val then
      local scope, err = check_scope(flags)
      if not scope then
         return nil, err
      end
      local keys = {
         ["variables.LUA_DIR"] = cfg.variables.LUA_DIR,
         ["variables.LUA_BINDIR"] = cfg.variables.LUA_BINDIR,
         ["variables.LUA_INCDIR"] = cfg.variables.LUA_INCDIR,
         ["variables.LUA_LIBDIR"] = cfg.variables.LUA_LIBDIR,
         ["lua_interpreter"] = cfg.lua_interpreter,
      }
      return write_entries(keys, scope, flags["unset"])
   end

   if var then
      if val or flags["unset"] then
         local scope, err = check_scope(flags)
         if not scope then
            return nil, err
         end
   
         return write_entries({ [var] = val }, scope, flags["unset"])
      else
         return print_entry(var, cfg, flags["json"])
      end
   end

   local cleancfg = cleanup(cfg)

   if flags["json"] then
      return print_json(cleancfg)
   else
      print(persist.save_from_table_to_string(cleancfg))
      return true
   end
end

return config_cmd
