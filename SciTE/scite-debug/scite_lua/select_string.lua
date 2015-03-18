-- this extends the usual double-click behaviour; any group of chars with the same style 
-- (such as a string or a comment) will be extended. It is called immediately after the
-- default behaviour, which selects words. If a word was selected, then the cursor will
-- be at the end, and we ignore this case.

function expand_same_style()
	if not scite_GetPropBool("scite.double.click.select.string",false) then
		return
	end
   
	local pos = editor.CurrentPos
	local style = editor.StyleAt[pos]
	if style == 0 or not editor.Focus then return end
	local p = pos
	while p > -1 and editor.StyleAt[p] == style do
		p = p - 1
	end
	local pstart = p+1
	if pstart == pos then return end -- we're at the end!
	p = pos
	local sz = editor.Length-1
	while p < sz and editor.StyleAt[p] == style do
		p = p + 1
	end
	editor:SetSel(pstart,p)
end

scite_OnDoubleClick(expand_same_style)
	
