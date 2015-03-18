-- A simple gdb interface for SciTE
-- Steve Donovan, 2007
-- changes:
-- (1) debug.backtrace.depth will configure depth of stack frame dump (default is 20)
-- (2) initially only adds Run and Breakpoint to the menu
-- (3) first generalized version
local GTK = scite_GetProp('PLAT_GTK')

function do_set_menu()
--~ 	scite_Command {
--~ 	  'Step|do_step|Alt+C',
--~ 	  'Step Over|do_next|Alt+N',
--~ 	  'Go To|do_temp_breakpoint|Alt+G',
--~ 	  'Kill|do_kill|Alt+K',
--~ 	  'Inspect|do_inspect|Alt+I',
--~ 	  'Locals|do_locals|Alt+Ctrl+L',
--~       'Watch|do_watch|Alt+W',
--~ 	  'Backtrace|do_backtrace|Alt+Ctrl+B',
--~       'Step Out|do_finish|Alt+M',
--~ 	  'Up|do_up|Alt+U',
--~ 	  'Down|do_down|Alt+D',
--~ 	}
end

-- only bring up the absolute minimum commands initially....
scite_Command {
--~   'Run|do_run|*{savebefore:yes}|Alt+R',
--~   'Breakpoint|do_breakpoint|F9'
}

scite_require 'extlib.lua'

local lua_prompt = '(lua)'
local prompt
local prompt_len
local sub = string.sub
local find = string.find
local len = string.len
local gsub = string.gsub
local status = 'dead'
local last_command
local last_breakpoint
local traced
local dbg

function dbg_last_command()
    return dbg.last_command
end

function dbg_status()
    return status
end

function dbg_obj()
	return dbg
end

function debug_line_handler(line)
	local state = dbg_status()
	local dbg = dbg_obj()
    if state ~= 'dead' then
        dbg.last_command = '<inter>'
        spawner_command(line)
	end
end

local debug_status = scite_GetProp('debug.status',false)

-- *doc* you can add $(status.msg) to your statusbar.text.1 property if
-- you want to see debugger status.
-- (see SciTEGlobal.properties for examples)
function set_status(s)
    if s ~= status then
        if debug_status then print('setting status to '..s) end
        status = s
		local str = s
		if s == 'dead' then str = '' end
        props['status.msg'] = str
        scite.UpdateStatusBar(true)
    end
end

function dbg_status()
    return status
end

------- Generic debugger interface, based on GDB ------
Dbg = class()

function Dbg:init(root)
end

function Dbg:default_target()
    local ext = self.no_target_ext
    if ext then
        local res = props['FileName']
        if ext ~= '' then res = res..'.'..ext end
        return res
    else
        return props['FileNameExt']
    end
end

function Dbg:step()
	dbg_command('step')
end

function Dbg:step_over()
	dbg_command('next')
end

function Dbg:continue()
	dbg_command('cont')
end

function Dbg:quit()
	spawner_command('quit')
    if not self.no_quit_confirm then
        spawner_command('y')
    end
end

function Dbg:set_breakpoint(file,lno)
	dbg_command('break',file..':'..lno)
end

-- generally there are two ways to kill breakpoints in debuggers;
-- either by number or by explicit file:line.
function Dbg:clear_breakpoint(file,line,num)
	if file then
        dbg_command('clear',file..':'..line)
	else
		print ('no breakpoint at '..file..':'..line)
	end
end

-- run until the indicated file:line is reached
function Dbg:goto(file,lno)
	dbg_command('tbreak',file..':'..lno)
	dbg_command('continue')
end

function Dbg:set_display_handler(fun)
	-- 0.8 change: if a handler is already been set, don't try to set a new one!
	if self.result_handler then return end
	self.result_handler = fun
end

function Dbg:inspect(word)
	dbg_command('print',word)
end

local skip_file_pattern
local do_skip_includes

--- *doc* you can choose a directory pattern for files which you don't want to skip through
--- for Unix, this is usually easy, but for mingw you have to supply the path to
--- your gcc directory.
function Dbg:auto_skip_over_file(file)
    if not do_skip_includes then return end
    return find(file,skip_file_pattern)
end

