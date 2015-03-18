require 'iuplua'

if not iupx then iupx = {} end

function iupx.menu(templ)
	local items = {}
	for i = 1,#templ,2 do
		local label = templ[i]
		local data = templ[i+1]
		if type(data) == 'function' then
			item = iup.item{title = label}
			item.action = data
		elseif type(data) == 'nil' then
			item = iup.separator{}
		else
			item = iup.submenu {iupx.menu(data); title = label}
		end
		table.insert(items,item)
	end
	return iup.menu(items)
end

function iupx.show_dialog (tbl)
    local dlg = iup.dialog(tbl)
    dlg:show()
    iup.MainLoop()
end

function iupx.GetString (title,prompt,default)
	require "iupluacontrols"
	return iup.GetParam(title, nil,prompt.." %s\n",default or "")
end

function iupx.pplot (tbl)
	-- only load this functionality on demand! ---
	require 'iupxpplot'
	return iupxpplot.pplot(tbl)
end


