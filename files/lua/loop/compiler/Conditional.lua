--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Conditional Compiler for Code Generation                          --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local type       = type
local assert     = assert
local ipairs     = ipairs
local setfenv    = setfenv
local loadstring = loadstring

local table = require "table"
local oo    = require "loop.base"

module("loop.compiler.Conditional", oo.class)

function source(self, includes)
	local func = {}
	for line, strip in ipairs(self) do
		local cond = strip[2]
		if cond then
			cond = assert(loadstring("return "..cond,
				"compiler condition "..line..":"))
			setfenv(cond, includes)
			cond = cond()
		else
			cond = true
		end
		if cond then
			assert(type(strip[1]) == "string",
				"code string is not a string")
			func[#func+1] = strip[1]
		end
	end
	return table.concat(func, "\n")
end

function execute(self, includes, ...)
	return assert(loadstring(self:source(includes), self.name))(...)
end
