-- GDB-style interface to clidebug
scite_require 'gdb.lua'
local find = string.find
local match = string.match
local push = table.insert
local pop = table.remove
local esc = string.char(26)
local gprefix = esc..esc
--local ferr = io.stderr

local GTK = scite_GetProp('PLAT_GTK')

-- the convention with cli debug is that all Windows filenames are lowercase!
local function canonical(file)
	if not GTK then file = file:lower() end
	return file
end

local function fpath(file)
	return canonical(fullpath(file))
end

function slashify(s)
	return s:gsub('\\','\\\\')
end

local function file_is_lua (file)
    return extension_of(file) == 'lua'
end

local info_line_success = '^Line %d+ of'
local info_line_error = '^No line number information available'

function info_line_handler(line,dbg)
  local success = line:find(info_line_success)
  if success then -- we can set a break command
    --dbg:queue_command('tbreak *'..dbg.addr)
	spawner_command('tbreak *'..dbg.addr)
    dbg.addresses[dbg.addr] = true     
  end
  -- either way, we want to get out of GDB mode at the earliest opportunity!
  --dbg:queue_command 'continue' 
  spawner_command('continue')
end

LGdb = class(Gdb)

function LGdb.discriminator(target)
	local res = find(target,'^:gdb') == 1
	return res
end

function LGdb:init (root)
    Gdb.init(self,root)
    self.root = root
    self.target_dir = canonical(props['FileDir'])
    self.no_target_ext = false
    -- this is added to the package.path of the Lua program
    print(extman_Path())
    self.clidebug_path = scite_GetProp('clidebug.path',join(extman_Path(),'lua_clidebugger'))
	self.clidebug_debugger = canonical(join(self.clidebug_path,'debugger.lua'))
    
--    self.no_quit_confirm = true
	self.skip_system_extension = ".lua"	
    self.deferred_stack = {}
    
    self.postprocess_command['info line'] = {pattern=info_line_success,
        action=info_line_handler, alt_pat=info_line_error}
    
    self.addresses = {}
    self.mode = 'gdb'
    
    -- GDB likes forward slashes, on both platforms...
    local dbgl_file = join(self.clidebug_path,"dbgl.c"):gsub('\\','/')
    
    -- this is a persistent event handler which monitors every program break,
    -- and keeps track of whether we are in GDB or clidebug. Will raise
    -- the events 'gdb' and 'lua' accordingly.
    self:set_event('break',function(file,line)
        local new_mode
        local lf = file_is_lua(file)
        -- don't respond to any breaks in dbgl.c
        if not lf and file == dbgl_file then
            return true,true
        end
        if self.mode ~= 'lua' and lf then
            new_mode = 'lua'
        end
        if self.mode == 'lua' and not lf then
            new_mode = 'gdb'
        end
        if new_mode then
            self.mode = new_mode
            self:raise_event(new_mode)
        end
        return true
    end)
    
end

function LGdb:check_breakpoint (b)
    return not file_is_lua(b.file)
end

function LGdb:parameter_string ()
    local parms = Gdb.parameter_string(self)
    -- we have to modify the package path and cpath for this process so that
    -- the clidebug and dbgl packages are visible.
    local so = choose(GTK,'?.so;','?.dll;')
	local ppath = "'"..slashify(join(self.clidebug_path,'?.lua;')).."'"
    local cpath = "'"..slashify(join(self.clidebug_path,so)).."'"
    local p = 'package'
    local cmdline
    -- if the target isn't Lua, then we assume it's a program that hosts Lua and that
    --  there's an explicit clidebug initialization somewhere in a user Lua script.
    if self.not_lua then
        cmdline = ''    
    else
        cmdline = ('-e "%s.path=%s..%s.path; %s.cpath=%s..%s.cpath; GDB=true; WIN=%s" -lclidebug %s'):format(
			p,ppath,p,p,cpath,p,choose(GTK,'false','true'),self.lua_target)        
    end
	print('*',cmdline)
	return cmdline..' '..parms
end

