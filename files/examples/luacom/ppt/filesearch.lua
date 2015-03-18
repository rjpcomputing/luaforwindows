-- filesearch.lua

   exe = create_process{cmd="c:\\Program Files\\Microsoft Office\\Office\\POWERPNT.exe /AUTOMATION"}

   sleep(3)  
   ppt = luacom_GetObject("Powerpoint.Application")
   fs = ppt.FileSearch
   fs.LookIn = "C:\\users\\rcerq"
   fs.FileName = "*.ppt"
   fs.FileType = 5
   fs.SearchSubFolders = 1
   n = fs:Execute()
   print("Number of files: " .. n)
   files = fs.FoundFiles
   i = 1
   while i <= n do
      print(files.Item(i))
      i = i + 1
   end

