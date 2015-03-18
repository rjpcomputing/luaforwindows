--[[
Example Lua Object for using Windows Managment and Instrumentation via LuaCom
This object is meant to be used as a class to create other objects.
Contributed by Michael Cumming
--]]

require("luacom")

cWMI = {
  New = function (self)
    o = {}
    setmetatable (o,self)
    self.__index = self
    return o
  end,

  Connect = function (self,computer,user,password)
    computer = computer or "."

    if not user then
      self.oWMIService = luacom.GetObject ("winmgmts:{impersonationLevel=Impersonate}!\\\\" ..computer.. "\\root\\cimv2")
    else
      self.oWMIService = luacom.GetObject ( "winmgmts:\\\\" ..computer.. "\\root\\cimv2",user,password)
    end

    if not self.oWMIService then
      return nil,"Failed to connect to computer "..computer
    end

    --refresher
    self.oRefresher = luacom.CreateObject ("WbemScripting.SWbemRefresher")
    self.oRefresher.AutoReconnect = 1

    -- processor
    self.refobjProcessor = self.oRefresher:AddEnum(self.oWMIService,"Win32_PerfFormattedData_PerfOS_Processor").ObjectSet

    -- memory
    self.refobjMemory = self.oRefresher:AddEnum(self.oWMIService,"Win32_PerfFormattedData_PerfOS_Memory").ObjectSet

    --drive
    self.refobjDisk = self.oRefresher:AddEnum(self.oWMIService,"Win32_PerfFormattedData_PerfDisk_LogicalDisk").ObjectSet
 
    --network
    self.refobjNetwork = self.oRefresher:AddEnum(self.oWMIService,"Win32_PerfFormattedData_Tcpip_NetworkInterface").ObjectSet
    self.oRefresher:Refresh ()

    local cWMISettings = self.oWMIService:ExecQuery ("Select * from Win32_WMISetting")

    for index,item in luacomE.pairs (cWMISettings) do
      self.ver = item:BuildVersion ()
    end

    return self.ver
  end,

  GetProcessorPercentTime = function (self)
    self.oRefresher:Refresh ()
    for index,item in luacomE.pairs (self.refobjProcessor) do
      if item:Name () == "_Total" then
        return item:PercentProcessorTime ()
      end
    end
    return 0
  end,

  GetFreeMemory = function (self)
    local x
    self.oRefresher:Refresh ()
    for index,item in luacomE.pairs (self.refobjMemory) do
      x = item:AvailableMBytes ()
    end
    return x or 0
  end, 

  GetFreeDiskSpace = function (self,drive)
    local x,y
    self.oRefresher:Refresh ()
    for index,item in luacomE.pairs (self.refobjDisk) do
      if item:Name () == drive then
        x = item:FreeMegaBytes ()
        y = item:PercentFreeSpace ()
        return x,y
      end
    end
    return 0,0
  end,

  GetNetworkInterfaceAll = function (self)
    local item,BpsSent,BpsRec,BpsTot,bpsBandwidth
    BpsSent,BpsRec,BpsTot,bpsBandwidth = 0,0,0,0
    for index,item in luacomE.pairs (self.refobjNetwork) do
      BpsRec = BpsRec + item:BytesReceivedPerSec()
      BpsSent = BpsSent + item:BytesSentPerSec()
      BpsTot = BpsTot + item:BytesTotalPerSec()
      bpsBandwidth = bpsBandwidth + item:CurrentBandwidth()
    end
    return BpsSent,BpsRec,BpsTot,bpsBandwidth   
  end,

  CreateProcess = function (self,Process)
    local objProcess = self.oWMIService:Get("Win32_Process")
    return objProcess:Create (Process,nil,nil,nil)
  end,

--[[ returns the following error codes
0 Successful completion
2 Access denied
3 Insufficient privilege
8 Unknown failure
9 Path not found
21 Invalid parameter ]]

  TerminateProcess = function (self,Process)
    local colProcesses = self.oWMIService:ExecQuery("select * from Win32_Process where Name=\""..Process.."\"",nil,48)
    local i
    for index,item in luacomE.pairs (colProcesses) do 
      i = (i or 0) + 1
      item:Terminate ()
    end
    return i
  end,

  ExistProcess = function (self,Process)
    local colProcesses = self.oWMIService:ExecQuery("select * from Win32_Process where Name=\""..Process.."\"",nil,48)
    local i
    for index,item in luacomE.pairs (colProcesses) do
      i = (i or 0) + 1
    end
   return i
  end
}

localWMI = cWMI:New ()

localWMI:Connect (".") -- connect to local machine using current user credentials

print (localWMI.ver)
print (localWMI:GetProcessorPercentTime ())
print (localWMI:GetFreeMemory ())
print (localWMI:GetNetworkInterfaceAll ())
print (localWMI:GetFreeDiskSpace ("C:"))
print (localWMI:CreateProcess ("notepad.exe"))
print (localWMI:ExistProcess ("notepad.exe"))
print (localWMI:TerminateProcess ("notepad.exe"))
