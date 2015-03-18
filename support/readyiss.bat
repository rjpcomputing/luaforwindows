@echo off
::**************************************************************************
:: File:           readyiss.bat
:: Version:        1.05
:: Name:           Andrew Wilson and Ryan Pusztai <rpusztai@gmail.com>
:: Date:           04/27/2009
:: Description:    Helps to ready the installed files to be used with lua.iss
::
:: Copyright (C) 2009 Andrew Wilson and Ryan Pusztai
::
:: Permission is hereby granted, free of charge, to any person obtaining a copy
:: of this software and associated documentation files (the "Software"), to deal
:: in the Software without restriction, including without limitation the rights
:: to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
:: copies of the Software, and to permit persons to whom the Software is
:: furnished to do so, subject to the following conditions:
::
:: The above copyright notice and this permission notice shall be included in
:: all copies or substantial portions of the Software.
::
:: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
:: IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
:: FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
:: AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
:: LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
:: OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
:: THE SOFTWARE.
::
:: Version:		1.00 - Initial release.
::				1.01 - Changed where to copy files from to match new layout.
::				1.02 - Updated for new module development.
::				1.03 - Updated for the new vcredist_x86.exe placement.
::				1.04 - Updated for the new name for lualibs to lua.
::				1.05 - Updated for the installer name to LuaForWindows.
::
:: Notes:
::			- Must run from the 'install/support' directory.
::			- Download and install inno script compiler  isetup-5.2.3.exe,
::				ispack-5.2.3.exe from http://www.jrsoftware.org/isdl.php to
::				compile lua.iss .
::			- Once batch file is done inno compiler with lua.iss file to 
::				regenerate single executable install file.
::**************************************************************************

set APP_VERSION=1.05
set APP_TITLE=Ready Lua for Windows Install Files Package

echo ----------------------------------------
echo       %APP_TITLE% v%APP_VERSION%
echo                   By
echo    Andrew Wilson and Ryan Pusztai
echo.
echo Creates the install files package.
echo.
echo             Copyright (c) 2008  
echo ----------------------------------------
echo.

:: Cleanup old sources.
if exist ..\files rmdir /S /Q ..\files
if exist ..\SciTE rmdir /S /Q ..\SciTE

:: Check to see if 'source' directory exists.
if exist ..\files goto BEGIN_COPY

mkdir ..\files

:BEGIN_COPY

echo.
echo Coping directories/files to 'files'...
xcopy ..\..					..\files           /I /H /Y /EXCLUDE:excludes
xcopy ..\..\clibs			..\files\clibs     /E /I /H /Y /EXCLUDE:excludes
xcopy ..\..\docs			..\files\docs      /E /I /H /Y /EXCLUDE:excludes
xcopy ..\..\examples		..\files\examples  /E /I /H /Y /EXCLUDE:excludes
xcopy ..\..\include		    ..\files\include   /E /I /H /Y /EXCLUDE:excludes
xcopy ..\..\lib		        ..\files\lib       /E /I /H /Y /EXCLUDE:excludes
xcopy ..\..\lua				..\files\lua	   /E /I /H /Y /EXCLUDE:excludes
xcopy ..\..\utils			..\files\utils     /E /I /H /Y /EXCLUDE:excludes
xcopy ..\..\SciTE			..\SciTE           /E /I /H /Y

echo.
echo Renaming files...
ren ..\files\bin2c.exe bin2c5.1.exe
ren ..\files\wlua.exe  wlua5.1.exe
ren ..\files\lua.exe   lua5.1.exe
ren ..\files\luac.exe  luac5.1.exe

echo.
echo A little bit of reorganization...
move ..\files\changes.txt ..
move ..\files\todo.txt    ..
if exist vcredist_x86.exe move vcredist_x86.exe     ..

goto END

:END
echo.
echo LuaForWindows.iss is ready for use with INNO Setup compiler...
echo Example:
echo     cd ..
echo     "C:\Program Files\INNO Setup 5\iscc.exe" LuaForWindows.iss

:: Cleanup environment.
set APP_VERSION=
set APP_TITLE=
