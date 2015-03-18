;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; File:			LuaForWindows.iss
; Author:		Ryan Pusztai <rpusztai@gmail.com>
; Date:			05/13/2008
; License:
;	Copyright (C) 2008-2012 Ryan Pusztai.
;
;	Permission is hereby granted, free of charge, to any person obtaining a copy
;	of this software and associated documentation files (the "Software"), to deal
;	in the Software without restriction, including without limitation the rights
;	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;	copies of the Software, and to permit persons to whom the Software is
;	furnished to do so, subject to the following conditions:
;
;	The above copyright notice and this permission notice shall be included in
;	all copies or substantial portions of the Software.
;
;	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
;	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;	THE SOFTWARE.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; -- General Installer configuration
#define MyAppVer "5.1.4.46"
#define MyAppDisplayVer "5.1.4-46"
#define MyAppName "Lua"
#define MyAppDisplayName "Lua for Windows"
#define MyAppPublisher "The Lua for Windows Project and Lua and Tecgraf, PUC-Rio"
#define MyAppURL "http://luaforwindows.googlecode.com"
#define MyAppExeName "lua.exe"
#define AppMinVer "5.1.3.21"

; -- Dependancy handling configuration
;		Comment out the #define DOWNLOAD_FILES if you want to build the
;		dependencies into the installer.
#define DOWNLOAD_FILES
#define vcRedistURL "http://luaforwindows.googlecode.com/files/vcredist_x86.4053.exe"

; -- Pre-Build Step.
;#expr Exec( "create_install_files_pkg.bat", NULL, ".", 1, SW_SHOWMINIMIZED )

