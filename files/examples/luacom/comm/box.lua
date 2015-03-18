$debug
-- box.lua

do 
Box = {}

function Box:open(port)
   local obj
   obj = luacom_CreateObject("MSCOMMLib.MSComm.1")
   obj.CommPort = (port or 1)
   obj.Settings = "2400,N,8,1"
   obj.InputLen = 0
   obj.PortOpen = 1
   self.obj = obj
end

function Box:close()
   self.obj.PortOpen = 0
end

function Box:reset()
   self.obj.Output = "6c82c0cc6d"
   return self.obj.Input
end

function Box:id_request()
   self.obj.Output = "6c82c1cc6d"
   return self.obj.Input
end

function Box:read_io()
   self.obj.Output = "6c82d0cc6d"
   return self.obj.Input
end

function Box:read_reg()
   self.obj.Output = "6c82d2cc6d"
   return self.obj.Input
end

function Box:readLowMem()
end

end
