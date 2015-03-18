--
-- Test resource cleanup
--
-- This feature was ... by discussion on the Lua list about exceptions.
-- The idea is to always run a certain block at exit, whether due to success
-- or error. Normally, 'pcall' would be used for such but as Lua already
-- does that, simply giving a 'cleanup=function' parameter is a logical
-- thing to do.     -- AKa 22-Jan-2009
--

require "lanes"

local FN= "finalizer-test.tmp"

local cleanup

local which= os.time() % 2  -- 0/1

local function lane()

    set_finalizer(cleanup)

    local f,err= io.open(FN,"w")
    if not f then
        error( "Could not create "..FN..": "..err )
    end

    f:write( "Test file that should get removed." )

    io.stderr:write( "File "..FN.." created\n" )    

    if which==0 then
        error("aa")    -- exception here; the value needs NOT be a string
    end

    -- no exception
end

-- 
-- This is called at the end of the lane; whether succesful or not.
-- Gets the 'error()' parameter as parameter ('nil' if normal return).
--
cleanup= function(err)

    -- An error in finalizer will override an error (or success) in the main
    -- chunk.
    --
    --error( "This is important!" )

    if err then
        io.stderr:write( "Cleanup after error: "..tostring(err).."\n" )
    else
        io.stderr:write( "Cleanup after normal return\n" )
    end
        
    local _,err2= os.remove(FN)
    assert(not err2)    -- if this fails, it will be shown in the calling script
                        -- as an error from the lane itself
    
    io.stderr:write( "Removed file "..FN.."\n" )
end

local lgen = lanes.gen("*", lane)

io.stderr:write "Launching the lane!\n"

local h= lgen()

local _,err,stack= h:join()   -- wait for the lane (no automatic error propagation)
if err then
    assert(stack)
    io.stderr:write( "Lane error: "..tostring(err).."\n" )
    io.stderr:write( "\t", table.concat(stack,"\t\n"), "\n" )
end

local f= io.open(FN,"r")
if f then
    error( "CLEANUP DID NOT WORK: "..FN.." still exists!" )
end

io.stderr:write "Finished!\n"
