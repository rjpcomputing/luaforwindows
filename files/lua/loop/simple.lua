--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Release: 2.3 beta                                                          --
-- Title  : Simple Inheritance Class Model                                    --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Exported API:                                                              --
--   class(class, super)                                                      --
--   new(class, ...)                                                          --
--   classof(object)                                                          --
--   isclass(class)                                                           --
--   instanceof(object, class)                                                --
--   memberof(class, name)                                                    --
--   members(class)                                                           --
--   superclass(class)                                                        --
--   subclassof(class, super)                                                 --
--------------------------------------------------------------------------------

local require = require
local rawget  = rawget
local pairs   = pairs

local table = require "loop.table"

module "loop.simple"
--------------------------------------------------------------------------------
local ObjectCache = require "loop.collection.ObjectCache"
local base        = require "loop.base"
--------------------------------------------------------------------------------
table.copy(base, _M)
--------------------------------------------------------------------------------
local DerivedClass = ObjectCache {
	retrieve = function(self, super)
		return base.class { __index = super, __call = new }
	end,
}
function class(class, super)
	if super
		then return DerivedClass[super](initclass(class))
		else return base.class(class)
	end
end
--------------------------------------------------------------------------------
function isclass(class)
	local metaclass = classof(class)
	if metaclass then
		return metaclass == rawget(DerivedClass, metaclass.__index) or
		       base.isclass(class)
	end
end
--------------------------------------------------------------------------------
function superclass(class)
	local metaclass = classof(class)
	if metaclass then return metaclass.__index end
end
--------------------------------------------------------------------------------
function subclassof(class, super)
	while class do
		if class == super then return true end
		class = superclass(class)
	end
	return false
end
--------------------------------------------------------------------------------
function instanceof(object, class)
	return subclassof(classof(object), class)
end