function Dbg:finish()
    dbg_command('finish')
end

function Dbg:locals()
	dbg_command('info locals')
end

function Dbg:watch(word)
	dbg_command('display',word)
end

function Dbg:up()
	dbg_command('up')
end

function Dbg:down()
	dbg_command('down')
end

function Dbg:backtrace(depth)
	dbg_command('backtrace',depth)
end

function Dbg:frame(f)
	dbg_command('frame',f)
end

function Dbg:detect_frame(line)
	local _,_,frame = find(line,'#(%d+)')
	if _ then
		dbg:frame(frame)
	end
end

function Dbg:special_debugger_setup(out)
end

function Dbg:breakpoint_confirmation(line)
	-- breakpoint defintion confirmation
	-- ISSUE: only picking up for breakpoints added _during_ session!
    local _,_,bnum = find(line,"Breakpoint (%d+) at")
	if  _ then
		if last_breakpoint then
			print('breakpoint:',last_breakpoint.line,bnum)
			last_breakpoint.num = bnum
		end
	end
end

function quote(s)
    return '"'..s..'"'
end

function Dbg:find_execution_break(line)
    local _,_,file,lineno = find(line,self.break_line)
    if _ then return file,lineno end
end

function Dbg:check_breakpoint (b)
    return true
end

-- add our currently defined breakpoints
function Dbg:dump_breakpoints(out)
	for b in Breakpoints() do
        if self:check_breakpoint(b) then
            local f = basename(b.file)
            print (b.file,f)
            out:write('break '..f..':'..b.line..'\n')
        end
	end
end

function Dbg:run_program(out,parms)
	out:write('run '..parms..'\n')
end

function Dbg:detect_program_crash(line)
	return false
end

----- Debugger commands --------
local spawner_obj

local function launch_debugger()
	if do_launch() then
		set_status('running')
		return true
	else
		print 'Unable to debug program!'
		return false
	end
end

local function try_start_debugger()
	if not dbg then
		return launch_debugger()
	else
		return true
	end
end

function do_step()
    if not try_start_debugger() then return end
	dbg:step()
end

function do_run()
    if status == 'dead' then
		launch_debugger()
    else
        RemoveLastMarker(true)
        dbg:continue()
        set_status('running')
    end
end

function do_kill()
    if not dbg then return end
	if status == 'running' then
		-- this actually kills the debugger process
		spawner_obj:kill()
	else
		-- this will ask the debugger nicely to exit
		dbg:quit()
	end
    closing_process()
end

function do_next()
    if not try_start_debugger() then return end
	dbg:step_over()
end

function breakpoint_from_position(lno)
	for b in Breakpoints() do
		if b.file == scite_CurrentFile() and b.line == lno then
			return b
		end
	end
	return nil
end

function do_breakpoint()
	local lno = current_line() + 1
	local file = props['FileNameExt']
	-- do we have already have a breakpoint here?
	local brk = breakpoint_from_position(lno)
	if brk then
		local bnum = brk.num
		brk:delete()
		if status ~= 'dead' then
			dbg:clear_breakpoint(file,lno,bnum)
		end
	else
		last_breakpoint = SetBreakMarker(lno)
		if  last_breakpoint then
			if status ~= 'dead' then
				dbg:set_breakpoint(file,lno)
			end
		end
	end
end

function do_temp_breakpoint()
    if not try_start_debugger() then return end
	local lno = current_line() + 1
	local file = props['FileNameExt']
	dbg:goto(file,lno)
end

local function char_at(p)
    return string.char(editor.CharAt[p])
end

-- used to pick up current expression from current document position
-- We use the selection, if available, and otherwise pick up the word;
-- if it seems to be a field expression, look for the object before.
local function current_expr(pos)
    local s = editor:GetSelText()
    if s == '' then -- no selection, so find the word
        pos = pos or editor.CurrentPos
        local p1 = editor:WordStartPosition(pos,true)
        local p2 = editor:WordEndPosition(pos,true)
        -- is this a field of some object?
        while true do
            if  char_at(p1-1) == '.' then -- generic member access
                p1 = editor:WordStartPosition(p1-2,true)
            elseif char_at(p1-1) == '>' and char_at(p1-2) == '-' then --C/C++ pointer
                p1 = editor:WordStartPosition(p1-3,true)
            else
                break
            end
        end
        return editor:textrange(p1,p2)
    else
        return s
    end
