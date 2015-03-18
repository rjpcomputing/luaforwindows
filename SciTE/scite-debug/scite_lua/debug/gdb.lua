-- A simple gdb interface for SciTE
-- Steve Donovan, 2007-2008
scite_require 'debugger.lua'

local sub = string.sub
local find = string.find
local len = string.len
local gsub = string.gsub

-- this is not only gdb-specific, but depends on looking for patterns
-- which depend on the implementation of std::string, etc.
function simplify_term(s)
	-- std::string
    if find(s,'^{%s*static npos = 4294967295,') then
        local _,_,str = find(s,'(".*")')
        return str
    end
    -- SString
    if find(s,'^{%s*<SContainer> = {%s*s =') then
        local _,_,str = find(s,'(".*"),%s*sSize =')
        return str
    end
	-- add your custom patterns here!
    -- arb structure; process recursively
    if sub(s,1,1) == '{' then
        local arg = sub(s,2,-2)
        return '{'..simplify(arg)..'}'
    else
        return s
    end
end

-- apply simplify_term recursively!
function simplify(str)    
    str = simplify_term(str)
    local res = gsub(str,'%b{}',simplify_term)
    return res
end

local inspect_pattern = '^(%$%d+) = '
local symbol_pattern = '[%w_]+'
local locals_pattern = '^'..symbol_pattern..' = '
local pointer_pattern = '%('..symbol_pattern..' %*%)'
local const_pointer_pattern = '%(const '..symbol_pattern..' %*%)'
local inspect_error_pattern = '^Cannot access memory at address 0x'
local last_arg

local function print_process(s,dbg)    
    local enum,expr = s:match(inspect_pattern..'(.*)')
	local argument = dbg,last_arg
	if not enum and not expr then
		expr = '(cannot evaluate)'
--~ 		last_arg = nil
	end
--~ 	print('+',expr)
	-- if the result was a pointer, then try to evaluate that pointer.
	if (expr:find(pointer_pattern) or expr:find(const_pointer_pattern)) and not expr:find '{' then
		dbg:inspect('*'..enum)
		last_arg = dbg.last_arg..' '..expr
--~ 		print('+last_arg',last_arg)
	else
--~ 		print('-last_arg',last_arg)
		if last_arg then
			dbg.last_arg = last_arg
			last_arg = nil
		end
		display(dbg.last_arg.." = "..simplify(expr))
	end
end

local function locals_process(s)
    local s1,s2 = find(s,locals_pattern)
	-- split this 'var = expr' line and try simplify the expression
    local var = sub(s,s1,s2 - 3)  -- miss out on the ' = '
    local _,_,expr = find(s,locals_pattern..'(.*)')
    display(var.." = "..simplify(expr))
end

local backtrace_pattern = '^#(%d+)'

function backtrace_process(s)
    local s = gsub(s,'0x%w+ in ','',1)
    print(s)
end

local finish_pattern = '^Value returned is %$%d+ ='

local function finish_process(s)
    local s1,s2 = find(s,finish_pattern)
    local expr = sub(s,s2+1)
    display('returned '..simplify(expr))
end

local was_error = false
-- commands where one ignores gdb's response 
local silent_command = {frame = true}
-- special actions for commands which require postprocessing
local postprocess_command = {
    backtrace = {pattern=backtrace_pattern,action=backtrace_process},
    print = {pattern=inspect_pattern, action=print_process, alt_pat=inspect_error_pattern},
    ['info locals'] = {pattern=locals_pattern, action=locals_process},
    display = {pattern=locals_pattern,action=locals_process},
    finish = {pattern=finish_pattern,action=finish_process,once=true}
}

local GTK = scite_GetProp('PLAT_GTK')

Gdb = class(Dbg)

function Gdb:init(root)
	print('locals pattern"'..locals_pattern..'"')
	local esc = string.char(26)	
	self.prompt = '(GDB)'
    self.no_target_ext = ''
	self.cmd_file = root..'/prompt.cmd'
	self.postprocess_command = postprocess_command
	-- commands where one ignores gdb's response
	self.silent_command={frame = true}
	if GTK then
		self.break_line = '^'..esc..esc..'(/[^:]+):(%d+)'
	else
		self.break_line = '^'..esc..esc..'(%a:[^:]+):(%d+)'
	end
	last_arg = nil
end

function Gdb:command_line(target)
	local gdb = scite_GetProp("debug.gdb","gdb")
	return gdb..' --quiet -x '..quote_if_needed(self.cmd_file)..' -f '..target
end

function Gdb:special_debugger_setup(out)
	out:write('set prompt (GDB)\\n\n') -- ensure gdb prompt has linefeed
	out:write('set height 0\n') -- disable gdb paging
	if scite_GetPropBool('debug.breakpoint.pending',GTK) then
		-- unrecognized file:line assumed to be 'pending'
		out:write('set breakpoint pending on\n') 
	end
    local env = scite_GetProp('debug.environment')
    if env then
        for _,e in ipairs(split(env,';')) do
            local var,val = splitv(e,'=')
            out:write(('set env %s %s\n'):format(var,val))
        end
    end
	-- normally gdb will not let you set breakpoints if there's no debug information.
	-- Fortunately, it's not picky about exactly what symbols are available, so
	-- we placate it with a little stub.
    if not self.host_symbols then
		local stub = slashify(join(extman_Path(),choose(GTK,'stubby.so','stubby.dll')))
        out:write('symbol-file ',stub,'\n')
    end
	-- @doc under Windows it's usually better to force GDB to create a new console window
	-- for a command-line application.
	if not GTK then
		out:write('set new-console on\n')
	end
end

function Gdb:detect_program_end(line)
    local no_program = find(line,"No executable specified, use `target exec'%.")
	if no_program then print 'NO PROGRAM' end
	-- detecting normal end of program execution
	local res = find(line,'^Program exited normally%.') or find(line,'^Program exited with code %d+') or no_program
    return res,false
end

function Gdb:detect_program_crash(line)
	return find(line,'^Program received signal ')
end

register_debugger('gdb','*',Gdb)
