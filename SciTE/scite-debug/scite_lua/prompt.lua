--creating an Interactive Lua prompt
------------------------------- Lua prompt -----------------------
scite_require 'switch_buffers.lua'

scite_Command 'Start Interactive Lua|start_lua_prompt'
scite_Command 'Load Lua into Session|load_current_lua_file'

local lua_p
local skipping
local lua_interactive
local SL_prefix='\01SL\02'

function OnExit(s)
	s = tonumber(s)
	if s ~= 0 then
		scite.MenuCommand(IDM_NEXTMSG)
	end
end

local function write_to_lua(line,skip_output)
	skipping = skip_output
    lua_p:write(line..'\n')
end

function eval_lua(line)
    local f,err = loadstring(line,'local')
    if not f then 
		scite_Trace(err)
    else
		pcall(f)
    end
end

function write_output(s)
	if not skipping then
		local i1,i2 = s:find(SL_prefix)
		if i1 == 1 then
			eval_lua(s:sub(i2+1))
		else
			scite_Trace(s)
		end
	else
		skipping = false
	end
end

function edit (f)
    scite.Open(f)
end

-- the cd() command is special, because it is evaluated both in the Lua session _and_ in SciTE.
-- (cmd type 3s are evaluated in both contexts)
function cd (path)
    if path then
		os.chdir(path)
	end
end

local cmds = {
	cd = 3, dir = 1, edit = 2
}

local function check_command (line)
    local cmd,rest = line:match('([%w_]+)(.*)')
	local ctype = cmds[cmd]
	if ctype then
		local arg = rest:match('(%S+)')
		if arg then
			return cmd..'[['..arg..']]', ctype
		else
			return cmd..'()',ctype
		end
	else
		return line,1
	end
end

-- whenever SciTE changes its current directory, make sure that the prompt and SciTE are in sync!
scite_OnDirChange(function(dir)
	if lua_p then
		write_to_lua(('cd(%q)'):format(dir),true)
		cd(dir)
	end
end)

function evaluate_line(line)
	line,ct = check_command (line)
	if line == 'quit' then
		if lua_interactive then
			write_to_lua 'os.exit()'
		else
			write_to_lua 'quit'
		end
        print 'goodbye!'
		scite.MenuCommand(IDM_WRAPOUTPUT)
		lua_p = nil
        return true
	end
	if ct == 2 or ct == 3 then
		eval_lua(line)
		if ct == 2 then scite_Trace '> ' end
	end
	if ct == 1 or ct == 3 then
		write_to_lua(line)
	end
end

function start_lua_prompt()
	if lua_p ~= nil then return end
	local cmd = props['lua.prompt']
	lua_interactive = cmd:find('-i',1,true)
	scite.MenuCommand(IDM_WRAPOUTPUT)
	lua_p = spawner.new(cmd)
	lua_p:set_output('write_output')
	lua_p:run()
	scite_InteractivePromptHandler('>+ ',evaluate_line)
end

function load_current_lua_file()
	if lua_p then
        scite.MenuCommand(IDM_SAVE)
		write_to_lua('print(pcall(dofile,[['..props['FilePath']..']]))',true)
		scite.MenuCommand(IDM_SWITCHPANE)
	end
end

--- a general interactive prompt engine -----

local keymap
local lines
local lines_idx = 1
local line_callback
local prompt
local lastpos = 1


if not GTK then -- see winuser.h
    keymap = {
    [40] = SCK_DOWN,
    [38] = SCK_UP,
    [37] = SCK_LEFT,
    [39] = SCK_RIGHT,
    [36] = SCK_HOME,
    [35] = SCK_END,
    [33] = SCK_PRIOR,
    [34] = SCK_NEXT,
    [46] = SCK_DELETE,
    [45] = SCK_INSERT,
    [0x1B] = SCK_ESCAPE,
    [8] = SCK_BACK,
    [9] = SCK_TAB,
    [13] = SCK_RETURN,
    [0x6B] = SCK_ADD,
    [0x6D] = SCK_SUBTRACT,
    [0x6F] = SCK_DIVIDE,
    [0x5B] = SCK_WIN,
    [0x5C] = SCK_RWIN,
    [18] = SCK_MENU,
    }
