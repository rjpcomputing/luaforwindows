-- extlib.lua
-- a useful set of SciTE Lua functions
scite_require 'class.lua'
local sub = string.sub
local append = table.insert
local find = string.find

local colours = {red = "#FF0000", blue = '#0000FF', green = '#00FF00',pink ="#FFAAAA" ,
					black = '#000000', lightblue = '#AAAAFF',lightgreen = '#AAFFAA'}
local indicator_masks = {[0] = INDIC0_MASK, [1] = INDIC1_MASK, [2] = INDIC2_MASK}
WORD_PATTERN = "[a-zA-Z0-9_]"
NOT_WORD_PATTERN = "[^a-zA-Z0-9_]"

local GTK = scite_GetProp('PLAT_GTK')
local dirsep
if GTK then
	dirsep = '/'
else
	dirsep = '\\'
end

function join(path,part1,part2)
	local res = path..dirsep..part1
    if part2 then return res..dirsep..part2 else return res end
end

function fullpath(file)
	return props['FileDir']..dirsep..file
end

function choose(cond,x,y)
	if cond then return x else return y end
end

function split(s,re)
	local i1 = 1
	local sz = #s
	local ls = {}
	while true do
		local i2,i3 = s:find(re,i1)
		if not i2 then
			append(ls,s:sub(i1))
			return ls
		end
		append(ls,s:sub(i1,i2-1))
		i1 = i3+1
		if i1 >= sz then return ls end
	end
end

function split_list(s)
	return split(s,'[%s,]+') 
end

local function at (s,i)
    return s:sub(i,i)
end

--- note: for finding the last occurance of a character, it's actualy
--- easier to do it in an explicit loop rather than use patterns.
--- (These are not time-critcal functions)
local function split_last (s,ch)
    local i = #s
    while i > 0 do
        if at(s,i) == ch then
            return s:sub(i+1),i
        end
        i = i - 1
    end    
end

function basename(s)
    local res = split_last(s,dirsep)
    if res then return res else return s end
end

function path_of (s)
	local basename,idx = split_last(s,dirsep)
	if idx then
		return s:sub(1,idx-1)
	else
		return ''
	end
end

function extension_of (s)
    return split_last(s,'.')
end

function filename(path)
    local fname = basename(path)
    local _,idx = split_last(fname,'.')
    if idx then return fname:sub(1,idx-1) else return fname end
end

function strip_eol(s)
	if at(s,-1) == '\n' then
		if at(s,-2) == '\r' then
			return s:sub(1,-3)
		else
			return s:sub(1,-2)
		end
	else
		return s
	end
end


function rtrim(s)
    return string.gsub(s,'%s*$','')
end

--line information functions --

function current_line()
	return editor:LineFromPosition(editor.CurrentPos)
end

function current_output_line()
	return output:LineFromPosition(output.CurrentPos)
end

function current_pos()
	return editor.CurrentPos
end

-- start position of the given line; defaults to start of current line
function start_line_position(line)
	if not line then line = current_line() end
	return editor.LineEndPosition[line]
end

-- what is the word directly behind the cursor?
-- returns the word and its position.
function word_at_cursor()
	local pos = editor.CurrentPos
	local line_start = start_line_position()
	-- look backwards to find the first non-word character!
	local p1,p2 = editor:findtext(NOT_WORD_PATTERN,SCFIND_REGEXP,pos,line_start)
	if p1 then
		return editor:textrange(p2,pos),p2
	end
end

-- this centers the cursor position
-- easy enough to make it optional!
function center_line(line)
	if not line then line = current_line() end
	local top = editor.FirstVisibleLine
	local middle = top + editor.LinesOnScreen/2
	editor:LineScroll(0,line - middle)
end

--general useful routines--

-- returns the character at position p as a string
function char_at(p)
	return string.char(editor.CharAt[p])
end

-- allows you to use standard HTML '#RRGGBB' colours; there are also a few predefined colours available.
function colour_parse(str)
	if sub(str,1,1) ~= '#' then
		str = colours[str]
	end
	return tonumber(sub(str,6,7)..sub(str,4,5)..sub(str,2,4),16)
end

function expand_string(subst)
	return string.gsub(subst,'%$%(([%w_]+)%)',function(arg)
		  local repl = props[arg]
		  return repl
	end)
end

-- indicators --
-- INDIC_PLAIN   Underlined with a single, straight line.
-- INDIC_SQUIGGLE  	A squiggly underline.
-- INDIC_TT  A line of small T shapes.
-- INDIC_DIAGONAL  	Diagonal hatching.
-- INDIC_STRIKE  	Strike out.
-- INDIC_HIDDEN	An indicator with no visual effect.
-- INDIC_BOX 	A rectangle around the text.

local function indicator_mask(ind)
	return indicator_masks[ind]
end

-- this is the default situation: first 5 bits are for lexical styling
local style_mask = 31

-- get the lexical style at position p, without indicator bits!
function style_at(p)
	return math.mod(editor.StyleAt[p],32)
end

-- define a given indicator's type and foreground colour
Indicator = class(function(self,which,typ,colour)
	editor.IndicStyle[which] = typ
	if colour then
		editor.IndicFore[which] = colour_parse(colour)
	end
	self.ind = which
end)

-- set the given indicator ind between pos and endp inclusive
-- (the val arg is only used by indicator_clear)
function Indicator:set(pos,endp,val)
    local es = editor.EndStyled
	local mask = indicator_mask(self.ind)
	if not val then
		val = mask
	end
    editor:StartStyling(pos,mask)
    editor:SetStyling(endp-pos,val)
    editor:StartStyling(es,style_mask)
