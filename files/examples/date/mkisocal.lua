--[[---------------------
This script makes an iso year-week-day calendar
Syntax: mkisocal.lua year1 year2 year3 .. yearn > file
arg:
	year1 .. yearn - the year(s) of the calendar to generate
	file           - the name of the file to write the generated text calendar
--]]---------------------

require"date"

local htm_foot = [[</body></html>]]
local htm_head = [[<html><head><style>body{color:#000000;background-color:#FFFFFF;font-family:sans-serif;}th{background:#000000;color:#CCCCCC;vertical-align:middle;}td{vertical-align:top;text-align:center;font-weight:bold;}.s{color:#999999;font-size:60%;}</style></head><body>]]
local htm_yearhead = [[<table align="center" width="100%" border="1"><tr><th>Year</th><th>Week</th><th>Mon</th><th>Tue</th><th>Wed</th><th>Thu</th><th>Fri</th><th>Sat</th><th>Sun</th></tr>]]
local htm_yearfoot = [[</table>]]
function makecalendar(year, iow)
	local d = date():setisoyear(year,1,1)
	iow(htm_yearhead)
	iow("<!--".. d .. "-->\n")	
	while d:getisoyear() == year do
		iow(d:fmt("<tr><td>%G</td><td>%V<br/><small class='s'>%Y-%j</small></td>"))
		repeat	iow(d:fmt("<td>%u<br/><small class='s'>%b %d %Y</small></td>"))
		until	d:adddays(1):getisoweekday() == 1
		iow("</tr>\n")
	end
	iow(htm_yearfoot)
			
end


local out = io.write

out(htm_head)

for k, v in ipairs(arg) do
	local d = tonumber(v);
	if d then makecalendar(d, out) end
end

out(htm_foot)


