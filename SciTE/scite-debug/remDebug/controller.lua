--
-- RemDebug 1.0 Beta
-- Copyright Kepler Project 2005 (http://www.keplerproject.org/remdebug)
--

local socket = require"socket"

local global_print = print

function print(...)
  global_print(...)
  io.stdout:flush()
end
--~ io.stdout:setvbuf("no")

print("Lua Remote Debugger")
print("Run the program you wish to debug")

local server = socket.bind("*", 8171)
local client = server:accept()

local breakpoints = {}
local watches = {}

client:send("STEP\n")
client:receive()

local breakpoint = client:receive()
local _, _, file, line = string.find(breakpoint, "^202 Paused%s+([%w%p]+)%s+(%d+)$")
if file and line then
  print("Paused at file " .. file )
  print("Type 'help' for commands")
else
  local _, _, size = string.find(breakpoint, "^401 Error in Execution (%d+)$")
  if size then
    print("Error in remote application: ")
    print(client:receive(size))
  end
end

local basedir = ""
local display_expressions

local function eval_error(client,len)
    len = tonumber(len)
    local res = client:receive(len)
    print("Error in expression:")
    --print(res)  -- sjd I cd see no reason to print this bogus value
end

function any_command_args(line)
  local _, _, exp = string.find(line, "^[a-z]+%s+(.+)$")
  return exp
end

function remote_eval(exp)
  client:send("EXEC return remdebug.engine.expand_value(" .. exp .. ")\n")
  local line = client:receive()
  local _, _, status, len = string.find(line, "^(%d+)[a-zA-Z ]+(%d+)$")
  if status == "200" then
    len = tonumber(len)
    local res = client:receive(len)
    return true,res
  elseif status == "401" then
    eval_error(client,len)
    return false
  else
    print("Unknown error")
    return false
  end
end

function on_paused_execution()
  if display_expressions then
    for i,v in ipairs(display_expressions) do
      local ok,res = remote_eval(v)
      if ok then
        print(v .. " = " .. res)
      end
    end
  end
end

function process_line(line)
  local _, _, command = string.find(line, "^([a-z]+)")
  if command == "run" or command == "step" or command == "over" then
    client:send(string.upper(command) .. "\n")
    client:receive() -- always 'OK'
    local breakpoint = client:receive()
    if not breakpoint then -- client has terminated normally...
      print("Program finished")
      os.exit()
    end
    local _, _, status = string.find(breakpoint, "^(%d+)")
    if status == "202" then
      local _, _, file, line = string.find(breakpoint, "^202 Paused%s+([%w%p]+)%s+(%d+)$")
      if file and line then 
        print("Paused at file " .. file .. " line " .. line)
        on_paused_execution()
      end
    elseif status == "203" then
      local _, _, file, line, watch_idx = string.find(breakpoint, "^203 Paused%s+([%w%p]+)%s+(%d+)%s+(%d+)$")
      if file and line and watch_idx then
        print("Paused at file " .. file .. " line " .. line .. " (watch expression " .. watch_idx .. ": [" .. watches[watch_idx] .. "])")
        on_paused_execution()
      end
    elseif status == "401" then 
      local _, _, size = string.find(breakpoint, "^401 Error in Execution (%d+)$")
      if size then
        print("Error in remote application: ")
        print(client:receive(tonumber(size)))
        os.exit()
      end
    else
      print("Unknown error")
      os.exit()
    end
  elseif command == "exit" then
    client:close()
    os.exit()
  elseif command == "setb" then
    local _, _, _, filename, line = string.find(line, "^([a-z]+)%s+([%w%p]+)%s+(%d+)$")
    if filename and line then
      filename = basedir .. filename
      if not breakpoints[filename] then breakpoints[filename] = {} end
      client:send("SETB " .. filename .. " " .. line .. "\n")
      if client:receive() == "200 OK" then 
        breakpoints[filename][line] = true
      else
        print("Error: breakpoint not inserted")
      end
    else
      print("Invalid command")
    end
  elseif command == "setw" then
    local _, _, exp = string.find(line, "^[a-z]+%s+(.+)$")
    if exp then
      client:send("SETW " .. exp .. "\n")
      local answer = client:receive()
      local _, _, watch_idx = string.find(answer, "^200 OK (%d+)$")
      if watch_idx then
        watches[watch_idx] = exp
        print("Inserted watch exp no. " .. watch_idx)
      else
        print("Error: Watch expression not inserted")
      end
    else
      print("Invalid command")
    end
  elseif command == "delb" then
    local _, _, _, filename, line = string.find(line, "^([a-z]+)%s+([%w%p]+)%s+(%d+)$")
    if filename and line then
      filename = basedir .. filename
      if not breakpoints[filename] then breakpoints[filename] = {} end
      client:send("DELB " .. filename .. " " .. line .. "\n")
      if client:receive() == "200 OK" then 
        breakpoints[filename][line] = nil
      else
        print("Error: breakpoint not removed")
      end
    else
      print("Invalid command")
    end
  elseif command == "delallb" then
    for filename, breaks in pairs(breakpoints) do
      for line, _ in pairs(breaks) do
        client:send("DELB " .. filename .. " " .. line .. "\n")
        if client:receive() == "200 OK" then 
          breakpoints[filename][line] = nil
        else
          print("Error: breakpoint at file " .. filename .. " line " .. line .. " not removed")
        end
      end
    end
  elseif command == "delw" then
    local _, _, index = string.find(line, "^[a-z]+%s+(%d+)$")
    if index then
      client:send("DELW " .. index .. "\n")
      if client:receive() == "200 OK" then 
        watches[index] = nil
      else
        print("Error: watch expression not removed")
      end
    else
      print("Invalid command")
    end
  elseif command == "delallw" then
    for index, exp in pairs(watches) do
      client:send("DELW " .. index .. "\n")
      if client:receive() == "200 OK" then 
        watches[index] = nil
      else
        print("Error: watch expression at index " .. index .. " [" .. exp .. "] not removed")
      end
    end
  elseif command == "locals" then  --new--
    client:send("LOCALS\n")
    local line = client:receive()
    local _, _, size = string.find(line, "^200 OK (%d+)$")
    if size then
      local msg = client:receive(tonumber(size))
      print(msg)
    end
  elseif command == "detach" then  --new--
    client:send("DETACH\n")
    client:receive()  
  elseif command == "display" then
    local exp = any_command_args(line)
    if not display_expressions then display_expressions = {} end
    table.insert(display_expressions,exp)
  elseif command == "eval" then
    local exp = any_command_args(line)
    if exp then 
      local ok,res = remote_eval(exp)
      if ok then -- this pattern makes it a little easier for scite-gdb
        print('= '..res)  
      end
    else
      print("Bad command")
    end
  elseif command == "exec" then
    local exp = any_command_args(line)
    if exp then 
      client:send("EXEC " .. exp .. "\n")
      local line = client:receive()
      if not line then --sjd case where exp is 'os.exit(0)'
        print("Program killed")
        os.exit(0)
      end
      local _, _, status, len = string.find(line, "^(%d+)[%s%w]+(%d+)$")
      if status == "200" then
        len = tonumber(len)
        local res = client:receive(len)
        print(res)
      elseif status == "401" then
        eval_error(client,res)
      else
        print("Unknown error")
      end
    else
      print("Invalid command")
    end
  elseif command == "listb" then
    for k, v in pairs(breakpoints) do
      io.write(k .. ": ")
      for k, v in pairs(v) do
        io.write(k .. " ")
      end
      io.write("\n")
    end
  elseif command == "listw" then
    for i, v in pairs(watches) do
      print("Watch exp. " .. i .. ": " .. v)
    end    
  elseif command == "basedir" then
    local _, _, dir = string.find(line, "^[a-z]+%s+(.+)$")
    if dir then
      if not string.find(dir, "/$") then dir = dir .. "/" end
      basedir = dir
      print("New base directory is " .. basedir)
    else
      print(basedir)
    end
  elseif command == "help" then
    print("setb <file> <line>    -- sets a breakpoint")
    print("delb <file> <line>    -- removes a breakpoint")
    print("delallb               -- removes all breakpoints")
    print("setw <exp>            -- adds a new watch expression")
    print("delw <index>          -- removes the watch expression at index")
    print("delallw               -- removes all watch expressions")
    print("run                   -- run until next breakpoint")
    print("step                  -- run until next line, stepping into function calls")
    print("over                  -- run until next line, stepping over function calls")
    print("listb                 -- lists breakpoints")
    print("listw                 -- lists watch expressions")
    print("locals                 -- lists local variables")
    print("detach                 -- stop debugging remote process")
    print("display                 -- add an expression to the display list")
    print("eval <exp>            -- evaluates expression on the current context and returns its value")
    print("exec <stmt>           -- executes statement on the current context")
    print("basedir [<path>]      -- sets the base path of the remote application, or shows the current one")
    print("exit                  -- exits debugger")
  else
    local _, _, spaces = string.find(line, "^(%s*)$")
    if not spaces then
      print("Invalid command")
    end
  end
end

if table.getn(arg) == 1 then
  local f = io.open(arg[1],'r')
  for line in f:lines() do
    process_line(line)
  end  
end

local prompt = "> "
if _DPROMPT then
  prompt = _DPROMPT
  prompt = string.gsub(prompt,'\\n','\n')
end

while true do
  io.write(prompt)
  process_line(io.read("*line"))
end
