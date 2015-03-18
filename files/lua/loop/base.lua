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
-- Title  : Base Class Model                                                  --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Exported API:                                                              --
--   class(class)                                                             --
--   new(class, ...)                                                          --
--   classof(object)                                                          --
--   isclass(class)                                                           --
--   instanceof(object, class)                                                --
--   memberof(class, name)                                                    --
--   members(class)                                                           --
--------------------------------------------------------------------------------

local pairs        = pairs
local unpack       = unpack
local rawget       = rawget
local setmetatable = setmetatable
local getmetatable = getmetatable

module "loop.base"

--------------------------------------------------------------------------------
function rawnew(class, object)
	return setmetatable(object or {}, class)
end
--------------------------------------------------------------------------------
function new(class, ...)
	if class.__init
		then return class:__init(...)
		else return rawnew(class, ...)
	end
end
--------------------------------------------------------------------------------
function initclass(class)
	if class == nil then class = {} end
	if class.__index == nil then class.__index = class end
	return class
end
--------------------------------------------------------------------------------
local MetaClass = { __call = new }
function class(class)
	return setmetatable(initclass(class), MetaClass)
end
--------------------------------------------------------------------------------
classof = getmetatable
--------------------------------------------------------------------------------
function isclass(class)
	return classof(class) == MetaClass
end
--------------------------------------------------------------------------------
function instanceof(object, class)
	return classof(object) == class
end
--------------------------------------------------------------------------------
memberof = rawget
--------------------------------------------------------------------------------
members = pairs
