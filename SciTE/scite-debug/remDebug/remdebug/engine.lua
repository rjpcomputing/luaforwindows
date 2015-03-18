--
-- RemDebug 1.0 Beta
-- Copyright Kepler Project OK5 (http://www.keplerproject.org/remdebug)
--

local socket = require"socket"
local lfs = require"lfs"
local debug = require"debug"

module("remdebug.engine", package.seeall)

_COPYRIGHT = "2006 - Kepler Project"
_DESCRIPTION = "Remote Debugger for the Lua programming language"
_VERSION = "1.0"

local UNIX = string.sub(lfs.currentdir(),1,1) == '/'
if not UNIX then
  local global_print = print
  function print(...)
    global_print(...)
    io.stdout:flush()
  end
end

-- Some 'pretty printing' code. In particular, it will try to expand tables, up to
-- a specified number of elements.
-- obviously table.concat is much more efficient, but requires that the table values
-- be strings.
function join(tbl,delim,start,finish)
  local n = table.getn(tbl)
  local res = ''
  local k = 0
  -- this is a hack to work out if a table is 'list-like' or 'map-like'
  local index1 = n > 0 and tbl[1] ~= nil
  local index2 = n > 1 and tbl[2] ~= nil
  if index1 and index2 then
    for i,v in ipairs(tbl) do
      res = res..delim..tostring(v)
      k = k + 1
      if k > finish then
        res = res.." ... "
      end
    end
  else
    for i,v in pairs(tbl) do
      res = res..delim..tostring(i)..'='..tostring(v)
      k = k + 1
      if k > finish then
        res = res.." ... "
      end      
    end
  end
  return string.sub(res,2)
end

function expand_value(val)
  if type(val) == 'table' then
    if val.__tostring then
      return tostring(val)
    else
      return '{'..join(val,',',1,20)..'}'
    end
  elseif type(val) == 'string' then
    return "'"..val.."'"
  else
    return val
  end
end

local coro_debugger
local events = { BREAK = 1, WATCH = 2 }
local breakpoints = {}
local watches = {}
local step_into = false
local step_over = false
local step_level = 0
local stack_level = 0

local controller_host = "localhost"
local controller_port = 8171

local function set_breakpoint(file, line)
  if not breakpoints[file] then
    breakpoints[file] = {}
  end
  breakpoints[file][line] = true  
end

local function remove_breakpoint(file, line)
  if breakpoints[file] then
    breakpoints[file][line] = nil
  end
end

local function has_breakpoint(file, line)
  return breakpoints[file] and breakpoints[file][line]
end

local function restore_vars(vars)
  if type(vars) ~= 'table' then return end
  local func = debug.getinfo(3, "f").func
  local i = 1
  local written_vars = {}
  while true do
    local name = debug.getlocal(3, i)
    if not name then break end
    debug.setlocal(3, i, vars[name])
    written_vars[name] = true
    i = i + 1
  end
  i = 1
  while true do
    local name = debug.getupvalue(func, i)
    if not name then break end
    if not written_vars[name] then
      debug.setupvalue(func, i, vars[name])
      written_vars[name] = true
    end
    i = i + 1
  end
end

local function capture_vars()
  local vars = {}
  local func = debug.getinfo(3, "f").func
  local i = 1
  while true do
    local name, value = debug.getupvalue(func, i)
    if not name then break end
    vars[name] = value
    i = i + 1
  end
  i = 1
  while true do
    local name, value = debug.getlocal(3, i)
    if not name then break end
    vars[name] = value
    i = i + 1
  end
  setmetatable(vars, { __index = getfenv(func), __newindex = getfenv(func) })
  return vars
end

local function break_dir(path) 
  local paths = {}
  path = string.gsub(path, "\\", "/")
  for w in string.gfind(path, "[^\/]+") do
    table.insert(paths, w)
  end
  return paths
end

local function merge_paths(path1, path2)
  -- check if path is already absolute
  if UNIX then
    if string.sub(path2,1,1) == '/' then
      return path2
    end
  else
    if string.sub(path2,2,2) == ':' then
      return path2:gsub('\\','/')
    end
  end
  local paths1 = break_dir(path1)
  local paths2 = break_dir(path2)
  for i, path in ipairs(paths2) do
    if path == ".." then
      table.remove(paths1, table.getn(paths1))
    elseif path ~= "." then
      table.insert(paths1, path)
    end
  end
  local res = table.concat(paths1, "/")
  if UNIX then
    return "/"..res
  else
    return res
  end
end

local function debug_hook(event, line)
  if event == "call" then
    stack_level = stack_level + 1
  elseif event == "return" then
    stack_level = stack_level - 1
  else
    local file = debug.getinfo(2, "S").source
    if string.find(file, "@") == 1 then
      file = string.sub(file, 2)
    end
    file = merge_paths(lfs.currentdir(), file)
    local vars = capture_vars()
    table.foreach(watches, function (index, value)
      setfenv(value, vars)
      local status, res = pcall(value)
      if status and res then
        coroutine.resume(coro_debugger, events.WATCH, vars, file, line, index)
      end
    end)
    if step_into or (step_over and stack_level <= step_level) or has_breakpoint(file, line) then
      step_into = false
      step_over = false
      coroutine.resume(coro_debugger, events.BREAK, vars, file, line)
      restore_vars(vars)
    end
  end
end

--- protocol response helpers
local function bad_request(server)
    server:send("400 Bad Request\n") -- check this!
end

local function OK(server,res)
    if res then
      if type(res) == 'string' then
        server:send("200 OK "..string.len(res).."\n")
        server:send(res)
      else
        server:send("200 OK "..res.."\n")
      end
    else
      server:send("200 OK\n")
    end
end

local function pause(server,file,line,idx_watch)
  if not idx_watch then
    server:send("202 Paused " .. file .. " " .. line .. "\n")
  else
    server:send("203 Paused " .. file .. " " .. line .. " " .. idx_watch .. "\n")
  end
end

local function error(server,type,res)
  server:send("401 Error in "..type.." " .. string.len(res) .. "\n")
  server:send(res)
end

local function debugger_loop(server)
  local command
  local eval_env = {}
  
  while true do
    local line, status = server:receive()
    command = string.sub(line, string.find(line, "^[A-Z]+"))
--~     print('engine',command)
    if command == "SETB" then
      local _, _, _, filename, line = string.find(line, "^([A-Z]+)%s+([%w%p]+)%s+(%d+)$")
      if filename and line then
        set_breakpoint(filename, tonumber(line))
        OK(server)
      else
        bad_request(server)
      end
    elseif command == "DELB" then
      local _, _, _, filename, line = string.find(line, "^([A-Z]+)%s+([%w%p]+)%s+(%d+)$")
      if filename and line then
        remove_breakpoint(filename, tonumber(line))
        OK(server)
      else
        bad_request(server)
      end
    elseif command == "EXEC" then
      local _, _, chunk = string.find(line, "^[A-Z]+%s+(.+)$")
      if chunk then 
        local func = loadstring(chunk)
        local status, res
        if func then
          setfenv(func, eval_env)
          status, res = xpcall(func, debug.traceback)
        end
        res = tostring(res)
        if status then
          OK(server,res)
        else
          error(server,"Execute",res)
        end
      else
        bad_request(server)
      end
    elseif command == "SETW" then
      local _, _, exp = string.find(line, "^[A-Z]+%s+(.+)$")
      if exp then 
        local func = loadstring("return(" .. exp .. ")")
        local newidx = table.getn(watches) + 1
        watches[newidx] = func
        table.setn(watches, newidx)
        OK(server,newidx)
      else
        bad_request(server)
      end
    elseif command == "DELW" then
      local _, _, index = string.find(line, "^[A-Z]+%s+(%d+)$")
      index = tonumber(index)
      if index then
        watches[index] = nil
        OK(server)
      else
        bad_request(server)
      end
    elseif command == "RUN" or command == "STEP" or command == "OVER" then
      OK(server)
      if command == "STEP" then
        step_into = true
      elseif command == "OVER" then
        step_over = true
        step_level = stack_level
      end
      local ev, vars, file, line, idx_watch = coroutine.yield()
      eval_env = vars
      if ev == events.BREAK then
        pause(server,file,line)
      elseif ev == events.WATCH then
        pause(server,file,line,idx_watch)
      else
        error(server,"Execution",file)
      end
    elseif command == "LOCALS" then -- new --      
      -- not sure why I had to hack it this way?? SJD
      local tmpfile = 'remdebug-tmp.txt'
      local f = io.open(tmpfile,'w')
      for k,v in pairs(eval_env) do
          if k:sub(1,1) ~= '(' then
            f:write(k,' = ',tostring(v),'\n')
          end
      end
      f:close()
      f = io.open(tmpfile,'r')
      local res = f:read("*a")
      f:close()
      OK(server,res)
    elseif command == "DETACH" then --new--
      debug.sethook()
      OK(server)
    else
      bad_request(server)
    end
  end
end

coro_debugger = coroutine.create(debugger_loop)
--
-- remdebug.engine.config(tab)
-- Configures the engine
--
function config(tab)
  if tab.host then
    controller_host = tab.host
  end
  if tab.port then
    controller_port = tab.port
  end
end

--
-- remdebug.engine.start()
-- Tries to start the debug session by connecting with a controller
--
function start()
  pcall(require, "remdebug.config")
  local server = socket.connect(controller_host, controller_port)
  if server then
    _TRACEBACK = function (message) 
      local err = debug.traceback(message)
      error(server,"Execute",res)
      server:close()
      return err
    end
    debug.sethook(debug_hook, "lcr")
    return coroutine.resume(coro_debugger, server)
  end
end

