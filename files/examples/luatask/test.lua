require 'task'

TEST = {}

function TEST.ts()
    local tl = task.list()
    io.stdout:write( '\nID   SCRIPT           COUNT     REG/ID\n' )
    io.stdout:write( '---- ---------------- --------- ----------------\n' )
    if tl then
        for i, t in pairs( tl ) do
            io.stdout:write( string.format( '%4d %-16.16s %9d %-16.16s\n',
                    i, t.script or arg[0], t.msgcount, t.id or '' ) )
        end
    end
end

function TEST.main( arg )
    
    task.register( 'Main' )
    
    local cmd = 'ts'
    while cmd ~= 'quit' do
        if cmd == 'ts' then
            TEST.ts()
        elseif string.sub( cmd, 1, 3 ) == 'run' then
            local rarg = {}
            string.gsub( cmd, '([^ ]+)', function( x ) table.insert( rarg, x ) end )
            if not rarg[2] then
                io.stdout:write( 'Run what?\n' )
            else
                local script = rarg[2]
                table.remove( rarg, 1)
                table.remove( rarg, 1)
                local tsk = task.create( script, rarg )
                if tsk == -1 then
                    io.stdout:write( "-> Can't expand task list.\n" )
                elseif tsk == -2 then
                    io.stdout:write( "-> Can't strdup file name.\n" )
                elseif tsk == -3 then
                    io.stdout:write( "-> Can't create message queue.\n" )
                elseif tsk == -4 then
                    io.stdout:write( "-> Can't create os thread.\n" )
                elseif tsk == -11 then
                    io.stdout:write( "-> The library seems corrupt.\n" )
                else
                    io.stdout:write( "-> Task ", tsk, " started.\n" )
                end
            end
        end
        io.stdout:write( 'TEST> ' )
        io.stdout:flush()
        cmd = io.stdin:read()
    end

    io.stdout:write( '\nTEST terminated\n' )
    
    os.exit( 0 )
end

TEST.main( arg )
