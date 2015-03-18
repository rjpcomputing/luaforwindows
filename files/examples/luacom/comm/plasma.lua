-- plasma.lua

require "luacom"

do 

local in1 = {
   pack = function (data)
      local i = 1
      local sum = 0
      local buffer = ""
      while data[i] do
         local v = data[i]
         if type(v) == "string" then
            v = tonumber(v,16)
         end
         sum = sum + v
         buffer = buffer .. strchar(v)
         i = i + 1
      end
      local aux = mod(sum,256)
      buffer = buffer .. strchar(aux)
      return buffer
   end,

   byte2str = function(buf)
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
   end,
}


Plasma = {}

function Plasma:write(cmd1,cmd2,data)
   if not data then
      data = {}
   end
   tinsert(data,1,getn(data))
   tinsert(data,1,cmd2)
   tinsert(data,1,"60")
   tinsert(data,1,"80")
   tinsert(data,1,cmd1)
   local msg = in1.pack(data)
   print(in1.byte2str(msg))
   print(strlen(msg))
   if self.obj and self.obj.PortOpen ~= 0 then
      print("Writing")
      self.obj.Output = msg
      print(self.obj.CommEvent)
   end
end

function Plasma:read(n,dt)
   if self.obj and self.obj.PortOpen ~= 0 then
      local data = ""
      local t0 = clock()
      dt = dt or 5
      while (strlen(data) < n) and (clock() - t0 < dt) do
         data = data .. self.obj.Input
      end
      print(clock()- t0)
      print(self.obj.CommEvent)
      return data
   else
      print "Read Error: Comm port is not open"
   end
end

function Plasma:open(port)
   local obj
   obj = luacom.CreateObject("MSCOMMLib.MSComm.1")
   obj.CommPort = (port or 1)
   obj.Settings = "9600,O,8,1"
   obj.InputLen = 0
   obj.InputMode = 1
   obj.PortOpen = 1
   self.obj = obj
end

function Plasma:close()
   self.obj.PortOpen = 0
end

function Plasma:on()
   self:write("9f","4e")
   print(in1.byte2str(self:read(6,15)))
end

function Plasma:off()
   self:write("9f","4f")
   print(in1.byte2str(self:read(6,15)))
end

function acox()
   local msg = in1.pack({98,121,101}) -- bye
   print(msg)
   print(in1.byte2str(msg))
   if Plasma.obj and Plasma.obj.PortOpen ~= 0 then
      print("Writing")
      Plasma.obj.Output = msg
      print(Plasma.obj.CommEvent)
   end
end

end
