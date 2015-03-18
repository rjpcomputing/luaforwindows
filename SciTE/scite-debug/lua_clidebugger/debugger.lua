--GDB = true
--{{{  history

--15/03/06 DCN Created based on RemDebug
--28/04/06 DCN Update for Lua 5.1
--01/06/06 DCN Fix command argument parsing
--             Add step/over N facility
--             Add trace lines facility
--05/06/06 DCN Add trace call/return facility
--06/06/06 DCN Make it behave when stepping through the creation of a coroutine
--06/06/06 DCN Integrate the simple debugger into the main one
--07/06/06 DCN Provide facility to step into coroutines
--13/06/06 DCN Fix bug that caused the function environment to get corrupted with the global one
--14/06/06 DCN Allow 'sloppy' file names when setting breakpoints
--04/08/06 DCN Allow for no space after command name
--11/08/06 DCN Use io.write not print
--30/08/06 DCN Allow access to array elements in 'dump'
--10/10/06 DCN Default to breakfile for all commands that require a filename and give '-'
--06/12/06 DCN Allow for punctuation characters in DUMP variable names
--03/01/07 DCN Add pause on/off facility
--19/06/07 DCN Allow for duff commands being typed in the debugger (thanks to Michael.Bringmann@lsi.com)
--             Allow for case sensitive file systems               (thanks to Michael.Bringmann@lsi.com)

--}}}
--{{{  description

--A simple command line debug system for Lua written by Dave Nichols of
--Match-IT Limited. Its public domain software. Do with it as you wish.

--This debugger was inspired by:
-- RemDebug 1.0 Beta
-- Copyright Kepler Project 2005 (http://www.keplerproject.org/remdebug)

--Usage:
--  require('debugger')        --load the debug library
--  pause(message)             --start/resume a debug session

--An assert() failure will also invoke the debugger.

--}}}

local tinsert = table.insert
local strfind = string.find
local strsub = string.sub
local strlower = string.lower
local gsub  = string.gsub
local write = io.write
local esc = string.char(26)
local gprefix = esc..esc
local bpattern

print(GDB,WIN)
if GDB then
    require 'dbgl'
    if WIN then
      bpattern = '([a-z]:[^:]+):(%d+)'
    else
      bpattern = '([^:]+):(%d+)'
    end
end

local IsWindows = strfind(strlower(os.getenv('OS') or ''),'^windows')

local coro_debugger
local events = { BREAK = 1, WATCH = 2, STEP = 3, SET = 4 }
local breakpoints = {}
local watches = {}
local step_into   = false
local step_over   = false
local step_lines  = 0
local step_level  = {main=0}
local stack_level = {main=0}
local trace_level = {main=0}
local step
local tracing = false
local trace_calls = false
local trace_returns = false
local trace_lines = false
local ret_file, ret_line, ret_name
local current_thread = 'main'
local started = false
local pause_off = false
local _g      = _G
local cocreate, cowrap = coroutine.create, coroutine.wrap
local pausemsg = 'pause'


local start_t,msg_t

local function start_timer (msg)
    start_t = os.clock()
    msg_t = msg
end

local ferr = io.stderr

local function errf (fmt,...)
    ferr:write(fmt:format(...))
end

local function end_timer ()
   -- errf("%s: took %7.2f sec\n",msg_t,os.clock()-start_t)
end

local hints = { }

-- Some 'pretty printing' code. In particular, it will try to expand tables, up to
-- a specified number of elements.
-- (Based on ilua)
local pretty_print_limit = 20
local max_depth = 7
local jstack = {}
local push = tinsert
local pop = table.remove
local getn = table.getn

local function is_map_like(tbl)
	for k,v in pairs(tbl) do
		if type(k) ~= 'number' then
			return true
		end
	end
	return false
end

local function join(tbl,delim,limit,depth)
    if not limit then limit = pretty_print_limit end
    if not depth then depth = max_depth end
    local n = getn(tbl)
    local res = ''
    local k = 0
    -- very important to avoid disgracing ourselves with circular references or
	-- excessively nested tables...
    if getn(jstack) > depth then
        return "..."
    end
    for i,t in ipairs(jstack) do
        if tbl == t then
            return "<self>"
        end
    end
    push(jstack,tbl)
    -- a table may have a 'list-like' part if it has a non-zero size
	-- and may have have a 'map-like' part if it has non-numerical keys
    local is_list,is_map
	is_list = getn(tbl) > 0
	is_map = is_map_like(tbl)
    if is_list then
        for i,v in ipairs(tbl) do
            res = res..delim..val2str(v)
            k = k + 1
            if k > limit then
                res = res.." ... "
                break
            end
        end
    end
	if is_map then
        for key,v in pairs(tbl) do
			local num = type(key) == 'number'
			key = tostring(key)
			if not num or (num and not is_list) then
				if num then
					key = '['..key..']'
				end
				res = res..delim..key..'='..val2str(v)
				k = k + 1
				if k > limit then
					res = res.." ... "
					break
				end
			end
        end
    end
    pop(jstack)
    return strsub(res,2)
end

function val2str(val)
    local tp = type(val)
    if tp == 'function' then
        return tostring(val)
    elseif tp == 'table' then
        if val.__tostring  then
            return tostring(val)
        else
            return '{'..join(val,',')..'}'
        end
    elseif tp == 'string' then
        return "'"..val.."'"
    elseif tp == 'number' then
		return tostring(val)
    else
        return tostring(val)
    end
end

--{{{  local function getinfo(level,field)

--like debug.getinfo but copes with no activation record at the given level
--and knows how to get 'field'. 'field' can be the name of any of the
--activation record fields or any of the 'what' names or nil for everything.
--only valid when using the stack level to get info, not a function name.

local function getinfo(level,field)
  level = level + 1  --to get to the same relative level as the caller
  if not field then return debug.getinfo(level) end
  local what
  if field == 'name' or field == 'namewhat' then
    what = 'n'
  elseif field == 'what' or field == 'source' or field == 'linedefined' or field == 'lastlinedefined' or field == 'short_src' then
    what = 'S'
  elseif field == 'currentline' then
    what = 'l'
  elseif field == 'nups' then
    what = 'u'
  elseif field == 'func' then
    what = 'f'
  else
    return debug.getinfo(level,field)
  end
  local ar = debug.getinfo(level,what)
  if ar then return ar[field] else return nil end
end



--}}}
--{{{  local function indented( level, ... )

local function indented( level, ... )
  write( string.rep('  ',level), table.concat({...}), '\n' )
end

--}}}
--{{{  local function dumpval( level, name, value, limit )

local dumpvisited

local function dumpval( level, name, value, limit )
  local index
  if type(name) == 'number' then
    index = string.format('[%d] = ',name)
  elseif type(name) == 'string'
     and (name == '__VARSLEVEL__' or name == '__ENVIRONMENT__' or name == '__GLOBALS__' or name == '__UPVALUES__' or name == '__LOCALS__') then
    --ignore these, they are debugger generated
    return
  elseif type(name) == 'string' and strfind(name,'^[_%a][_.%w]*$') then
    index = name ..' = '
  else
    index = string.format('[%q] = ',tostring(name))
  end
  if type(value) == 'table' then
    if dumpvisited[value] then
      indented( level, index, string.format('ref%q;',dumpvisited[value]) )
    else
      dumpvisited[value] = tostring(value)
      if (limit or 0) > 0 and level+1 >= limit then
        indented( level, index, dumpvisited[value] )
      else
        indented( level, index, '{  -- ', dumpvisited[value] )
        for n,v in pairs(value) do
          dumpval( level+1, n, v, limit )
        end
        indented( level, '};' )
      end
    end
  else
    if type(value) == 'string' then
      if string.len(value) > 40 then
        indented( level, index, '[[', value, ']];' )
      else
        indented( level, index, string.format('%q',value), ';' )
      end
    else
      indented( level, index, tostring(value), ';' )
    end
  end
end

--}}}
--{{{  local function dumpvar( value, limit, name )

local function dumpvar( value, limit, name )
  dumpvisited = {}
  dumpval( 0, name or tostring(value), value, limit )
end

--}}}
--{{{  local function show(file,line,before,after)

--show +/-N lines of a file around line M

local function show(file,line,before,after)

  line   = tonumber(line   or 1)
  before = tonumber(before or 10)
  after  = tonumber(after  or before)


  -- SJD: if a qualified module name is given, then we can use that....
  if not strfind(file,'%.') then file = file..'.lua' end

  local f = io.open(file,'r')
  if not f then
    --{{{  try to find the file in the path

    --
    -- looks for a file in the package path
    --
    local path = package.path or LUA_PATH or ''
    for c in string.gmatch (path, "[^;]+") do
      local c = gsub (c, "%?%.lua", file)
      f = io.open (c,'r')
      if f then
        break
      end
    end

    --}}}
    if not f then
      write('Cannot find '..file..'\n')
      return
    end
  end

  local i = 0
  for l in f:lines() do
    i = i + 1
    if i >= (line-before) then
      if i > (line+after) then break end
      if i == line then
        write(i..'***\t'..l..'\n')
      else
        write(i..'\t'..l..'\n')
      end
    end
  end

  f:close()

end

--}}}
--{{{  local function tracestack(l)

local function gi( i )
  return function() i=i+1 return debug.getinfo(i),i end
end

local function gl( level, j )
  return function() j=j+1 return debug.getlocal( level, j ) end
end

local function gu( func, k )
  return function() k=k+1 return debug.getupvalue( func, k ) end
end

local  traceinfo

local function tracestack(l,tracing)
  local l = l + 1                        --NB: +1 to get level relative to caller
  traceinfo = {}
  traceinfo.pausemsg = pausemsg
  for ar,i in gi(l) do
    tinsert( traceinfo, ar )
    if tracing then
        local names  = {}
        local values = {}
        for n,v in gl(i,0) do
          if strsub(n,1,1) ~= '(' then   --ignore internal control variables
            tinsert( names, n )
            tinsert( values, v )
          end
        end
        if #names > 0 then
          ar.lnames  = names
          ar.lvalues = values
        end
        if ar.func then
          local names  = {}
          local values = {}
          for n,v in gu(ar.func,0) do
            if strsub(n,1,1) ~= '(' then   --ignore internal control variables
              tinsert( names, n )
              tinsert( values, v )
            end
          end
          if #names > 0 then
            ar.unames  = names
            ar.uvalues = values
          end
        end
    end
  end
end

--}}}
--{{{  local function trace()

local function trace(set)
  local mark
  if not traceinfo then return end
  for level,ar in ipairs(traceinfo) do
    local description = (ar.name or ar.what)..' in '..ar.short_src..':'..ar.currentline
    if GDB then
        write('#',level,' ',description)
    else
        if level == set then
          mark = '***'
        else
          mark = ''
        end
        write('['..level..']\t'..description..' '..mark..'\n')
    end
  end
end

--}}}
--{{{  local function info()

local function info() dumpvar( traceinfo, 0, 'traceinfo' ) end

--}}}

-- this value distinguishes temporary from persistent breakpoints
local TEMPORARY = 1

--{{{  local function set_breakpoint(file, line)

local function set_breakpoint(file, line, value)
  if not breakpoints[line] then
    breakpoints[line] = {}
  end
  breakpoints[line][file] = value
end

--}}}
--{{{  local function remove_breakpoint(file, line)

local function remove_breakpoint(file, line)
  if breakpoints[line] then
    breakpoints[line][file] = nil
  end
end

--}}}
--{{{  local function has_breakpoint(file, line)

local function has_breakpoint(file,line)
	local bpl = breakpoints[line]
	if bpl then
		return breakpoints[line][file]
	end
end

--}}}
--{{{  local function capture_vars(ref,level,line)

local function capture_vars(ref,level,line)
  --get vars, file and line for the given level relative to debug_hook offset by ref

  local lvl = ref + level                --NB: This includes an offset of +1 for the call to here

  --{{{  capture variables

  local ar = debug.getinfo(lvl, "f")
  if not ar then return {},'?',0 end

  local vars = {__UPVALUES__={}, __LOCALS__={}}
  local i

  local func = ar.func
  if func then
    i = 1
    while true do
      local name, value = debug.getupvalue(func, i)
      if not name then break end
      if strsub(name,1,1) ~= '(' then  --NB: ignoring internal control variables
        vars[name] = value
        vars.__UPVALUES__[i] = name
      end
      i = i + 1
    end
    vars.__ENVIRONMENT__ = getfenv(func)
  end

  vars.__GLOBALS__ = getfenv(0)

  i = 1
  while true do
    local name, value = debug.getlocal(lvl, i)
    if not name then break end
    if strsub(name,1,1) ~= '(' then    --NB: ignoring internal control variables
      vars[name] = value
      vars.__LOCALS__[i] = name
    end
    i = i + 1
  end

  vars.__VARSLEVEL__ = level

  if func then
    --NB: Do not do this until finished filling the vars table
    setmetatable(vars, { __index = getfenv(func), __newindex = getfenv(func) })
  end

  --NB: Do not read or write the vars table anymore else the metatable functions will get invoked!

  --}}}

  local file = getinfo(lvl, "source")
  if strfind(file, "@") == 1 then
    file = strsub(file, 2)
  end
  if IsWindows then file = string.lower(file) end

  if not line then
    line = getinfo(lvl, "currentline")
  end

  return vars,file,line

end

--}}}
--{{{  local function restore_vars(ref,vars)

local function restore_vars(ref,vars)

  if type(vars) ~= 'table' then return end

  local level = vars.__VARSLEVEL__       --NB: This level is relative to debug_hook offset by ref
  if not level then return end

  level = level + ref                    --NB: This includes an offset of +1 for the call to here

  local i
  local written_vars = {}

  i = 1
  while true do
    local name, value = debug.getlocal(level, i)
    if not name then break end
    if vars[name] and strsub(name,1,1) ~= '(' then     --NB: ignoring internal control variables
      debug.setlocal(level, i, vars[name])
      written_vars[name] = true
    end
    i = i + 1
  end

  local ar = debug.getinfo(level, "f")
  if not ar then return end

  local func = ar.func
  if func then

    i = 1
    while true do
      local name, value = debug.getupvalue(func, i)
      if not name then break end
      if vars[name] and strsub(name,1,1) ~= '(' then   --NB: ignoring internal control variables
        if not written_vars[name] then
          debug.setupvalue(func, i, vars[name])
        end
        written_vars[name] = true
      end
      i = i + 1
    end

  end

end

--}}}
--{{{  local function trace_event(event, line, level)

local function print_trace(level,depth,event,file,line,name)

  --NB: level here is relative to the caller of trace_event, so offset by 2 to get to there
  level = level + 2

  local file = file or getinfo(level,'short_src')
  local line = line or getinfo(level,'currentline')
  local name = name or getinfo(level,'name')

  local prefix = ''
  if current_thread ~= 'main' then prefix = '['..tostring(current_thread)..'] ' end

  write(prefix..
           string.format('%08.2f:%02i.',os.clock(),depth)..
           string.rep('.',depth%32)..
           (file or '')..' ('..(line or '')..') '..
           (name or '')..
           ' ('..event..')\n')

end

local function trace_event(event, line, level)

  if event == 'return' and trace_returns then
    --note the line info for later
    ret_file = getinfo(level+1,'short_src')
    ret_line = getinfo(level+1,'currentline')
    ret_name = getinfo(level+1,'name')
  end

  if event ~= 'line' then return end

  local slevel = stack_level[current_thread]
  local tlevel = trace_level[current_thread]

  if trace_calls and slevel > tlevel then
    --we are now in the function called, so look back 1 level further to find the calling file and line
    print_trace(level+1,slevel-1,'c',nil,nil,getinfo(level+1,'name'))
  end

  if trace_returns and slevel < tlevel then
    print_trace(level,slevel,'r',ret_file,ret_line,ret_name)
  end

  if trace_lines then
    print_trace(level,slevel,'l')
  end

  trace_level[current_thread] = stack_level[current_thread]

end

--}}}
--{{{  local function debug_hook(event, line, level, thread)

local curfile,thisfile,project_root_path,dirsep,stepping_out
local addresses = {}

if IsWindows then
    dirsep = '\\'
else
    dirsep = '/'
end

local function set_debug_break ()
    local addr = dbgl.c_addr()
    if addr and not addresses[addr] then
        write('//@// '..addr..'\n')
        stepping_out = true
        --addresses[addr] = true
        dbgl.debug_break()
    end
end

local file_cache = {}

local function exists (path)
    if file_cache[path] ~= nil then
        return file_cache[path]
    end
    local f = io.open(path,'r')
    local ret
--~     print('checked',path)
    if f then
        f:close()
        ret = true
    else
        ret = false
    end
    file_cache[path] = ret
    return ret
end


-- *SJD* optimizations:
-- capture_vars() is expensive; now it's only called if:
--  - we have active watches
--  - if we actually break execution

local in_debugger

local function get_canonical_filename (file)
    if strfind(file,"@") == 1 then
        file = strsub(file,2)
		if strfind(file,".",1,true) == 1 then file = strsub(file,3) end
        if step_into and project_root_path and not exists(file) then
            step_into = false
            step_over = true
        end
    end
	local abspath = strsub(file,1,1) == '/' or strsub(file,2,2) == ':'
	if not abspath and project_root_path then -- relative path
		file = project_root_path..dirsep..file
	end
	if IsWindows then
		file = strlower(file)
		file = file:gsub('/','\\') -- canonical for Win32!
		file = file:gsub(' ','%%')
	end
    return file
end


local function debug_hook(event, line, level, thread)
  local vars,file
  if not started then debug.sethook() return end
  current_thread = thread or 'main'
  --print(event,line,step_into,step_lines)
  local level = level or 2
  if tracing then trace_event(event,line,level) end
  if event == "call" then
    if step_into and GDB then -- this might be a C function, prepare to step into it...
      local ar = debug.getinfo(level,"S")
      if ar.what == 'C' and not in_debugger then
        set_debug_break ()
      end
    end
    stack_level[current_thread] = stack_level[current_thread] + 1
  elseif event == "return" or event == "tail return" then
	local sl = stack_level[current_thread] - 1
    stack_level[current_thread] = sl
    if sl < 0 then stack_level[current_thread] = 0 end
          if stepping_out then
            stepping_out = false
          end
  else
    local ar = debug.getinfo(level,"S")
    local rawfile = ar.source
    if not line then
        line = debug.getinfo(level,"l").currentline
    end

--    local vars,file,line = capture_vars(level,1,line)
	--SJD the idea here is to keep track of the _absolute_ filename
	--we are told up front what the project path is; anything which is relative will be relative to this path.
	if rawfile ~= curfile then
        file = rawfile
		curfile = rawfile
        file = get_canonical_filename(file)
--~ 		print('rawfile',rawfile,line)
		thisfile = file
	end
    local stop, ev, idx = false, events.STEP, 0
    while true do
      if #watches > 0 then -- only capture vars if we're tracing
         vars = capture_vars(level,1,line)
          for index, value in pairs(watches) do
            setfenv(value.func, vars)
            local status, res = pcall(value.func)
            if status and res then
              ev, idx = events.WATCH, index
              stop = true
              break
            end
          end
          if stop then break end
      end
      if (step_into)
      or (step_over and (stack_level[current_thread] <= step_level[current_thread] or stack_level[current_thread] == 0)) then
        step_lines = step_lines - 1
        if step_lines < 1 then
          vars = capture_vars(level,1,line)
          ev, idx = events.STEP, 0
          break
        end
      end
	  --print(thisfile,line)
	  local bkval = has_breakpoint(thisfile, line)
      if bkval then
        vars = capture_vars(level,1,line)
        ev, idx = events.BREAK, 0
		if bkval == TEMPORARY then remove_breakpoint(thisfile,line) end
        break
      end
      return
    end
    tracestack(level,tracing)
    local last_next = 1
    local err, next = assert(coroutine.resume(coro_debugger, ev, vars, thisfile, line, idx))
    while true do
      if next == 'cont' then
        return
      elseif next == 'stop' then
        started = false
        write("Program finished\n")
        debug.sethook()
        return
      elseif tonumber(next) then --get vars for given level or last level
        next = tonumber(next)
        if next == 0 then next = last_next end
        last_next = next
        restore_vars(level,vars)
        vars, file, line = capture_vars(level,next)
        err, next = assert(coroutine.resume(coro_debugger, events.SET, vars, file, line, idx))
      else
        write('Unknown command from debugger_loop: '..tostring(next)..'\n')
        write('Stopping debugger\n')
        next = 'stop'
      end
    end
  end
end


--}}}

local display_exprs = {}

local function eval(env,line)
--~   print('eval "'..line..'"')
  local ok, func = pcall(loadstring,line)
  if func == nil or not ok then
    return nil
  else
    setfenv(func, env)
    return pcall(func)
  end
end

local function dump_display(env)
  for i,disp in ipairs(display_exprs) do
    local res,value = eval(env,'return '..disp)
    if res then
      write('<'..disp..'> = '..val2str(value)..'\n')
    end
  end
end

--{{{  local function report(ev, vars, file, line, idx_watch)

local function report(ev, vars, file, line, idx_watch)
  local vars = vars or {}
  local file = file or '?'
  local line = line or 0
  local postfix = ''
  --SJD put the message out first, so we know if it's a crash!
  write '\n'
  if ev ~= events.SET then

    if pausemsg and pausemsg ~= '' and pausemsg ~= 'debug' then
        if not pausemsg:find('(%S+):(%d+)') then
            -- the message did not have an explicit file:line,
            -- so let's try to find a valid Lua frame which called this frame
            local level = 3
            while level <= #traceinfo and traceinfo[level].currentline == -1 do
                level = level + 1
            end
            local ar = traceinfo[level]
            pausemsg = get_canonical_filename(ar.source)..':'..ar.currentline..' '..pausemsg
        end
        write('Message: '..pausemsg..'\n') end
        pausemsg = ''
  end
  if GDB then
    if ev == events.STEP or ev == events.BREAK or ev == events.WATCH then
        write(gprefix..file..':'..line..'\n')
    end
  else
      if current_thread ~= 'main' then postfix = '['..tostring(current_thread)..'] ' end
      if ev == events.STEP then
        write("Paused at file "..file.." line "..line..' ('..stack_level[current_thread]..') '..postfix..'\n')
        dump_display(vars)
      elseif ev == events.BREAK then
        write("Paused at file "..file.." line "..line..' ('..stack_level[current_thread]..') (breakpoint) '..postfix..'\n')
        end_timer()
        dump_display(vars)
      elseif ev == events.WATCH then
        write("Paused at file "..file.." line "..line..' ('..stack_level[current_thread]..')'.." (watch expression "..idx_watch.. ": ["..watches[idx_watch].exp.."])"..postfix.."\n")
        dump_display(vars)
      elseif ev == events.SET then
        --do nothing
      else
        write("Error in application: "..file.." line "..line.." "..postfix.."\n")
      end
  end
  return vars, file, line
end

--}}}

local initial_commands = {}
local kount = 1

--{{{  local function debugger_loop(server)

local prompt
if GDB then prompt = '(GDB)\n' else prompt = '(DBG)\n' end

local function debugger_loop(ev, vars, file, line, idx_watch)

  write("Lua Debugger\n")
  local eval_env, breakfile, breakline = report(ev, vars, file, line, idx_watch)

  local command, args

  --{{{  local function getargs(spec)

  --get command arguments according to the given spec from the args string
  --the spec has a single character for each argument, arguments are separated
  --by white space, the spec characters can be one of:
  -- F for a filename    (defaults to breakfile if - given in args)
  -- L for a line number (defaults to breakline if - given in args)
  -- N for a number
  -- V for a variable name
  -- S for a string

  local function getargs(spec)
    local res={}
    local char,arg
    local ptr=1
    for i=1,string.len(spec) do
      char = strsub(spec,i,i)
      if     char == 'F' then
        _,ptr,arg = strfind(args..' ',"%s*([%w%p]*)%s*",ptr)
        if not arg or arg == '' then arg = '-' end
        if arg == '-' then arg = breakfile end
      elseif char == 'L' then
        _,ptr,arg = strfind(args..' ',"%s*([%w%p]*)%s*",ptr)
        if not arg or arg == '' then arg = '-' end
        if arg == '-' then arg = breakline end
        arg = tonumber(arg) or 0
      elseif char == 'N' then
        _,ptr,arg = strfind(args..' ',"%s*([%w%p]*)%s*",ptr)
        if not arg or arg == '' then arg = '0' end
        arg = tonumber(arg) or 0
      elseif char == 'V' then
        _,ptr,arg = strfind(args..' ',"%s*([%w%p]*)%s*",ptr)
        if not arg or arg == '' then arg = '' end
      elseif char == 'S' then
        _,ptr,arg = strfind(args..' ',"%s*([%w%p]*)%s*",ptr)
        if not arg or arg == '' then arg = '' end
      else
        arg = ''
      end
      tinsert(res,arg or '')
    end
    return unpack(res)
  end

  --}}}

  while true do
    write(prompt) --SJD temporary
    local line
    if initial_commands and #initial_commands > 0 then
      line = table.remove(initial_commands,1)
    else
      initial_commands = nil
      line  = io.read("*line")
    end
    if line == nil then write('\n'); line = 'exit' end

    if strfind(line, "^[a-z]+") then
      command = strsub(line, strfind(line, "^[a-z]+"))
      args    = gsub(line,"^[a-z]+%s*",'',1)            --strip command off line
    else
      command = ''
    end

    if command == "setb" or command == 'break' or command == 'tb' then
      --{{{  set breakpoint
      local line, filename
      if command ~= 'break' then
        line,filename = getargs('LF')
      else
        filename,line = args:match(bpattern)
        line = tonumber(line)
      end
      if filename ~= '' and line ~= '' and line ~= nil then
		local val = true
		if command == 'tb' then val = TEMPORARY end
        set_breakpoint(filename,line,val)
        write("Breakpoint set in file "..filename..' line '..line..'\n')
      else
        write("Bad request\n")
      end

      --}}}

    elseif command == "delb" or command == 'clear' then
      --{{{  delete breakpoint

      local line, filename
      if command == 'delb' then
        line, filename = getargs('LF')
      else
        filename,line = args:match('([^:]+):(%d+)')
        line = tonumber(line)
      end
      if filename ~= '' and line ~= '' then
        remove_breakpoint(filename, line)
        write("Breakpoint deleted from file "..filename..' line '..line.."\n")
      else
        write("Bad request\n")
      end

      --}}}

    elseif command == "debugbreak" then
        if GDB then
            dbgl.debug_break()
        end
    elseif command == "delallb" then
      --{{{  delete all breakpoints
      breakpoints = {}
      write('All breakpoints deleted\n')
      --}}}

    elseif command == "listb" then
      --{{{  list breakpoints
      for i, v in pairs(breakpoints) do
        for ii, vv in pairs(v) do
          write("Break at: "..i..' in '..ii..'\n')
        end
      end
      --}}}

    elseif command == "setw" then
      --{{{  set watch expression

      if args and args ~= '' then
        local func = loadstring("return(" .. args .. ")")
        local newidx = #watches + 1
        watches[newidx] = {func = func, exp = args}
        write("Set watch exp no. " .. newidx..'\n')
      else
        write("Bad request\n")
      end

      --}}}

    elseif command == "delw" then
      --{{{  delete watch expression

      local index = tonumber(args)
      if index then
        watches[index] = nil
        write("Watch expression deleted\n")
      else
        write("Bad request\n")
      end

      --}}}

    elseif command == "delallw" then
      --{{{  delete all watch expressions
      watches = {}
      write('All watch expressions deleted\n')
      --}}}

    elseif command == "listw" then
      --{{{  list watch expressions
      for i, v in pairs(watches) do
        write("Watch exp. " .. i .. ": " .. v.exp..'\n')
      end
      --}}}

    elseif command == "run" or command == 'cont' then
      --{{{  run until breakpoint
      step_into = false
      step_over = false
      eval_env, breakfile, breakline = report(coroutine.yield('cont'))
      --}}}

    elseif command == "step" then
      --{{{  step N lines (into functions)
      local N = tonumber(args) or 1
      step_over  = false
      step_into  = true
      step_lines = tonumber(N or 1)
      eval_env, breakfile, breakline = report(coroutine.yield('cont'))
      --}}}

    elseif command == "over" or command == 'next' then
      --{{{  step N lines (over functions)
      local N = tonumber(args) or 1
      step_into  = false
      step_over  = true
      step_lines = tonumber(N or 1)
      step_level[current_thread] = stack_level[current_thread]
      eval_env, breakfile, breakline = report(coroutine.yield('cont'))
      --}}}

    elseif command == "out" or command == 'finish' then
      --{{{  step N lines (out of functions)
      local N = tonumber(args) or 1
      step_into  = false
      step_over  = true
      step_lines = 1
      step_level[current_thread] = stack_level[current_thread] - tonumber(N or 1)
      eval_env, breakfile, breakline = report(coroutine.yield('cont'))
      --}}}

    elseif command == "goto" then
      --{{{  step until reach line
      local N = tonumber(args)
      if N then
        step_over  = false
        step_into  = false
        if has_breakpoint(breakfile,N) then
          eval_env, breakfile, breakline = report(coroutine.yield('cont'))
        else
          local bf = breakfile
          set_breakpoint(breakfile,N,true)
          eval_env, breakfile, breakline = report(coroutine.yield('cont'))
          if breakfile == bf and breakline == N then remove_breakpoint(breakfile,N) end
        end
      else
        write("Bad request\n")
      end
      --}}}

    elseif command == "set" or command == 'frame' then
      --{{{  set/show context level
      local level = tonumber(args)
      if level and level == '' then level = nil end
      -- find the first valid Lua frame that called this frame!
      while level <= #traceinfo and traceinfo[level].currentline == -1 do
         level = level + 1
      end
      if level then
        eval_env, breakfile, breakline = report(coroutine.yield(level))
      end

--~       if eval_env.__VARSLEVEL__ then
--~         write('Level: '..eval_env.__VARSLEVEL__..'\n')
--~       else
--~         write('No level set\n')
--~       end
      --}}}

    elseif command == "vars" then
      --{{{  list context variables
      local depth = args
      if depth and depth == '' then depth = nil end
      depth = tonumber(depth) or 1
      dumpvar(eval_env, depth+1, 'variables')
      --}}}

    elseif command == "glob" then
      --{{{  list global variables
      local depth = args
      if depth and depth == '' then depth = nil end
      depth = tonumber(depth) or 1
      dumpvar(eval_env.__GLOBALS__,depth+1,'globals')
      --}}}

    elseif command == "fenv" then
      --{{{  list function environment variables
      local depth = args
      if depth and depth == '' then depth = nil end
      depth = tonumber(depth) or 1
      dumpvar(eval_env.__ENVIRONMENT__,depth+1,'environment')
      --}}}

    elseif command == "ups" then
      --{{{  list upvalue names
      dumpvar(eval_env.__UPVALUES__,2,'upvalues')
      --}}}

    elseif command == "locs" then
      --{{{  list locals names
      dumpvar(eval_env.__LOCALS__,2,'upvalues')
      --}}}

    elseif command == "what" then
      --{{{  show where a function is defined
      if args and args ~= '' then
        local v = eval_env
        local n = nil
        for w in string.gmatch(args,"[%w_]+") do
          v = v[w]
          if n then n = n..'.'..w else n = w end
          if not v then break end
        end
        if type(v) == 'function' then
          local def = debug.getinfo(v,'S')
          if def then
            write(def.what..' in '..def.short_src..' '..def.linedefined..'..'..def.lastlinedefined..'\n')
          else
            write('Cannot get info for '..v..'\n')
          end
        else
          write(v..' is not a function\n')
        end
      else
        write("Bad request\n")
      end
      --}}}

    elseif command == "dump" then
      --{{{  dump a variable
      local name, depth = getargs('VN')
      if name ~= '' then
        if depth == '' or depth == 0 then depth = nil end
        depth = tonumber(depth or 1)
        local v = eval_env
        local n = nil
        for w in string.gmatch(name,"[^%.]+") do     --get everything between dots
          if tonumber(w) then
            v = v[tonumber(w)]
          else
            v = v[w]
          end
          if n then n = n..'.'..w else n = w end
          if not v then break end
        end
        dumpvar(v,depth+1,n)
      else
        write("Bad request\n")
      end
      --}}}

    elseif command == "show" then
      --{{{  show file around a line or the current breakpoint

      local line, file, before, after = getargs('LFNN')
      if before == 0 then before = 10     end
      if after  == 0 then after  = before end

      if file ~= '' and file ~= "=stdin" then
        show(file,line,before,after)
      else
        write('Nothing to show\n')
      end

      --}}}

    elseif command == "poff" then
      --{{{  turn pause command off
      pause_off = true
      --}}}

    elseif command == "pon" then
      --{{{  turn pause command on
      pause_off = false
      --}}}

    elseif command == "tron" then
      --{{{  turn tracing on/off
      local option = getargs('S')
      trace_calls   = false
      trace_returns = false
      trace_lines   = false
      tracing = false
      if strfind(option,'c') then trace_calls   = true; tracing = true end
      if strfind(option,'r') then trace_returns = true; tracing = true end
      if strfind(option,'l') then trace_lines   = true; tracing = true end
      --}}}

    elseif command == "trace" then
      --{{{  dump a stack trace
      trace(eval_env.__VARSLEVEL__)
      --}}}

    elseif command == "info" then
      --{{{  dump all debug info captured
      write('info?\n')
      info()
      --}}}

    elseif command == "pause" then
      --{{{  not allowed in here
      write('pause() should only be used in the script you are debugging\n')
      --}}}

    elseif command == "help" then
      --{{{  help
      local command = getargs('S')
      if command ~= '' and hints[command] then
        write(hints[command]..'\n')
      else
        for _,v in pairs(hints) do
          local _,_,h = strfind(v,"(.+)|")
          write(h..'\n')
        end
      end
      --}}}

    elseif command == "display" then
    --{{{ Add a variable to the display list
      local expr = getargs('S')
      if expr == "" then
        for i,d in ipairs(display_exprs) do
          write(d,'\n')
        end
      else
        tinsert(display_exprs,expr)
      end
    --}}}
    elseif command == "undisplay" then
    --{{{ clear the display list
      display_exprs = {}
    --}}}
    elseif command == "up" or command == "down" then
		local level = eval_env.__VARSLEVEL__
		if command == "up" and level >= 1 then
			level = level + 1
		else
			level = level - 1
		end
		eval_env, breakfile, breakline = report(coroutine.yield(level))
		if eval_env.__VARSLEVEL__ then
            if GDB then breakfile =  project_root_path..dirsep..breakfile end
			report(events.BREAK,eval_env,breakfile,breakline)
		end
	elseif command == "rootpath" then  --SJD scite-debug integration
		project_root_path = getargs('S')
        curfile = nil -- force renormalization of current filename
        write('rootpath '..project_root_path..'\n')
    elseif command == "exit" or command == 'quit' then
      --{{{  exit debugger
      return 'stop'
      --}}}

    elseif line ~= '' then
      --{{{  just execute whatever it is in the current context

      --map line starting with "=..." to "return ..."
      -- SJD: also 'eval ' and 'print ', which has a special meaning to scite-debug
      local scite_debug_print
      local scite_debug_eval = line:find('^eval ')
      if GDB then scite_debug_print = line:find('^print ') end
      if scite_debug_eval then
        line = line:gsub('eval ','return ',1)
      elseif scite_debug_print then
        line = line:gsub('print ','return ',1)
      elseif line:sub(1,1) == '=' then
        line = line:gsub('=','return ',1)
      end
	 write('expr ',line,'\n')

      local ok, func = pcall(loadstring,line)
      if func == nil then                             --Michael.Bringmann@lsi.com
        write("Compile error: "..line..'\n')
      elseif not ok then
        write("Compile error: "..func..'\n')
      else
        setfenv(func, eval_env)
        local res = {pcall(func)}
        if res[1] then
          if res[2] then
            table.remove(res,1)
            if scite_debug_eval then --SJD give scite-debug a clear marker
              write('= '..val2str(res[1]),'\n')
            elseif scite_debug_print then -- GDB-style results!
              write('$'..kount..' = '..val2str(res[1])..'\n')
              kount = kount + 1
            else
              for _,v in ipairs(res) do
                write(tostring(v))
                write('\t')
              end
              write('\n')
            end
          end
          --update in the context
          eval_env, breakfile, breakline = report(coroutine.yield(0))
        else
          write("Run error: "..res[2]..'\n')
        end
      end
      --}}}
     in_debugger = false
    end
  end
end_timer()

end

--}}}

--{{{  coroutine.create

--This function overrides the built-in for the purposes of propagating
--the debug hook settings from the creator into the created coroutine.

_G.coroutine.create = function(f)
  local thread
  local hook, mask, count = debug.gethook()
  if hook then
    local function thread_hook(event,line)
      hook(event,line,3,thread)
    end
    thread = cocreate(function(...)
                        stack_level[thread] = 0
                        trace_level[thread] = 0
                        step_level [thread] = 0
                        debug.sethook(thread_hook,mask,count)
                        return f(...)
                      end)
    return thread
  else
    return cocreate(f)
  end
end

--}}}
--{{{  coroutine.wrap

--This function overrides the built-in for the purposes of propagating
--the debug hook settings from the creator into the created coroutine.

_G.coroutine.wrap = function(f)
  local thread
  local hook, mask, count = debug.gethook()
  if hook then
    local function thread_hook(event,line)
      hook(event,line,3,thread)
    end
    thread = cowrap(function(...)
                      stack_level[thread] = 0
                      trace_level[thread] = 0
                      step_level [thread] = 0
                      debug.sethook(thread_hook,mask,count)
                      return f(...)
                    end)
    return thread
  else
    return cowrap(f)
  end
end

--}}}

--{{{  function pause()

--
-- Starts/resumes a debug session
--

function pause(x)
  if pause_off then return end               --being told to ignore pauses
  pausemsg = x or 'pause'
  local lines
  local src = getinfo(2,'short_src')
  if src == "stdin" then
    lines = 1   --if in a console session, stop now
  else
    lines = 2   --if in a script, stop when get out of pause()
  end
  if started then
    --we'll stop now 'cos the existing debug hook will grab us
    step_lines = lines
    step_into  = true
  else
    --SJD: see if we can open clidebug.cmd
    local f = io.open(os.getenv('TMP')..'\\clidebug.cmd')
    if f then
      for line in f:lines() do
        tinsert(initial_commands,line)
      end
      f:close()
    else
      write('no command file found\n')
    end
    start_timer 'BREAK'
    coro_debugger = cocreate(debugger_loop)  --NB: Use original coroutune.create
    --set to stop when get out of pause()
    trace_level[current_thread] = 0
    step_level [current_thread] = 0
    stack_level[current_thread] = 1
    step_lines = lines
    step_into  = true
    started    = true
    debug.sethook(debug_hook, "crl")         --NB: this will cause an immediate entry to the debugger_loop
  end
end

--}}}
--{{{  function dump()

--shows the value of the given variable, only really useful
--when the variable is a table
--see dump debug command hints for full semantics

function dump(v,depth)
  dumpvar(v,(depth or 1)+1,tostring(v))
end

--}}}
--{{{  function debug.traceback(x)

local _traceback = debug.traceback       --note original function

--override standard function
debug.traceback = function(...)
  local args = {...}
  local message = ""
  if #args == 0 then -- "",2
    args = {"",2}
  elseif #args == 1 then -- message,2
    args[1] = args[1] or ""
    message = args[1]
    table.insert(args,2)
  elseif #args == 2 then -- message,level+1
    args[1] = args[1] or ""
    message = args[1]
    args[2] = args[2]+1
  elseif #args == 3 then -- thread,message,level+1
    message = args[2]
    args[3] = args[3]+1
  end
  local assertmsg = _traceback(unpack(args))        --do original function
  if not DEBUG_TRACEBACK_NO_PAUSE then
    pause(message)                               --let user have a look at stuff
  end
  return assertmsg                       --carry on
end

_TRACEBACK = debug.traceback             --Lua 5.0 function

--}}}

