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
-- Title  : Component Model with Full Containment Support                     --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Exported API:                                                              --
--   Template                                                                 --
--   factoryof(component)                                                     --
--   templateof(factory|component)                                            --
--   ports(template)                                                          --
--   segmentof(portname, component)                                           --
--------------------------------------------------------------------------------

local pairs  = pairs
local select = select
local type   = type

local oo          = require "loop.cached"
local base        = require "loop.component.wrapped"

module "loop.component.contained"

--------------------------------------------------------------------------------

BaseTemplate = oo.class({}, base.BaseTemplate)

function BaseTemplate:__new(...)
	local state = { __factory = self }
	local comp = self.__component or self[1]
	if comp then
		comp = comp(...)
		state.__component = comp
	else
		comp = ... or {}
	end
	for port, class in pairs(self) do
		if type(port) == "string" and port:match("^%a[%w_]*$") then
			state[port] = class(comp and comp[port], comp)
		end
	end
	return state
end

function Template(template, ...)
	return oo.class(template, BaseTemplate, ...)
end

--------------------------------------------------------------------------------

delegate = base.delegate -- used by 'dynamic' component model

--------------------------------------------------------------------------------

factoryof  = base.factoryof
templateof = base.templateof
ports      = base.ports
segmentof  = base.segmentof

--------------------------------------------------------------------------------

addport    = base.addport
removeport = base.removeport