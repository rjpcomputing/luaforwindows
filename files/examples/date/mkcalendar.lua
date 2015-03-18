--[[---------------------
This script makes an html calendar
Syntax: mkcalendar.lua year1 year2 year3 .. yearn > file
arg:
	year1 .. yearn - the year(s) of the calendar to generate
	file           - the name of the file to write the generated text calendar
--]]---------------------

require"date"

function makemonth(y,m)
	local t = {}
	local d = date(y,m,1)
	t.name = d:fmt("%B")
	t.year = y
	-- get back to the nearest sunday
	d:adddays(-(d:getweekday()-1))
	repeat
		local tt = {}
		table.insert(t,tt)
		repeat -- insert the week days
			table.insert(tt, d:getday())
		until d:adddays(1):getweekday() == 1
	until d:getmonth() ~= m
	return t
end

local htm_foot = '\n</html>'
local htm_head = [[
<style>
	th {background:black; color: silver; vertical-align: middle;}
	td {vertical-align: middle; text-align:center;}
	td.sun {color: red;}
	td.sat {color: blue;}
</style>	
<html>
]]
local htm_yearhead = '\n<table align="left">'
local htm_monhead  = '\n<tr><th colspan = "7">%s, %s</th></tr><tr><td>sun</td><td>mon</td><td>tue</td><td>wed</td><td>thu</td><td>fri</td><td>sat</td></tr>'
local htm_monweek  = '\n<tr><td class="sun">%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td class="sat">%s</td></tr>'
local htm_yearfoot = '\n</table>'
function makecalendar(y, iox)
	iox:write(htm_yearhead)	
	for i = 1, 12 do
		local tm = makemonth(y, i)
		iox:write(string.format(htm_monhead, tm.name, tm.year))
		for k, v in ipairs(tm) do
			iox:write(string.format(htm_monweek, v[1], v[2], v[3], v[4], v[5], v[6], v[7]))
		end
	end
	iox:write(htm_yearfoot)
			
end

io.stdout:write(htm_head)

for k, v in ipairs(arg) do
	local y = tonumber(v)
	if y then makecalendar(y, io.stdout) end
end

io.stdout:write(htm_foot)