end

function actually_inspect(w)
    if len(w) > 0 then
        dbg:inspect(w)
    end
end

function do_inspect()
    if not dbg then return end
    local w = current_expr()
	scite.Prompt("Inspect which expression:",w,"actually_inspect")
end

function do_locals()
    if not dbg then return end
	dbg:locals()
end

function actually_watch(w)
    dbg:watch(w)
end

function do_watch()
    if not dbg then return end
	scite.Prompt("Watch which expression:",current_expr(),"actually_watch")
end

function do_backtrace()
    if not dbg then return end
	dbg:backtrace(scite_GetProp('debug.backtrace.depth','20'))
end

function do_up()
    if not dbg then return end
	dbg:up()
end

function do_down()
    if not dbg then return end
	dbg:down()
end

function do_finish()
    if not dbg then return end
    dbg:finish()
end

local root

function Dbg:parameter_string()
	-- any parameters defined with View|Parameters
    local parms = ' '
    local i = 1
    local parm = props[i]
    while parm ~= '' do
        if find(parm,'%s') then
			-- if it's already quoted, then preserve the quotes
 			if find(parm,'"') == 1 then
 				parm = gsub(parm,'"','\\"')
 			end
            parm = '"'..parm..'"'
        end
        parms = parms..' '..parm
        i = i + 1
        parm = props[i]
    end
    return parms
end

local menu_init = false
local debug_verbose
local debuggers = {}
local append = table.insert
local remove = table.remove

---- event handling

-- If an event returns true, then this event will persist.
-- The return value of this function is true if any event returns an extra true result
-- Note: we iterate over a copy of the list, because this is the only way I've
-- found to make this method re-enterant. With this scheme it is
-- safe to raise an event within an event handler.
function Dbg:raise_event (event,...)
    local events = self.events
    if not events then return end
    -- not recommended for big tables!
    local cpy = {unpack(events)}
    local ignore
    for i,evt in ipairs(cpy) do
        if evt.event == event then
            local keep,want_to_ignore = evt.handler(...)
            if not keep then
               remove(events,i)
            end
            ignore = ignore or want_to_ignore
        end
    end
    return ignore
end

function Dbg:set_event (name,handler)
    if not self.events then self.events = {} end
    append(self.events,{event=name,handler=handler})
end

function Dbg:queue_command (cmd)
    self:set_event('prompt',function() spawner_command(cmd) end)
end

function create_existing_breakpoints()
	local out = io.open(dbg.cmd_file,"w")
	dbg:special_debugger_setup(out)
	dbg:dump_breakpoints(out)
    local parms = dbg:parameter_string()
	dbg:run_program(out,parms)
	out:close();
end

-- you may register more than one debugger class (@dclass) but such classes must
-- have a static method discriminate() which will be passed the full target name.
function register_debugger(name,ext,dclass)
    if type(ext) == 'table' then
        for i,v in ipairs(ext) do
            register_debugger(name,v,dclass) --**
        end
    else
		if not debuggers[ext] then
			debuggers[ext] = {dclass}
		else
			if not dclass.discriminator then
				error("Multiple debuggers registered for this extension, with no discriminator function")
			end
			append(debuggers[ext],dclass)
		end
    end
end

function create_debugger(ext,target)
	local dclasses = debuggers[ext]
    if not dclasses then dclasses = debuggers['*'] end
	if #dclasses == 1 then -- there is only one possible debugger for this extension!
		return dclasses[1]
	else -- there are several registered. We need to call the discriminator!
		for i,d in ipairs(dclasses) do
			if d.discriminator(target) then
				return d
			end
		end
	end
	error("unable to find appropriate debugger")
end

local initialized
local was_error = false
local continued_line, end_line_action, postproc

