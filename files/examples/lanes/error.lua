--
-- Error reporting
--
-- Note: this code is supposed to end in errors; not included in 'make test'
--

require "lanes"

local function lane()

    local subf= function()  -- this so that we can see the call stack
        --error "aa"
        error({})
        error(error)
    end
    local subf2= function()
        subf()
    end
    subf2()
end

local function cleanup(err)
end

local lgen = lanes.gen("*", { --[[finalizer=cleanup]] }, lane)

---
io.stderr:write( "\n** Error catching **\n" )
--
local h= lgen()
local _,err,stack= h:join()   -- wait for the lane (no automatic error propagation)

if err then
    assert( type(stack)=="table" )
    io.stderr:write( "Lane error: "..tostring(err).."\n" )

    io.stderr:write( "\t", table.concat(stack,"\n\t"), "\n" );
end

---
io.stderr:write( "\n** Error propagation **\n" )
--
local h2= lgen()
local _= h2[0]
assert(false)   -- does NOT get here

--never ends
