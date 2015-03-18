-- debugging

require("luacom")

luacom.config.abort_on_API_error = true
luacom.config.abort_on_error = false

function GetNetworkInterface ()
print("GetNetworkInterface")
  local item,BpsSent,BpsRec,BpsTot,bpsBandwidth

  BpsSent,BpsRec,BpsTot,bpsBandwidth = 0,0,0,0
  objNetworkRefresher:Refresh ()
  NetworkEnum:Reset ()
  item = NetworkEnum:Next ()
  while item do
    print("item")
    BpsRec = BpsRec + item:BytesReceivedPerSec()
    BpsSent = BpsSent + item:BytesSentPerSec()
    BpsTot = BpsTot + item:BytesTotalPerSec()
    bpsBandwidth = bpsBandwidth + item:CurrentBandwidth()
    item = NetworkEnum:Next ()
   end
  item = nil
  collectgarbage ()
  print("memory: " .. gcinfo())
  return BpsSent,BpsRec,BpsTot,bpsBandwidth or 0,0,0,0
end

function WMIInit ()
print("init")
  objWMIService = luacom.GetObject("winmgmts:{impersonationLevel=Impersonate}!\\\\.\\root\\cimv2")
  objNetworkRefresher = luacom.CreateObject("WbemScripting.SWbemRefresher")
  objNetworkRefresher.AutoReconnect = 1
  refobjNetwork = objNetworkRefresher:AddEnum(objWMIService,"Win32_PerfFormattedData_Tcpip_NetworkInterface")
  objNetworkRefresher:Refresh ()
  NetworkEnum = luacom.GetEnumerator (refobjNetwork.ObjectSet)
end

function WMIClose ()
print("close")
  objWMIService = nil
  objNetworkRefresher = nil
  refobjNetwork = nil
  NetworkEnum = nil
  collectgarbage ()
end

function TestRefresher ()
  local x
  WMIInit ()

  for x = 1, 1 do
    GetNetworkInterface ()
  end

  WMIClose ()
end


function TestCreateDestroy ()
  local x

  WMIInit ()
  WMIClose ()
end




TestCreateDestroy ()
TestRefresher ()

