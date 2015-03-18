require "CLRPackage"
require "ilua"
require "CLRForm"
import "System.Windows.Forms"
import "System.Drawing"
import "System.IO"

import "TextBox.dll"

local ferr = io.stderr --debug
local append = table.insert

-- it appears necessary to force a delayed evaluation, for which we use a timer....
local timer = Timer()
timer.Interval = 10
local callback

timer.Tick:Add(function()
	timer:Stop()
	callback()
end)

local function call_later (fun)
    callback = fun
	timer:Start()
end

local function readfile (file)
    local f = io.open(file,'r')
	if not f then return end
	local res = f:read("*a")
	f:close()
	return res
end

local function writefile (file,s)
    local f = io.open(file,'w')
	if not f then return end
	f:write(s)
	f:close()
	return true
end

function current_line (pane)
    return pane:GetLineFromCharIndex(pane.SelectionStart)
end

-- a useful function for selecting lines in Rich text boxes; if lno is not specified,
-- then use the current line
function select_line (pane,lno)
	if not lno then -- current line
        lno = current_line(pane)
	end
    local istart = 0
    local i = 0
    for line in enum(pane.Lines) do
        local len = #line
        if i == lno then
            pane:Select(istart,len)
            return
        end
        i = i + 1
        istart = istart + len + 1
    end
end

local lines = {}
local list = ListBox()
local no_name = true
local this_dir = Environment.CurrentDirectory
local user_dir = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory)
local session_dir = user_dir..'\\'..'li-session'
--ferr:write('session ',session_dir,'\n')

if Directory.Exists(session_dir) then
    local files = Directory.GetFiles(session_dir,"*.lua")
    for i = 1,files.Length do
        list.Items:Add(Path.GetFileNameWithoutExtension(files[i-1]))
    end
else
    Directory.CreateDirectory(session_dir)
end

local function list_contains (name)
    for i = 1,list.Items.Count do
		if list.Items[i-1] == name then return true end
	end
end

local function add_to_list (name)
    list.Items:Add(name)
    list.SelectedItem = name
    current_name = name
end

local function session_file (name)
	if not name then return end
    return session_dir..'\\'..name..'.lua'
end

local code = ConsoleTextBox() --RichTextBox()
code.Font = Font("Tahoma",10,FontStyle.Bold)
code.WordWrap = false

code:SetHandler(function(key)
    if key == Keys.Tab then
        code.SelectedText = "    "
        return true
    end
    return false
end)

local text = ConsoleTextBox() --RichTextBox()
text.Font = code.Font
text.WordWrap = false

-- please note that you must explicitly return false, since LuaInterface is
-- expecting a boolean return value!
text:SetHandler(function(key)
    if key == Keys.Up then
        get_history(true)
        return true
    elseif key == Keys.Down then
        get_history(false)
        return true
    end
    return false
end)

local function write (s)
    text:AppendText(s)
end

list.SelectedIndexChanged:Add(function()
    local file = session_file(list.SelectedItem)
	if not file or not File.Exists(file) then return end
    local txt = readfile(file)
	if not txt then
		ShowError ("Cannot open '"..file.."'")
		return
	end
    code.Text = txt
end)

local function load_lua_file (file)
    local oldFun = fun
    fun = function(file) end
    local res,err = pcall(dofile,file)
    if not res then -- we have an error!
        ShowError(err)
        print(err)
    end
    fun = oldFun
end

local function load_lua ()
    local dlg = OpenFileDialog()
    dlg.Filter = "Lua (*.lua)|*.lua"
    dlg.InitialDirectory = this_dir
    if dlg:ShowDialog() == DialogResult.OK then
        load_lua_file(dlg.FileName)
    end
end

local function save_session ()
    local dlg = SaveFileDialog()
    dlg.Filter = "Lua (*.lua)|*.lua"
	dlg.InitialDirectory = this_dir
    if dlg:ShowDialog() ~= DialogResult.OK then return end
    local f = io.open(dlg.FileName,"w")
    f:write(table.concat(lines,'\n'))
    f:close()
end

function clear_code ()
    code:Clear()
	no_name = true
end

function delete_list_item ()
    local path = session_file(list.SelectedItem)
    os.remove(path)
    list.Items:Remove(list.SelectedItem)
    clear_code()
end

function save_code ()
	local file
	if code.Lines.Length == 0 then return end
    if not no_name then
		file = list.SelectedItem
	else -- no name has been assigned, after clearing the code pane
        -- try make up an appropriate one!
		local firstline = code.Lines[0]
		local comment = firstline:match('%s*%-%-%s*(.*)')
		if comment then file = comment
		else file = "[current]" end
        no_name = false
	end
    local path = session_file(file)
	writefile(path,code.Text)
    if not list_contains(file) then
        add_to_list(file)
    else
        list.SelectedItem = file
    end
	return path
end

