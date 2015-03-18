--[[
  Some Time Trails for the JSON4Lua package
]]--

require('json')
local os = require('os')
local table = require('table')
local string = require("string")

local skipDecode = (...) == '--skipDecode'
local count = tonumber(select(2, ...) or 500) or 500
local strDup = tonumber(select(3, ...) or 1) or 1
local t1 = os.clock()
local jstr
local v
for i=1,count do
  local t = {}
  for j=1,500 do
    t[#t + 1] = j
  end
  for j=1,500 do
    t[#t + 1] = string.rep("VALUE", strDup)
  end
  jstr = json.encode(t)
  if not skipDecode then v = json.decode(jstr) end
  --print(json.encode(t))
end

for i = 1,count do
  local t = {}
  for j=1,500 do
    local m= j % 4
    local idx = string.rep('a'..j, strDup)
    if (m==0) then
      t[idx] = true
    elseif m==1 then 
      t[idx] = json.util.null
    elseif m==2 then
      t[idx] = j
    else
      t[idx] = string.char(j % 0xFF)
    end
  end
  jstr = json.encode(t)
  if not skipDecode then v = json.decode(jstr) end
end

print (jstr)
--print(type(t1))
local t2 = os.clock()

print ("Elapsed time=" .. os.difftime(t2,t1) .. "s")
