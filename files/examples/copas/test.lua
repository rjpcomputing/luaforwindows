-- Tests Copas with a simple Echo server
--
-- Run the test file and the connect to the server using telnet on the used port.
-- The server should be able to echo any input, to stop the test just send the command "quit"

require"copas"

local function echoHandler(skt)
  skt = copas.wrap(skt)
  while true do
    local data = skt:receive()
    if data == "quit" then
      break
    end
    skt:send(data)
  end
end

local server = socket.bind("localhost", 20000)

copas.addserver(server, echoHandler)

copas.loop()