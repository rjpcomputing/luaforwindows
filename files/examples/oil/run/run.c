#include <stdio.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <luasocket.h>

#ifndef PRELOAD
#include <oilbit.h>
#else
#include <oilall.h>
#endif

int main(int argc, char* argv[])
{
	lua_State *L;
	
	if (argc != 2) {
		fprintf(stderr, "Usage: run <script file>\n");
		return 1;
	}
	
	L = lua_open();
	luaL_openlibs(L);

#ifndef PRELOAD
	 // open the LuaSocket library
	luaL_findtable(L, LUA_GLOBALSINDEX, "package.loaded", 1);
	luaopen_socket_core(L);
	lua_setfield(L, -2, "socket.core");
	// open the OiL bit library (only OiL C library)
	luaopen_oil_bit(L);
#else
	// preload the LuaSocket library
	luaL_findtable(L, LUA_GLOBALSINDEX, "package.preload", 1);
	lua_pushcfunction(L, luaopen_socket_core);
	lua_setfield(L, -2, "socket.core");
	 // preload all OiL libraries
	luapreload_oilall(L);
#endif

	if (luaL_loadfile(L, argv[1]) || lua_pcall(L, 0, 0, 0))
		fprintf(stderr, "error in file '%s'\n", argv[1]);
		
	return 0;
}
