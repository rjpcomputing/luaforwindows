require "CLRPackage"
import "System.Windows.Forms"
import "System.Drawing"
local Directory = luanet.import_type("System.IO.Directory")
local Path = luanet.import_type("System.IO.Path")
local File = luanet.import_type("System.IO.File")
local append = table.insert
local ferr = io.stderr -- for debugging

----------- some generally useful functions -----------------
--- Can be used to set multiple properties of an object, by supplying a table.
-- e.g. set(button,{Text="Click Me",Dock = DockStyle.Fill})
function set (obj,props)
    for k,v in pairs(props) do
		if type(k) == 'string' then
			obj[k] = v
		end
	end
end

--- works like AddRange, except it takes a table of controls
-- e.g add_controls(form,{button1,button2})
function add_controls (ctrl,ctrls)
    for k,v in pairs(ctrls) do
	    ctrl.Controls:Add(v)
	end
end

function ShowMessageBox (caption,icon)
	icon = icon or MessageBoxIcon.Information
    MessageBox.Show(caption,arg[0],MessageBoxButtons.OK,icon)
end

function ShowError (caption)
    ShowMessageBox(caption,MessageBoxIcon.Error)
end

---------- Utility function for creating classes -------------
--- Does single-inheritance and _delegation_
function class(base)
	local c = {}     -- a new class instance, which is the metatable for all objects of this type
	local mt = {}   -- a metatable for the class instance
	local userdata_base
	if base == nil then
	--nada
	elseif type(base) == 'table' then
		-- our new class is a shallow copy of the base class!
		for i,v in pairs(base) do
			c[i] = v
		end
		c._base = base
		-- inherit the 'not found' handler, if present
		if c._handler then mt.__index = c._handler end
	end
	-- the class will be the metatable for all its objects,
	-- and they will look up their methods in it.
	c.__index = c

	-- expose a ctor which can be called by <classname>(<args>)
	mt.__call = function(class_tbl,...)
		local obj= {}
		setmetatable(obj,c)
		-- nice alias for the base class ctor (which you have to call explicitly if you have a ctor)
		if base then c.super = base._init end
		if c._init then
			c._init(obj,...)
		else
			-- make sure that any stuff from the base class is initialized!
			if base and base._init then
				base._init(obj,...)
			end
		end
		return obj
	end

	-- Call Class.catch to set a handler for methods/properties not found in the class!
	c.catch = function(handler)
		c._handler = handler
		mt.__index = handler
	end
	c._init = ctor
	c.is_a = function(self,klass)
		local m = getmetatable(self)
		if not m then return false end --*can't be an object!
		while m do
			if m == klass then return true end
			m = rawget(m,'_base')
		end
		return false
	end
	c.class_of = function(obj)
		return c.is_a(obj,c)
	end
	-- any object can have a specified delegate which is called with unrecognized methods
	-- if _handler exists and obj[key] is nil, then pass onto handler!
	c.delegate = function(self,obj)
        local me = self
		mt.__index = function(tbl,key)
            -- handling fields!
            local getter = rawget(c,"Get_"..key)
            if getter then return getter(me) end
            getter = rawget(me,"_"..key)
            if getter then return getter end
			local method = obj[key]
			if method then
				-- it exists in the delegate! First check if it's callable
				if type(method) == 'function' or getmetatable(method).__call then
					return function(self,...)
						return method(obj,...)
					end
				else -- otherwise, just return
					return method
				end
			elseif self._handler then
				return self._handler(tbl,key)
			end
		end
		c.__newindex = function(self,key,val)
            local setter = rawget(c,"Set_"..key)
            if setter then
                setter(self,val)
            else
                obj[key] = val
            end
		end
	end
	setmetatable(c,mt)
	return c
end

----------- Creating Menus -----------------------------

local ShortcutType = Shortcut.F1:GetType()

local function parse_shortcut (s)
    local res
    if pcall(function()  -- we have to catch the exception!
        res = Enum.Parse(ShortcutType,s,false)
    end) then return res end
end

local function add_menu_items (item,tbl)
    for i = 1,#tbl,2 do
        item.MenuItems:Add(create_menu_item(tbl[i],tbl[i+1]))
    end
end

