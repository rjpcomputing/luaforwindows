
--- Functions for managing the repository on disk.
local repos = {}

local fs = require("luarocks.fs")
local path = require("luarocks.path")
local cfg = require("luarocks.core.cfg")
local util = require("luarocks.util")
local dir = require("luarocks.dir")
local manif = require("luarocks.manif")
local vers = require("luarocks.core.vers")
local E = {}

local unpack = unpack or table.unpack

--- Get type and name of an item (a module or a command) provided by a file.
-- @param deploy_type string: rock manifest subtree the file comes from ("bin", "lua", or "lib").
-- @param file_path string: path to the file relatively to deploy_type subdirectory.
-- @return (string, string): item type ("module" or "command") and name.
local function get_provided_item(deploy_type, file_path)
   assert(type(deploy_type) == "string")
   assert(type(file_path) == "string")
   local item_type = deploy_type == "bin" and "command" or "module"
   local item_name = item_type == "command" and file_path or path.path_to_module(file_path)
   return item_type, item_name
end

-- Tree of files installed by a package are stored
-- in its rock manifest. Some of these files have to
-- be deployed to locations where Lua can load them as
-- modules or where they can be used as commands.
-- These files are characterised by pair
-- (deploy_type, file_path), where deploy_type is the first
-- component of the file path and file_path is the rest of the
-- path. Only files with deploy_type in {"lua", "lib", "bin"}
-- are deployed somewhere.
-- Each deployed file provides an "item". An item is
-- characterised by pair (item_type, item_name).
-- item_type is "command" for files with deploy_type
-- "bin" and "module" for deploy_type in {"lua", "lib"}.
-- item_name is same as file_path for commands
-- and is produced using path.path_to_module(file_path)
-- for modules.