function do_launch()
	if not menu_init then
		do_set_menu()
		menu_init = true
	end
	scite.MenuCommand(IDM_SAVE)
	local no_host_symbols
    traced = false
	debug_verbose = true
   	-- *doc* detect the debugger we want to use, based on target extension
    -- if there is no explicit target, then use the current file.
    local target = scite_GetProp('debug.target')
    local ext
    if target then
	    -- @doc the target may not actually have debug symbols, in the case
		-- where we are debugging some dynamic libraries. Indicate this
		-- by prefixing target with [n]
		if target:find('^%[n%]') then
			target = target:sub(4)
			no_host_symbols = true
		end
        ext = extension_of(target)
    else
        ext = props['FileExt']
    end
	dbg = create_debugger(ext,choose(target,target,props['FileName']))
	dbg.host_symbols = not no_host_symbols
    -- this isn't ideal!
    root = props['TMP']
    dbg:init(root)
    do_skip_includes = scite_GetProp('debug.skip.includes',false)
    if do_skip_includes then
		local inc_path
        if GTK then inc_path = '^/usr/' else inc_path = '<<<DONUT>>>' end
		local file_pat_prop = 'debug.skip.file.matching'
		if dbg.skip_system_extension then
			file_pat_prop = file_pat_prop..dbg.skip_system_extension
		end
		skip_file_pattern = scite_GetProp(file_pat_prop,inc_path)
    end
    -- *doc* the default target depends on the debugger (it wd have extension for pydb, etc)
    if not target then target = dbg:default_target() end
    target = quote_if_needed(target)
    -- *doc* this determines the time before calltips appear; you can set this as a SciTE property.
	if props['dwell.period'] == '' then props['dwell.period'] = 500 end
    -- get the debugger process command string
    local dbg_cmd = dbg:command_line(target)
    print(dbg_cmd)
    continued_line = nil
    -- first create the cmd file for the debugger
	create_existing_breakpoints()
	scite_InteractivePromptHandler (dbg.prompt,debug_line_handler)
    --- and go!!
	scite.SetDirectory(props['FileDir'])
    spawner.verbose(scite_GetPropBool('debug.spawner.verbose',false))
--	spawner.fulllines(1)
	spawner_obj = spawner.new(dbg_cmd)
	spawner_obj:set_output('ProcessChunk')
	spawner_obj:set_result('ProcessResult')
	return spawner_obj:run()
end

-- speaking to the spawned process goes through a named pipe on both
-- platforms.
local pipe = nil
local last_command_line

function dbg_command_line(s)
    if status == 'active' or status == 'error' then
        spawner_command(s)
        last_command_line = s
        if dbg.trailing_prompt then
            last_command_line = dbg.prompt..last_command_line
        end
    end
end

function spawner_command(line)
    if not dbg then return end
	spawner_obj:write(line..'\n')
end

--local ferr = io.stderr

function dbg_command(s,argument)
    if not dbg then return end
	dbg.last_command = s
    dbg.last_arg = argument
    if argument then s = s..' '..argument end
    dbg_command_line(s)
end

-- *doc* currently, only win32-spawner understands the !up command; I can't
-- find the Unix/GTK equivalent! It is meant to bring the debugger
-- SciTE instance to the front.
function raise_scite()
	--spawner.foreground()
end

-- output of inspected variables goes here; this mechanism allows us
-- to redirect command output (to a tooltip in this case)
function display(s)
	if dbg.result_handler then
		dbg.result_handler(s)
        dbg.result_handler = nil
	else
		print(s)
	end
end

function closing_process()
    print 'quitting debugger'
--	spawner_obj:close()
    set_status('dead')
    RemoveLastMarker(true)
	scite_LeaveInteractivePrompt()
    dbg = nil
end

local function finish_pending_actions()
    if continued_line then
        end_line_action(continued_line,dbg)
        continued_line = nil
        if postproc.once then dbg.last_command = ''  end
    end
end

local function set_error_state()
    if was_error then
        set_status('error')
        was_error = false
    else
        set_status('active')
    end
end

local function auto_backtrace()
    if status == 'error' and not traced then
        raise_scite()
        do_backtrace()
        traced = true
    end
end

local current_file

local function error(s)
    io.stderr:write(s..'\n')
end

local was_prompt

