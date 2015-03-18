require 'luanet'
luanet.load_assembly "System"
Console = luanet.import_type "System.Console"
Math = luanet.import_type "System.Math"

Console.WriteLine("sqrt(2) is {0}",Math.Sqrt(2))
