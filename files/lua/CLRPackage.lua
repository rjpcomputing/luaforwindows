---
--- This lua module provides auto importing of .net classes into a named package.
--- Makes for super easy use of LuaInterface glue
---
--- example:
---   Threading = CLRPackage("System", "System.Threading")
---   Threading.Thread.Sleep(100)
---
--- Extensions:
--- import() is a version of CLRPackage() which puts the package into a list which is used by a global __index lookup,
--- and thus works rather like C#'s using statement. It also recognizes the case where one is importing a local
--- assembly, which must end with an explicit .dll extension.

-- LuaInterface hosted with stock Lua interpreter will need to explicitly require this...
if not luanet then require 'luanet' end

local packages = {}

local mt = {
	--- Lookup a previously unfound class and add it to our table
	__index = function(package, classname)
		local class = rawget(package, classname)

		if class == nil then
			class = luanet.import_type(package.packageName .. "." .. classname)
			package[classname] = class		-- keep what we found around, so it will be shared
		end

		return class
	end
	}

local globalMT = {
	__index = function(T,classname)
			for i,package in ipairs(packages) do
			    local class = package[classname]
				if class then
					_G[classname] = class
					return class
				end
			end
	end
}
setmetatable(_G, globalMT)

--- Create a new Package class
function CLRPackage(assemblyName, packageName)
  local t = {}
  -- a sensible default...
  packageName = packageName or assemblyName
  luanet.load_assembly(assemblyName)			-- Make sure our assembly is loaded

  -- FIXME - table.packageName could instead be a private index (see Lua 13.4.4)
  t.packageName = packageName
  setmetatable(t, mt)
  return t
end

function import (assemblyName)
	local packageName
	local i = assemblyName:find('%.dll$')
	if i then packageName = assemblyName:sub(1,i-1)
	else packageName = assemblyName end
    local t = CLRPackage(assemblyName,packageName)
	table.insert(packages,t)
	return t
end

double = luanet.import_type "System.Double"

function make_array (tp,tbl)
    local arr = tp[#tbl]
	for i,v in ipairs(tbl) do
	    arr:SetValue(v,i-1)
	end
	return arr
end

function enum(o)
   local e = o:GetEnumerator()
   return function()
      if e:MoveNext() then
        return e.Current
     end
   end
end

-- nearly always need this!
import "System"


