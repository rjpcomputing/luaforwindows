local package = package

require 'metalua.mlc'

package.metalua_extension_prefix = 'metalua.extension.'

package.mpath = os.getenv 'LUA_MPATH' or
   './?.mlua;/usr/local/share/lua/5.1/?.mlua;'..
   '/usr/local/share/lua/5.1/?/init.mlua;'..
   '/usr/local/lib/lua/5.1/?.mlua;'..
   '/usr/local/lib/lua/5.1/?/init.mlua'


----------------------------------------------------------------------
-- resc(k) returns "%"..k if it's a special regular expression char,
-- or just k if it's normal.
----------------------------------------------------------------------
local regexp_magic = table.transpose{
   "^", "$", "(", ")", "%", ".", "[", "]", "*", "+", "-", "?" }
local function resc(k)
   return regexp_magic[k] and '%'..k or k
end

----------------------------------------------------------------------
-- Take a Lua module name, return the open file and its name,
-- or <false> and an error message.
----------------------------------------------------------------------
function package.findfile(name, path_string)
   local config_regexp = ("([^\n])\n"):rep(5):sub(1, -2)
   local dir_sep, path_sep, path_mark, execdir, igmark =
      package.config:strmatch (config_regexp)
   name = name:gsub ('%.', dir_sep)
   local errors = { }
   local path_pattern = string.format('[^%s]+', resc(path_sep))
   for path in path_string:gmatch (path_pattern) do
      --printf('path = %s, rpath_mark=%s, name=%s', path, resc(path_mark), name)
      local filename = path:gsub (resc (path_mark), name)
      --printf('filename = %s', filename)
      local file = io.open (filename, 'r')
      if file then return file, filename end
      table.insert(errors, string.format("\tno lua file %q", filename))
   end
   return false, table.concat(errors, "\n")..'\n'
end

----------------------------------------------------------------------
-- Execute a metalua module sources compilation in a separate process
-- Sending back the bytecode directly is difficult, as some shells
-- (at least MS-Windows') interpret some characters. So rather than
-- base64-encoding the bytecode, AST is returned from the child
-- process, and converted to bytecode then function in the calling
-- process.
----------------------------------------------------------------------
local function spring_load(filename)
   -- FIXME: handle compilation errors
   local pattern = 
      [=[lua -l metalua.compiler -l serialize -e ]=]..
      [=["print(serialize(mlc.ast_of_luafile [[%s]]))"]=]
   local cmd = string.format (pattern, filename)
   --print ("running command: ``" .. cmd .. "''")
   local fd = io.popen (cmd)
   local ast_src = fd:read '*a'
   fd:close()
   local ast = lua_loadstring (ast_src) () -- much faster than loadstring()
   return mlc.function_of_ast (ast, filename)
end

----------------------------------------------------------------------
-- Load a metalua source file.
----------------------------------------------------------------------
function package.metalua_loader (name)
   local file, filename_or_msg = package.findfile (name, package.mpath)
   if not file then return filename_or_msg end
   if package.metalua_nopopen then
      local luastring = file:read '*a'
      file:close()
      return mlc.function_of_luastring (luastring, name)
   else      
      file:close()
      require 'metalua.mlc_xcall'
      local status, ast = mlc_xcall.client_file (filename_or_msg)
      return mlc.function_of_ast(ast)
   end
end

----------------------------------------------------------------------
-- Placed after lua/luac loader, so precompiled files have
-- higher precedence.
----------------------------------------------------------------------
table.insert(package.loaders, package.metalua_loader)

----------------------------------------------------------------------
-- Load an extension.
----------------------------------------------------------------------
function extension (name, noruntime)
   local complete_name = package.metalua_extension_prefix..name
   local x = require (complete_name)
   if x==true then return
   elseif type(x) ~= 'table' then
      error ("extension returned %s instead of an AST", type(x))
   else
      return x
   end
end

return package
