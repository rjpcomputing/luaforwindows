@set LUA_PATH=;;%LUA_DEV%\lua\?.luac
@set LUA_MPATH=?.mlua;%LUA_DEV%\lua\metalua\?.mlua
@lua "%LUA_DEV%\lua\metalua.luac" %*
