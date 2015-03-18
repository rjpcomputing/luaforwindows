local luaerror = error
local pairs    = pairs
local tostring = tostring
local luatype  = type
local require  = require                                                        --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.assert"

--------------------------------------------------------------------------------

Exception = require "oil.Exception"

--------------------------------------------------------------------------------

error = luaerror
--function error(exception, level)
--  if luatype(exception) ~= "string" then
--    exception = tostring(exception)
--  end
--  luaerror(exception, (level or 0) + 1)
--end

--------------------------------------------------------------------------------

local IllegalValueMsg = "illegal %s"

function illegal(value, description, except)
	exception({ except or "illegal value",
		reason = "value",
		message = IllegalValueMsg:format(description),
		value = value,
		valuename = description,
	}, 2)
end

--------------------------------------------------------------------------------

TypeCheckers = {}

local TypeMismatchMsg = IllegalValueMsg.." (%s expected, got %s)"

function type(value, expected, description, except)
	local actual = luatype(value)
	if actual == expected then
		return true
	else
		local checker = TypeCheckers[expected]
		if checker and checker(value) then
			return true
		else
			for pattern, checker in pairs(TypeCheckers) do
				local result = expected:match(pattern)
				if result then
					checker, result = checker(value, result)
					expected = result or expected
					if checker
						then return true
						else break
					end
				end
			end
		end
	end
	exception({ except or "type mismatch",
		reason = "type",
		message = TypeMismatchMsg:format(description, expected, actual),
		expectedtype = expected,
		actualtype   = actual,
		value        = value,
	}, 2)
end

--------------------------------------------------------------------------------

function results(result, ...)
	if result == nil then exception(..., 2) end
	return result, ...
end

--------------------------------------------------------------------------------

function exception(except, level)
	if luatype(except) == "string" then
		except = { except }
	end
	error(Exception(except), (level or 0) + 1)
end