--- Get all installed versions of a package.
-- @param name string: a package name.
-- @return table or nil: An array of strings listing installed
-- versions of a package, or nil if none is available.
local function get_installed_versions(name)
   assert(type(name) == "string" and not name:match("/"))
   
   local dirs = fs.list_dir(path.versions_dir(name))
   return (dirs and #dirs > 0) and dirs or nil
end

--- Check if a package exists in a local repository.
-- Version numbers are compared as exact string comparison.
-- @param name string: name of package
-- @param version string: package version in string format
-- @return boolean: true if a package is installed,
-- false otherwise.
function repos.is_installed(name, version)
   assert(type(name) == "string" and not name:match("/"))
   assert(type(version) == "string")
      
   return fs.is_dir(path.install_dir(name, version))
end

function repos.recurse_rock_manifest_entry(entry, action)
   assert(type(action) == "function")

   if entry == nil then
      return true
   end

   local function do_recurse_rock_manifest_entry(tree, parent_path)

      for file, sub in pairs(tree) do
         local sub_path = (parent_path and (parent_path .. "/") or "") .. file
         local ok, err

         if type(sub) == "table" then
            ok, err = do_recurse_rock_manifest_entry(sub, sub_path)
         else
            ok, err = action(sub_path)
         end

         if err then return nil, err end
      end
      return true
   end
   return do_recurse_rock_manifest_entry(entry)
end

local function store_package_data(result, rock_manifest, deploy_type)
   if rock_manifest[deploy_type] then
      repos.recurse_rock_manifest_entry(rock_manifest[deploy_type], function(file_path)
         local _, item_name = get_provided_item(deploy_type, file_path)
         result[item_name] = file_path
         return true
      end)
   end
end

--- Obtain a table of modules within an installed package.
-- @param name string: The package name; for example "luasocket"
-- @param version string: The exact version number including revision;
-- for example "2.0.1-1".
-- @return table: A table of modules where keys are module names
-- and values are file paths of files providing modules
-- relative to "lib" or "lua" rock manifest subtree.
-- If no modules are found or if package name or version
-- are invalid, an empty table is returned.
function repos.package_modules(name, version)
   assert(type(name) == "string" and not name:match("/"))
   assert(type(version) == "string")

   local result = {}
   local rock_manifest = manif.load_rock_manifest(name, version)
   if not rock_manifest then return result end
   store_package_data(result, rock_manifest, "lib")
   store_package_data(result, rock_manifest, "lua")
   return result
end

--- Obtain a table of command-line scripts within an installed package.
-- @param name string: The package name; for example "luasocket"
-- @param version string: The exact version number including revision;
-- for example "2.0.1-1".
-- @return table: A table of commands where keys and values are command names
-- as strings - file paths of files providing commands
-- relative to "bin" rock manifest subtree.
-- If no commands are found or if package name or version
-- are invalid, an empty table is returned.
function repos.package_commands(name, version)
   assert(type(name) == "string" and not name:match("/"))
   assert(type(version) == "string")

   local result = {}
   local rock_manifest = manif.load_rock_manifest(name, version)
   if not rock_manifest then return result end
   store_package_data(result, rock_manifest, "bin")
   return result
end


--- Check if a rock contains binary executables.
-- @param name string: name of an installed rock
-- @param version string: version of an installed rock
-- @return boolean: returns true if rock contains platform-specific
-- binary executables, or false if it is a pure-Lua rock.
function repos.has_binaries(name, version)
   assert(type(name) == "string" and not name:match("/"))
   assert(type(version) == "string")

   local rock_manifest = manif.load_rock_manifest(name, version)
   if rock_manifest and rock_manifest.bin then
      for bin_name, md5 in pairs(rock_manifest.bin) do
         -- TODO verify that it is the same file. If it isn't, find the actual command.
         if fs.is_actual_binary(dir.path(cfg.deploy_bin_dir, bin_name)) then
            return true
         end
      end
   end
   return false
end

function repos.run_hook(rockspec, hook_name)
   assert(rockspec:type() == "rockspec")
   assert(type(hook_name) == "string")

   local hooks = rockspec.hooks
   if not hooks then
      return true
   end
   
   if cfg.hooks_enabled == false then
      return nil, "This rockspec contains hooks, which are blocked by the 'hooks_enabled' setting in your LuaRocks configuration."
   end
   
   if not hooks.substituted_variables then
      util.variable_substitutions(hooks, rockspec.variables)
      hooks.substituted_variables = true
   end
   local hook = hooks[hook_name]
   if hook then
      util.printout(hook)
      if not fs.execute(hook) then
         return nil, "Failed running "..hook_name.." hook."
      end
   end
   return true
end

function repos.should_wrap_bin_scripts(rockspec)
   assert(rockspec:type() == "rockspec")

   if cfg.wrap_bin_scripts ~= nil then
      return cfg.wrap_bin_scripts
   end
   if rockspec.deploy and rockspec.deploy.wrap_bin_scripts == false then
      return false
   end
   return true
end

local function find_suffixed(file, suffix)
   local filenames = {file}
   if suffix and suffix ~= "" then
      table.insert(filenames, 1, file .. suffix)
   end

   for _, filename in ipairs(filenames) do
      if fs.exists(filename) then
         return filename
      end
   end

   return nil, table.concat(filenames, ", ") .. " not found"
end

local function check_suffix(filename, suffix)
   local suffixed_filename, err = find_suffixed(filename, suffix)
   if not suffixed_filename then
      return ""
   end
   return suffixed_filename:sub(#filename + 1)
end

-- Files can be deployed using versioned and non-versioned names.
-- Several items with same type and name can exist if they are
-- provided by different packages or versions. In any case
-- item from the newest version of lexicographically smallest package
-- is deployed using non-versioned name and others use versioned names.

local function get_deploy_paths(name, version, deploy_type, file_path, repo)
   assert(type(name) == "string")
   assert(type(version) == "string")
   assert(type(deploy_type) == "string")
   assert(type(file_path) == "string")

   repo = repo or cfg.root_dir
   local deploy_dir = path["deploy_" .. deploy_type .. "_dir"](repo)
   local non_versioned = dir.path(deploy_dir, file_path)
   local versioned = path.versioned_name(non_versioned, deploy_dir, name, version)
   return { nv = non_versioned, v = versioned }
end

local function check_spot_if_available(name, version, deploy_type, file_path)
   local item_type, item_name = get_provided_item(deploy_type, file_path)
   local cur_name, cur_version = manif.get_current_provider(item_type, item_name)
   if (not cur_name)
      or (name < cur_name)
      or (name == cur_name and (version == cur_version
                                or vers.compare_versions(version, cur_version))) then
      return "nv", cur_name, cur_version, item_name
   else
      -- Existing version has priority, deploy new version using versioned name.
      return "v", cur_name, cur_version, item_name
   end
end

local function backup_existing(should_backup, target)
   if not should_backup then
      fs.delete(target)
      return
   end
   if fs.exists(target) then
      local backup = target
      repeat
         backup = backup.."~"
      until not fs.exists(backup) -- Slight race condition here, but shouldn't be a problem.
   
      util.warning(target.." is not tracked by this installation of LuaRocks. Moving it to "..backup)
      local move_ok, move_err = fs.move(target, backup)
      if not move_ok then
         return nil, move_err
      end
   end
end

local function op_install(op)
   local ok, err = fs.make_dir(dir.dir_name(op.dst))
   if not ok then
      return nil, err
   end

   ok, err = op.fn(op.src, op.dst, op.backup)
   if not ok then
      return nil, err
   end

   fs.remove_dir_tree_if_empty(dir.dir_name(op.src))
end

local function op_rename(op)
   if op.suffix then
      local suffix = check_suffix(op.src, op.suffix)
      op.src = op.src .. suffix
      op.dst = op.dst .. suffix
   end

   if fs.exists(op.src) then
      fs.make_dir(dir.dir_name(op.dst))
      fs.delete(op.dst)
      local ok, err = fs.move(op.src, op.dst)
      fs.remove_dir_tree_if_empty(dir.dir_name(op.src))
      return ok, err
   else
      return true
   end
end

local function op_delete(op)
   if op.suffix then
      local suffix = check_suffix(op.name, op.suffix)
      op.name = op.name .. suffix
   end

   local ok, err = fs.delete(op.name)
   fs.remove_dir_tree_if_empty(dir.dir_name(op.name))
   return ok, err
end

--- Deploy a package from the rocks subdirectory.
-- @param name string: name of package
-- @param version string: exact package version in string format
-- @param wrap_bin_scripts bool: whether commands written in Lua should be wrapped.
-- @param deps_mode: string: Which trees to check dependencies for:
-- "one" for the current default tree, "all" for all trees,
-- "order" for all trees with priority >= the current default, "none" for no trees.
function repos.deploy_files(name, version, wrap_bin_scripts, deps_mode)
   assert(type(name) == "string" and not name:match("/"))
   assert(type(version) == "string")
   assert(type(wrap_bin_scripts) == "boolean")

   local rock_manifest, load_err = manif.load_rock_manifest(name, version)
   if not rock_manifest then return nil, load_err end
   
   local repo = cfg.root_dir
   local renames = {}
   local installs = {}

   local function install_binary(source, target, should_backup)
      if wrap_bin_scripts and fs.is_lua(source) then
         backup_existing(should_backup, target .. (cfg.wrapper_suffix or ""))
         return fs.wrap_script(source, target, deps_mode, name, version)
      else
         backup_existing(should_backup, target)
         return fs.copy_binary(source, target)
      end
   end

   local function move_lua(source, target, should_backup)
      backup_existing(should_backup, target)
      return fs.move(source, target, "read")
   end

   local function move_lib(source, target, should_backup)
      backup_existing(should_backup, target)
      return fs.move(source, target, "exec")
   end

   if rock_manifest.bin then
      local source_dir = path.bin_dir(name, version)
      repos.recurse_rock_manifest_entry(rock_manifest.bin, function(file_path)
         local source = dir.path(source_dir, file_path)
         local paths = get_deploy_paths(name, version, "bin", file_path, repo)
         local mode, cur_name, cur_version = check_spot_if_available(name, version, "bin", file_path)

         if mode == "nv" and cur_name then
            local cur_paths = get_deploy_paths(cur_name, cur_version, "bin", file_path, repo)
            table.insert(renames, { src = cur_paths.nv, dst = cur_paths.v, suffix = cfg.wrapper_suffix })
         end
         local backup = name ~= cur_name or version ~= cur_version
         table.insert(installs, { fn = install_binary, src = source, dst = mode == "nv" and paths.nv or paths.v, backup = backup })
      end)
   end

   if rock_manifest.lua then
      local source_dir = path.lua_dir(name, version)
      repos.recurse_rock_manifest_entry(rock_manifest.lua, function(file_path)
         local source = dir.path(source_dir, file_path)
         local paths = get_deploy_paths(name, version, "lua", file_path, repo)
         local mode, cur_name, cur_version = check_spot_if_available(name, version, "lua", file_path)

         if mode == "nv" and cur_name then
            local cur_paths = get_deploy_paths(cur_name, cur_version, "lua", file_path, repo)
            table.insert(renames, { src = cur_paths.nv, dst = cur_paths.v })
            cur_paths = get_deploy_paths(cur_name, cur_version, "lib", file_path:gsub("%.lua$", "." .. cfg.lib_extension), repo)
            table.insert(renames, { src = cur_paths.nv, dst = cur_paths.v })
         end
         local backup = name ~= cur_name or version ~= cur_version
         table.insert(installs, { fn = move_lua, src = source, dst = mode == "nv" and paths.nv or paths.v, backup = backup })
      end)
   end

   if rock_manifest.lib then
      local source_dir = path.lib_dir(name, version)
      repos.recurse_rock_manifest_entry(rock_manifest.lib, function(file_path)
         local source = dir.path(source_dir, file_path)
         local paths = get_deploy_paths(name, version, "lib", file_path, repo)
         local mode, cur_name, cur_version = check_spot_if_available(name, version, "lib", file_path)

         if mode == "nv" and cur_name then
            local cur_paths = get_deploy_paths(cur_name, cur_version, "lua", file_path:gsub("%.[^.]+$", ".lua"), repo)
            table.insert(renames, { src = cur_paths.nv, dst = cur_paths.v })
            cur_paths = get_deploy_paths(cur_name, cur_version, "lib", file_path, repo)
            table.insert(renames, { src = cur_paths.nv, dst = cur_paths.v })
         end
         local backup = name ~= cur_name or version ~= cur_version
         table.insert(installs, { fn = move_lib, src = source, dst = mode == "nv" and paths.nv or paths.v, backup = backup })
      end)
   end

   for _, op in ipairs(renames) do
      op_rename(op)
   end
   for _, op in ipairs(installs) do
      op_install(op)
   end

   local writer = require("luarocks.manif.writer")
   return writer.add_to_manifest(name, version, nil, deps_mode)
end

--- Delete a package from the local repository.
-- @param name string: name of package
-- @param version string: exact package version in string format
-- @param deps_mode: string: Which trees to check dependencies for:
-- "one" for the current default tree, "all" for all trees,
-- "order" for all trees with priority >= the current default, "none" for no trees.
-- @param quick boolean: do not try to fix the versioned name
-- of another version that provides the same module that
-- was deleted. This is used during 'purge', as every module
-- will be eventually deleted.
function repos.delete_version(name, version, deps_mode, quick)
   assert(type(name) == "string" and not name:match("/"))
   assert(type(version) == "string")
   assert(type(deps_mode) == "string")

   local rock_manifest, load_err = manif.load_rock_manifest(name, version)
   if not rock_manifest then return nil, load_err end

   local repo = cfg.root_dir
   local renames = {}
   local deletes = {}

   if rock_manifest.bin then
      repos.recurse_rock_manifest_entry(rock_manifest.bin, function(file_path)
         local paths = get_deploy_paths(name, version, "bin", file_path, repo)
         local mode, cur_name, cur_version, item_name = check_spot_if_available(name, version, "bin", file_path)
         if mode == "v" then
            table.insert(deletes, { name = paths.v, suffix = cfg.wrapper_suffix })
         else
            table.insert(deletes, { name = paths.nv, suffix = cfg.wrapper_suffix })

            local next_name, next_version = manif.get_next_provider("command", item_name)
            if next_name then
               local next_paths = get_deploy_paths(next_name, next_version, "lua", file_path, repo)
               table.insert(renames, { src = next_paths.v, dst = next_paths.nv, suffix = cfg.wrapper_suffix })
            end
         end
      end)
   end

   if rock_manifest.lua then
      repos.recurse_rock_manifest_entry(rock_manifest.lua, function(file_path)
         local paths = get_deploy_paths(name, version, "lua", file_path, repo)
         local mode, cur_name, cur_version, item_name = check_spot_if_available(name, version, "lua", file_path)
         if mode == "v" then
            table.insert(deletes, { name = paths.v })
         else
            table.insert(deletes, { name = paths.nv })

            local next_name, next_version = manif.get_next_provider("module", item_name)
            if next_name then
               local next_lua_paths = get_deploy_paths(next_name, next_version, "lua", file_path, repo)
               table.insert(renames, { src = next_lua_paths.v, dst = next_lua_paths.nv })
               local next_lib_paths = get_deploy_paths(next_name, next_version, "lib", file_path:gsub("%.[^.]+$", ".lua"), repo)
               table.insert(renames, { src = next_lib_paths.v, dst = next_lib_paths.nv })
            end
         end
      end)
   end

   if rock_manifest.lib then
      repos.recurse_rock_manifest_entry(rock_manifest.lib, function(file_path)
         local paths = get_deploy_paths(name, version, "lib", file_path, repo)
         local mode, cur_name, cur_version, item_name = check_spot_if_available(name, version, "lib", file_path)
         if mode == "v" then
            table.insert(deletes, { name = paths.v })
         else
            table.insert(deletes, { name = paths.nv })

            local next_name, next_version = manif.get_next_provider("module", item_name)
            if next_name then
               local next_lua_paths = get_deploy_paths(next_name, next_version, "lua", file_path:gsub("%.[^.]+$", ".lua"), repo)
               table.insert(renames, { src = next_lua_paths.v, dst = next_lua_paths.nv })
               local next_lib_paths = get_deploy_paths(next_name, next_version, "lib", file_path, repo)
               table.insert(renames, { src = next_lib_paths.v, dst = next_lib_paths.nv })
            end
         end
      end)
   end

   for _, op in ipairs(deletes) do
      op_delete(op)
   end
   if not quick then
      for _, op in ipairs(renames) do
         op_rename(op)
      end
   end

   fs.delete(path.install_dir(name, version))
   if not get_installed_versions(name) then
      fs.delete(dir.path(cfg.rocks_dir, name))
   end

   if quick then
      return true
   end

   local writer = require("luarocks.manif.writer")
   return writer.remove_from_manifest(name, version, nil, deps_mode)
end

return repos
