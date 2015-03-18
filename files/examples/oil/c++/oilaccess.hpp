#ifndef OILACCESS_H
#define OILACCESS_H

extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

namespace OiLAccess {

	//
	// Template implementation auxilary functions
	//
	extern const char *CLASS_REGISTRY;
	extern const char *OBJECT_REGISTRY;

	int lua_tableinsert(lua_State *L, int table);
	void lua_pushregistry(lua_State *L, const char *name);

	//
	// Template declarations
	//
	template <class Actual> class Exported;

	template <class Actual> class ExportedObject {
	private:
		friend class Exported<Actual>;

		Exported<Actual> *exportedClass;
		Actual           *actualObject;
		int              registerIndex;
		
		ExportedObject(Exported<Actual> *expCls, Actual *instance);
		~ExportedObject();
	public:
		Actual *getObject();
		void pushOnStack();
	};

	template <class Actual> class Exported {
	public:

		typedef int (Actual::*PMethod)(lua_State*);

		typedef struct Method {
			const char* name;
			PMethod method;
		};
		
		typedef ExportedObject<Actual> Object;

		Exported(lua_State *state, Method *methods, lua_CFunction func);
		~Exported();

		Object *newObject(Actual *instance);

	private:
		friend class ExportedObject<Actual>;
		
		lua_State *luaState;
		Method    *methodList;
		int       registerIndex;

		int registerObject(Actual *object);
		void unregisterObject(int index);
		void pushObject(int index);
	};

};

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace OiLAccess {

	//
	// template ExportedObject member implementation
	//
	template <class Actual>
	ExportedObject<Actual>::ExportedObject(Exported<Actual> *expCls, Actual *instance) :
		exportedClass(expCls),
		actualObject(instance),
		registerIndex(exportedClass->registerObject(actualObject)) {};
	
	template <class Actual>
	ExportedObject<Actual>::~ExportedObject()
		{ exportedClass->unregisterObject(registerIndex); }
	
	template <class Actual>
	Actual* ExportedObject<Actual>::getObject()
		{ return actualObject; }
	
	template <class Actual>
	void ExportedObject<Actual>::pushOnStack()
		{ exportedClass->pushObject(registerIndex); }

	//
	// auxilary template functions
	//
	template <class Actual>
	void lua_boxmember( lua_State *L, typename Exported<Actual>::PMethod member )
	{
		int pointer_size = sizeof(typename Exported<Actual>::PMethod);
		void *userdata = lua_newuserdata(L, pointer_size);
		typename Exported<Actual>::PMethod *box =
			static_cast< typename Exported<Actual>::PMethod* >(userdata);
		*box = member;
	}
	
	template <class Actual>
	typename Exported<Actual>::PMethod lua_unboxmember( lua_State *L, int index )
	{
		void *userdata = lua_touserdata(L, index);
		typename Exported<Actual>::PMethod *box =
			static_cast< typename Exported<Actual>::PMethod* >(userdata);
		return *box;
	}
	//--------------------------------------------------------------------------
	template <class Actual>
	void lua_boxobject( lua_State *L, Actual *object )
	{
		int pointer_size = sizeof(Actual*);
		void *userdata = lua_newuserdata(L, pointer_size);
		Actual **box = static_cast< Actual** >(userdata);
		*box = object;
	}
	
	template <class Actual>
	Actual *lua_unboxobject( lua_State *L, int index )
	{
		void *userdata = lua_touserdata(L, index);
		Actual **box = static_cast< Actual** >(userdata);
		return *box;
	}
	//--------------------------------------------------------------------------
	template <class Actual>
	void lua_newcppclass(lua_State *L, typename Exported<Actual>::Method *methods, lua_CFunction func)
	{
		lua_newtable(L);
		int metatable = lua_gettop(L);
		for (int i = 0; methods[i].name; ++i) {
			lua_pushstring(L, methods[i].name);
			lua_boxmember<Actual>(L, methods[i].method);
			lua_pushcclosure(L, func, 1);
			lua_rawset(L, metatable);
		}
		lua_pushliteral(L, "__index");
		lua_pushvalue(L, metatable);
		lua_rawset(L, metatable);
	}
	//--------------------------------------------------------------------------
	template <class Actual>
	int lua_wrapper(lua_State *L)
	{
		int index = lua_upvalueindex(1);
		luaL_checktype(L, 1, LUA_TUSERDATA);
	
		typename Exported<Actual>::PMethod method = lua_unboxmember<Actual>(L, index);
		Actual *object = lua_unboxobject<Actual>(L, 1);
		lua_remove(L, 1);
		
		return ((*object).*method)(L);
	}

	//
	// template Exported member implementation
	//
	template <class Actual>
	Exported<Actual>::Exported(lua_State *state, typename Exported<Actual>::Method *methods, lua_CFunction func)
		: luaState(state), methodList(methods)
	{
		lua_pushregistry(luaState, CLASS_REGISTRY);
		lua_newcppclass<Actual>(luaState, methodList, func);
		registerIndex = lua_tableinsert(luaState, -2);
		lua_pop(luaState, 1);
	}
	
	template <class Actual>
	Exported<Actual>::~Exported()
	{
	}
	//--------------------------------------------------------------------------
	template <class Actual>
	int Exported<Actual>::registerObject(Actual *object)
	{
		lua_pushregistry(luaState, OBJECT_REGISTRY);  // OBJECTS
		lua_boxobject<Actual>(luaState, object);      // OBJECTS, object
		lua_pushregistry(luaState, CLASS_REGISTRY);   // OBJECTS, object, CLASSES
		lua_pushnumber(luaState, registerIndex);      // OBJECTS, object, CLASSES, classIndex
		lua_rawget(luaState, -2);                     // OBJECTS, object, CLASSES, classMeta
		lua_setmetatable(luaState, -3);               // OBJECTS, object, CLASSES
		lua_pop(luaState, 1);                         // OBJECTS, object
		int result = lua_tableinsert(luaState, -2);   // OBJECTS
		lua_pop(luaState, 1);                         // 
		return result;
	}
	
	template <class Actual>
	void Exported<Actual>::unregisterObject(int index)
	{
		lua_pushregistry(luaState, OBJECT_REGISTRY);  // OBJECTS
		lua_pushnumber(luaState, index);              // OBJECTS, index
		lua_rawget(luaState, -2);                     // OBJECTS, object
		lua_pushnil(luaState);                        // OBJECTS, object, nil
		lua_setmetatable(luaState, -2);               // OBJECTS, object
		lua_pop(luaState, 1);                         // OBJECTS 
		lua_pushnumber(luaState, index);              // OBJECTS, index
		lua_pushnil(luaState);                        // OBJECTS, index, nil
		lua_rawset(luaState, -2);                     // OBJECTS
		lua_pop(luaState, 1);                         // 
	}
	
	template <class Actual>
	void Exported<Actual>::pushObject(int index)
	{
		lua_pushregistry(luaState, OBJECT_REGISTRY);  // OBJECTS
		lua_pushnumber(luaState, index);              // OBJECTS, index
		lua_rawget(luaState, -2);                     // OBJECTS, object
		lua_remove(luaState, -2);                     // object
	}

	template <class Actual>
	typename Exported<Actual>::Object *Exported<Actual>::newObject(Actual *instance)
	{
		return new typename Exported<Actual>::Object(this, instance);
	}

};

#endif /* OILACCESS_H */