[Setup]
AppName={#MyAppName}
AppVerName={#MyAppDisplayName} {#MyAppDisplayVer}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}\5.1
DisableDirPage=false
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=false
AllowNoIcons=true
OutputBaseFilename=LuaForWindows_v{#MyAppDisplayVer}
Compression=lzma/ultra
SolidCompression=true
InternalCompressLevel=ultra
OutputDir=.
ShowLanguageDialog=yes
AppVersion={#MyAppVer}
WizardImageFile=compiler:WizModernImage-IS.bmp
WizardSmallImageFile=compiler:WizModernSmallImage-IS.bmp
VersionInfoVersion={#MyAppVer}
VersionInfoDescription={#MyAppName}
ChangesAssociations=true
ChangesEnvironment=true
LicenseFile=files/LICENSE.txt
MinVersion=0,5.0.2195
PrivilegesRequired=none
UninstallFilesDir={app}\uninstall
UninstallDisplayIcon={app}\lua.exe

[Messages]
BeveledLabel={#MyAppDisplayName} v{#MyAppDisplayVer}

[Tasks]
Name: desktopicon; Description: {cm:CreateDesktopIcon}; GroupDescription: {cm:AdditionalIcons}; Flags: unchecked
Name: blackscheme; Description: Use a black background syntax highlight theme for script editor; GroupDescription: Additional schemes:; Flags: unchecked

[Files]
; -- Main Lua files.
Source: files\bin2c5.1.exe; DestDir: {app}; DestName: bin2c.exe; Flags: ignoreversion
Source: files\LICENSE.txt; DestDir: {app}; Flags: ignoreversion
Source: files\lua5.1.dll; DestDir: {app}; Flags: ignoreversion
Source: files\lua5.1.exe; DestDir: {app}; DestName: lua.exe; Flags: ignoreversion
Source: files\lua51.dll; DestDir: {app}; Flags: ignoreversion
Source: files\luac5.1.exe; DestDir: {app}; DestName: luac.exe; Flags: ignoreversion
Source: files\wlua5.1.exe; DestDir: {app}; DestName: wlua.exe; Flags: ignoreversion
Source: files\metalua.bat; DestDir: {app}; Flags: ignoreversion
Source: files\luadoc_start.bat; DestDir: {app}; Flags: ignoreversion
Source: files\lExecutor.wlua; DestDir: {app}; Flags: ignoreversion
Source: files\ilua.cmd; DestDir: {app}; Flags: ignoreversion
; -- LuaRocks files
Source: files\luarocks.bat; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\luarocks-admin.bat; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\7z.dll; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\7z.exe; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\luarocks.lua; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\luarocks_config.lua; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\luarocks-admin.lua; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\rclauncher.o; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\rclauncher.obj; DestDir: {app}; Flags: ignoreversion; Components: luarocks
Source: files\rocks\*; DestDir: {app}\rocks; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: luarocks
Source: files\lua\luarocks\*; DestDir: {app}\lua\luarocks; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: luarocks
; -- Other files and modules.
Source: files\clibs\*; DestDir: {app}\clibs; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: modules
Source: files\docs\*; DestDir: {app}\docs; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: docs
Source: files\examples\*; DestDir: {app}\examples; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: examples
Source: files\include\*; DestDir: {app}\include; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: moduledevel
Source: files\lib\*; DestDir: {app}\lib; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: moduledevel
Source: files\lua\*; DestDir: {app}\lua; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\, luarocks\*; Components: modules
Source: files\utils\*; DestDir: {app}\utils; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: modules
Source: support\Microsoft.VC80.CRT.SP1\*; DestDir: {app}\Microsoft.VC80.CRT; Flags: ignoreversion; Excludes: .svn\; Check: IsNonAdminLoggedOn
Source: support\Microsoft.VC80.CRT.SP1\*; DestDir: {app}\clibs\Microsoft.VC80.CRT; Flags: ignoreversion; Excludes: .svn\; Components: modules; Check: IsNonAdminLoggedOn
Source: support\Microsoft.VC80.CRT\*; DestDir: {app}\clibs\alien\Microsoft.VC80.CRT; Flags: ignoreversion; Excludes: .svn\; Components: modules; Check: IsNonAdminLoggedOn
Source: support\Microsoft.VC80.CRT.SP1\*; DestDir: {app}\clibs\md5\Microsoft.VC80.CRT; Flags: ignoreversion; Excludes: .svn\; Components: modules; Check: IsNonAdminLoggedOn
Source: support\Microsoft.VC80.CRT.SP1\*; DestDir: {app}\clibs\mime\Microsoft.VC80.CRT; Flags: ignoreversion; Excludes: .svn\; Components: modules; Check: IsNonAdminLoggedOn
Source: support\Microsoft.VC80.CRT.SP1\*; DestDir: {app}\clibs\socket\Microsoft.VC80.CRT; Flags: ignoreversion; Excludes: .svn\; Components: modules; Check: IsNonAdminLoggedOn
Source: support\*; DestDir: {app}\install\support; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\
#ifdef DOWNLOAD_FILES
Source: support\isxdl.dll; DestDir: {tmp}; Flags: dontcopy
Source: {src}\vcredist_x86.exe; DestDir: {app}\install\support; Flags: ignoreversion external; Check: ShouldCopyVc8Runtime
#else
Source: vcredist_x86.exe; DestDir: {app}\install\support; Flags: ignoreversion; Excludes: .svn\
#endif
Source: LuaForWindows.iss; DestDir: {app}\install; Flags: ignoreversion; Excludes: .svn\
Source: changes.txt; DestDir: {app}; Flags: ignoreversion; Excludes: .svn\
Source: todo.txt; DestDir: {app}; Flags: ignoreversion; Excludes: .svn\

; -- SciTE files
Source: SciTE\*; DestDir: {app}\SciTE; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: .svn\; Components: editors/scite
Source: support\SciTEGlobal.black.properties; DestDir: {app}\SciTE; DestName: SciTEGlobal.properties; Tasks: blackscheme; Components: editors/scite; Flags: ignoreversion

[InstallDelete]
Name: {app}\lua\pl; Type: filesandordirs
Name: {app}\docs\bitlib; Type: filesandordirs
Name: {app}\docs\penlight; Type: filesandordirs
Name: {app}\examples\bitlib; Type: filesandordirs
Name: {app}\examples\penlight; Type: filesandordirs
Name: {app}\examples\iup\tree_set_attrs.lua; Type: filesandordirs
; Cleanup the old file.
Name: {app}\install\Lua.iss; Type: files

[Icons]
Name: {group}\Lua (Command Line); WorkingDir: {app}; Filename: {app}\lua.exe; Components: main
Name: {group}\iLua (Friendly Lua Command Line); WorkingDir: {app}; Filename: {app}\ilua.cmd; Components: main
Name: {group}\lExecutor; WorkingDir: {app}; Filename: {app}\lExecutor.wlua; Components: main
Name: {group}\LuaForWindows Documentation; Filename: {app}\docs\luaforwindows.html; Components: main
Name: {group}\QuickLuaTour; Filename: {app}\Examples\quickluatour.lua; Components: examples
Name: {group}\{#MyAppName} Examples; Filename: {app}\Examples; Components: examples
Name: {group}\Documentation\{#MyAppName} Module Documentation; Filename: {app}\docs; Components: docs
Name: {group}\Documentation\Lua Quick Reference; Filename: {app}\docs\luarefv51.html; Components: docs
Name: {group}\Documentation\Lua 5.1 Reference Manual; Filename: {app}\docs\lua5_1_4_Docs.chm; Components: docs
Name: {group}\Documentation\lExecutor Documentation; Filename: {app}\docs\lexecutor\lExecutor.html; Components: docs
Name: {group}\{cm:UninstallProgram,{#MyAppName}}; Filename: {uninstallexe}
Name: {commondesktop}\{#MyAppName}; Filename: {app}\{#MyAppExeName}; Tasks: desktopicon
; -- SciTE icons.
Name: {group}\SciTE; Filename: {app}\SciTE\scite.exe; Components: editors/scite
Name: {commondesktop}\SciTE; Filename: {app}\SciTE\scite.exe; Tasks: desktopicon; Components: editors/scite

[Run]
Filename: {app}\Examples\quickluatour.lua; Description: Run a simple introduction to Lua.; WorkingDir: {app}; Flags: nowait postinstall skipifsilent unchecked shellexec; Components: examples
Filename: {app}/install/support/vcredist_x86.exe; Parameters: "/q:a /c:""VCREDI~3.EXE /q:a /c:""""msiexec /i vcredist.msi /qn"""" """; StatusMsg: Installing Microsoft Visual C++ 2005 SP1 Redistributable...; Check: ShouldInstallVc8Runtime

[INI]
Filename: {group}\Documentation\{#MyAppName} On The Web.url; Section: InternetShortcut; Key: URL; String: http://lua.org/
Filename: {group}\Documentation\Lua PiL Book.url; Section: InternetShortcut; Key: URL; String: http://www.lua.org/pil/; Components: docs
Filename: {app}\docs\Lua PiL Book.url; Section: InternetShortcut; Key: URL; String: http://www.lua.org/pil/; Components: docs

[UninstallDelete]
Type: files; Name: {app}\{#MyAppName}.url
Type: files; Name: {app}\docs\Lua PiL Book.url
Type: files; Name: {app}\docs\lua5_1_3_Docs.chm
Type: filesandordirs; Name: {group}

[Components]
Name: main; Description: Lua (required); Flags: fixed dontinheritcheck checkablealone; Types: full compact custom
Name: editors; Description: Script Editors; Flags: dontinheritcheck disablenouninstallwarning; Types: full custom
Name: editors/scite; Description: SciTE (IDE with debugging); Flags: disablenouninstallwarning exclusive; Types: full custom
Name: modules; Description: Lua Modules; Flags: dontinheritcheck checkablealone disablenouninstallwarning; Types: full custom
Name: luarocks; Description: LuaRocks Module Installer (Experimental); Flags: dontinheritcheck checkablealone disablenouninstallwarning; Types: full custom
Name: moduledevel; Description: Lua Module Development files (libs and headers); Flags: dontinheritcheck checkablealone disablenouninstallwarning; Types: full custom
Name: docs; Description: Documentation; Flags: dontinheritcheck checkablealone disablenouninstallwarning; Types: full custom
Name: examples; Description: Examples; Flags: dontinheritcheck checkablealone disablenouninstallwarning; Types: full custom

[Registry]
; -- Add the Lua file associations.
Root: HKCR; SubKey: .lua; ValueType: string; ValueData: {#MyAppName}.Script; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .lua\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .lua\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: {#MyAppName}.Script\DefaultIcon; ValueType: string; ValueData: {app}\install\support\luafile.ico; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: {#MyAppName}.Script; ValueType: string; ValueData: {#MyAppName} Script File; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: {#MyAppName}.Script\Shell\Open\Command; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsAdminLoggedOn
Root: HKCR; SubKey: {#MyAppName}.Script\Shell\Edit; ValueType: string; ValueData: Edit Script; Flags: uninsdeletevalue; Components: editors/scite; Check: IsAdminLoggedOn
Root: HKCR; SubKey: {#MyAppName}.Script\Shell\Edit\Command; ValueType: expandsz; ValueData: """{app}\SciTE\scite.exe"" ""%1"""; Flags: uninsdeletevalue; Components: editors/scite; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .wlua; ValueType: string; ValueData: w{#MyAppName}.Script; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .wlua\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .wlua\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: w{#MyAppName}.Script\DefaultIcon; ValueType: string; ValueData: {app}\install\support\luafile.ico; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: w{#MyAppName}.Script; ValueType: string; ValueData: w{#MyAppName} Script File; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: w{#MyAppName}.Script\Shell\Open\Command; ValueType: string; ValueData: """{app}\w{#MyAppExeName}"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsAdminLoggedOn
Root: HKCR; SubKey: w{#MyAppName}.Script\Shell\Edit; ValueType: string; ValueData: Edit Script; Flags: uninsdeletevalue; Components: editors/scite; Check: IsAdminLoggedOn
Root: HKCR; SubKey: w{#MyAppName}.Script\Shell\Edit\Command; ValueType: expandsz; ValueData: """{app}\SciTE\scite.exe"" ""%1"""; Flags: uninsdeletevalue; Components: editors/scite; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .lexe; ValueType: string; ValueData: lExecutor.Script; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .lexe\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .lexe\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: lExecutor.Script\DefaultIcon; ValueType: string; ValueData: {app}\install\support\lexe.ico; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: lExecutor.Script; ValueType: string; ValueData: lExecutor Script File; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: lExecutor.Script\Shell\Open\Command; ValueType: string; ValueData: """{app}\w{#MyAppExeName}"" ""{app}\lExecutor.wlua"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsAdminLoggedOn
Root: HKCR; SubKey: lExecutor.Script\Shell\Edit; ValueType: string; ValueData: Edit Script; Flags: uninsdeletevalue; Components: editors/scite; Check: IsAdminLoggedOn
Root: HKCR; SubKey: lExecutor.Script\Shell\Edit\Command; ValueType: expandsz; ValueData: """{app}\SciTE\scite.exe"" ""%1"""; Flags: uninsdeletevalue; Components: editors/scite; Check: IsAdminLoggedOn
;
Root: HKCR; SubKey: .luac; ValueType: string; ValueData: {#MyAppName}.Compiled; Flags: uninsdeletekey; Check: IsAdminLoggedOn
;Root: HKCR; SubKey: .luac\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsAdminLoggedOn
;Root: HKCR; SubKey: .luac\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: {#MyAppName}.Compiled\DefaultIcon; ValueType: string; ValueData: {app}\install\support\luafile3.ico; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: {#MyAppName}.Compiled; ValueType: string; ValueData: {#MyAppName} Compiled File; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: {#MyAppName}.Compiled\Shell\Open\Command; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .mlua; ValueType: string; ValueData: Meta{#MyAppName}.Script; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .mlua\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: .mlua\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: Meta{#MyAppName}.Script\DefaultIcon; ValueType: string; ValueData: {app}\install\support\luafile2.ico; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: Meta{#MyAppName}.Script; ValueType: string; ValueData: Meta{#MyAppName} Script File; Flags: uninsdeletekey; Check: IsAdminLoggedOn
Root: HKCR; SubKey: Meta{#MyAppName}.Script\Shell\Open\Command; ValueType: string; ValueData: """{app}\metalua.bat"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsAdminLoggedOn
Root: HKCR; SubKey: Meta{#MyAppName}.Script\Shell\Edit; ValueType: string; ValueData: Edit Script; Flags: uninsdeletevalue; Components: editors/scite; Check: IsAdminLoggedOn
Root: HKCR; SubKey: Meta{#MyAppName}.Script\Shell\Edit\Command; ValueType: expandsz; ValueData: """{app}\SciTE\scite.exe"" ""%1"""; Flags: uninsdeletevalue; Components: editors/scite; Check: IsAdminLoggedOn

; -- Limited user Lua file associations.
Root: HKCU; SubKey: SOFTWARE\Classes\.lua; ValueType: string; ValueData: {#MyAppName}.Script; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.lua\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.lua\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\{#MyAppName}.Script\DefaultIcon; ValueType: string; ValueData: {app}\install\support\luafile.ico; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\{#MyAppName}.Script; ValueType: string; ValueData: {#MyAppName} Script File; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\{#MyAppName}.Script\Shell\Open\Command; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\{#MyAppName}.Script\Shell\Edit; ValueType: string; ValueData: Edit Script; Flags: uninsdeletevalue; Components: editors/scite; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\{#MyAppName}.Script\Shell\Edit\Command; ValueType: expandsz; ValueData: """{app}\SciTE\scite.exe"" ""%1"""; Flags: uninsdeletevalue; Components: editors/scite; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.wlua; ValueType: string; ValueData: w{#MyAppName}.Script; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.wlua\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.wlua\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\w{#MyAppName}.Script\DefaultIcon; ValueType: string; ValueData: {app}\install\support\luafile.ico; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\w{#MyAppName}.Script; ValueType: string; ValueData: w{#MyAppName} Script File; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\w{#MyAppName}.Script\Shell\Open\Command; ValueType: string; ValueData: """{app}\w{#MyAppExeName}"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\w{#MyAppName}.Script\Shell\Edit; ValueType: string; ValueData: Edit Script; Flags: uninsdeletevalue; Components: editors/scite; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\w{#MyAppName}.Script\Shell\Edit\Command; ValueType: expandsz; ValueData: """{app}\SciTE\scite.exe"" ""%1"""; Flags: uninsdeletevalue; Components: editors/scite; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.lexe; ValueType: string; ValueData: lExecutor.Script; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.lexe\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.lexe\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\lExecutor.Script\DefaultIcon; ValueType: string; ValueData: {app}\install\support\lexe.ico; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\lExecutor.Script; ValueType: string; ValueData: lExecutor Script File; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\lExecutor.Script\Shell\Open\Command; ValueType: string; ValueData: """{app}\w{#MyAppExeName}"" ""{app}\lExecutor.wlua"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\lExecutor.Script\Shell\Edit; ValueType: string; ValueData: Edit Script; Flags: uninsdeletevalue; Components: editors/scite; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\lExecutor.Script\Shell\Edit\Command; ValueType: expandsz; ValueData: """{app}\SciTE\scite.exe"" ""%1"""; Flags: uninsdeletevalue; Components: editors/scite; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.luac; ValueType: string; ValueData: {#MyAppName}.Compiled; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
;Root: HKCU; SubKey: SOFTWARE\Classes\.luac\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
;Root: HKCU; SubKey: SOFTWARE\Classes\.luac\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\{#MyAppName}.Compiled\DefaultIcon; ValueType: string; ValueData: {app}\install\support\luafile3.ico; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\{#MyAppName}.Compiled; ValueType: string; ValueData: {#MyAppName} Compiled File; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\{#MyAppName}.Compiled\Shell\Open\Command; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.mlua; ValueType: string; ValueData: Meta{#MyAppName}.Script; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.mlua\Content Type; ValueType: string; ValueData: text/plain; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\.mlua\PerceivedType; ValueType: string; ValueData: text; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\Meta{#MyAppName}.Script\DefaultIcon; ValueType: string; ValueData: {app}\install\support\luafile2.ico; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\Meta{#MyAppName}.Script; ValueType: string; ValueData: Meta{#MyAppName} Script File; Flags: uninsdeletekey; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\Meta{#MyAppName}.Script\Shell\Open\Command; ValueType: string; ValueData: """{app}\metalua.bat"" ""%1"" %*"; Flags: uninsdeletevalue; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\Meta{#MyAppName}.Script\Shell\Edit; ValueType: string; ValueData: Edit Script; Flags: uninsdeletevalue; Components: editors/scite; Check: IsNonAdminLoggedOn
Root: HKCU; SubKey: SOFTWARE\Classes\Meta{#MyAppName}.Script\Shell\Edit\Command; ValueType: expandsz; ValueData: """{app}\SciTE\scite.exe"" ""%1"""; Flags: uninsdeletevalue; Components: editors/scite; Check: IsNonAdminLoggedOn

[Code]
// -- Misc Functions

// -- Checks to see if a non-administrator is logged on.
function IsNonAdminLoggedOn(): boolean;
begin
	if IsAdminLoggedOn() then begin
		Result := false;
	end else begin
		Result := true;
	end;
end;

// -- Checks to see if the VC 8.0 run-time is installed.
function IsVc8RuntimeInstalled(): boolean;
begin
	Result := RegValueExists( HKLM, 'Software\Microsoft\DevDiv\VC\Servicing\8.0\RED\1033', 'Install' );
end;

// -- Checks to see if the VC 8.0 run-time is already installed and determines if it should be installed.
function ShouldInstallVc8Runtime(): boolean;
begin
	if IsVc8RuntimeInstalled() then begin
		// Already installed so no need to re-install.
		Result := false;
	end else begin
		if IsAdminLoggedOn() then begin
			Result := true;
		end else begin
			SuppressibleMsgBox( 'The Microsoft Visual C++ 2005 Redistributable doesn''t appear to be installed and requires administrator privileges.' #13 #13 'Please run "vcredist_x86.exe", as an Administrator, from' #13 '    ' + ExpandConstant( '{app}\install\support\vcredist_x86.exe' ) + #13 'after the install finishes.' #13 #13 'NOTE: Lua will have limited or no functionality, so please do this as soon as possible.' , mbInformation, MB_OK, IDOK );
			Result := false;
		end;
	end;
end;

// -- Checks to see if the VC 8.0 run-time needs to be copied
function ShouldCopyVc8Runtime(): boolean;
begin
	Result := not IsVc8RuntimeInstalled();
end;

// -- Updates specified environment variable.
procedure UpdateEnvironmentVariable( const environmentVariable: String; const stringToAdd: String );
var
	value: String;
	newVal: String;
	idx: Integer;

begin
	// Get the old value so the new value can be appended.
	// Also check if you have administrative rights so that we can read
	// from the right location. This is because reads are ok on a non-admin system.
	if IsAdminLoggedOn() then begin
		RegQueryStringValue( HKLM, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', environmentVariable, value )
	end else begin
		// Check if the local environment already exists and grab that as a starting place.
		if RegValueExists( HKCU, 'Environment', environmentVariable ) then begin
			RegQueryStringValue( HKCU, 'Environment', environmentVariable, value )
		end else begin
			if CompareText( environmentVariable, 'PATH' ) = 0 then begin
				RegQueryStringValue( HKCU, 'Environment', environmentVariable, value )
			end else begin
				RegQueryStringValue( HKLM, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', environmentVariable, value )
			end;
		end;
	end;

	// Only add the ';' if there is a string already.
	if Length( value ) > 0 then begin
		newVal := ';' + stringToAdd;
	end else begin
		newVal := stringToAdd
	end;

	// Search for the string
	idx := Pos( stringToAdd, value );
	if idx = 0 then begin
		value := value + newVal;
		if not RegWriteStringValue( HKLM, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', environmentVariable, value ) then
			RegWriteStringValue( HKCU, 'Environment', environmentVariable, value );
	end;
end;

// -- Updates specified environment variable.
procedure RemoveEnvironmentVariable( const environmentVariable: String; const stringToRemove: String );
var
	value: String;
	firstVal: String;
	secondVal: String;
	lastChar: String;
	idx: Integer;

begin
	// Get the old value so the new value can be appended.
	// Also check if you have administrative rights so that we can read
	// from the right location. This is because reads are ok on a non-admin system.
	if IsAdminLoggedOn() then begin
		RegQueryStringValue( HKLM, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', environmentVariable, value )
	end else begin
		// Check if the local environment already exists and grab that as a starting place.
		if RegValueExists( HKCU, 'Environment', environmentVariable ) then begin
			RegQueryStringValue( HKCU, 'Environment', environmentVariable, value )
		end else begin
			if CompareText( environmentVariable, 'PATH' ) = 0 then begin
				RegQueryStringValue( HKCU, 'Environment', environmentVariable, value )
			end else begin
				RegQueryStringValue( HKLM, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', environmentVariable, value )
			end;
		end;
	end;

	// Search for the string
	idx := Pos( stringToRemove, value );
	if idx > 0 then begin
		// get the parts of the string.
		firstVal := Copy( value, 0, idx - 1 );
		secondVal := Copy( value, idx + Length( stringToRemove ), Length( value ) );

		// Combine the first and second values to make the new value.
		value := firstVal + secondVal;

		// See if the value is now empty and delete it. Else write the balance back.
		if Length( value ) = 0 then begin
			if not RegDeleteValue( HKLM, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', environmentVariable ) then
				RegDeleteValue( HKCU, 'Environment', environmentVariable );
		end else begin
			// Clean up the string a bit by removing duplicate ;.
			StringChangeEx( value, ';;', ';', True );
			// Check the last character for a ; and remove it.
			lastChar := Copy( value, Length( value ), Length( value ) );
			if lastChar = ';' then
				value := Copy( value, 0, Length( value ) - 1 );

			// Write the new value back.
			if not RegWriteStringValue( HKLM, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', environmentVariable, value ) then
				RegWriteStringValue( HKCU, 'Environment', environmentVariable, value );
		end;
	end;
end;

// -- Previous version and uninstalling functions
function GetPathInstalled( AppID: String ): String;
var
   sPrevPath: String;
begin
  sPrevPath := '';
  if not RegQueryStringValue( HKLM,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID+'_is1',
      'Inno Setup: App Path', sPrevpath) then
    RegQueryStringValue( HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID+'_is1' ,
      'Inno Setup: App Path', sPrevpath);

  Result := sPrevPath;
end;

function GetPathUninstallString( AppID: String ): String;
var
   sPrevPath: String;
begin
  sPrevPath := '';
  if not RegQueryStringValue( HKLM,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID+'_is1',
		'UninstallString', sPrevpath) then
    RegQueryStringValue( HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID+'_is1' ,
		'UninstallString', sPrevpath);

  Result := sPrevPath;
end;

function GetInstalledVersion( AppID: String ): String;
var
   sPrevPath: String;

begin
  sPrevPath := '';
  if not RegQueryStringValue( HKLM,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID+'_is1',
		'DisplayVersion', sPrevpath) then
    RegQueryStringValue( HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\'+AppID+'_is1' ,
		'DisplayVersion', sPrevpath);

  Result := sPrevPath;
end;

function InitializeSetup(): boolean;
var
	ResultCode: Integer;
	sVersion: String;
	sUninstallEXE: String;

begin
	sVersion:= GetInstalledVersion('{#MyAppName}');
	sUninstallEXE:= RemoveQuotes(GetPathUninstallString('{#MyAppName}'));

	// Check to make sure there is an exceptable version of LfW installed.
	if Length(sVersion) = 0 then begin
		result:= true;
	end else begin
		//MsgBox( 'Version ' + sVersion + ' found. Minversion = ' + '{#AppMinVer}', mbInformation, MB_OK );
		if CompareText( sVersion, '{#AppMinVer}' ) <= 0 then begin
			if FileExists( sUninstallEXE ) then begin
				if WizardSilent() then begin
					// Just uninstall without asking because we are in silent mode.
					Exec( sUninstallEXE, '/SILENT', GetPathInstalled('{#MyAppName}'),
							SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode);

					// Make sure that Setup is visible and the foreground window
					BringToFrontAndRestore;
					result := true;
				end else begin
					// Ask if they really want to uninstall because we are in the default installer.
					if SuppressibleMsgBox( 'Version ' + sVersion + ' of {#MyAppName} was detected.' #13 'It is recommended that you uninstall the old version first before continuing.' + #13 + #13 + 'Would you like to uninstall it now?', mbInformation, MB_YESNO, IDYES ) = IDYES then begin
						Exec( sUninstallEXE, '/SILENT', GetPathInstalled('{#MyAppName}'),
							SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode);

						// Make sure that Setup is visible and the foreground window
						BringToFrontAndRestore;
						result := true;
					end else begin
						result := true;
					end;
				end;
			end;
		end else begin
			result := true;
		end;
	end;
end;

procedure CurStepChanged( CurStep: TSetupStep );
begin
	if CurStep = ssPostInstall then begin
		// Add the app path to the PATH environment variable.
		UpdateEnvironmentVariable( 'PATH', ExpandConstant( '{app}' ) );
		UpdateEnvironmentVariable( 'PATH', ExpandConstant( '{app}' ) + '\clibs' );
		// Add the file extentions to the PATHEXT environment variable.
		//UpdateEnvironmentVariable( 'PATHEXT', '.lua' );
		UpdateEnvironmentVariable( 'PATHEXT', '.wlua' );
		UpdateEnvironmentVariable( 'PATHEXT', '.lexe' );
		// Add the LUA_PATH and LUA_CPATH.
		UpdateEnvironmentVariable( 'LUA_PATH', ';;' + ExpandConstant( '{app}' ) + '\lua\?.luac' )
		//UpdateEnvironmentVariable( 'LUA_CPATH', ';;?.dll;' + ExpandConstant( '{app}' ) + '\clibs\?.dll;' + ExpandConstant( '{app}' ) + '\clibs\loadall.dll;' + ExpandConstant( '{app}' ) + '\clibs\?51.dll' )
		// Add LUA_DEV to help C module writers.
		UpdateEnvironmentVariable( 'LUA_DEV', ExpandConstant( '{app}' ) )
	end;
end;

procedure CurUninstallStepChanged( CurUninstallStep: TUninstallStep );
begin
	if CurUninstallStep = usPostUninstall then begin
        // Remove the app path to the PATH environment variable.
        RemoveEnvironmentVariable( 'PATH', ExpandConstant( '{app}' ) );
    	RemoveEnvironmentVariable( 'PATH', ExpandConstant( '{app}' ) + '\clibs' );
    	// Remove the file extentions to the PATHEXT environment variable.
    	//RemoveEnvironmentVariable( 'PATHEXT', '.lua' );
        RemoveEnvironmentVariable( 'PATHEXT', '.wlua' );
        RemoveEnvironmentVariable( 'PATHEXT', '.lexe' );
        // Remove the LUA_PATH and LUA_CPATH.
    	RemoveEnvironmentVariable( 'LUA_PATH', ';;' + ExpandConstant( '{app}' ) + '\lua\?.luac' )
    	//RemoveEnvironmentVariable( 'LUA_CPATH', ';;?.dll;' + ExpandConstant( '{app}' ) + '\clibs\?.dll;' + ExpandConstant( '{app}' ) + '\clibs\loadall.dll;' + ExpandConstant( '{app}' ) + '\clibs\?51.dll' )
    	// Remove the LUA_DEV variable.
		RemoveEnvironmentVariable( 'LUA_DEV', ExpandConstant( '{app}' ) )
    end;
end;

#ifdef DOWNLOAD_FILES
procedure isxdl_AddFile(URL, Filename: String);
external 'isxdl_AddFile@files:isxdl.dll stdcall';
function isxdl_DownloadFiles(hWnd: Integer): Integer;
external 'isxdl_DownloadFiles@files:isxdl.dll stdcall';
function isxdl_SetOption(Option, Value: String): Integer;
external 'isxdl_SetOption@files:isxdl.dll stdcall';


function NextButtonClick( CurPage: Integer ): Boolean;
var
	hWnd: Integer;
	downloadNeeded: Boolean;
	vcRedistPath: String;

begin
	downloadNeeded := false;
	Result := true;

	if CurPage = wpReady then begin
		hWnd := StrToInt( ExpandConstant( '{wizardhwnd}' ) );

		if not IsVc8RuntimeInstalled() then begin
			vcRedistPath := ExpandConstant( '{src}\vcredist_x86.exe' );
			if not FileExists( vcRedistPath ) then begin
				isxdl_AddFile( '{#vcRedistURL}', vcRedistPath );
				downloadNeeded := true;
			end;

			isxdl_SetOption( 'label', 'Downloading extra files' );
			isxdl_SetOption( 'description', 'Please wait while Setup is downloading the Microsoft Visual C++ 2005 SP1 Redistributable to your computer.' );
			if downloadNeeded then begin
				if isxdl_DownloadFiles( hWnd ) = 0 then begin
					Result := false;
				end;
			end;
		end;
	end;
end;
#endif


