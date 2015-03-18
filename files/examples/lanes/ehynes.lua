--
-- Test from <ehynes at dharmagaia.com>
--
require 'lanes'

local function PRINT_FMT( fmt, ... )
    io.stderr:write( string.format(fmt,...).."\n" )
end

-- a linda for sending messages
local linda = lanes.linda()

-- a linda message receiver
local receiver_gen = lanes.gen( 'base', 'os', 'string', 'io',
    function (message_name)
        PRINT_FMT( 'receiver for message %s entered', message_name )
        local n = 1
        while linda:receive(message_name) do
            PRINT_FMT( '%s %d receieved', message_name, n )
            n = n + 1
        end
    end
)

-- create a receiver
local receiver1 = receiver_gen('message')

-- create a second receiver (a second receiver in the same linda
-- appears to be needed to trigger the delays)
--
-- AKa 4-Aug-2008: No, with svn version it isn't. But it causes the 2nd
--                 message to be hanging...
--
local receiver2 = receiver_gen('another message')

-- a function to pause and log the execution for debugging
local function logf(s, f, ...)
    os.execute('sleep 1')
    PRINT_FMT( "*** %s", s )
    f(...)
end

-- first message sent is received right away
logf('first message sent', linda.send, linda, 'message', true)

-- second message sent is not received immediatly
logf('second message sent', linda.send, linda, 'message', true)

-- third message sent triggers receipt of both second and third messages
logf('third message sent', linda.send, linda, 'message', true)

logf('all done', function() end)
