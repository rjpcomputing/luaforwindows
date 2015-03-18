--
-- Test case for hang on [1]s and :join()s.
--

require "lanes"

local function ret(b)
    return b
end
local lgen = lanes.gen("*", {}, ret)

for i=1,10000 do
    local ln = lgen(i)

    print( "getting result for "..i )

    -- Hangs here forever every few hundred runs or so,
    -- can be illustrated by putting another print() statement
    -- after, which will never be called.
    --
    local result = ln[1];

    assert (result == i);
end

print "Finished!"