function create_menu_item (label,action)
    local item = MenuItem()
    local shortcut = label:match('%((%w+)%)')
    if shortcut then
        local shortcut = parse_shortcut(shortcut)
        if shortcut then item.Shortcut = shortcut end
        label = label:match('(.+)%(')
    end
    item.Text = label
    if type(action) == 'function' then
        item.Click:Add(action)
    else
        add_menu_items(item,action)
    end
    return item
end

function main_menu (tbl)
    local mm = MainMenu()
    add_menu_items(mm,tbl)
    return mm
end

function popup_menu (tbl)
    local mm = ContextMenu()
    add_menu_items(mm,tbl)
    return mm
end

-- a useful function for creating menu callbacks to methods of a given object.
function method (obj,fun)
    return function()
		fun(obj)
	end
end

local function populate_control (form,tbl)
	set(form,tbl)
	if #tbl > 0 then -- has an array part, containing controls
		if #tbl == 1 then
			table.insert(tbl,1,"Fill")
		end
		local i = 1
		while i <= #tbl do
			local c = tbl[i]
			local dock
			if type(c) == 'string' then
				dock = c
				c = tbl[i+1]
				i = i + 1
				c.Dock = DockStyle[dock]
			end
			form.Controls:Add(c)
			i = i + 1
		end
	end
    return form
end

function LuaForm (tbl)
	return populate_control(Form(),tbl)
end

function LuaPanel (tbl)
	return populate_control(Panel(),tbl)
end


---------------- Stream Layout --------------
StreamLayout = class()

function StreamLayout:_init(panel)
    self.xsep = 10
	self.X = self.xsep
	self.Y = self.xsep
	self.panel = panel
	self.newline = true
	self.maxX = 0
	self.maxHeight = 0
	self.labels = {}
	self.panel:SuspendLayout()
end

function StreamLayout:Add(c,like)
    if like then self.X = like.Left end
	c.Location = Point(self.X,self.Y)
	self.panel.Controls:Add(c)
	self.X = self.X + c.Width + self.xsep
	self.maxX = math.max(self.maxX,self.X)
	self.maxHeight = math.max(self.maxHeight,c.Height)
	if self.newline then
		self.firstC = c
		self.newline = false
		self.maxHeight = 0
	end
end

function StreamLayout:AddRow(lbl,...)
	local row = {...}
    if lbl then
		local label = Label()
		label.AutoSize = true
		label.Text = lbl
		row.label = label
		append(self.labels,row)
		self:Add(label)
	end
	for i,c in ipairs(row) do
		self:Add(c)
	end
	self:NextRow()
end

function StreamLayout:Height()
	return self.Y + self.maxHeight + self.xsep
end

function StreamLayout:Width()
    return self.maxX
end

function StreamLayout:NextRow()
    self.Y = self:Height()
	self.X = self.xsep
	self.newline = true
end

function StreamLayout:Finish ()
    local width = 0
	for i,row in ipairs(self.labels) do
		width = math.max(width,row.label.Width)
	end
	if width > 0 then -- i.e there is an explicit row of labels
		for i,row in ipairs(self.labels) do
			local lbl = row.label
			for j,c in ipairs(row) do
				c.Left = c.Left + (width - lbl.Width)
				self.maxX = math.max(self.maxX,c.Left+c.Width+self.xsep)
			end
		end
	end
	self.panel:ResumeLayout(false)
end

LayoutForm = class()

function LayoutForm:_init ()
	self.form = Form()
	self.layout = StreamLayout(self.form)
	self.hasButtons = false
	self.ok = false
	self.cancel = false
	self.finishedLayout = false
	-- this method can only be called once we've set up our own fields!
	self:delegate(self.form)
	self.FormBorderStyle = FormBorderStyle.FixedDialog
	self.MaximizeBox = false
	self.MinimizeBox = false
end

function LayoutForm:AddControl(c)
    self.layout:Add(c)
end

function LayoutForm:AddControlRow(lbl,...)
    self.layout:AddRow(lbl,...)
end

function LayoutForm:AddTextBoxRow(lbl)
	local textBox = TextBox()
	self:AddControlRow(lbl,textBox)
	return textBox
end

function LayoutForm:Btn (title,res)
    local b = Button()
	b.Text = title
	if res == DialogResult.OK then
		self.AcceptButton = b
	elseif res == DialogResult.Cancel then
		self.CancelButton = b
	end
	self.layout:Add(b)
	self.hasButtons = true
	return b
