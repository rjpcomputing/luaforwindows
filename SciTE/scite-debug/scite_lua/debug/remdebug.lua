scite_require 'debugger.lua'
local find = string.find
local sub = string.sub
local GTK = scite_GetProp('PLAT_GTK')

local p_pattern = '^= '

local function print_process(s,dbg)
    s = s:sub(3)
    display(dbg.last_arg..' = '..s)
end

-- special actions for commands which require postprocessing
local postprocess_command = {
    eval = {pattern=p_pattern, action=print_process, single_pattern=true},
}

Remdebug = class(Dbg)

-- RemDebug is  now only used for _remote connections_ if Clidebug is also registered!
function Remdebug.discriminator(target)
	return find(target,':') == 1
end

function Remdebug:init(root)
	self.prompt = 'DBG'
    self.no_target_ext = false
	self.cmd_file = root..'/dbg.cmd'
    self.detect_start = '^Run the program you wish to debug'
	-- find out where the Lua executable is; you can use the debug.lua property if it isn't the same
	-- as your lua executable specified in lua.properties.
	self.lua = scite_GetProp("debug.lua")
	if not self.lua then
		self.lua = scite_GetProp('command.go.*.lua'):match('^(%w+)')
	end
    -- this is added to the package.path of the Lua program
    self.remdebug_path = scite_GetProp('remdebug.path',extman_Path()..'/remDebug')
    self.no_quit_confirm = true
	local drive = '';
	if not GTK then drive = '[a-zA-Z]:' end
    self.break_line  = '^Paused at file ('..drive..'/[^%s]+)%sline%s(%d+)'
	self.silent_command = {}
	self.postprocess_command = postprocess_command
end

local function backslash(path)
	return path:gsub('\\','/')
end

function Remdebug:handle_debug_start()
    if not self.target:find('^:remote') then 
        local cmd = self.lua..' -e "package.path=\''..backslash(self.remdebug_path)
        cmd = cmd..'/?.lua;\'..package.path" -l remdebug '..self.target..' '..self:parameter_string()
		print(cmd)
		print 'spawning...'
        ts = spawner.new(cmd)
        ts:set_output('trace')
        ts:run()
    end
end

-- '%s -e "package.path=%s" -l remdebug %s'

local GTK = scite_GetProp('PLAT_GTK')

function Remdebug:command_line(target)
    self.target = target
	local rpath = self.remdebug_path
    return self.lua..' -e "_DPROMPT=\'DBG\\n\'" '..rpath..'/controller.lua '..self.cmd_file
end

function Remdebug:dump_breakpoints(out)
	for b in Breakpoints() do        
		out:write('setb '..b.file:gsub('\\','/')..' '..b.line..'\n')
	end
end

function Remdebug:run_program(out,parms)
    out:write('run\n')
end

function Remdebug:step()
	dbg_command('step')
end

function Remdebug:step_over()
	dbg_command('over')
end

function Remdebug:continue()
	dbg_command('run')
end

function Remdebug:quit()
	dbg_command('exec os.exit(0)')
end

function Remdebug:inspect(word)
	dbg_command('eval',word)
end

function Remdebug:set_breakpoint(file,lno)    
	dbg_command('setb',file..' '..lno)
end

function Remdebug:clear_breakpoint(file,line,num)
	if file then
        -- this function will only pass us the filename part, not the path!
        dbg_command('delb',fullpath(file)..' '..line)
	else
		print ('no breakpoint at '..file..':'..line)
	end
end


function Remdebug:backtrace(count)
end

function Remdebug:finish()
    
end

function Remdebug:locals()
    dbg_command('locals')
end

function Remdebug:detect_program_end(line)
	return find(line,'^Program finished')
end

register_debugger('remdebug','lua',Remdebug)
