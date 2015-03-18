#ifndef HELLO_H
#define HELLO_H

#include <string>
#include "oilaccess.hpp"

namespace Hello {
	
	class HelloWorld {
		bool quiet;
		long count;
	public:
		HelloWorld(bool isquiet) : quiet(isquiet), count(0) {};
		void _set_quiet(bool value) { quiet = value; };
		bool _get_quiet()           { return quiet; };
		long _get_count()           { return count; };
		std::string say_hello_to(std::string name);
	};

	class Wrapper {
		HelloWorld *object;
	public:
		Wrapper(HelloWorld *obj) : object(obj) {};
		int _set_quiet  (lua_State *state);
		int _get_quiet  (lua_State *state);
		int _get_count  (lua_State *state);
		int say_hello_to(lua_State *state);
	};

	int lua_wrapper(lua_State *state);

	typedef OiLAccess::Exported<Wrapper> ExportedWrapper;

	class Exported : public ExportedWrapper {
		static Method methods[];
	public:
		Exported(lua_State *state)
		: ExportedWrapper(state, methods, lua_wrapper) {};
	};
};

#endif /* HELLO_H */
