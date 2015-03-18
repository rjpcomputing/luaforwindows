#!/usr/bin/env lua
-- ----------------------------------------------------------------------------
-- Name:        lExecutor.wlua
-- Purpose:     This program assists in running Lua scripts in a GUI.
-- Author:      R. Pusztai
-- Modified by:
-- Created:     11/25/2008
-- License:   Copyright (C) 2008 RJP Computing. All rights reserved.
--
--	Permission is hereby granted, free of charge, to any person obtaining a copy
--	of this software and associated documentation files (the "Software"), to deal
--	in the Software without restriction, including without limitation the rights
--	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--	copies of the Software, and to permit persons to whom the Software is
--	furnished to do so, subject to the following conditions:
--
--	The above copyright notice and this permission notice shall be included in
--	all copies or substantial portions of the Software.
--
--	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
--	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--	THE SOFTWARE.
-- ----------------------------------------------------------------------------
require( "wx" )

-- ----------------------------------------------------------------------------
-- CONSTANTS
-- ----------------------------------------------------------------------------
local APP_VERSION	= "1.01"
local ID_IDCOUNTER	= nil

-- ----------------------------------------------------------------------------
-- GLOBAL VARIABLES
-- ----------------------------------------------------------------------------
lExecutor	= {}			-- Place to store the exported lExecutor functions.
_LEXECUTOR	= true			-- Used so that scripts can be written to know if
							-- lExecutor is running the script.
							-- Ex. if not _LEXECUTOR then main() end
APP_NAME	= "lExecutor"	-- Use this in the calling app to overwrite the
							-- windows title that is displayed.

-- ----------------------------------------------------------------------------
-- HELPER FUNCTIONS
-- ----------------------------------------------------------------------------

-- Equivalent to C's "cond ? a : b", all terms will be evaluated
local function iff( cond, a, b )
	if cond then
		return a
	else
		return b
	end
end

-- Generate a unique new wxWindowID
local function NewID()
    ID_IDCOUNTER = ( ID_IDCOUNTER or wx.wxID_HIGHEST ) + 1
    return ID_IDCOUNTER
end

