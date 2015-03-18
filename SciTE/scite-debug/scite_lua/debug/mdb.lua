if not scite_GetProp('PLAT_GTK') then return end

scite_require 'debugger.lua'
local find = string.find
local sub = string.sub

local  bt_pattern = '^[>%s] ([^%(]+)%((%d+)%)'

function bt_process(s)
    print(s)
end

local p_pattern = '.*'

function print_process(s,dbg)
    if not find(s,'^ERROR:') then
        display(dbg.last_arg.." = "..s)
    end
end

-- special actions for commands which require postprocessing
local postprocess_command = {
--    backtrace = {pattern=bt_pattern,action=bt_process},
    p = {pattern=p_pattern, action=print_process, single_pattern=true},
}

Mdb = class(Dbg)

function Mdb:init(root)
	self.prompt = '(mdb)'
    -- this means that the prompt doesn't have a line feed and will be only pulled
    -- in after the next comand
    self.trailing_prompt = true
    self.no_target_ext = true
	self.cmd_file = root..'/mdb.cmd'
    self.no_target_ext = 'exe'
    -- two patterns we use to extract break position; regular
    -- execution break and moving to a specified frame
    self.file_line_pattern = ' at (/[^:]+):(%d+)' 
    self.break1 = '^Thread @%d+ .*'..self.file_line_pattern
    self.break2 = '^#%d+: .*'..self.file_line_pattern
	self.silent_command = {}
	self.postprocess_command = postprocess_command
    self.launched = false
end

function Mdb:find_execution_break(line)
    local _,file,lineno
    -- regular execution break pattern
    _,_,file,lineno = find(line,self.break1)
    if _ then
        -- this hack makes us keep going until we get the actual exception
        if  find(line,'^Thread @%d+ received signal 11 at ') then
            spawner_command('continue')
        else
            return file,lineno
        end
    end
    -- pattern for recognizing frame change line
    _,_,file,lineno = find(line,self.break2)
    if dbg_last_command() == 'backtrace' then return nil end
    if _ then return file,lineno end    
end

function Mdb:command_line(target)
--~ 	return 'mdb -script '..self.cmd_file..' -f '..target
    return 'mdb -f '..target
end

-- these are almost but not the same as gdb; mdb just has to be different.
function Mdb:backtrace(count)
    dbg_command('backtrace','-max '..count)
end

function Dbg:frame(f)
	dbg_command('frame','-frame '..f)
end

function Mdb:detect_program_end(line)
    -- an opportunity to check if the debugger is launched and ready!
    -- we do this because mdb won't allow a command file on the 
    -- command line.
    if not self.launched and find(line,'^Mono Debugger') then
        self.launched = true
        local cf = io.open(self.cmd_file,'r')
        for line in cf:lines() do
            spawner_command(line)
        end
        cf:close()
    end
    -- this is better than 'Process..ended'
	local res = find(line,'Target exited%.') or find(line,'(mdb) Target exited%.')
    return res,false    
end

function Mdb:detect_program_crash(line)
--~ 	return find(line,'^Thread @%d+ received signal %d+ at')
    return find(line,'^Unhandled Exception: ')
end

register_debugger('mdb',{'cs','exe'},Mdb)
