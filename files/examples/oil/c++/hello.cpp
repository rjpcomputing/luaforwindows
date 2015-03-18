#include "hello.hpp"

#include <iostream>

extern "C" {
#include <lauxlib.h>
}

using namespace Hello;

std::string HelloWorld::say_hello_to(std::string name)
{
	std::string message("C++: Hello " + name + "!");
	count++;
	if (!quiet) std::cout << message << std::endl;
	return message;
}

////////////////////////////////////////////////////////////////////////////////

int Wrapper::_set_quiet(lua_State *L)
{
	object->_set_quiet(lua_toboolean(L, 1) != 0);
	return 0;
}

int Wrapper::_get_quiet(lua_State *L)
{
	lua_pushboolean(L, object->_get_quiet() ? 1 : 0);
	return 1;
}

int Wrapper::_get_count(lua_State *L)
{
	lua_pushnumber(L, object->_get_count());
	return 1;
}

int Wrapper::say_hello_to(lua_State *L)
{
	std::string name(luaL_checkstring(L, 1));
	std::string result(object->say_hello_to(name));
	lua_pushstring(L, result.c_str());
	return 1;
}

////////////////////////////////////////////////////////////////////////////////

int Hello::lua_wrapper(lua_State *state)
{
	return OiLAccess::lua_wrapper<Wrapper>(state);
}

ExportedWrapper::Method Exported::methods[] = {
	{"_set_quiet",   &Wrapper::_set_quiet},
	{"_get_quiet",   &Wrapper::_get_quiet},
	{"_get_count",   &Wrapper::_get_count},
	{"say_hello_to", &Wrapper::say_hello_to},
{0,0} };
