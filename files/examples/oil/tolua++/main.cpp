#include <iostream>
#include <string.h>

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <luasocket.h>
#include <oilbit.h>
}

#ifndef TOLUA_API
#define TOLUA_API
#endif

#include "hello.hpp"
#include "bind.hpp"

////////////////////////////////////////////////////////////////////////////////

static bool callfield(lua_State *L, const char *name, int narg, int nres);
static void pushfield(lua_State *L, const char *name);

lua_State *newstate()
{
	lua_State *L = lua_open();

	luaL_openlibs(L);
	luaopen_socket_core(L);
#ifndef PRELOAD
	luaopen_oil_bit(L);   // open the OiL bit library (only OiL C library)
#else
	luapreload_oilall(L); // preload all OiL libraries
#endif
	
	return L;
}

int main(int argc, char* argv[])
{
	Hello::HelloWorld *hello = new Hello::HelloWorld(true);
	
	lua_State *L = newstate();
	
	// require "oil"
	lua_pushliteral(L, "oil");
	callfield(L, "require", 1, 0);
	
	// oil.loadidl("interface Hello { ... }")
	lua_pushliteral(L, 
		"interface Hello {"
		"  attribute boolean quiet;"
		"  readonly attribute long count;"
		"  string say_hello_to(in string name);"
		"};");
	callfield(L, "oil.loadidl", 1, 0);
	
	// oil.writeto('...ref', oil.tostring(oil.newservant(<hello>, "::Hello")))
	lua_pushliteral(L, "../hello/hello.ref");
	tolua_pushusertype(L, (void*)hello, "Hello::HelloWorld");
	lua_pushliteral(L, "::Hello");
	callfield(L, "oil.newservant", 2, 1);
	callfield(L, "oil.tostring", 1, 1);
	callfield(L, "oil.writeto", 2, 0);
	
	// oil.main(oil.run())
	pushfield(L, "oil.run");
	callfield(L, "oil.main", 1, 0);
	
	return 0;
}

////////////////////////////////////////////////////////////////////////////////

static void pushfield(lua_State *L, const char *name)
{
	const char *end = strchr(name, '.');
	lua_pushvalue(L, LUA_GLOBALSINDEX);
	while (end) {
		lua_pushlstring(L, name, end - name);
		lua_gettable(L, -2);
		lua_remove(L, -2);
		if (lua_isnil(L, -1)) return;
		name = end+1;
		end = strchr(name, '.');
	}
	lua_pushstring(L, name);
	lua_gettable(L, -2);
	lua_remove(L, -2);
}

static int traceback (lua_State *L) {
	lua_getfield(L, LUA_GLOBALSINDEX, "debug");
	if (!lua_istable(L, -1)) {
		lua_pop(L, 1);
		return 1;
	}
	lua_getfield(L, -1, "traceback");
	if (!lua_isfunction(L, -1)) {
		lua_pop(L, 2);
		return 1;
	}
	lua_pushvalue(L, 1);  /* pass error message */
	lua_pushinteger(L, 2);  /* skip this function and traceback */
	lua_call(L, 2, 1);  /* call debug.traceback */
	return 1;
}

static bool callfield(lua_State *L, const char *name, int narg, int nres)
{
	pushfield(L, name);
	int base = lua_gettop(L) - narg;  /* 1st arg index */
	lua_insert(L, base);  /* put function under args */
	lua_pushcfunction(L, traceback);  /* push traceback function */
	lua_insert(L, base);  /* put traceback under function and args */
	int status = lua_pcall(L, narg, nres, base);
	lua_remove(L, base);  /* remove traceback function */
	if (status && !lua_isnil(L, -1)) {
		const char *msg;
		if (lua_istable(L, -1)) {
			lua_getfield(L, LUA_GLOBALSINDEX, "tostring");
			lua_insert(L, -2);
			lua_call(L, 1, 1);
		}
		msg = lua_tostring(L, -1);
		if (msg == NULL) msg = "(error object is not a string)";
		fprintf(stderr, "%s\n", msg);
		lua_pop(L, 1);
		return false;
	}
	return true;
}
