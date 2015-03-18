-- using Alien to find out what the caption title of SciTE is,
-- and iterating over all top-level windows.
-- Ensure that SciTE is running first!
require 'alien'
local user = alien.load 'user32.dll'

-- these are the API calls needed. Note two NB things:
-- (1) functions dealing with text ending with 'A' are for ASCII
-- (2) need to specify abi to get proper __stdcall
user.FindWindowA:types {"string","string",abi="stdcall"}
user.GetWindowTextA:types {"int","string","int",abi="stdcall"}

find  = user.FindWindowA
gettext = user.GetWindowTextA

-- find the handle of the SciTE window using its class name
hwnd = find("SciTEWindow",nil)

-- and grab the text of that window (will be the caption)
-- create a buffer and it will be filled!
buf = alien.buffer(128)
gettext(hwnd,buf,128)
print(buf:tostring())

-- Iterating over all top-level windows.
-- again, note the abi for both EnumWindows and the callback! EnumWindows is
-- expecting an _integer_ back from the callback, where 1 means 'true' means
-- 'continue going'
function each_hwnd (hwnd,p)
    print(hwnd)
    return 1
end

each_hwnd_callback = alien.callback(each_hwnd,{"int","pointer",abi="stdcall"})

user.EnumWindows:types {"callback","pointer",abi="stdcall"}

user.EnumWindows(each_hwnd_callback,nil)