-- Setup the args table so that it is right for the script being loaded.
local function ReorganizeArgTable( filename )
	-- Set the filename element to the loaded scripts filename.
	arg[0] = filename

	for i = 2, #arg do
		arg[i - 1] = arg[i]
	end

	-- Clear the last entry.
	-- It is not needed in the loaded script.
	arg[#arg] = nil
end

-- ----------------------------------------------------------------------------
-- Class Declaration
-- ----------------------------------------------------------------------------
local lExecutorGUI =
{
	-- GUI control variables
	--
	frame             			= nil,		-- The wxFrame of the program
    panel             			= nil,		-- The main wxPanel child of the wxFrame
	logTextCtrl					= nil,
	passFailStaticText			= nil,
	executeButton				= nil,
	repeatCheck					= nil,

	-- Initialize the wxConfig for loading/saving the preferences
	--
	config 						= nil,

	-- CONTROL ID'S
	--
	-- File menu.
	ID_FILE_OPEN				= wx.wxID_OPEN,
	ID_FILE_SAVE_LOG			= NewID(),
	ID_FILE_EXIT				= wx.wxID_EXIT,
	-- Help menu
	ID_HELP_ABOUT				= wx.wxID_ABOUT,
	-- Controls
	ID_EXECUTE_BUTTON			= NewID(),
	ID_LOG_TEXTCTRL				= NewID(),
	ID_PASS_FAIL_STATIC_TEXT	= NewID(),
	ID_REPEAT_CHECKBOX			= NewID(),
}

local AppData =
{
	script						= nil,				-- The actual loaded script.
	scriptEnvironment			= {},				-- The environment used by the loaded script.
	startupFilename				= arg[1] or nil,	-- The Lua file to load and run.
	filename					= nil,				-- The Lua file to load and run.
	isScriptLoaded				= false,			-- Flag to use to see if a script has already been load.
	lastSavePath				= nil,
	lastOpenPath				= nil,
}

-- ----------------------------------------------------------------------------
-- EXPORTED/AVAILABLE FUNCTIONS
-- ----------------------------------------------------------------------------
function print( ... )
	-- Build the text to log
	local msg = ""
	for _, value in ipairs( { ... } ) do
		msg = msg..tostring( value ).."\t"
	end
	msg = msg.."\n"
	lExecutorGUI.logTextCtrl:AppendText( msg )
end

local originalRequire = require
function require( moduleName )
	-- Call the original require().
	local mod = originalRequire( moduleName )

	-- If the module is the 'Utils' replace the Prompt() function.
	if "Utils" == moduleName then
		mod.Prompt = lExecutor.Prompt
	end

	return mod
end

function lExecutor.Prompt( message )
	if type( message ) ~= "string" then
		error( "bad argument #1 to Prompt' (Expected string but recieved "..type( message )..")" )
	end

	local msgDialog = wx.wxTextEntryDialog( lExecutorGUI.frame, message )
	msgDialog:ShowModal()
	return msgDialog:GetValue()
end

---	Sets the pass/fail status indicator to the specified state. Use this to
--	display a pass or fail status to the user running the script.
--	This function will show the pass/fail status indicator the first time
--	it is called.
--	@param isPassed {bool} [DEF] If true then the indicator will display "PASS"
--		and the background will be green. If false, then it will display "FAIL"
--		and the background will be red.
--	@param show {bool} [DEF] If true then the indicator will display, else if false
--		it will not show. This defaults to true.
function lExecutor.SetPassFailStatus( isPassed, show )
	isPassed = isPassed or false
	if nil == show then
		show = true
	end
	lExecutorGUI.panel:Freeze()

	if isPassed then
		lExecutorGUI.passFailStaticText:SetLabel( "PASS" )
		lExecutorGUI.passFailStaticText:SetBackgroundColour( wx.wxColour( 0, 255, 0 ) )
	else
		lExecutorGUI.passFailStaticText:SetLabel( "FAIL" )
		lExecutorGUI.passFailStaticText:SetBackgroundColour( wx.wxColour( 255, 0, 0 ) )
	end

	if show then
		lExecutorGUI.passFailStaticText:Show()
	else
		lExecutorGUI.passFailStaticText:Hide()
	end

	lExecutorGUI.panel:Layout()
	lExecutorGUI.panel:Thaw()
end

---	Clears the log
function lExecutor.ClearLog()
	lExecutorGUI.logTextCtrl:Clear()
end

-- ----------------------------------------------------------------------------
-- GUI RELATED FUNCTIONS
-- ----------------------------------------------------------------------------

-- wxConfig load/save preferences functions
function lExecutorGUI.ConfigRestoreFramePosition( window, windowName )
    local path = lExecutorGUI.config:GetPath()
    lExecutorGUI.config:SetPath( "/"..windowName )

    local _, s = lExecutorGUI.config:Read( "s", -1 )
    local _, x = lExecutorGUI.config:Read( "x", 0 )
    local _, y = lExecutorGUI.config:Read( "y", 0 )
    local _, w = lExecutorGUI.config:Read( "w", 0 )
    local _, h = lExecutorGUI.config:Read( "h", 0 )

	-- Always restore the position.
	local clientX, clientY, clientWidth, clientHeight
	clientX, clientY, clientWidth, clientHeight = wx.wxClientDisplayRect()

	if x < clientX then x = clientX end
	if y < clientY then y = clientY end

	if w > clientWidth  then w = clientWidth end
	if h > clientHeight then h = clientHeight end

	window:SetSize( x, y, w, h )

	-- Now check to see if it should be minimized or maximized.
    if 1 == s then
        window:Maximize( true )
    elseif 2 == s then
        window:Iconize( true )
    end

    lExecutorGUI.config:SetPath( path )
end

function lExecutorGUI.ConfigSaveFramePosition( window, windowName )
    local path = lExecutorGUI.config:GetPath()
    lExecutorGUI.config:SetPath( "/"..windowName )

    local s    = 0
    local w, h = window:GetSizeWH()
    local x, y = window:GetPositionXY()

    if window:IsMaximized() then
        s = 1
    elseif window:IsIconized() then
        s = 2
    end

    lExecutorGUI.config:Write( "s", s )

    if s == 0 then
        lExecutorGUI.config:Write( "x", x )
        lExecutorGUI.config:Write( "y", y )
        lExecutorGUI.config:Write( "w", w )
        lExecutorGUI.config:Write( "h", h )
    end

    lExecutorGUI.config:SetPath( path )
end

function lExecutorGUI.ConfigRestorePaths()
    local path = lExecutorGUI.config:GetPath()
    lExecutorGUI.config:SetPath( "/Paths" )

    local _, save = lExecutorGUI.config:Read( "Save", "" )
    local _, open = lExecutorGUI.config:Read( "Open", "" )

	-- Set these to AppData.
	AppData.lastSavePath = save
	AppData.lastOpenPath = open

    lExecutorGUI.config:SetPath( path )
end

function lExecutorGUI.ConfigSavePaths()
    local path = lExecutorGUI.config:GetPath()
    lExecutorGUI.config:SetPath( "/Paths" )

	lExecutorGUI.config:Write( "Save", AppData.lastSavePath )
	lExecutorGUI.config:Write( "Open", AppData.lastOpenPath )

    lExecutorGUI.config:SetPath( path )
end

-- Creates the needed wxIcon of the application xmp.
local function GetAppIcon()
	local appIconXpmData =
	{
		"32 32 209 2",
		"  	c None",
		"! 	c black",
		"# 	c #46739A",
		"$ 	c #747575",
		"% 	c #858585",
		"& 	c #7F8080",
		"' 	c #7C7D7D",
		"( 	c #7C7C7D",
		") 	c #797A7A",
		"* 	c #79797A",
		"+ 	c #7F7F80",
		", 	c #7A7F84",
		"- 	c #777D81",
		". 	c #72787C",
		"0 	c #747A7E",
		"1 	c #6A7075",
		"2 	c #6D7378",
		"3 	c #737A7F",
		"4 	c #7C8186",
		"5 	c #7A7C7F",
		"6 	c #466885",
		"7 	c #60666B",
		"8 	c #8A8A8A",
		"9 	c #ADADAD",
		": 	c #A3A3A3",
		"; 	c #A6A6A6",
		"< 	c #A1A1A1",
		"= 	c #A8A8A8",
		"> 	c #9C9C9C",
		"? 	c #9E9E9E",
		"@ 	c #999999",
		"A 	c #969696",
		"B 	c #8C8C8C",
		"C 	c #8F8F8F",
		"D 	c #757575",
		"E 	c #000508",
		"F 	c #595959",
		"G 	c #666666",
		"H 	c #6B6B6B",
		"I 	c #6E6E6E",
		"J 	c #696969",
		"K 	c #B5B5B5",
		"L 	c #ABABAB",
		"M 	c #5E5E5E",
		"N 	c #FD6A2E",
		"O 	c #87727E",
		"P 	c #1F1F1F",
		"Q 	c #4C4C4C",
		"R 	c #424242",
		"S 	c #3D3D3D",
		"T 	c #383838",
		"U 	c #3B3B3B",
		"V 	c #454545",
		"W 	c #404040",
		"X 	c #2E2E2E",
		"Y 	c #545454",
		"Z 	c #161616",
		"[ 	c #7D7D7D",
		"] 	c #CEDFDC",
		"^ 	c #BDD5DA",
		"_ 	c #B9D2D9",
		"` 	c #B9D3DA",
		"a 	c #B9D2DA",
		"b 	c #B9D3D9",
		"c 	c #B8D3D9",
		"d 	c #B6CFD8",
		"e 	c #B3CDD6",
		"f 	c #B7D1D9",
		"g 	c #B5CFD8",
		"h 	c #B4CFD8",
		"i 	c #B4D1DD",
		"j 	c #AAD2E3",
		"k 	c #C3DCDE",
		"l 	c #080809",
		"m 	c white",
		"n 	c #FBFBFB",
		"o 	c #F1F1F1",
		"p 	c #EBEBEB",
		"q 	c #EDEDED",
		"r 	c #F9F9F9",
		"s 	c #EFEFEF",
		"t 	c #FAFAFA",
		"u 	c #B7B7DC",
		"v 	c #4949A5",
		"w 	c #7979BD",
		"x 	c #F1F1F9",
		"y 	c #B0B0B0",
		"z 	c #000104",
		"{ 	c #828282",
		"| 	c #FFFFFA",
		"} 	c #FBFBF6",
		"~ 	c #F1F1ED",
		" !	c #FAFAF5",
		"!!	c #F2F2ED",
		"#!	c #F4F4F5",
		"$!	c #0E0E87",
		"%!	c #000080",
		"&!	c #8686C1",
		"'!	c #FFFFFD",
		"(!	c #FFFFF9",
		")!	c #F1F1EC",
		"*!	c #F2F2EE",
		"+!	c #FEFEFA",
		",!	c #AFAFD4",
		"-!	c #7474B8",
		".!	c #41419F",
		"0!	c #7474BA",
		"1!	c #AFAFD6",
		"2!	c #FEFEF9",
		"3!	c #E3E3ED",
		"4!	c #020281",
		"5!	c #6767B2",
		"6!	c #FFFFFB",
		"7!	c #808080",
		"8!	c #F7F7F3",
		"9!	c #DFDFEB",
		":!	c #4242A0",
		";!	c #7373B8",
		"<!	c #070784",
		"=!	c #292994",
		">!	c #D7D7EA",
		"?!	c #FFFFFE",
		"@!	c #7A7A7A",
		"A!	c #F3F3EE",
		"B!	c #0F0F88",
		"C!	c #4848A4",
		"D!	c #B6B6DB",
		"E!	c #8686C3",
		"F!	c #1D1D8E",
		"G!	c #F1F1F4",
		"H!	c #FCFCF7",
		"I!	c #000103",
		"J!	c #FFFFFC",
		"K!	c #F0F0ED",
		"L!	c #0B0B85",
		"M!	c #F1F1F8",
		"N!	c #7979BC",
		"O!	c #F4F4EF",
		"P!	c #FDFDF8",
		"Q!	c #EAEAE8",
		"R!	c #AFAFD5",
		"S!	c #1C1C8E",
		"T!	c #FDFDFE",
		"U!	c #9898CC",
		"V!	c #ECECE8",
		"W!	c #EDEDE8",
		"X!	c #040482",
		"Y!	c #8C8CC6",
		"Z!	c #F8F8FC",
		"[!	c #D6D6EB",
		"]!	c #282894",
		"^!	c #F9F9F4",
		"_!	c #4141A0",
		"`!	c #4444A2",
		"a!	c #2C2C96",
		"b!	c #313198",
		"c!	c #3E3E9F",
		"d!	c #6767B3",
		"e!	c #7E7EBF",
		"f!	c #000206",
		"g!	c #5757AB",
		"h!	c #38389C",
		"i!	c #3F3F9F",
		"j!	c #5050A8",
		"k!	c #4646A3",
		"l!	c #6868B4",
		"m!	c #B0B0D8",
		"n!	c #EDEDE9",
		"o!	c #9999CC",
		"p!	c #080884",
		"q!	c #5151A8",
		"r!	c #4949A4",
		"s!	c #6060B0",
		"t!	c #A6A6D3",
		"u!	c #101088",
		"v!	c #AFAFD7",
		"w!	c #737373",
		"x!	c #F6F6F2",
		"y!	c #6565B2",
		"z!	c #8080C0",
		"{!	c #0D0D86",
		"|!	c #7676BB",
		"}!	c #4F4FA7",
		"~!	c #6C6CB6",
		" #	c #707070",
		"!#	c #F3F3EF",
		"##	c #F9F9F5",
		"$#	c #F5F5F0",
		"%#	c #000205",
		"&#	c #F7F7F2",
		"'#	c #F2F2F1",
		"(#	c #F3F3F2",
		")#	c #F4F4F3",
		"*#	c #FAFAF9",
		"+#	c #FFFFF7",
		",#	c #ECECEC",
		"-#	c #F6F6F6",
		".#	c #010307",
		"0#	c #4F4F4F",
		"1#	c #525252",
		"2#	c #575757",
		"3#	c #010306",
		"4#	c #39455C",
		"5#	c #35383E",
		"6#	c #2E3035",
		"7#	c #292B30",
		"8#	c #292B2F",
		"9#	c #191C21",
		":#	c #000102",
		"                                                                ",
		"                                                                ",
		"                                                                ",
		"# $ % & ' ( ) ) ) ) * ( ' ' + , - . 0 . . 1 1 . 1 2 3 4 5 6     ",
		"7 8 9 : : ; ; < = > > : : ? : : ? > ? @ A ? < A : ; > B C D E   ",
		"F G H H H H H H I I I I H H J J H H H J J ? K J L 9 M N O J P   ",
		"Q R S T T T T T T T T T T U T T T T T T T S V T W W U X U Y Z   ",
		"[ ] ^ _ _ ` ` a ` ` ` ` _ b _ _ a a a _ c d e f g h i j k 8 l   ",
		"B m m m m m m m m m m n o p q r s p t m u v w x m m m m m y z   ",
		"{ m m | | | | | | } ~  !| | | | | | !!#!$!%!%!&!| | '!m m L z   ",
		"[ m m | m m (!| )!*!| +!,!-!.!.!0!1!2!3!4!%!%!5!(!6!(!6!m = z   ",
		"7!m m (!(!(!|  !8!| 9!:!%!%!%!%!%!%!:!9!;!<!=!>!6!?!(!m m ; z   ",
		"@!m ?!(!(!(!| A!| 9!B!%!%!%!%!%!C!D!E!F!9!G!H!| | (!(!m m = I!  ",
		"[ m m (!J!J!+!K!+!:!%!%!%!%!%!L!M!m m N!:!+!O!P!| | (!m m ; I!  ",
		"@!m m | (!6!Q!J!R!%!%!%!%!%!%!S!T!m m U!%!,!| V!| | | J!m ; I!  ",
		"@!m m (!| | W!(!-!%!X!%!%!%!%!%!Y!Z![!]!%!-!| V!| | | | m : I!  ",
		"D m m (!| | ^!| _!%!U!%!%!%!%!%!%!$!%!%!%!_!| ^!| | | 6!m : I!  ",
		"D m m (!| | *!| _!%!U!%!%!`!a!b!c!d!e!0!%!_!| *!| | | 6!m : f!  ",
		"D m m (!| | V!| -!%!U!%!%!g!h!i!j!k!l!m!%!-!| V!| | | 6!m < f!  ",
		"D m m (!| | n!| ,!%!o!p!p!q!r!s!j!t!u!v!%!,!| n!| | | 6!m < f!  ",
		"w!m ?!(!(!(!| x!+!:!y!z!z!{!|!C!]!}!~!g!:!+!x!| | | | 6!m < f!  ",
		" #m ?!6!J!J!6!!#| 9!B!%!%!%!%!%!%!%!%!B!9!| !#| | | | 6!m ? f!  ",
		"I m '!| (!6!6!##$#| 9!:!%!%!%!%!%!%!:!9!| $# !| | | | 6!m ? %#  ",
		"I m J!J!6!| | | n!8!| +!,!-!_!_!-!,!+!| &#n!| | | | | J!m > %#  ",
		"w!m m ?!?!?!?!m m r '#(#?!?!?!?!?!?!)#(#*#?!?!?!?!?!?!m m < f!  ",
		"D m m m m m m | +#6!m m ,#q -#-#q ,#m m m m m m m m m '!m ? .#  ",
		"0#F Y 1#1#1#1#1#1#1#Y Y Y Y Y Y Y Y Y Y Y Y Y Y Y 1#1#1#2#Y 3#  ",
		"4#5#6#7#7#7#7#7#7#7#7#7#7#7#7#7#8#8#8#8#8#8#8#8#8#8#8#8#8#9#:#  ",
		"  ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !   ",
		"                                                                ",
		"                                                                ",
		"                                                                "
	}
	local appBitmap = wx.wxBitmap( appIconXpmData )
    local appIcon = wx.wxIcon()
    appIcon:CopyFromBitmap( appBitmap )

	return appIcon
end

-- ----------------------------------------------------------------------------
-- EVENT HANDLERS
-- ----------------------------------------------------------------------------
-- Open menu item event handler
function lExecutorGUI.OnOpen( event )
	local filename = ""
	if AppData.startupFilename then
		filename = AppData.startupFilename
		-- Clear the startupFileName so it isn't used again.
		AppData.startupFilename = nil
	else
		filename = wx.wxFileSelector( "Choose a Lua to open", AppData.lastOpenPath,
			"", ".lua", "Lua files (*.lua;*.lexe)|*.lua;*.lexe|All files (*.*)|*.*",
			wx.wxFD_FILE_MUST_EXIST )
	end

	if filename:len() > 0 then
		-- Cleanup script and GUI.
		--
		-- Clear the old script.
		AppData.script = nil
		-- Clear the old script environment.
		AppData.scriptEnvironment = {}
		-- Now collect the garbage.
		collectgarbage()
		-- Remove the pass/fail status so the GUI starts out fresh.
		lExecutorGUI.passFailStaticText:Hide()
		lExecutorGUI.panel:Layout()

		-- work with the file
		AppData.filename = filename

		-- Set the current directory to the running script.
		AppData.lastOpenPath = wx.wxPathOnly( AppData.filename )
		wx.wxSetWorkingDirectory( AppData.lastOpenPath )

		-- Clear the log.
		lExecutorGUI.logTextCtrl:Clear()
		-- Setup the arg table to be right when calling the loaded script.
		ReorganizeArgTable( AppData.filename )

		-- Compile and load the file.
		local errorMsg
		AppData.script, errorMsg = loadfile( filename )
		if errorMsg then
			lExecutorGUI.frame:SetStatusText( "File Loaded: <empty>" )
			wx.wxMessageBox( "Error during script loading.\n\n"..errorMsg, "Script Error Occured", wx.wxICON_ERROR )
			return
		end

		-- Setup the execution environment.
		setmetatable( AppData.scriptEnvironment, { __index = _G } )
		setfenv( AppData.script, AppData.scriptEnvironment )

		--Execute the script to initialize the script.
		local ret, err = pcall( AppData.script )
		if ret then
			-- Update GUI to reflect the script loaded.
			APP_NAME = AppData.scriptEnvironment.APP_NAME or APP_NAME
			lExecutorGUI.frame:SetTitle( APP_NAME )
			lExecutorGUI.frame:SetStatusText( "File Loaded: "..AppData.filename or "<empty>" )
		else
			lExecutorGUI.frame:SetStatusText( "File Loaded: <empty>" )
			wx.wxMessageBox( "Error during script inititalization.\n\n"..err, "Script Error Occured", wx.wxICON_ERROR )
		end
	end
end

-- Open menu item event handler
function lExecutorGUI.OnSaveLog( event )
	local filename = wx.wxFileSelector( "Choose a file to save", AppData.lastSavePath,
		"", ".txt", "Log files (*.log;*.txt)|*.log;*.txt|All files (*.*)|*.*",
		wx.wxFD_SAVE + wx.wxFD_OVERWRITE_PROMPT )

	if filename:len() > 0 then
		-- Work with the file.
		lExecutorGUI.logTextCtrl:SaveFile( filename )

		-- Clear the log.
		lExecutorGUI.logTextCtrl:Clear()

		-- Save path to AppData.
		AppData.lastSavePath = wx.wxPathOnly( filename )
	end
end

-- Build buttons event handler
function lExecutorGUI.OnExecuteClicked(event)
	local shouldRepeat = true

	print( "["..os.date().." - Execution started]" )

	while shouldRepeat do
		lExecutor.SetPassFailStatus( false, false ) -- hide the fail status

		-- Check if there is a main() function and call that now.
		if AppData.scriptEnvironment.main then
			AppData.scriptEnvironment.main()
		else
			if AppData.script then
				--Execute the script.
				local ret, err = pcall( AppData.script )
				if false == ret then
					wx.wxMessageBox( "Error during execution of the loaded script.\n\n"..err, "Script Error Occured", wx.wxICON_ERROR )
				end
			else
				wx.wxMessageBox( "Execution failed due to no script loaded.\n\nPlease use 'File->Open' (Ctrl+O) to open/load a script to execute.", "Script Error Occured", wx.wxICON_ERROR )
			end
		end

		-- Update the GUI.
		wx.wxYield()
		shouldRepeat = lExecutorGUI.repeatCheckBox:GetValue()
	end
end

-- Frame close event
function lExecutorGUI.OnClose( event )
	lExecutorGUI.ConfigSavePaths()

	lExecutorGUI.ConfigSaveFramePosition( lExecutorGUI.frame, "MainFrame" )
	lExecutorGUI.config:delete() -- always delete the config
	event:Skip()
end

-- Frame close event
function lExecutorGUI.OnExit( event )
	lExecutorGUI.frame:Close( true )
end

-- About dialog event handler
function lExecutorGUI.OnAbout( event )
	local info = wx.wxAboutDialogInfo()
    info:SetName( APP_NAME )
    info:SetVersion( APP_VERSION )
	info:SetIcon( GetAppIcon() )
	info:SetWebSite( "http://rjpcomputing.com" )
    info:SetDescription( "This program assists in running Lua scripts in a GUI." )
    info:SetCopyright( "Copyright © RJP Computing 2008" )

    wx.wxAboutBox(info)
end

-- ----------------------------------------------------------------------------
-- APPLICATION ENTRY POINT
--
-- Create a function to encapulate the code, not necessary, but it makes it
-- easier to debug in some cases.
-- ----------------------------------------------------------------------------
local function __main()
	lExecutorGUI.config = wx.wxFileConfig( "lExecutor", "APP")
	if lExecutorGUI.config then
		lExecutorGUI.config:SetRecordDefaults()
	end

    -- create the wxFrame window
    lExecutorGUI.frame = wx.wxFrame( wx.NULL,		-- no parent for toplevel windows
						wx.wxID_ANY,				-- don't need a wxWindow ID
                        APP_NAME,					-- caption on the frame
                        wx.wxDefaultPosition,		-- let system place the frame
                        wx.wxDefaultSize,			-- set the size of the frame
                        wx.wxDEFAULT_FRAME_STYLE )	-- use default frame styles

	-- Set the applications icon
    lExecutorGUI.frame:SetIcon( GetAppIcon() )

    -- create a single child window, wxWidgets will set the size to fill frame
    lExecutorGUI.panel = wx.wxPanel( lExecutorGUI.frame, wx.wxID_ANY )

    -- create a file menu
    local fileMenu = wx.wxMenu()
    fileMenu:Append( lExecutorGUI.ID_FILE_OPEN, "&Open\tCtrl+O", "Open makefile for viewing only" )
	fileMenu:AppendSeparator()
	fileMenu:Append( lExecutorGUI.ID_FILE_SAVE_LOG, "&Save Output\tCtrl+S", "Save output log to a text file" )
	fileMenu:AppendSeparator()
    fileMenu:Append( lExecutorGUI.ID_FILE_EXIT, "E&xit\tAlt+F4", "Quit the program" )

    -- create a help menu
    local helpMenu = wx.wxMenu()
    helpMenu:Append( lExecutorGUI.ID_HELP_ABOUT, "&About\tF1", "About the "..APP_NAME.." Application")

    -- create a menu bar and append the file and help menus
    local menuBar = wx.wxMenuBar()
    menuBar:Append( fileMenu, "&File" )
    menuBar:Append( helpMenu, "&Help" )

    -- attach the menu bar into the frame
    lExecutorGUI.frame:SetMenuBar( menuBar )

    -- create a simple status bar
    lExecutorGUI.frame:CreateStatusBar( 1, wx.wxST_SIZEGRIP )
    lExecutorGUI.frame:SetStatusText( "Welcome to "..APP_NAME.."." )

	-- Layout all the buttons using wxSizers
	local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )
	lExecutorGUI.logTextCtrl = wx.wxTextCtrl( lExecutorGUI.panel, lExecutorGUI.ID_LOG_TEXTCTRL, "",
		wx.wxDefaultPosition, wx.wxSize( 600,300 ), wx.wxTE_MULTILINE + wx.wxTE_DONTWRAP + wx.wxTE_READONLY )
	lExecutorGUI.executeButton = wx.wxButton( lExecutorGUI.panel, lExecutorGUI.ID_EXECUTE_BUTTON, "Execute" )
	lExecutorGUI.repeatCheckBox = wx.wxCheckBox( lExecutorGUI.panel, lExecutorGUI.ID_REPEAT_CHECKBOX, "Continuous" )
	mainSizer:Add( lExecutorGUI.logTextCtrl, 1, wx.wxALL + wx.wxEXPAND, 5 )
	lExecutorGUI.passFailStaticText = wx.wxStaticText( lExecutorGUI.panel, lExecutorGUI.ID_PASS_FAIL_STATIC_TEXT,
		"FAIL", wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxALIGN_CENTRE + wx.wxDOUBLE_BORDER )
	lExecutorGUI.passFailStaticText:Wrap( -1 )
	lExecutorGUI.passFailStaticText:SetFont( wx.wxFont( 28, 70, 90, 90, false ) )
	lExecutorGUI.passFailStaticText:SetBackgroundColour( wx.wxColour( 255, 0, 0 ) )
	lExecutorGUI.passFailStaticText:Hide()
	mainSizer:Add( lExecutorGUI.passFailStaticText, 0, wx.wxALL + wx.wxEXPAND, 5 );

	local sizer2 = wx.wxBoxSizer( wx.wxHORIZONTAL )
	sizer2:Add( lExecutorGUI.executeButton, 1, wx.wxALL + wx.wxEXPAND, 5 )
	sizer2:Add( lExecutorGUI.repeatCheckBox, 0, wx.wxALL + wx.wxEXPAND, 5 )
	mainSizer:Add( sizer2, 0, wx.wxEXPAND, 5 )
	lExecutorGUI.panel:SetSizer( mainSizer )
	mainSizer:SetSizeHints( lExecutorGUI.frame )

	-- Connect to the window event here.
	--
	lExecutorGUI.frame:Connect( wx.wxEVT_CLOSE_WINDOW, lExecutorGUI.OnClose )

	-- Connect menu handlers here.
	--
	-- connect the selection event of the open menu item
	lExecutorGUI.frame:Connect( lExecutorGUI.ID_FILE_OPEN, wx.wxEVT_COMMAND_MENU_SELECTED,
		lExecutorGUI.OnOpen )

	-- connect the selection event of the open menu item
	lExecutorGUI.frame:Connect( lExecutorGUI.ID_FILE_SAVE_LOG, wx.wxEVT_COMMAND_MENU_SELECTED,
		lExecutorGUI.OnSaveLog )

    -- connect the selection event of the exit menu item
	lExecutorGUI.frame:Connect( wx.wxID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
		lExecutorGUI.OnExit )

    -- connect the selection event of the about menu item
	lExecutorGUI.frame:Connect( wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        lExecutorGUI.OnAbout )

	-- Connect control event handlers here.
	--
	-- connect the build now buttons event
	lExecutorGUI.frame:Connect( lExecutorGUI.ID_EXECUTE_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        lExecutorGUI.OnExecuteClicked )

	-- Setup default behavior.
	--
	lExecutorGUI.executeButton:SetFocus()
	lExecutorGUI.executeButton:SetDefault()

	-- Restore the saved settings
	lExecutorGUI.ConfigRestorePaths()
	lExecutorGUI.ConfigRestoreFramePosition( lExecutorGUI.frame, "MainFrame" )

	-- show the frame window
    lExecutorGUI.frame:Show( true )

	-- Ask user to specify the script to load.
	lExecutorGUI.OnOpen()

    -- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
	-- otherwise the wxLua program will exit immediately.
	wx.wxGetApp():MainLoop()
end

__main()