end

function LayoutForm:OkBtn (title)
    return self:Btn(title,DialogResult.OK)
end

function LayoutForm:CancelBtn (title)
    return self:Btn(title,DialogResult.Cancel)
end

function LayoutForm:NextRow()
    self.layout:NextRow()
end

function LayoutForm:OkCancel ()
	if not self.layout.newline then self:NextRow() end
	self.ok = self:OkBtn "OK"
	self.cancel = self:CancelBtn "Cancel"
end

function LayoutForm:OnOK()
	return true
end

function LayoutForm:CenterControls (...)
    local w = 0
	local ctrls = {...}
	for _,c in ipairs(ctrls) do
	    w = w + c.Width
	end
	local diff = (self.layout:Width() - w)/(#ctrls + 1)
	local xx = diff
	for _,c in ipairs(ctrls) do
	    c.Left = xx
		xx = xx + c.Width + diff
	end
end

function LayoutForm:FinishLayout()
    if not self.hasButtons then
		self:OkCancel()
		self:CenterControls(self.ok,self.cancel)
		self.ok.Click:Add(function()
			if self:OnOK() then
				self.DialogResult = DialogResult.OK
			else
				self.DialogResult = DialogResult.None
			end
		end)
	end
	local layout = self.layout
	layout:Finish()
	self.ClientSize = Size(layout:Width(), layout:Height())
	self.finishedLayout = true
end

function LayoutForm:ShowDialogOK ()
    if not self.finishedLayout then
		self:FinishLayout()
	end
	return self:ShowDialog() == DialogResult.OK
end

------------------- Converters ------------------------------
-- These classes convert values between controls and Lua values, and provide basic verification,
-- like ensuring that a string is a valid number, for instance.
-- They provide an appropriate control for editing the particular value.
Converter = class()

function Converter:Control ()
    self.box = TextBox()
	return self.box
end

function Converter:Read (c)
    return c.Text
end

function Converter:Write (c,text)
    c.Text = text
end

NumberConverter = class(Converter)

function NumberConverter:Read (c)
	local txt = c.Text
    local value = tonumber(txt)
	if not value then return nil, "Cannot convert '"..txt.."' to a number" end
	return value
end

BoolConverter = class(Converter)

function BoolConverter:Control ()
    return CheckBox()
end

function BoolConverter:Read (c)
    return c.Checked
end

function BoolConverter:Write (c,val)
    c.Checked = val
end

ListConverter = class(Converter)

function ListConverter:_init (list)
    self.list = list
end

function ListConverter:Control ()
	local c = ComboBox()
	if not self.list.Editable then
		c.DropDownStyle = ComboBoxStyle.DropDownList
	end
	for i,item in ipairs(self.list) do
		c.Items:Add(item)
	end
	return c
end

function ListConverter:Read (c)
    local val = c.SelectedItem
	if not val then val = c.Text end
	return val
end

function ListConverter:Write (c,val)
    c.SelectedItem = val
end

FileConverter = class(Converter)

function FileConverter:_init (reading,mask)
	-- the filter is in a simplified form like 'Lua Files (*.lua)|C# Files (*.cs)"
	-- this will expand it into the required form.
    self.filter = mask:gsub("%((.-)%)",function(pat)
		return "("..pat..")|"..pat
	end)
	self.reading = reading
end

-- ExtraControl is an optional method which gives a converter the opportunity of adding another
-- control to the row after the primary control. In this case, we create a file browser button.
function FileConverter:ExtraControl ()
    local btn = Button()
	local box = self.box
	btn.Width = 30
	btn.Text = ".."
	btn.Click:Add(function()
		-- if possible, open the file browser in the same directory as the filename
		local path = self:Read(box)
		if not File.Exists(path) then
			path = Directory.GetCurrentDirectory()
		else
			path = Path.GetDirectoryName(path)
		end
		-- depending on whether we want a file to read or write ("Save as"), pick the file dialog.
		local filebox
		if self.reading then filebox = OpenFileDialog
		else filebox = SaveFileDialog 	end
		local dlg = filebox()
		dlg.Filter = self.filter
		dlg.InitialDirectory = path
		if dlg:ShowDialog() == DialogResult.OK then
			self:Write(box,dlg.FileName)
		end
	end)
	return btn
end

-- Note an important convention: this converter puts the full file path in the text box's Tag field,

function FileConverter:Write (c,val)
    c.Text = Path.GetFileName(val)
	c.Tag = val
end

function FileConverter:Read (c)
    return c.Tag
end

-- there are then two subclasses, depending if you want to open a file for reading or writing.

FileIn = class(FileConverter)

function FileIn:_init (mask)
    self:super(true,mask)
end

FileOut = class(FileConverter)

function FileOut:_init (mask)
    self:super(false,mask)
end

local converters = {
	number = NumberConverter(),
	string = Converter(),
	boolean = BoolConverter(),
}

function Converter.AddConverter (typename,conv)
    converters[typename] = conv
end

---------------- AutoVarDialog ------------------------------

local function callable (method)
	local mt = getmetatable(method)
	return type(method) == 'function' or (mt and mt.__call)
end

local function simple_list (nxt)
    return type(nxt) == 'table' and #nxt > 0
end

AutoVarDialog = class(LayoutForm)

function AutoVarDialog:_init (tbl)
	self.rows = {}
	self.T = tbl.Object or _G
	self.verify = tbl.Verify
	self.verify_exists = tbl.Verify ~= nil
	--end of local fields; NOW we can initialize the form!
	self.super(self)
	self.Text = tbl.Text or "untitled"
	local i,n = 1,#tbl
    while i <= n do
		local converter,constraint,extra
		local lbl = tbl[i]
		local var = tbl[i+1]
		local value = self.T[var]
		local vtype = type(value)
		-- is there a particular default or constraint set?
		if i+1 < n then
			local nxt = tbl[i+2]
			if type(nxt) ~= 'string' then
				if callable(nxt) then
					constraint = nxt
				elseif simple_list(nxt) then
					-- have been given a list of possible values
					converter = ListConverter(nxt)
				elseif Converter.class_of(nxt) then
					converter = nxt
				else
					ShowError("Unknown converter or verify function: "..nxt)
					return
				end
				i = i + 1
			end
		end
		if not converter then
			-- use a default converter appropriate to this type
			converter = converters[vtype]
			if not converter then
				ShowError("Cannot find a converter for type: "..vtype)
				return
			end
		end
		local c = converter:Control()
	    self:AddControlRow(lbl,c,converter.ExtraControl and converter:ExtraControl())
		converter:Write(c,value)
		append(self.rows,{cntrl=c,converter=converter,var=var, constraint=constraint})
		i = i + 2
	end
end

function AutoVarDialog:OnOK ()
	local T = {}
    for _,t in ipairs(self.rows) do
		local value,err = t.converter:Read(t.cntrl)
		if not err and t.constraint then
			err = t.constraint(value)
		end
		if err then
			ShowError(err)
			t.cntrl:Focus()
			return false
		end
		T[t.var] = value
	end
	 -- a function to verify the fields has been supplied
	if self.verify_exists then
		local err = self.verify(T)
		if err then
			ShowError(err)
			return false
		end
	end
	-- NOW we can finally copy the changed values into the target table!
	for k,v in pairs(T) do
	    self.T[k] = v
	end
    return true
end

function Match (pat,err)
    return function (s)
		--ferr:write(',',s,',',pat,'\n')
		if not s:find(pat) then return err end
	end
end

function Range (x1,x2)
	if not x2 then -- unbound upper range
		return function(x)
			if x < x1 then return "Must be greater than "..x1 end
		end
	elseif not x1 then -- unbound lower range
		return function(x)
			if x > x2 then return "Must be less than "..x2 end
		end
	else
		return function(x)
			if x < x1 or x > x2 then return "Must be in range "..x1.." to "..x2 end
		end
	end
end

NonBlank = Match ('%S+','Must be a non-blank string')
Word = Match('^%w+$','Must be a word')

--- A useful function for prompting a user for a single value.
-- returns a non-nil value if the user clicks on OK or presses <enter>.
function PromptForString (caption,prompt,default)
	local tbl = {val = default or ""}
    local form = AutoVarDialog {Text = caption, Object = tbl;
		prompt,"val"
	}
	if form:ShowDialogOK() then
		return tbl.val
	end
end