else -- see gdk/gdkkeysyms.h
    keymap = {
    [0xFF54] = SCK_DOWN,
    [0xFF52] = SCK_UP,
    [0xFF51] = SCK_LEFT,
    [0xFF53] = SCK_RIGHT,
    [0xFF50] = SCK_HOME,
    [0xFF57] = SCK_END,
    [0xFF55] = SCK_PRIOR,
    [0xFF56] = SCK_NEXT,
    [0xFFFF] = SCK_DELETE,
    [0xFF63] = SCK_INSERT,
    [0xFF1B] = SCK_ESCAPE,
    [0xFF08] = SCK_BACK,
    [0xFF09] = SCK_TAB,
    [0xFF0D] = SCK_RETURN,
    [0xFFAB] = SCK_ADD,
    [0xFFAD] = SCK_SUBTRACT,
    [0xFFAF] = SCK_DIVIDE,
    [0xFFEB] = SCK_WIN,
    [0xFFEC] = SCK_RWIN,
    [0xFF67] = SCK_MENU,
    }
end

function scite_ConvertToSCK (key)
    local res = keymap[key]
    if res then return res else return key end
end

function enable_arrow_keys (yesno)
    if yesno then
        output:AssignCmdKey(SCK_TAB,0,SCI_TAB)
        output:AssignCmdKey(SCK_UP,0,SCI_LINEUP)
        output:AssignCmdKey(SCK_DOWN,0,SCI_LINEDOWN)
    else
        output:AssignCmdKey(SCK_TAB,0,SCI_NULL)
        output:AssignCmdKey(SCK_UP,0,SCI_NULL)
        output:AssignCmdKey(SCK_DOWN,0,SCI_NULL)
    end
end

function scite_ReplaceLine(pane,l,txt)
    pane.TargetStart = lastpos --pane:PositionFromLine(l)
    pane.TargetEnd = pane.LineEndPosition[l]
    pane:ReplaceTarget(txt)
    pane:GotoPos(pane.TargetEnd)
end

local function current_line ()
    return output:LineFromPosition(output.CurrentPos)
end

function replace_current_line (txt)
    local l = current_line()
--~     scite_ReplaceLine(output,l,prompt..txt)
    scite_ReplaceLine(output,l,txt)	
end

local function strip_prompt(line)
--~    local i1,i2 = line:find(prompt)
--~    if i1 == 1 then
--~         line = line:sub(i2+1)
--~     end	
--~     return line
	local l = current_line()-1
	local p = output:PositionFromLine(l)
	local offset = lastpos - p + 1
	return line:sub(offset)
end

function handle_keys (key)
    if editor.Focus then return end
    key = scite_ConvertToSCK(key)
    local delta
    if key == SCK_UP then
        if lines_idx == 1 then return end
        delta = -1
    elseif key == SCK_DOWN then
        if lines_idx == #lines then return end
        delta = 1
    elseif key == SCK_TAB then
        local line = strip_prompt(output:GetCurLine())
        local matches = {}        
        for i,l in ipairs(lines) do 
            if l:find(line,1,true) == 1 then
                table.insert(matches,1,l)
            end
        end
        if #matches == 0 then return end
        if #matches == 1 then
            replace_current_line(matches[1])
            return
        end
        enable_arrow_keys (true)
        scite_UserListShow(matches,1,function(l)
            replace_current_line(l)            
            enable_arrow_keys (false)
        end)
        return
    end
    if delta then
        lines_idx = lines_idx + delta
        local txt = lines[lines_idx]
        if txt then
            replace_current_line(txt)
        end
    end
end    

function scite_Trace (s)
	trace(s)
	lastpos = output.CurrentPos
end

local function line_handler(line)
    line = strip_prompt(line)
    -- prevent immediate duplicates
    if lines[#lines] ~= line then
        table.insert(lines,line)
    end
    lines_idx = #lines + 1    
    if line_callback(line) then
        scite_LeaveInteractivePrompt()
    end
	
end

function  scite_InteractivePromptHandler(the_prompt,fun)
    prompt = the_prompt
    line_callback = fun
    lines_idx = 1
    lines = {}
    enable_arrow_keys(false)
    scite_OnKey(handle_keys)
    scite_OnOutputLine(line_handler)
end

function scite_LeaveInteractivePrompt ()
    scite_OnOutputLine(line_handler,true)
    enable_arrow_keys(true)
	scite_OnKey(handle_keys,'remove')
end

