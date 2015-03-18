#include "oilaccess.hpp"

const char *OiLAccess::CLASS_REGISTRY = "OiL C++ Classes";
const char *OiLAccess::OBJECT_REGISTRY = "OiL C++ Objects";

int OiLAccess::lua_tableinsert(lua_State *L, int table)
{
	if (table < 0) table += lua_gettop(L) + 1;
	int index = luaL_getn(L, table);
	lua_rawseti(L, table, ++index);
	luaL_setn(L, table, index);
	return index;
}

void OiLAccess::lua_pushregistry(lua_State *L, const char *name)
{
	lua_pushstring(L, name);
	lua_rawget(L, LUA_REGISTRYINDEX);
	if (lua_isnil(L, -1)) {
		lua_pop(L, 1);
		lua_newtable(L);
		lua_pushstring(L, name);
		lua_pushvalue(L, -2);
		lua_rawset(L, LUA_REGISTRYINDEX);
	}
}
