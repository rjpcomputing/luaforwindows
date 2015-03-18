require "logging.sql"
local has_module, err = pcall(require, "luasql.sqlite3")
if not has_module then
   print("SQLite 3 Logging SKIP (missing luasql.sqlite3)")
else
   if not luasql or not luasql.sqlite3 then
      print("Missing LuaSQL SQLite 3 driver!")
   else
      local env, err = luasql.sqlite3()

      local logger = logging.sql{
         connectionfactory = function()
                                local con, err = env:connect("test.db")
                                assert(con, err)
                                return con
                             end,
         keepalive = true,
      }

      logger:info("logging.sql test")
      logger:debug("debugging...")
      logger:error("error!")
      print("SQLite 3 Logging OK")
   end
end