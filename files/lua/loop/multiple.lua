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
-- Title  : Multiple Inheritance Class Model                                  --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Exported API:                                                              --
--   class(class, ...)                                                        --
--   new(class, ...)                                                          --
--   classof(object)                                                          --
--   isclass(class)                                                           --
--   instanceof(object, class)                                                --
--   memberof(class, name)                                                    --
--   members(class)                                                           --
--   superclass(class)                                                        --
--   subclassof(class, super)                                                 --
--   supers(class)                                                            --
--------------------------------------------------------------------------------

local unpack  = unpack
local require = require
local ipairs  = ipairs
local select  = select

local table = require "loop.table"

module "loop.multiple"
--------------------------------------------------------------------------------
local base = require "loop.simple"
--------------------------------------------------------------------------------
table.copy(base, _M)
--------------------------------------------------------------------------------
local MultipleClass = {
	__call = new,
	__index = function (self, field)
		self = base.classof(self)
		for _, super in ipairs(self) do
			local value = super[field]
			if value ~= nil then return value end
		end
	end,
}

function class(class, ...)
	if select("#", ...) > 1
		then return base.rawnew(table.copy(MultipleClass, {...}), initclass(class))
		else return base.class(class, ...)
	end
end
--------------------------------------------------------------------------------
function isclass(class)
	local metaclass = base.classof(class)
	if metaclass then
		return metaclass.__index == MultipleClass.__index or
		       base.isclass(class)
	end
end
--------------------------------------------------------------------------------
function superclass(class)
	local metaclass = base.classof(class)
	if metaclass then
		local indexer = metaclass.__index
		if (indexer == MultipleClass.__index)
			then return unpack(metaclass)
			else return metaclass.__index
		end
	end
end
--------------------------------------------------------------------------------
local function isingle(single, index)
	if single and not index then
		return 1, single
	end
end
function supers(class)
	local metaclass = classof(class)
	if metaclass then
		local indexer = metaclass.__index
		if indexer == MultipleClass.__index
			then return ipairs(metaclass)
			else return isingle, indexer
		end
	end
	return isingle
end
--------------------------------------------------------------------------------
function subclassof(class, super)
	if class == super then return true end
	for _, superclass in supers(class) do
		if subclassof(superclass, super) then return true end
	end
	return false
end
--------------------------------------------------------------------------------
function instanceof(object, class)
	return subclassof(classof(object), class)
end
