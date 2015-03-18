--------------------------------------------------------------------------------
------------------------------  #####      ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------ ##   ## ##  ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------  #####  ### ###### ------------------------------
--------------------------------                --------------------------------
----------------------- An Object Request Broker in Lua ------------------------
--------------------------------------------------------------------------------
-- Project: OiL - ORB in Lua: An Object Request Broker in Lua                 --
-- Release: 0.4                                                               --
-- Title  : Server-Side Broker                                                --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- broker:Facet
-- 	[configs:table], [except:table] initialize([configs:table])
-- 	servant:object object(impl:object, [objectkey:string])
-- 	reference:string tostring(servant:object)
-- 	success:boolean, [except:table] pending()
-- 	success:boolean, [except:table] step()
-- 	success:boolean, [except:table] run()
-- 	success:boolean, [except:table] shutdown()
-- 
-- objects:Receptacle
-- 	object:object register(impl:object, key:string)
-- 	impl:object unregister(key:string)
-- 	impl:object retrieve(key:string)
-- 
-- acceptor:Receptacle
-- 	configs:table, [except:table] setup([configs:table])
-- 	success:boolean, [except:table] hasrequest(configs:table)
-- 	success:boolean, [except:table] acceptone(configs:table)
-- 	success:boolean, [except:table] acceptall(configs:table)
-- 	success:boolean, [except:table] halt(configs:table)
-- 
-- references:Receptacle
-- 	reference:table referenceto(objectkey:string, accesspointinfo:table...)
-- 	stringfiedref:string encode(reference:table)
-- 
-- types:Receptacle
-- 	type:table resolve(type:string)
--------------------------------------------------------------------------------

local getmetatable = getmetatable
local rawget       = rawget
local type         = type

local table = require "loop.table"

local oo     = require "oil.oo"
local Server = require "oil.kernel.base.Server"                                 --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.kernel.typed.Server"

oo.class(_M, Server)

context = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local KeyFmt = "\0%s%s"

function object(self, object, key, type)
	local context = self.context
	local metatable = getmetatable(object)
	if metatable then
		type = object.__type   or metatable.__type   or type
		key  = object.__objkey or metatable.__objkey or key
	else
		type = object.__type   or type
		key  = object.__objkey or key
	end
	local result, except = context.types:resolve(type)
	if result then
		key = key or KeyFmt:format(self:hashof(object), self:hashof(result))
		result, except = context.mapper:register(result, key)
		if result then
			result, except = Server.object(self, object, key)
			if not result then
				context.mapper:unregister(key)
			end
		end
	end
	return result, except
end

function remove(self, key, objtype)
	local context = self.context
	local result, except
	if type(key) == "table" then key = rawget(key, "_key") or key end
	if type(key) ~= "string" then
		result, except = context.types:resolve(result)
		if result
			then key = KeyFmt:format(self:hashof(key), self:hashof(result))
			else key = nil
		end
	end
	if key then
		result, except = context.mapper:unregister(key)
		if result then
			result, except = context.objects:unregister(key)
		end
	end
	return result, except
end
