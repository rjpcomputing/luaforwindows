-- parser for format strings
-- you give it a format string, a table of code generators,
-- and a flag indicating whether to apply the preamble/postable
-- it gives you lua source

local require,concat = require,table.concat

local print = print

module((...))

local lex = require(_PACKAGE.."lexer")

return function(source, codegen, prepost)
	local asl = {}
	local get = lex(source)
	
	for token in get do
		-- seperate statements because codegen may change #asl
		local code = codegen[token.type](token, get, asl)
		asl[#asl+1] = code
	end
	
	local source = concat(asl, "\n")
	
	if prepost then
		source = codegen.preamble
			.. source
			.. codegen.postamble
	end
	
	return source
end