end

-- clear an indicator ind between pos and endp
function Indicator:clear(ind,pos,endp)
	self:set(pos,endp,0)
end

-- find the next position which has indicator ind
-- (won't handle overlapping indicators!)
function Indicator:find(pos)
	if not pos then pos = editor.CurrentPos end
	local endp = editor.Length
	local mask = indicator_mask(self.ind)
	while pos ~= endp do
		local style = editor.StyleAt[pos]
		if style > style_mask then -- there are indicators!
			-- but is the particular bit set?
			local diff = style - mask
			if diff >= 0 and diff < mask then
				return pos
			end
		end
		pos = pos + 1
	end
end

-- markers --

Marker = class(function(self,idx,line,file)
	buffer = scite_CurrentFile()
	if not file then file = buffer end
	self.idx = idx
	self.file = file
	self.line = line
	if file == buffer then
		self:create()
	else
		self.state = 'waiting'
	end
end)

function Marker:create()
	self.handle = editor:MarkerAdd(self.line-1,self.idx)
	if self.handle == -1 then
		self.state = 'dud'
		if self.type then self:cannot_create(self.file,self.line) end
	else
		self.state = 'created'
	end
end

function Marker:delete()
	if self.file ~= scite_CurrentFile() then -- not the correct buffer!
		self.state = 'expired'
	else
		editor:MarkerDelete(self.line-1,self.idx)
		if self.type then self.type:remove(self) end
	end
end

function Marker:goto(centre)
	editor:GotoLine(self.line-1)
	if centre then center_line() end
end

function Marker:update_line()
	self.line = editor:MarkerLineFromHandle(self.handle)+1
end

MarkerType = class(function(self,idx,typ,fore,back)
	if typ then editor:MarkerDefine(idx,typ) end
	if fore then editor:MarkerSetFore(idx,colour_parse(fore)) end
	if back then editor:MarkerSetBack(idx,colour_parse(back)) end
	self.idx = idx
	self.markers = create_list()
	-- there may be 'expired' markers which need to finally die!
	scite_OnSwitchFile(function(f)
		local ls = create_list()
		for m in self:for_file() do
			if m.state == 'expired' or m.state == 'dud' then
				ls:append(m)
			end
			if m.state == 'waiting' then
				m:create()
			end
		end
		for m in ls:iter() do
			m:delete()
		end
	end)
	-- when a file is saved, we update any markers associated with it.
	scite_OnSave(function(f)
		local changed = false
		for m in self:for_file() do
			local lline = m.line
			m:update_line()
			changed = changed or lline ~= m.line
		end
		if changed then
			self:has_changed('moved')
		end
	end)		
end)

function MarkerType:has_changed(how)
	if self.on_changed then
		self:on_changed(how)
	end
end

function MarkerType:cannot_create(file,line)
	print('error:',file,line)
end

function MarkerType:create(line,file)
	local m = Marker(self.idx,line,file)
	self.markers:append(m)
	m.type = self
	self:has_changed('create')
	return m
end

function MarkerType:remove(marker)
	if self.markers:remove(marker) then
		self:has_changed('remove')
	end
end

-- return an iterator for all markers defined in this file
-- (see PiL, 7.1)
function MarkerType:for_file(fname)
	if not fname then fname = scite_CurrentFile() end
	local i = 0
    local n = table.getn(self.markers)
	local t = self.markers
--~ 	print(n,t)
    return function ()
               i = i + 1
               while i <= n do
--~ 					print (i,t[i].line)
					if t[i].file == fname then
						return t[i]
					else
						i = i + 1
					end
				end
             end
end

function MarkerType:iter()
	return self.markers:iter()
end

function MarkerType:dump()
	for m in self:iter() do
		print(m.line,m.file)
	end
end

Bookmark = MarkerType(1)

g = {} -- for globals that don't go away ;)

-- get the next line following the marker idx
-- from the specified line (optional)
function MarkerType:next(line)
	if not line then line = current_line() end
	local mask = math.pow(2,self.idx)
	return editor:MarkerNext(line,mask)+1
end

------ Marker management -------
local active_cursor_idx = 5
local signalled_cursor_idx = 6
local breakpoint_idx = 7
local active_cursor = nil
local signalled_cursor = nil
local breakpoint = nil
local last_marker = nil
local initialized = false

local function init_breakpoints()
	if not initialized then
		active_cursor = MarkerType(active_cursor_idx,SC_MARK_BACKGROUND,nil,props['stdcolor.active'])
		signalled_cursor = MarkerType(signalled_cursor_idx,SC_MARK_BACKGROUND,nil,props['stdcolor.error'])
		breakpoint = MarkerType(breakpoint_idx,SC_MARK_ARROW,nil,'red')
		initialized = true
	end
end

function Breakpoints()
	init_breakpoints()
	return breakpoint:iter()
end

function RemoveLastMarker(do_remove)
	if last_marker then
		last_marker:delete()
	end
	if do_remove then
		last_marker = nil
	end
end

function OpenAtPos(fname,lineno,how)
	init_breakpoints()
	RemoveLastMarker(false)
	if not last_marker or (last_marker and fname ~= last_marker.file) then
		scite.Open(fname)
	end
	if how == 'active' then
		last_marker = active_cursor:create(lineno)
	elseif how == 'error' then
		last_marker = signalled_cursor:create(lineno)
	else
		last_marker = nil
	end
	if last_marker then
		last_marker:goto()
	else
		editor:GotoLine(lineno-1)
	end
end

function SetBreakMarker(line)
	init_breakpoints()
	return breakpoint:create(line)
end
