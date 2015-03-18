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
-- Title  : Object Request Dispatcher                                         --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- objects:Facet
-- 	object:object register(impl:object, objectkey:string)
-- 	impl:object unregister(objectkey:string)
-- 
-- dispatcher:Facet
-- 	success:boolean, [except:table]|results... dispatch(objectkey:string, operation:string|function, params...)
-- 
-- indexer:Receptacle
-- 	[member:string], [implementation:function] valueof(objectkey:string, operation:string)
--------------------------------------------------------------------------------


local oo         = require "oil.oo"
local Exception  = require "oil.Exception"
local Dispatcher = require "oil.kernel.base.Dispatcher"                         --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.kernel.typed.Dispatcher"

oo.class(_M, Dispatcher)

context = false

--------------------------------------------------------------------------------
-- Dispatcher facet

function dispatch(self, key, operation, default, ...)
	local indexer = self.context.indexer
	local member, implement = indexer:valueof(indexer:typeof(key), operation)
	if member then
		return Dispatcher.dispatch(self, key, operation, default or implement, ...)
	else
		return false, Exception{
			reason = "badoperation",
			message = "operation is illegal for object with key",
			operation = operation,
			key = key,
		}
	end
end