function LGdb:command_line(target)
    local gtarget,ltarget = target:match('^:gdb;([^;]+);(.*)')
    self.lua_target = ltarget
	print('+',gtarget,ltarget)
    local idx = gtarget:find('%[h%]$')
    if idx then
        gtarget = gtarget:sub(1,idx-1)
        self.not_lua = true
    end
    --- we are going to embed a clidebug session inside a GDB session, so it's
    --- necessary to explicitly create the clidebug.cmd file. This folows the 
    --- sequence in create_existing_breakpoints() in debugger.lua
    local lua_cmd = join(self.root,'clidebug.cmd')
    local out = io.open(lua_cmd,'w')
	for b in Breakpoints() do
        if file_is_lua(b.file) then
            out:write('break '..canonical(b.file)..':'..b.line..'\n')
        end
	end	
	out:write('rootpath '..self.target_dir..'\n')
    if not self.not_lua then
        out:write('run\n')    
    end
    out:close()    
    return  Gdb.command_line(self,gtarget)
end

-- need to put at least one breakpoint into the system, so that we can drop into
-- gdb mode when necessary.  Under Windows, you definitely do not want a separate
-- console window, since we want to capture the result of running clidebug inside GDB.
function LGdb:special_debugger_setup(out)
    Gdb.special_debugger_setup(self,out)
	if not GTK then
		out:write('set new-console off\n')
	end
	-- a useful command when in C Lua code.
    out:write[[
define lstack
    p debug_lua_stack($arg0)
end
    ]]
    out:write('directory ',self.clidebug_path,'\n')
    -- clidebug will use this break to get us into gdb
    out:write('break dbgl.c:9\n')    
end

function LGdb:set_breakpoint(file,lno)
    local lf = file_is_lua(file)
    -- clidebug works best with absolute paths
    if lf then file = fullpath(file) end
    -- if we are in the wrong mode, then the actual setting of a breakpoint
    -- needs to happen when we next switch to the correct mode.
    if (self.mode == 'lua') ~= lf then
        local function set_break ()
            Gdb.set_breakpoint(self,file,lno)
        end        
        if self.mode == 'lua' then
            spawner_command('debugbreak')
            self:set_event('break',set_break)
            self:queue_command 'continue'
        else
            self:set_event('lua',set_break)
        end
    else
        Gdb.set_breakpoint(self,file,lno)
    end
end

function LGdb:goto_file_line(file,line)	
	ProcessOutput(gprefix..self.target_dir..'/'..file..":"..line..'\n')
end

-- there is some clidebugger hackery going on here. It will put us into its own version of debug.stacktrace,
-- and we need to put the program into frame #3, which is where the wobby originally happened. The usual Lua
-- error message is put out by the 'Message: ' line, which we use to capture the file:line needed to jump to.
-- The jumping is achieved by pushing the correct break pattern back into the input above (there must be
-- a more elegant way of doing this!)
local fmsg,lmsg

function LGdb:find_execution_break(line)
    local _,_,file,lineno = find(line,self.break_line)
    if _ then
        -- has our program thrown a wobbly in Lua?
		if file == self.clidebug_debugger and fmsg then 
			self:frame(3)
			return fmsg,lmsg,true
		else
			return file,lineno
		end
	else
		fmsg,lmsg = match(line,'Message: (%S+):(%d+)')
		if fmsg then return end        
        -- clidebug emits this pattern when Lua is entering a C function
        -- we have to check whether this function has any debug symbols
        -- before trying to step into it.
        local addr = match(line,'//@//%s(.+)')
        if addr then
            self.addr = strip_eol(addr)
            -- at this point, we have entered GDB at debug_break (forced by clidebug)
            local cached = self.addresses[self.addr]
            if cached == nil then
                -- haven't met this function before; check for line info.
                self:set_event('break',function()                    
                    dbg_command('info line','*'..self.addr)
                    -- info_line_handler() above will process the output...
                end)                        
            elseif cached == true then
                --we know this function has line numbers defined
                self:set_event('break',function()
                    self:queue_command('tbreak *'..self.addr)
                    self:queue_command('continue')
                end)
            end
            return
        end
	end
end

register_debugger('luagdb','lua',LGdb)
