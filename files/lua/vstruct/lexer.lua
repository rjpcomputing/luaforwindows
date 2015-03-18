local lexis = {}

local function lexeme(name)
	return function(pattern)
		lexis[#lexis+1] = { name=name, pattern="^"..pattern }
	end
end

lexeme (false) 		"%s+"	-- whitespace
lexeme "table" 		"(%b{})"
lexeme "group" 		"(%b())"
lexeme "name_atom"	"([%a_][%w_]*)%:(%a)([%d.]*)"
lexeme "name_table"	"([%a_][%w_]*)%:(%b{})"
lexeme "prerepeat" 	"(%d+)%s*%*"
lexeme "postrepeat"	"%*%s*(%d+)"
lexeme "control"	"([-+@<>=ax])([%d.]*)"
lexeme "atom"		"(%a)([%d.]*)"

return function(source)
	local orig = source
	local index = 1
	
	local function iter()
		if #source == 0 then return nil end
		
		for _,lexeme in ipairs(lexis) do
			if source:match(lexeme.pattern) then
				local result = { source:find(lexeme.pattern) }
				local eof = table.remove(result, 2)
				table.remove(result, 1)
				
				source = source:sub(eof+1, -1)
				index = index+eof
				
				if lexeme.name then
					result.type = lexeme.name
					coroutine.yield(result)
				end
				return iter()
			end
		end
		error (function() return "Error lexing format string [["
			..(orig)
			.."]] at char "
			..index
			.." ("
			..(source:sub(1,1))
			..")"
			end)
	end

	return coroutine.wrap(iter)
end