function ProcessOutput(line)
    -- on the GTK version, commands are currently echoed....
    if last_command_line and find(line,last_command_line) then
        return
     end
	 -- Debuggers (esp. clidebug) can emit spurious blank lines. This makes them quieter!
	 if was_prompt and line:find('^%s*$') then
		was_prompt = false
		return
	end
--~  	 trace('*'..line)
    -- sometimes it's useful to know when the debugger process has properly started
    if dbg.detect_start and find(line,dbg.detect_start) then
        dbg:handle_debug_start()
        dbg.detect_start = nil
        return
    end
	-- detecting end of program execution
    local prog_ended,process_fininished = dbg:detect_program_end(line)
	if prog_ended then
		if not processed_finished then spawner_command('quit') end
        set_status('dead')
        closing_process()
		return
	end
    -- ignore prompt; this is the point at which we know that commands have finished
	if find(line,dbg.prompt) then
        dbg:raise_event 'prompt'
        finish_pending_actions()
        if was_error then set_error_state() end
        auto_backtrace()
		was_prompt = true
		return
	end

    -- the result of some commands require postprocessing;
	-- it will collect multi-line output together!
    postproc = dbg.postprocess_command[dbg.last_command]
    if postproc then
        local tline = rtrim(line)
        if find(tline,postproc.pattern)
			or (postproc.alt_pat and find(tline,postproc.alt_pat)) then
            if not postproc.single_pattern then
                finish_pending_actions()
                continued_line = tline
                end_line_action = postproc.action
            else
                postproc.action(tline,dbg)
            end
        else
            if continued_line then continued_line = continued_line..tline end
        end
    end
	-- did we get a confirmation message about a created breakpoint?
    dbg:breakpoint_confirmation(line)
	-- have we crashed?
	if dbg:detect_program_crash(line) then
		was_error = true
	end
	-- looking for break at line pattern
	local file,lineno,explicit_error = dbg:find_execution_break(line)
	if file and status ~= 'dead' then
        if dbg.check_skip_always or current_file ~= file then
            current_file = file
            if dbg:auto_skip_over_file(file) then
                dbg:finish()
                spawner_command('step') --??
                return
            end
        end
		-- a debugger can indicate an explicit error, rather than depending on
		-- detect_program_crash()
		if explicit_error then
			was_error = true
		end
        set_error_state()
        -- if any of the break events wishes, we can ignore this break...
        if not dbg:raise_event ('break',file,lineno,status)  then
            OpenAtPos(file,lineno,status)
            raise_scite()
            auto_backtrace()
            dbg.last_comand = ''
            -- may schedule a command to be executed after the error backtrace
            if type(explicit_error) == 'string' then
                dbg:queue_command(explicit_error)
            end
        end
	else
        local cmd = dbg.last_command
        if (debug_verbose or dbg.last_command == '<inter>') and
			not (dbg.silent_command[cmd] or dbg.postprocess_command[cmd]) then
				trace(line)
        end
	end
end

function ProcessChunk(s)
	local i1 = 1
	local i2 = find(s,'\n',i1)
	while i2 do
		local line = sub(s,i1,i2)
		ProcessOutput(line)
		i1 = i2 + 1
		i2 = find(s,'\n',i1)
	end
	if i1 <= len(s) then
		local line = sub(s,i1)
		ProcessOutput(line)
	end
end

function ProcessResult(res)
	if status ~= 'dead' then
		closing_process()
	end
end

--- *doc* currently, double-clicking in the output pane will try to recognize
--- a stack frame pattern and move to that frame if possible.
scite_OnDoubleClick(function()
	if output.Focus and status == 'active' or status == 'error' then
		dbg:detect_frame(output:GetLine(current_output_line()))
	end
end)

-- *doc* if your scite has OnDwellStart, then the current symbol under the mouse
-- pointer will be evaluated and shown in a calltip.
local _pos

function calltip(s)
    editor:CallTipShow(_pos,s)
end

scite_OnDwellStart(function (pos,s)
    if status == 'active' or status == 'error' then
        if s ~= '' then
			s = current_expr(pos)
            _pos = pos
            dbg:set_display_handler(calltip)
			dbg:inspect(s)
        else
           editor:CallTipCancel()
        end
        return true
    end
end)


