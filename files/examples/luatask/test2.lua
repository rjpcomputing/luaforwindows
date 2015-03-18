if arg[1] and ( arg[1] == 'ClIeNt' ) then
    task.register( 'Client' )
    for i = 1, arg[3] do
        task.receive( arg[4] ) -- used like a timer
        if i > 10 then
            task.post( arg[2], '*******...*', i )
        else
            task.post( arg[2], string.rep( '*', i ), i )
        end
    end
else
    task.register( 'Server' )
    local cnt = tonumber( arg[1] ) or 10
    local dly = tonumber( arg[2] ) or 750
    local tsk = task.create( 'test2.lua', { 'ClIeNt', task.id(), cnt, dly } )
    
    while cnt > 0 do
        local buf, flags, err = task.receive( -1 )
        io.stderr:write( '\ttest2 => ', buf or '', ' ', flags or '', ' ', err or '', '\n' )
        io.stderr:flush()
        cnt = cnt - 1
        collectgarbage( 'collect' )
    end
end
