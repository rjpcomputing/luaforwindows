scite_require 'debugger.lua'
local find = string.find
local sub = string.sub
local GTK = scite_GetProp('PLAT_GTK')

-- there are several Windows oddities which we have to work around. The spawner will
-- only do python if the -i flag is supplied.  Because of bad stderr/stdout synchronization,
-- the line break pattern can actually get split up, so we use a win32-specific pattern.
local exec_break_pattern
local flag

if GTK then
	exec_break_pattern = '^> ([^%(]+)%((%d+)%)'
	flag = ''
else
	exec_break_pattern = '(%a:[^%(]+)%((%d+)%)'
	flag = '-i '
end

local where_pattern = '^[>%s] ([^%(]+)%((%d+)%)'

function where_process(s)
    print(s)
end

local p_pattern = '.*'

function p_process(s,dbg)
    if sub(s,1,3) ~= '***' then
        display(dbg.last_arg.." = "..s)
    end
end

-- special actions for commands which require postprocessing
local postprocess_command = {
    where = {pattern=where_pattern,action=where_process},
    p = {pattern=p_pattern, action=p_process, single_pattern=true},
}

Pydb = class(Dbg)

function Pydb:init(root)
	self.prompt = '(PDB)'
    self.no_target_ext = false
	self.cmd_file = '.pdbrc'
    self.no_quit_confirm = true
	self.skip_system_extension = ".py"
	self.check_skip_always = true
    self.xpdb = quote_if_needed(extman_Path()..'/xpdb.py')
	self.silent_command = {}
	self.postprocess_command = postprocess_command
	self.started = false
end

function Pydb:command_line(target)
	return 'python '..flag..self.xpdb..' '..target..' '..self:parameter_string()
end

function Pydb:run_program(out,parms)
end

function Pydb:backtrace(count)
    dbg_command('where')
end

function Pydb:inspect(word)
	dbg_command('p',word)
end

function Dbg:finish()
    dbg_command('return')
end

function Pydb:find_execution_break(line)
    local _,_,file,lineno = find(line,exec_break_pattern)    
    if _ and file ~= '<string>' then -- a little hack necessary....
	-- an attempt to make pydb restart at the first line - why not work? --
--~ 		if not self.started then
--~ 			self.started = true
--~ 			self:continue()
--~ 		end
		return file,lineno
    end
end

function Pydb:detect_program_end(line)
	local res = (find(line,'^The program exited') or
				   find(line,'^The program finished and will not be restarted'))
    return res,true
end

function Pydb:detect_program_crash(line)
	return find(line,'^Uncaught exception. Entering post mortem debugging')
end

register_debugger('pygdb','py',Pydb)
