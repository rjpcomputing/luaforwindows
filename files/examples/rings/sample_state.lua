-- $Id: sample_state.lua,v 1.2 2006/07/25 14:09:45 tomas Exp $

require"rings"

local init_cmd = [[
require"stable"]]

local count_cmd = [[
count = stable.get"shared_counter" or 0
stable.set ("shared_counter", count + 1)
return count
]]

S = rings.new () -- new state
assert(S:dostring (init_cmd))
print (S:dostring (count_cmd)) -- true, 0
print (S:dostring (count_cmd)) -- true, 1
S:close ()

S = rings.new () -- another new state
assert (S:dostring (init_cmd))
print (S:dostring (count_cmd)) -- true, 2
S:close ()

print("OK!")
