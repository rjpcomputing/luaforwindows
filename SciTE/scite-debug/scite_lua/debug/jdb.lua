scite_require 'debugger.lua'
local find = string.find
local sub = string.sub

local p_pattern = '.*= '

local function print_process(s)
    display(s)
end

-- special actions for commands which require postprocessing
local postprocess_command = {
    print = {pattern=p_pattern, action=print_process, single_pattern=true},
}

Jdb = class(Dbg)

function Jdb:init(root)
	self.prompt = '(JDB)'
    self.no_target_ext = ''
	self.cmd_file = '.jdbrc'
    self.no_quit_confirm = true
	self.silent_command = {}
	self.postprocess_command = postprocess_command
end

local GTK = scite_GetProp('PLAT_GTK')

function Jdb:command_line(target)
	return 'jdb '..target..' '..self:parameter_string()
end

function Jdb:run_program(out,parms)
    out:write('run\n')
end

function Jdb:dump_breakpoints(out)
	for b in Breakpoints() do        
		out:write('stop at '..filename(b.file)..':'..b.line..'\n')
	end
end

function Jdb:clear_breakpoint(file,line,num)
	if file then
        dbg_command('clear',filename(file)..':'..line)
	else
		print ('no breakpoint at '..file..':'..line)
	end
end

function Jdb:backtrace(count)
    dbg_command('where')
end

function Jdb:finish()
    dbg_command('step up')
end

function Jdb:locals()
	dbg_command('locals')
end

function Jdb:watch(word)
	dbg_command('monitor print',word)
end

function Jdb:set_breakpoint(file,lno)    
	dbg_command('stop at',filename(file)..':'..lno)
end

-- a little hack necessary....
function Jdb:find_execution_break(line)
    local _,method,lineno,file
    -- get the classname from 'classname.method()'
    _,_,method,lineno = find(line,'", ([^%(]+)%(%), line=(%d+)')    
    if _  then
        -- we get file from the classname - everything up to '.'
        local klass = filename(method)
        if not klass then return nil end
        file = klass..'.java'
        return file,lineno
    end
end

function Jdb:detect_program_end(line)
	return find(line,'^The application exited')
end

function Jdb:detect_program_crash(line)
	return find(line,'^Uncaught exception. Entering post mortem debugging')
end

register_debugger('jdb','java',Jdb)
