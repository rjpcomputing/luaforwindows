-- $Id: sample.lua,v 1.4 2008/05/30 18:44:05 carregal Exp $

require"rings"

S = rings.new ()

data = { 12, 13, 14, }
print (S:dostring ([[
aux = {}
for i, v in ipairs {...} do
	table.insert (aux, 1, v)
end
return unpack (aux)]], unpack (data)))

S:close ()

print("OK!")
