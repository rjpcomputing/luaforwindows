-- plasma.lua

do 
dofile "plasma.lua"

Plasma:open()

local byte2str = function(buf)
   if buf and type(buf) == "string" then
      local n = strlen(buf)
      local code = ""
      local i = 1
      while i <= n do
         local hexa = format("%02x",strbyte(buf,i))
         code = code .. hexa
         i = i + 1
      end
      return code
   else
      return ""
   end
end

local all = ""
while 1 do
   local data = Plasma.obj.Input
   all = all .. data
   write(byte2str(data))
   if strfind(all,"bye") then
      Plasma:close()
      return
   end
end

end

