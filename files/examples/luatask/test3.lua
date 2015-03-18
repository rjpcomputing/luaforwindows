require 'task'

if arg[1] ~= null then
    i = 0
    id = task.id()
    while true do
        task.receive( 500 )
        i = i + 1
        if math.mod( i, 10 ) == 0 then
            print( id, i )
        end
        task.sleep( 500 )
    end
end


tsks = {}

n = 508

for i = 1, n do
    tsks[i] = task.create( 'test3.lua', { i } ) 
    print( tsks[i] )
end

while true do
    task.sleep( 3000 )
    local k = -1
    for i,t in ipairs( task.list() ) do
        k = k + 1
    end
    if n == k then
        print( 'Main task: subtasks ok' )
    else
        print( 'Main task: expected', n, 'substask,', k, 'found' )
    end
    task.receive( 2000 ) 
end