local function save_text ()
    local dlg = SaveFileDialog()
    dlg.Filter = "Text (*.txt)|*.txt"
	dlg.InitialDirectory = this_dir
    if dlg:ShowDialog() ~= DialogResult.OK then return end
    writefile(dlg.FileName,text.Text)
end

local function save_and_go ()
	local file = save_code()
	if not file then return end
    local res,err = pcall(dofile,file)
    --ferr:write(file,'\n')
    if not res then
        local i1,i2,line = err:find(':(%d+):')
        if i1 then
            print(err:sub(i2+1))
            write '\n> '
            code:Focus()
            select_line(code,tonumber(line)-1)
            return
        end
    end
    write '\n> '
    append(lines,'dofile[['..file..']]')
    text:Focus()
end

function fun (fn)
	if not fn then -- prompt for a function name
		fn = PromptForString("Lua Interface Console","Function name","")
		if not fn then	return end
	end
	if list_contains(fn) then
		ShowError("'"..fn.."' already exists. Pick another name")
		return
	end
    no_name = false
    local txt = "function "..fn.."( )\n\nend\n"
    code.Text = txt
    add_to_list(fn)
    code:Focus()
end

---------------------- Main Menu --------------------------------------
local menu = main_menu {
    "File",{
        "Load Lua(CtrlO)",load_lua,
        "Save Session(CtrlS)",save_session,
        "Save As Text",save_text,
        "E&xit(CtrlX)",function() os.exit(0) end,
    },
	"Run",{
		"Save and Go(F5)",save_and_go,
		"Create Function",function() fun() end,
        "Delete Item",delete_list_item,
		"Clear Code Pane",clear_code,
	},
    "History", {
        "Last(AltUpArrow)", function() get_history(true) end,
        "Previous(AltDownArrow)", function() get_history(false) end
    }
}

local function method (obj,fun)
    return function()
		fun(obj)
	end
end

local popup = popup_menu {
	"Copy",method(text,text.Copy),
	"Paste",method(text,text.Paste),
	"Cut",method(text,text.Cut),
}

------------ Managing Command History -----------
local help_idx = 1

function get_history (up)
	call_later(function()
		local delta
		-- awful hack, cancelling out the last up/down arrow movement!
		if up then
			delta = -1
		else
			delta = 1
		end
        key_sent = true
		call_later(function()
			help_idx = help_idx + delta
			local txt = lines[help_idx]
            if not txt then
                help_idx = help_idx - delta
                return
            end
			select_line(text)
			text.SelectedText = '> '..txt
		end)
	end)
end

------------ Special Key Handling ------------------
local lastLine = -1

text.KeyDown:Add(function(sender,args)
	if args.KeyCode == Keys.Enter then
		local lineNo = text:GetLineFromCharIndex(text.SelectionStart)
		if lineNo ~= lastLine then -- for some reason, happens twice!
			local line = text.Lines[lineNo]
			line = line:gsub('^> ','')
			lastLine = lineNo
			call_later(function()
				eval_lua(line)
				append(lines,line)
				help_idx = #lines + 1
				write '> '
			end)
		end
    end
end)

----------------------- Ouput Redirection ---------------------------------
function write_out (expand,...)
	local t = {...}
	local n = #t - 1
	for i = 1,n do
		write(tostring(t[i]))
		if expand then write '\t' end
	end
	write(tostring(t[n+1]))
end

function writer (...)
    write_out(false,...)
end

ilua.set_writer(writer)
function print (...)
    write_out(true,...)
	write '\r\n'
end

-------- Layout Controls ---------------------------------------------
local form = Form()
form.Menu = menu
form.Text = "LuaInterface GUI Prompt"
form.Size = Size(420,420)
form.Closing:Add(function()
    os.exit(0)
end)

local panel = Panel()
panel.Dock = DockStyle.Top

local hsplitter = Splitter()
hsplitter.Dock = DockStyle.Left
hsplitter.MinSize = 70

code.Dock = DockStyle.Fill
code.Height = 70

list.Dock = DockStyle.Left
list.Width = 70

panel.Controls:Add(code)
panel.Controls:Add(hsplitter)
panel.Controls:Add(list)

-- note the particular order!
local splitter = Splitter()
splitter.Dock = DockStyle.Top
splitter.MinSize = 70
splitter.MinExtra = 100
text.Dock = DockStyle.Fill
text.ContextMenu = popup
form.Controls:Add(text)
form.Controls:Add(splitter)
form.Controls:Add(panel)

-- stuff exported to the interactive console
gettype = luanet.import_type
app = {code=code,text=text, list=list, form=form}
function cd (path)
    if not path or #path == 0 then
		print(Directory.GetCurrentDirectory())
	else
		Directory.SetCurrentDirectory(path)
	end
end

write 'ILUA: Lua 5.1.1  Copyright (C) 1994-2007 Lua.org, PUC-Rio\r\n'
write '> '

if arg[1] and File.Exists(arg[1]) then
    load_lua_file(arg[1])
end
form:ShowDialog()


