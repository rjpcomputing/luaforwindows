--
-- ARGTABLE.LUA            Copyright (c) 2007, Asko Kauppi <akauppi@gmail.com>
--
-- Command line parameter parsing
--
-- NOTE: Wouldn't hurt having such a service built-in to Lua...? :P
--

local m= {}

-- tbl= argtable(...)
--
-- Returns a table with 1..N indices being 'value' parameters, and any
-- "-flag[=xxx]" or "--flag[=xxx]" parameters set to { flag=xxx/true }.
--
-- In other words, makes handling command line parameters simple. :)
--
--      15          -->     { 15 }
--      -20         -->     { -20 }
--      -a          -->     { ['a']=true }
--      --some=15   -->     { ['some']=15 }
--      --more=big  -->     { ['more']='big' }
--
function m.argtable(...)
    local ret= {}
    for i=1,select('#',...) do
        local v= select(i,...)
        local flag,val= string.match( v, "^%-+([^=]+)%=?(.*)" )
        if flag and not tonumber(v) then
            ret[flag]= (val=="") and true or tonumber(val) or val
        else
            table.insert( ret, v )  -- 1..N
        end
    end
    return ret
end

return m
