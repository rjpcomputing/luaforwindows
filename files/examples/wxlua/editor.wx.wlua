-------------------------------------------------------------------------=---
-- Name:        Editor.wx.lua
-- Purpose:     wxLua IDE
-- Author:      J Winwood
-- Created:     March 2002
-- Copyright:   (c) 2002-5 Lomtick Software. All rights reserved.
-- Licence:     wxWidgets licence
-------------------------------------------------------------------------=---

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-- Equivalent to C's "cond ? a : b", all terms will be evaluated
function iff(cond, a, b) if cond then return a else return b end end

-- Does the num have all the bits in value
function HasBit(value, num)
    for n = 32, 0, -1 do
        local b = 2^n
        local num_b = num - b
        local value_b = value - b
        if num_b >= 0 then
            num = num_b
        else
            return true -- already tested bits in num
        end
        if value_b >= 0 then
            value = value_b
        end
        if (num_b >= 0) and (value_b < 0) then
            return false
        end
    end

    return true
end

-- Generate a unique new wxWindowID
local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
function NewID()
    ID_IDCOUNTER = ID_IDCOUNTER + 1
    return ID_IDCOUNTER
end

-- File menu
local ID_NEW              = wx.wxID_NEW
local ID_OPEN             = wx.wxID_OPEN
local ID_CLOSE            = NewID()
local ID_SAVE             = wx.wxID_SAVE
local ID_SAVEAS           = wx.wxID_SAVEAS
local ID_SAVEALL          = NewID()
local ID_EXIT             = wx.wxID_EXIT
-- Edit menu
local ID_CUT              = wx.wxID_CUT
local ID_COPY             = wx.wxID_COPY
local ID_PASTE            = wx.wxID_PASTE
local ID_SELECTALL        = wx.wxID_SELECTALL
local ID_UNDO             = wx.wxID_UNDO
local ID_REDO             = wx.wxID_REDO
local ID_AUTOCOMPLETE     = NewID()
local ID_AUTOCOMPLETE_ENABLE = NewID()
local ID_COMMENT          = NewID()
local ID_FOLD             = NewID()
-- Find menu
local ID_FIND             = wx.wxID_FIND
local ID_FINDNEXT         = NewID()
local ID_FINDPREV         = NewID()
local ID_REPLACE          = NewID()
local ID_GOTOLINE         = NewID()
local ID_SORT             = NewID()
-- Debug menu
local ID_TOGGLEBREAKPOINT = NewID()
local ID_COMPILE          = NewID()
local ID_RUN              = NewID()
local ID_ATTACH_DEBUG     = NewID()
local ID_START_DEBUG      = NewID()
local ID_USECONSOLE       = NewID()

local ID_STOP_DEBUG       = NewID()
local ID_STEP             = NewID()
local ID_STEP_OVER        = NewID()
local ID_STEP_OUT         = NewID()
local ID_CONTINUE         = NewID()
local ID_BREAK            = NewID()
local ID_VIEWCALLSTACK    = NewID()
local ID_VIEWWATCHWINDOW  = NewID()
local ID_SHOWHIDEWINDOW   = NewID()
local ID_CLEAROUTPUT      = NewID()
local ID_DEBUGGER_PORT    = NewID()
-- Help menu
local ID_ABOUT            = wx.wxID_ABOUT
-- Watch window menu items
local ID_WATCH_LISTCTRL   = NewID()
local ID_ADDWATCH         = NewID()
local ID_EDITWATCH        = NewID()
local ID_REMOVEWATCH      = NewID()
local ID_EVALUATEWATCH    = NewID()

-- Markers for editor marker margin
local BREAKPOINT_MARKER         = 1
local BREAKPOINT_MARKER_VALUE   = 2 -- = 2^BREAKPOINT_MARKER
local CURRENT_LINE_MARKER       = 2
local CURRENT_LINE_MARKER_VALUE = 4 -- = 2^CURRENT_LINE_MARKER

-- ASCII values for common chars
local char_CR  = string.byte("\r")
local char_LF  = string.byte("\n")
local char_Tab = string.byte("\t")
local char_Sp  = string.byte(" ")

-- Global variables
programName      = nil    -- the name of the wxLua program to be used when starting debugger
editorApp        = wx.wxGetApp()

debuggerServer     = nil    -- wxLuaDebuggerServer object when debugging, else nil
debuggerServer_    = nil    -- temp wxLuaDebuggerServer object for deletion
debuggee_running   = false  -- true when the debuggee is running
debugger_destroy   = 0      -- > 0 if the debugger is to be destroyed in wxEVT_IDLE
debuggee_pid       = 0      -- pid of the debuggee process
debuggerPortNumber = 1551   -- the port # to use for debugging

-- wxWindow variables
frame            = nil    -- wxFrame the main top level window
splitter         = nil    -- wxSplitterWindow for the notebook and errorLog
notebook         = nil    -- wxNotebook of editors
errorLog         = nil    -- wxStyledTextCtrl log window for messages
watchWindow      = nil    -- the watchWindow, nil when not created
watchListCtrl    = nil    -- the child listctrl in the watchWindow

in_evt_focus     = false  -- true when in editor focus event to avoid recursion
openDocuments    = {}     -- open notebook editor documents[winId] = {
                          --   editor     = wxStyledTextCtrl,
                          --   index      = wxNotebook page index,
                          --   filePath   = full filepath, nil if not saved,
                          --   fileName   = just the filename,
                          --   modTime    = wxDateTime of disk file or nil,
                          --   isModified = bool is the document modified? }
ignoredFilesList = {}
editorID         = 100    -- window id to create editor pages with, incremented for new editors
exitingProgram   = false  -- are we currently exiting, ID_EXIT
autoCompleteEnable = true -- value of ID_AUTOCOMPLETE_ENABLE menu item
wxkeywords       = nil    -- a string of the keywords for scintilla of wxLua's wx.XXX items
font             = nil    -- fonts to use for the editor
fontItalic       = nil

findReplace = {
    dialog           = nil,   -- the wxDialog for find/replace
    replace          = false, -- is it a find or replace dialog
    fWholeWord       = false, -- match whole words
    fMatchCase       = false, -- case sensitive
    fDown            = true,  -- search downwards in doc
    fRegularExpr     = false, -- use regex
    fWrap            = false, -- search wraps around
    findTextArray    = {},    -- array of last entered find text
    findText         = "",    -- string to find
    replaceTextArray = {},    -- array of last entered replace text
    replaceText      = "",    -- string to replace find string with
    foundString      = false, -- was the string found for the last search

    -- HasText()                 is there a string to search for
    -- GetSelectedString()       get currently selected string if it's on one line
    -- FindString(reverse)       find the findText string
    -- Show(replace)             create the dialog
}

-- ----------------------------------------------------------------------------

-- Pick some reasonable fixed width fonts to use for the editor
if wx.__WXMSW__ then
    font       = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, false, "Andale Mono")
    fontItalic = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_ITALIC, wx.wxFONTWEIGHT_NORMAL, false, "Andale Mono")
else
    font       = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, false, "")
    fontItalic = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_ITALIC, wx.wxFONTWEIGHT_NORMAL, false, "")
end

-- ----------------------------------------------------------------------------
-- Initialize the wxConfig for loading/saving the preferences

config = wx.wxFileConfig("wxLuaIDE", "WXLUA")
if config then
    config:SetRecordDefaults()
end

-- ----------------------------------------------------------------------------
-- Create the wxFrame
-- ----------------------------------------------------------------------------
frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxLua")

statusBar = frame:CreateStatusBar( 4 )
local status_txt_width = statusBar:GetTextExtent("OVRW")
frame:SetStatusWidths({-1, status_txt_width, status_txt_width, status_txt_width*5})
frame:SetStatusText("Welcome to wxLua")

toolBar = frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_FLAT + wx.wxTB_DOCKABLE)
-- note: Ususally the bmp size isn't necessary, but the HELP icon is not the right size in MSW
local toolBmpSize = toolBar:GetToolBitmapSize()
toolBar:AddTool(ID_NEW,     "New",      wx.wxArtProvider.GetBitmap(wx.wxART_NORMAL_FILE, wx.wxART_MENU, toolBmpSize), "Create an empty document")
toolBar:AddTool(ID_OPEN,    "Open",     wx.wxArtProvider.GetBitmap(wx.wxART_FILE_OPEN, wx.wxART_MENU, toolBmpSize),   "Open an existing document")
toolBar:AddTool(ID_SAVE,    "Save",     wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE, wx.wxART_MENU, toolBmpSize),   "Save the current document")
toolBar:AddTool(ID_SAVEALL, "Save All", wx.wxArtProvider.GetBitmap(wx.wxART_NEW_DIR, wx.wxART_MENU, toolBmpSize),     "Save all documents")
toolBar:AddSeparator()
toolBar:AddTool(ID_CUT,   "Cut",   wx.wxArtProvider.GetBitmap(wx.wxART_CUT, wx.wxART_MENU, toolBmpSize),   "Cut the selection")
toolBar:AddTool(ID_COPY,  "Copy",  wx.wxArtProvider.GetBitmap(wx.wxART_COPY, wx.wxART_MENU, toolBmpSize),  "Copy the selection")
toolBar:AddTool(ID_PASTE, "Paste", wx.wxArtProvider.GetBitmap(wx.wxART_PASTE, wx.wxART_MENU, toolBmpSize), "Paste text from the clipboard")
toolBar:AddSeparator()
toolBar:AddTool(ID_UNDO, "Undo", wx.wxArtProvider.GetBitmap(wx.wxART_UNDO, wx.wxART_MENU, toolBmpSize), "Undo last edit")
toolBar:AddTool(ID_REDO, "Redo", wx.wxArtProvider.GetBitmap(wx.wxART_REDO, wx.wxART_MENU, toolBmpSize), "Redo last undo")
toolBar:AddSeparator()
toolBar:AddTool(ID_FIND,    "Find",    wx.wxArtProvider.GetBitmap(wx.wxART_FIND, wx.wxART_MENU, toolBmpSize), "Find text")
toolBar:AddTool(ID_REPLACE, "Replace", wx.wxArtProvider.GetBitmap(wx.wxART_FIND_AND_REPLACE, wx.wxART_MENU, toolBmpSize), "Find and replace text")
toolBar:Realize()

-- ----------------------------------------------------------------------------
-- Add the child windows to the frame

splitter = wx.wxSplitterWindow(frame, wx.wxID_ANY,
                               wx.wxDefaultPosition, wx.wxDefaultSize,
                               wx.wxSP_3DSASH)

notebook = wx.wxNotebook(splitter, wx.wxID_ANY,
                         wx.wxDefaultPosition, wx.wxDefaultSize,
                         wx.wxCLIP_CHILDREN)

notebook:Connect(wx.wxEVT_COMMAND_NOTEBOOK_PAGE_CHANGED,
        function (event)
            if not exitingProgram then
                SetEditorSelection(event:GetSelection())
            end
            event:Skip() -- skip to let page change
        end)

errorLog = wxstc.wxStyledTextCtrl(splitter, wx.wxID_ANY)
errorLog:Show(false)
errorLog:SetFont(font)
errorLog:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
errorLog:StyleClearAll()
errorLog:SetMarginWidth(1, 16) -- marker margin
errorLog:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL);
errorLog:MarkerDefine(CURRENT_LINE_MARKER, wxstc.wxSTC_MARK_ARROWS, wx.wxBLACK, wx.wxWHITE)
errorLog:SetReadOnly(true)

splitter:Initialize(notebook) -- split later to show errorLog

-- ----------------------------------------------------------------------------
-- wxConfig load/save preferences functions

function ConfigRestoreFramePosition(window, windowName)
    local path = config:GetPath()
    config:SetPath("/"..windowName)

    local _, s = config:Read("s", -1)
    local _, x = config:Read("x", 0)
    local _, y = config:Read("y", 0)
    local _, w = config:Read("w", 0)
    local _, h = config:Read("h", 0)

    if (s ~= -1) and (s ~= 2) then
        local clientX, clientY, clientWidth, clientHeight
        clientX, clientY, clientWidth, clientHeight = wx.wxClientDisplayRect()

        if x < clientX then x = clientX end
        if y < clientY then y = clientY end

        if w > clientWidth  then w = clientWidth end
        if h > clientHeight then h = clientHeight end

        window:SetSize(x, y, w, h)
    elseif s == 1 then
        window:Maximize(true)
    end

    config:SetPath(path)
end

function ConfigSaveFramePosition(window, windowName)
    local path = config:GetPath()
    config:SetPath("/"..windowName)

    local s    = 0
    local w, h = window:GetSizeWH()
    local x, y = window:GetPositionXY()

    if window:IsMaximized() then
        s = 1
    elseif window:IsIconized() then
        s = 2
    end

    config:Write("s", s)

    if s == 0 then
        config:Write("x", x)
        config:Write("y", y)
        config:Write("w", w)
        config:Write("h", h)
    end

    config:SetPath(path)
end

-- ----------------------------------------------------------------------------
-- Get/Set notebook editor page, use nil for current page, returns nil if none
function GetEditor(selection)
    local editor = nil
    if selection == nil then
        selection = notebook:GetSelection()
    end
    if (selection >= 0) and (selection < notebook:GetPageCount()) then
        editor = notebook:GetPage(selection):DynamicCast("wxStyledTextCtrl")
    end
    return editor
end

-- init new notebook page selection, use nil for current page
function SetEditorSelection(selection)
    local editor = GetEditor(selection)
    if editor then
        editor:SetFocus()
        editor:SetSTCFocus(true)
        IsFileAlteredOnDisk(editor)
    end
    UpdateStatusText(editor) -- update even if nil
end

-- ----------------------------------------------------------------------------
-- Update the statusbar text of the frame using the given editor.
--  Only update if the text has changed.
statusTextTable = { "OVR?", "R/O?", "Cursor Pos" }

function UpdateStatusText(editor)
    local texts = { "", "", "" }
    if frame and editor then
        local pos  = editor:GetCurrentPos()
        local line = editor:LineFromPosition(pos)
        local col  = 1 + pos - editor:PositionFromLine(line)

        texts = { iff(editor:GetOvertype(), "OVR", "INS"),
                  iff(editor:GetReadOnly(), "R/O", "R/W"),
                  "Ln "..tostring(line + 1).." Col "..tostring(col) }
    end

    if frame then
        for n = 1, 3 do
            if (texts[n] ~= statusTextTable[n]) then
                frame:SetStatusText(texts[n], n)
                statusTextTable[n] = texts[n]
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Get file modification time, returns a wxDateTime (check IsValid) or nil if
--   the file doesn't exist
function GetFileModTime(filePath)
    if filePath and (string.len(filePath) > 0) then
        local fn = wx.wxFileName(filePath)
        if fn:FileExists() then
            return fn:GetModificationTime()
        end
    end

    return nil
end

-- Check if file is altered, show dialog to reload it
function IsFileAlteredOnDisk(editor)
    if not editor then return end

    local id = editor:GetId()
    if openDocuments[id] then
        local filePath   = openDocuments[id].filePath
        local fileName   = openDocuments[id].fileName
        local oldModTime = openDocuments[id].modTime

        if filePath and (string.len(filePath) > 0) and oldModTime and oldModTime:IsValid() then
            local modTime = GetFileModTime(filePath)
            if modTime == nil then
                openDocuments[id].modTime = nil
                wx.wxMessageBox(fileName.." is no longer on the disk.",
                                "wxLua Message",
                                wx.wxOK + wx.wxCENTRE, frame)
            elseif modTime:IsValid() and oldModTime:IsEarlierThan(modTime) then
                local ret = wx.wxMessageBox(fileName.." has been modified on disk.\nDo you want to reload it?",
                                            "wxLua Message",
                                            wx.wxYES_NO + wx.wxCENTRE, frame)
                if ret ~= wx.wxYES or LoadFile(filePath, editor, true) then
                    openDocuments[id].modTime = nil
                end
            end
        end
    end
end

-- Set if the document is modified and update the notebook page text
function SetDocumentModified(id, modified)
    local pageText = openDocuments[id].fileName or "untitled.lua"

    if modified then
        pageText = "* "..pageText
    end

    openDocuments[id].isModified = modified
    notebook:SetPageText(openDocuments[id].index, pageText)
end

-- ----------------------------------------------------------------------------
-- Create an editor and add it to the notebook
function CreateEditor(name)
    local editor = wxstc.wxStyledTextCtrl(notebook, editorID,
                                          wx.wxDefaultPosition, wx.wxDefaultSize,
                                          wx.wxSUNKEN_BORDER)

    editorID = editorID + 1 -- increment so they're always unique

    editor:SetBufferedDraw(true)
    editor:StyleClearAll()

    editor:SetFont(font)
    editor:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
    for i = 0, 32 do
        editor:StyleSetFont(i, font)
    end

    editor:StyleSetForeground(0,  wx.wxColour(128, 128, 128)) -- White space
    editor:StyleSetForeground(1,  wx.wxColour(0,   127, 0))   -- Block Comment
    editor:StyleSetFont(1, fontItalic)
    --editor:StyleSetUnderline(1, false)
    editor:StyleSetForeground(2,  wx.wxColour(0,   127, 0))   -- Line Comment
    editor:StyleSetFont(2, fontItalic)                        -- Doc. Comment
    --editor:StyleSetUnderline(2, false)
    editor:StyleSetForeground(3,  wx.wxColour(127, 127, 127)) -- Number
    editor:StyleSetForeground(4,  wx.wxColour(0,   127, 127)) -- Keyword
    editor:StyleSetForeground(5,  wx.wxColour(0,   0,   127)) -- Double quoted string
    editor:StyleSetBold(5,  true)
    --editor:StyleSetUnderline(5, false)
    editor:StyleSetForeground(6,  wx.wxColour(127, 0,   127)) -- Single quoted string
    editor:StyleSetForeground(7,  wx.wxColour(127, 0,   127)) -- not used
    editor:StyleSetForeground(8,  wx.wxColour(0,   127, 127)) -- Literal strings
    editor:StyleSetForeground(9,  wx.wxColour(127, 127, 0))  -- Preprocessor
    editor:StyleSetForeground(10, wx.wxColour(0,   0,   0))   -- Operators
    --editor:StyleSetBold(10, true)
    editor:StyleSetForeground(11, wx.wxColour(0,   0,   0))   -- Identifiers
    editor:StyleSetForeground(12, wx.wxColour(0,   0,   0))   -- Unterminated strings
    editor:StyleSetBackground(12, wx.wxColour(224, 192, 224))
    editor:StyleSetBold(12, true)
    editor:StyleSetEOLFilled(12, true)

    editor:StyleSetForeground(13, wx.wxColour(0,   0,  95))   -- Keyword 2 highlighting styles
    editor:StyleSetForeground(14, wx.wxColour(0,   95, 0))    -- Keyword 3
    editor:StyleSetForeground(15, wx.wxColour(127, 0,  0))    -- Keyword 4
    editor:StyleSetForeground(16, wx.wxColour(127, 0,  95))   -- Keyword 5
    editor:StyleSetForeground(17, wx.wxColour(35,  95, 175))  -- Keyword 6
    editor:StyleSetForeground(18, wx.wxColour(0,   127, 127)) -- Keyword 7
    editor:StyleSetBackground(18, wx.wxColour(240, 255, 255)) -- Keyword 8

    editor:StyleSetForeground(19, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(19, wx.wxColour(224, 255, 255))
    editor:StyleSetForeground(20, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(20, wx.wxColour(192, 255, 255))
    editor:StyleSetForeground(21, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(21, wx.wxColour(176, 255, 255))
    editor:StyleSetForeground(22, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(22, wx.wxColour(160, 255, 255))
    editor:StyleSetForeground(23, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(23, wx.wxColour(144, 255, 255))
    editor:StyleSetForeground(24, wx.wxColour(0,   127, 127))
    editor:StyleSetBackground(24, wx.wxColour(128, 155, 255))

    editor:StyleSetForeground(32, wx.wxColour(224, 192, 224))  -- Line number
    editor:StyleSetBackground(33, wx.wxColour(192, 192, 192))  -- Brace highlight
    editor:StyleSetForeground(34, wx.wxColour(0,   0,   255))
    editor:StyleSetBold(34, true)                              -- Brace incomplete highlight
    editor:StyleSetForeground(35, wx.wxColour(255, 0,   0))
    editor:StyleSetBold(35, true)                              -- Indentation guides
    editor:StyleSetForeground(37, wx.wxColour(192, 192, 192))
    editor:StyleSetBackground(37, wx.wxColour(255, 255, 255))

    editor:SetUseTabs(false)
    editor:SetTabWidth(4)
    editor:SetIndent(4)
    editor:SetIndentationGuides(true)

    editor:SetVisiblePolicy(wxstc.wxSTC_VISIBLE_SLOP, 3)
    --editor:SetXCaretPolicy(wxstc.wxSTC_CARET_SLOP, 10)
    --editor:SetYCaretPolicy(wxstc.wxSTC_CARET_SLOP, 3)

    editor:SetMarginWidth(0, editor:TextWidth(32, "99999_")) -- line # margin

    editor:SetMarginWidth(1, 16) -- marker margin
    editor:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginSensitive(1, true)

    editor:MarkerDefine(BREAKPOINT_MARKER,   wxstc.wxSTC_MARK_ROUNDRECT, wx.wxWHITE, wx.wxRED)
    editor:MarkerDefine(CURRENT_LINE_MARKER, wxstc.wxSTC_MARK_ARROW,     wx.wxBLACK, wx.wxGREEN)

    editor:SetMarginWidth(2, 16) -- fold margin
    editor:SetMarginType(2, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginMask(2, wxstc.wxSTC_MASK_FOLDERS)
    editor:SetMarginSensitive(2, true)

    editor:SetFoldFlags(wxstc.wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED +
                        wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED)

    editor:SetProperty("fold", "1")
    editor:SetProperty("fold.compact", "1")
    editor:SetProperty("fold.comment", "1")

    local grey = wx.wxColour(128, 128, 128)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPEN,    wxstc.wxSTC_MARK_BOXMINUS, wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDER,        wxstc.wxSTC_MARK_BOXPLUS,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERSUB,     wxstc.wxSTC_MARK_VLINE,    wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERTAIL,    wxstc.wxSTC_MARK_LCORNER,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEREND,     wxstc.wxSTC_MARK_BOXPLUSCONNECTED,  wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPENMID, wxstc.wxSTC_MARK_BOXMINUSCONNECTED, wx.wxWHITE, grey)
    editor:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERMIDTAIL, wxstc.wxSTC_MARK_TCORNER,  wx.wxWHITE, grey)
    grey:delete()

    editor:Connect(wxstc.wxEVT_STC_MARGINCLICK,
            function (event)
                local line = editor:LineFromPosition(event:GetPosition())
                local margin = event:GetMargin()
                if margin == 1 then
                    ToggleDebugMarker(editor, line)
                elseif margin == 2 then
                    if wx.wxGetKeyState(wx.WXK_SHIFT) and wx.wxGetKeyState(wx.WXK_CONTROL) then
                        FoldSome()
                    else
                        local level = editor:GetFoldLevel(line)
                        if HasBit(level, wxstc.wxSTC_FOLDLEVELHEADERFLAG) then
                            editor:ToggleFold(line)
                        end
                    end
                end
            end)

    editor:Connect(wxstc.wxEVT_STC_CHARADDED,
            function (event)
                -- auto-indent
                local ch = event:GetKey()
                if (ch == char_CR) or (ch == char_LF) then
                    local pos = editor:GetCurrentPos()
                    local line = editor:LineFromPosition(pos)

                    if (line > 0) and (editor:LineLength(line) == 0) then
                        local indent = editor:GetLineIndentation(line - 1)
                        if indent > 0 then
                            editor:SetLineIndentation(line, indent)
                            editor:GotoPos(pos + indent)
                        end
                    end
                elseif autoCompleteEnable then -- code completion prompt
                    local pos = editor:GetCurrentPos()
                    local start_pos = editor:WordStartPosition(pos, true)
                    -- must have "wx.X" otherwise too many items
                    if (pos - start_pos > 0) and (start_pos > 2) then
                        local range = editor:GetTextRange(start_pos-3, start_pos)
                        if range == "wx." then
                            local commandEvent = wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED,
                                                                   ID_AUTOCOMPLETE)
                            wx.wxPostEvent(frame, commandEvent)
                        end
                    end
                end
            end)

    editor:Connect(wxstc.wxEVT_STC_USERLISTSELECTION,
            function (event)
                local pos = editor:GetCurrentPos()
                local start_pos = editor:WordStartPosition(pos, true)
                editor:SetSelection(start_pos, pos)
                editor:ReplaceSelection(event:GetText())
            end)

    editor:Connect(wxstc.wxEVT_STC_SAVEPOINTREACHED,
            function (event)
                SetDocumentModified(editor:GetId(), false)
            end)

    editor:Connect(wxstc.wxEVT_STC_SAVEPOINTLEFT,
            function (event)
                SetDocumentModified(editor:GetId(), true)
            end)

    editor:Connect(wxstc.wxEVT_STC_UPDATEUI,
            function (event)
                UpdateStatusText(editor)
            end)

    editor:Connect(wx.wxEVT_SET_FOCUS,
            function (event)
                event:Skip()
                if in_evt_focus or exitingProgram then return end
                in_evt_focus = true
                IsFileAlteredOnDisk(editor)
                in_evt_focus = false
            end)

    if notebook:AddPage(editor, name, true) then
        local id            = editor:GetId()
        local document      = {}
        document.editor     = editor
        document.index      = notebook:GetSelection()
        document.fileName   = nil
        document.filePath   = nil
        document.modTime    = nil
        document.isModified = false
        openDocuments[id]   = document
    end

    return editor
end

function IsLuaFile(filePath)
    return filePath and (string.len(filePath) > 4) and
           (string.lower(string.sub(filePath, -4)) == ".lua")
end

function SetupKeywords(editor, useLuaParser)
    if useLuaParser then
        editor:SetLexer(wxstc.wxSTC_LEX_LUA)

        -- Note: these keywords are shamelessly ripped from scite 1.68
        editor:SetKeyWords(0,
            [[and break do else elseif end false for function if
            in local nil not or repeat return then true until while]])
        editor:SetKeyWords(1,
            [[_VERSION assert collectgarbage dofile error gcinfo loadfile loadstring
            print rawget rawset require tonumber tostring type unpack]])
        editor:SetKeyWords(2,
            [[_G getfenv getmetatable ipairs loadlib next pairs pcall
            rawequal setfenv setmetatable xpcall
            string table math coroutine io os debug
            load module select]])
        editor:SetKeyWords(3,
            [[string.byte string.char string.dump string.find string.len
            string.lower string.rep string.sub string.upper string.format string.gfind string.gsub
            table.concat table.foreach table.foreachi table.getn table.sort table.insert table.remove table.setn
            math.abs math.acos math.asin math.atan math.atan2 math.ceil math.cos math.deg math.exp
            math.floor math.frexp math.ldexp math.log math.log10 math.max math.min math.mod
            math.pi math.pow math.rad math.random math.randomseed math.sin math.sqrt math.tan
            string.gmatch string.match string.reverse table.maxn
            math.cosh math.fmod math.modf math.sinh math.tanh math.huge]])
        editor:SetKeyWords(4,
            [[coroutine.create coroutine.resume coroutine.status
            coroutine.wrap coroutine.yield
            io.close io.flush io.input io.lines io.open io.output io.read io.tmpfile io.type io.write
            io.stdin io.stdout io.stderr
            os.clock os.date os.difftime os.execute os.exit os.getenv os.remove os.rename
            os.setlocale os.time os.tmpname
            coroutine.running package.cpath package.loaded package.loadlib package.path
            package.preload package.seeall io.popen
            debug.debug debug.getfenv debug.gethook debug.getinfo debug.getlocal
            debug.getmetatable debug.getregistry debug.getupvalue debug.setfenv
            debug.sethook debug.setlocal debug.setmetatable debug.setupvalue debug.traceback]])

        -- Get the items in the global "wx" table for autocompletion
        if not wxkeywords then
            local keyword_table = {}
            for index, value in pairs(wx) do
                table.insert(keyword_table, "wx."..index.." ")
            end

            table.sort(keyword_table)
            wxkeywords = table.concat(keyword_table)
        end

        editor:SetKeyWords(5, wxkeywords)
    else
        editor:SetLexer(wxstc.wxSTC_LEX_NULL)
        editor:SetKeyWords(0, "")
    end

    editor:Colourise(0, -1)
end

function CreateAutoCompList(key_) -- much faster than iterating the wx. table
    local key = "wx."..key_;
    local a, b = string.find(wxkeywords, key, 1, 1)
    local key_list = ""

    while a do
        local c, d = string.find(wxkeywords, " ", b, 1)
        key_list = key_list..string.sub(wxkeywords, a+3, c or -1)
        a, b = string.find(wxkeywords, key, d, 1)
    end

    return key_list
end

-- ---------------------------------------------------------------------------
-- Create the watch window

function ProcessWatches()
    if watchListCtrl and debuggerServer then
        for idx = 0, watchListCtrl:GetItemCount() - 1 do
            local expression = watchListCtrl:GetItemText(idx)
            debuggerServer:EvaluateExpr(idx, expression)
        end
    end
end

function CloseWatchWindow()
    if watchWindow then
        watchListCtrl = nil
        watchWindow:Destroy()
        watchWindow = nil
    end
end

function CreateWatchWindow()
    local width = 180
    watchWindow = wx.wxFrame(frame, wx.wxID_ANY, "wxLua Watch Window",
                             wx.wxDefaultPosition, wx.wxSize(width, 160))

    local watchMenu = wx.wxMenu{
            { ID_ADDWATCH,      "&Add Watch"        },
            { ID_EDITWATCH,     "&Edit Watch\tF2"   },
            { ID_REMOVEWATCH,   "&Remove Watch"     },
            { ID_EVALUATEWATCH, "Evaluate &Watches" }}

    local watchMenuBar = wx.wxMenuBar()
    watchMenuBar:Append(watchMenu, "&Watches")
    watchWindow:SetMenuBar(watchMenuBar)

    watchListCtrl = wx.wxListCtrl(watchWindow, ID_WATCH_LISTCTRL,
                                  wx.wxDefaultPosition, wx.wxDefaultSize,
                                  wx.wxLC_REPORT + wx.wxLC_EDIT_LABELS)

    local info = wx.wxListItem()
    info:SetMask(wx.wxLIST_MASK_TEXT + wx.wxLIST_MASK_WIDTH)
    info:SetText("Expression")
    info:SetWidth(width / 2)
    watchListCtrl:InsertColumn(0, info)

    info:SetText("Value")
    info:SetWidth(width / 2)
    watchListCtrl:InsertColumn(1, info)

    watchWindow:CentreOnParent()
    ConfigRestoreFramePosition(watchWindow, "WatchWindow")
    watchWindow:Show(true)

    local function FindSelectedWatchItem()
        local count = watchListCtrl:GetSelectedItemCount()
        if count > 0 then
            for idx = 0, watchListCtrl:GetItemCount() - 1 do
                if watchListCtrl:GetItemState(idx, wx.wxLIST_STATE_FOCUSED) ~= 0 then
                    return idx
                end
            end
        end
        return -1
    end

    watchWindow:Connect( wx.wxEVT_CLOSE_WINDOW,
            function (event)
                ConfigSaveFramePosition(watchWindow, "WatchWindow")
                watchWindow = nil
                watchListCtrl = nil
                event:Skip()
            end)

    watchWindow:Connect(ID_ADDWATCH, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local row = watchListCtrl:InsertItem(watchListCtrl:GetItemCount(), "Expr")
                watchListCtrl:SetItem(row, 0, "Expr")
                watchListCtrl:SetItem(row, 1, "Value")
                watchListCtrl:EditLabel(row)
            end)

    watchWindow:Connect(ID_EDITWATCH, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local row = FindSelectedWatchItem()
                if row >= 0 then
                    watchListCtrl:EditLabel(row)
                end
            end)
    watchWindow:Connect(ID_EDITWATCH, wx.wxEVT_UPDATE_UI,
            function (event)
                event:Enable(watchListCtrl:GetSelectedItemCount() > 0)
            end)

    watchWindow:Connect(ID_REMOVEWATCH, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                local row = FindSelectedWatchItem()
                if row >= 0 then
                    watchListCtrl:DeleteItem(row)
                end
            end)
    watchWindow:Connect(ID_REMOVEWATCH, wx.wxEVT_UPDATE_UI,
            function (event)
                event:Enable(watchListCtrl:GetSelectedItemCount() > 0)
            end)

    watchWindow:Connect(ID_EVALUATEWATCH, wx.wxEVT_COMMAND_MENU_SELECTED,
            function (event)
                ProcessWatches()
            end)
    watchWindow:Connect(ID_EVALUATEWATCH, wx.wxEVT_UPDATE_UI,
            function (event)
                event:Enable(watchListCtrl:GetItemCount() > 0)
            end)

    watchListCtrl:Connect(wx.wxEVT_COMMAND_LIST_END_LABEL_EDIT,
            function (event)
                watchListCtrl:SetItem(event:GetIndex(), 0, event:GetText())
                ProcessWatches()
                event:Skip()
            end)
end

-- ---------------------------------------------------------------------------
-- Create the File menu and attach the callback functions

-- force all the wxEVT_UPDATE_UI handlers to be called
function UpdateUIMenuItems()
    if frame and frame:GetMenuBar() then
        for n = 0, frame:GetMenuBar():GetMenuCount()-1 do
            frame:GetMenuBar():GetMenu(n):UpdateUI()
        end
    end
end

menuBar = wx.wxMenuBar()
fileMenu = wx.wxMenu({
        { ID_NEW,     "&New\tCtrl-N",        "Create an empty document" },
        { ID_OPEN,    "&Open...\tCtrl-O",    "Open an existing document" },
        { ID_CLOSE,   "&Close page\tCtrl+W", "Close the current editor window" },
        { },
        { ID_SAVE,    "&Save\tCtrl-S",       "Save the current document" },
        { ID_SAVEAS,  "Save &As...\tAlt-S",  "Save the current document to a file with a new name" },
        { ID_SAVEALL, "Save A&ll...\tCtrl-Shift-S", "Save all open documents" },
        { },
        { ID_EXIT,    "E&xit\tAlt-X",        "Exit Program" }})
menuBar:Append(fileMenu, "&File")

function NewFile(event)
    local editor = CreateEditor("untitled.lua")
    SetupKeywords(editor, true)
end

frame:Connect(ID_NEW, wx.wxEVT_COMMAND_MENU_SELECTED, NewFile)

-- Find an editor page that hasn't been used at all, eg. an untouched NewFile()
function FindDocumentToReuse()
    local editor = nil
    for id, document in pairs(openDocuments) do
        if (document.editor:GetLength() == 0) and
           (not document.isModified) and (not document.filePath) and
           not (document.editor:GetReadOnly() == true) then
            editor = document.editor
            break
        end
    end
    return editor
end

function LoadFile(filePath, editor, file_must_exist)
    local file_text = ""
    local handle = io.open(filePath, "rb")
    if handle then
        file_text = handle:read("*a")
        handle:close()
    elseif file_must_exist then
        return nil
    end

    if not editor then
        editor = FindDocumentToReuse()
    end
    if not editor then
        editor = CreateEditor(wx.wxFileName(filePath):GetFullName() or "untitled.lua")
     end

    editor:Clear()
    editor:ClearAll()
    SetupKeywords(editor, IsLuaFile(filePath))
    editor:MarkerDeleteAll(BREAKPOINT_MARKER)
    editor:MarkerDeleteAll(CURRENT_LINE_MARKER)
    editor:AppendText(file_text)
    editor:EmptyUndoBuffer()
    local id = editor:GetId()
    openDocuments[id].filePath = filePath
    openDocuments[id].fileName = wx.wxFileName(filePath):GetFullName()
    openDocuments[id].modTime = GetFileModTime(filePath)
    SetDocumentModified(id, false)
    editor:Colourise(0, -1)

    return editor
end

function OpenFile(event)
    local fileDialog = wx.wxFileDialog(frame, "Open file",
                                       "",
                                       "",
                                       "Lua files (*.lua)|*.lua|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
        if not LoadFile(fileDialog:GetPath(), nil, true) then
            wx.wxMessageBox("Unable to load file '"..fileDialog:GetPath().."'.",
                            "wxLua Error",
                            wx.wxOK + wx.wxCENTRE, frame)
        end
    end
    fileDialog:Destroy()
end
frame:Connect(ID_OPEN, wx.wxEVT_COMMAND_MENU_SELECTED, OpenFile)

-- save the file to filePath or if filePath is nil then call SaveFileAs
function SaveFile(editor, filePath)
    if not filePath then
        return SaveFileAs(editor)
    else
        local backPath = filePath..".bak"
        os.remove(backPath)
        os.rename(filePath, backPath)

        local handle = io.open(filePath, "wb")
        if handle then
            local st = editor:GetText()
            handle:write(st)
            handle:close()
            editor:EmptyUndoBuffer()
            local id = editor:GetId()
            openDocuments[id].filePath = filePath
            openDocuments[id].fileName = wx.wxFileName(filePath):GetFullName()
            openDocuments[id].modTime  = GetFileModTime(filePath)
            SetDocumentModified(id, false)
            return true
        else
            wx.wxMessageBox("Unable to save file '"..filePath.."'.",
                            "wxLua Error Saving",
                            wx.wxOK + wx.wxCENTRE, frame)
        end
    end

    return false
end

frame:Connect(ID_SAVE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor   = GetEditor()
            local id       = editor:GetId()
            local filePath = openDocuments[id].filePath
            SaveFile(editor, filePath)
        end)

frame:Connect(ID_SAVE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            if editor then
                local id = editor:GetId()
                if openDocuments[id] then
                    event:Enable(openDocuments[id].isModified)
                end
            end
        end)

function SaveFileAs(editor)
    local id       = editor:GetId()
    local saved    = false
    local fn       = wx.wxFileName(openDocuments[id].filePath or "")
    fn:Normalize() -- want absolute path for dialog

    local fileDialog = wx.wxFileDialog(frame, "Save file as",
                                       fn:GetPath(),
                                       fn:GetFullName(),
                                       "Lua files (*.lua)|*.lua|Text files (*.txt)|*.txt|All files (*)|*",
                                       wx.wxSAVE)

    if fileDialog:ShowModal() == wx.wxID_OK then
        local filePath = fileDialog:GetPath()

        if SaveFile(editor, filePath) then
            SetupKeywords(editor, IsLuaFile(filePath))
            saved = true
        end
    end

    fileDialog:Destroy()
    return saved
end

frame:Connect(ID_SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            SaveFileAs(editor)
        end)
frame:Connect(ID_SAVEAS, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor ~= nil)
        end)

function SaveAll()
    for id, document in pairs(openDocuments) do
        local editor   = document.editor
        local filePath = document.filePath

        if document.isModified then
            SaveFile(editor, filePath) -- will call SaveFileAs if necessary
        end
    end
end

frame:Connect(ID_SAVEALL, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            SaveAll()
        end)

frame:Connect(ID_SAVEALL, wx.wxEVT_UPDATE_UI,
        function (event)
            local atLeastOneModifiedDocument = false
            for id, document in pairs(openDocuments) do
                if document.isModified then
                    atLeastOneModifiedDocument = true
                    break
                end
            end
            event:Enable(atLeastOneModifiedDocument)
        end)

function RemovePage(index)
    local  prevIndex = nil
    local  nextIndex = nil
    local newOpenDocuments = {}

    for id, document in pairs(openDocuments) do
        if document.index < index then
            newOpenDocuments[id] = document
            prevIndex = document.index
        elseif document.index == index then
            document.editor:Destroy()
        elseif document.index > index then
            document.index = document.index - 1
            if nextIndex == nil then
                nextIndex = document.index
            end
            newOpenDocuments[id] = document
        end
    end

    notebook:RemovePage(index)
    openDocuments = newOpenDocuments

    if nextIndex then
        notebook:SetSelection(nextIndex)
    elseif prevIndex then
        notebook:SetSelection(prevIndex)
    end

    SetEditorSelection(nil) -- will use notebook GetSelection to update
end

-- Show a dialog to save a file before closing editor.
--   returns wxID_YES, wxID_NO, or wxID_CANCEL if allow_cancel
function SaveModifiedDialog(editor, allow_cancel)
    local result   = wx.wxID_NO
    local id       = editor:GetId()
    local document = openDocuments[id]
    local filePath = document.filePath
    local fileName = document.fileName
    if document.isModified then
        local message
        if fileName then
            message = "Save changes to '"..fileName.."' before exiting?"
        else
            message = "Save changes to 'untitled' before exiting?"
        end
        local dlg_styles = wx.wxYES_NO + wx.wxCENTRE + wx.wxICON_QUESTION
        if allow_cancel then dlg_styles = dlg_styles + wx.wxCANCEL end
        local dialog = wx.wxMessageDialog(frame, message,
                                          "Save Changes?",
                                          dlg_styles)
        result = dialog:ShowModal()
        dialog:Destroy()
        if result == wx.wxID_YES then
            SaveFile(editor, filePath)
        end
    end

    return result
end

frame:Connect(ID_CLOSE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            local id     = editor:GetId()
            if SaveModifiedDialog(editor, true) ~= wx.wxID_CANCEL then
                RemovePage(openDocuments[id].index)
            end
        end)

frame:Connect(ID_CLOSE, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable((GetEditor() ~= nil) and (debuggerServer == nil))
        end)

function SaveOnExit(allow_cancel)
    for id, document in pairs(openDocuments) do
        if (SaveModifiedDialog(document.editor, allow_cancel) == wx.wxID_CANCEL) then
            return false
        end

        document.isModified = false
    end

    return true
end

frame:Connect( ID_EXIT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if not SaveOnExit(true) then return end
            frame:Close() -- will handle wxEVT_CLOSE_WINDOW
            CloseWatchWindow()
        end)

-- ---------------------------------------------------------------------------
-- Create the Edit menu and attach the callback functions

editMenu = wx.wxMenu{
        { ID_CUT,       "Cu&t\tCtrl-X",        "Cut selected text to clipboard" },
        { ID_COPY,      "&Copy\tCtrl-C",       "Copy selected text to the clipboard" },
        { ID_PASTE,     "&Paste\tCtrl-V",      "Insert clipboard text at cursor" },
        { ID_SELECTALL, "Select A&ll\tCtrl-A", "Select all text in the editor" },
        { },
        { ID_UNDO,      "&Undo\tCtrl-Z",       "Undo the last action" },
        { ID_REDO,      "&Redo\tCtrl-Y",       "Redo the last action undone" },
        { },
        { ID_AUTOCOMPLETE,        "Complete &Identifier\tCtrl+K", "Complete the current identifier" },
        { ID_AUTOCOMPLETE_ENABLE, "Auto complete Identifiers",    "Auto complete while typing", wx.wxITEM_CHECK },
        { },
        { ID_COMMENT, "C&omment/Uncomment\tCtrl-Q", "Comment or uncomment current or selected lines"},
        { },
        { ID_FOLD,    "&Fold/Unfold all\tF12", "Fold or unfold all code folds"} }
menuBar:Append(editMenu, "&Edit")

editMenu:Check(ID_AUTOCOMPLETE_ENABLE, autoCompleteEnable)

function OnUpdateUIEditMenu(event) -- enable if there is a valid focused editor
    local editor = GetEditor()
    event:Enable(editor ~= nil)
end

function OnEditMenu(event)
    local menu_id = event:GetId()
    local editor = GetEditor()
    if editor == nil then return end

    if     menu_id == ID_CUT       then editor:Cut()
    elseif menu_id == ID_COPY      then editor:Copy()
    elseif menu_id == ID_PASTE     then editor:Paste()
    elseif menu_id == ID_SELECTALL then editor:SelectAll()
    elseif menu_id == ID_UNDO      then editor:Undo()
    elseif menu_id == ID_REDO      then editor:Redo()
    end
end

frame:Connect(ID_CUT, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_CUT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_COPY, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_COPY, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_PASTE, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_PASTE, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            -- buggy GTK clipboard runs eventloop and can generate asserts
            event:Enable(editor and (wx.__WXGTK__ or editor:CanPaste()))
        end)

frame:Connect(ID_SELECTALL, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_SELECTALL, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_UNDO, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_UNDO, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor and editor:CanUndo())
        end)

frame:Connect(ID_REDO, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditMenu)
frame:Connect(ID_REDO, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable(editor and editor:CanRedo())
        end)

frame:Connect(ID_AUTOCOMPLETE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            if (editor == nil) then return end
            local pos = editor:GetCurrentPos()
            local start_pos = editor:WordStartPosition(pos, true)
            -- must have "wx.XX" otherwise too many items
            if (pos - start_pos > 2) and (start_pos > 2) then
                local range = editor:GetTextRange(start_pos-3, start_pos)
                if range == "wx." then
                    local key = editor:GetTextRange(start_pos, pos)
                    local userList = CreateAutoCompList(key)
                    if userList and string.len(userList) > 0 then
                        editor:UserListShow(1, userList)
                    end
                end
            end
        end)
frame:Connect(ID_AUTOCOMPLETE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_AUTOCOMPLETE_ENABLE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            autoCompleteEnable = event:IsChecked()
        end)

frame:Connect(ID_COMMENT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            local buf = {}
            if editor:GetSelectionStart() == editor:GetSelectionEnd() then
                local lineNumber = editor:GetCurrentLine()
                editor:SetSelection(editor:PositionFromLine(lineNumber), editor:GetLineEndPosition(lineNumber))
            end
            for line in string.gmatch(editor:GetSelectedText()..'\n', "(.-)\r?\n") do
                if string.sub(line,1,2) == '--' then
                    line = string.sub(line,3)
                else
                    line = '--'..line
                end
                table.insert(buf, line)
            end
            editor:ReplaceSelection(table.concat(buf,"\n"))
        end)
frame:Connect(ID_COMMENT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

function FoldSome()
    local editor = GetEditor()
    editor:Colourise(0, -1)       -- update doc's folding info
    local visible, baseFound, expanded, folded
    for ln = 2, editor.LineCount - 1 do
        local foldRaw = editor:GetFoldLevel(ln)
        local foldLvl = math.mod(foldRaw, 4096)
        local foldHdr = math.mod(math.floor(foldRaw / 8192), 2) == 1
        if not baseFound and (foldLvl ==  wxstc.wxSTC_FOLDLEVELBASE) then
            baseFound = true
            visible = editor:GetLineVisible(ln)
        end
        if foldHdr then
            if editor:GetFoldExpanded(ln) then
                expanded = true
            else
                folded = true
            end
        end
        if expanded and folded and baseFound then break end
    end
    local show = not visible or (not baseFound and expanded) or (expanded and folded)
    local hide = visible and folded

    if show then
        editor:ShowLines(1, editor.LineCount-1)
    end

    for ln = 1, editor.LineCount - 1 do
        local foldRaw = editor:GetFoldLevel(ln)
        local foldLvl = math.mod(foldRaw, 4096)
        local foldHdr = math.mod(math.floor(foldRaw / 8192), 2) == 1
        if show then
            if foldHdr then
                if not editor:GetFoldExpanded(ln) then editor:ToggleFold(ln) end
            end
        elseif hide and (foldLvl == wxstc.wxSTC_FOLDLEVELBASE) then
            if not foldHdr then
                editor:HideLines(ln, ln)
            end
        elseif foldHdr then
            if editor:GetFoldExpanded(ln) then
                editor:ToggleFold(ln)
            end
        end
    end
    editor:EnsureCaretVisible()
end

frame:Connect(ID_FOLD, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            FoldSome()
        end)
frame:Connect(ID_FOLD, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

-- ---------------------------------------------------------------------------
-- Create the Search menu and attach the callback functions

findMenu = wx.wxMenu{
        { ID_FIND,       "&Find\tCtrl-F",            "Find the specified text" },
        { ID_FINDNEXT,   "Find &Next\tF3",           "Find the next occurrence of the specified text" },
        { ID_FINDPREV,   "Find &Previous\tShift-F3", "Repeat the search backwards in the file" },
        { ID_REPLACE,    "&Replace\tCtrl-H",         "Replaces the specified text with different text" },
        { },
        { ID_GOTOLINE,   "&Goto line\tCtrl-G",       "Go to a selected line" },
        { },
        { ID_SORT,       "&Sort",                    "Sort selected lines"}}
menuBar:Append(findMenu, "&Search")

function EnsureRangeVisible(posStart, posEnd)
    local editor = GetEditor()
    if posStart > posEnd then
        posStart, posEnd = posEnd, posStart
    end

    local lineStart = editor:LineFromPosition(posStart)
    local lineEnd   = editor:LineFromPosition(posEnd)
    for line = lineStart, lineEnd do
        editor:EnsureVisibleEnforcePolicy(line)
    end
end

-------------------- Find replace dialog

function SetSearchFlags(editor)
    local flags = 0
    if findReplace.fWholeWord   then flags = wxstc.wxSTC_FIND_WHOLEWORD end
    if findReplace.fMatchCase   then flags = flags + wxstc.wxSTC_FIND_MATCHCASE end
    if findReplace.fRegularExpr then flags = flags + wxstc.wxSTC_FIND_REGEXP end
    editor:SetSearchFlags(flags)
end

function SetTarget(editor, fDown, fInclude)
    local selStart = editor:GetSelectionStart()
    local selEnd =  editor:GetSelectionEnd()
    local len = editor:GetLength()
    local s, e
    if fDown then
        e= len
        s = iff(fInclude, selStart, selEnd +1)
    else
        s = 0
        e = iff(fInclude, selEnd, selStart-1)
    end
    if not fDown and not fInclude then s, e = e, s end
    editor:SetTargetStart(s)
    editor:SetTargetEnd(e)
    return e
end

function findReplace:HasText()
    return (findReplace.findText ~= nil) and (string.len(findReplace.findText) > 0)
end

function findReplace:GetSelectedString()
    local editor = GetEditor()
    if editor then
        local startSel = editor:GetSelectionStart()
        local endSel   = editor:GetSelectionEnd()
        if (startSel ~= endSel) and (editor:LineFromPosition(startSel) == editor:LineFromPosition(endSel)) then
            findReplace.findText = editor:GetSelectedText()
            findReplace.foundString = true
        end
    end
end

function findReplace:FindString(reverse)
    if findReplace:HasText() then
        local editor = GetEditor()
        local fDown = iff(reverse, not findReplace.fDown, findReplace.fDown)
        local lenFind = string.len(findReplace.findText)
        SetSearchFlags(editor)
        SetTarget(editor, fDown)
        local posFind = editor:SearchInTarget(findReplace.findText)
        if (posFind == -1) and findReplace.fWrap then
            editor:SetTargetStart(iff(fDown, 0, editor:GetLength()))
            editor:SetTargetEnd(iff(fDown, editor:GetLength(), 0))
            posFind = editor:SearchInTarget(findReplace.findText)
        end
        if posFind == -1 then
            findReplace.foundString = false
            frame:SetStatusText("Find text not found.")
        else
            findReplace.foundString = true
            local start  = editor:GetTargetStart()
            local finish = editor:GetTargetEnd()
            EnsureRangeVisible(start, finish)
            editor:SetSelection(start, finish)
        end
    end
end

function ReplaceString(fReplaceAll)
    if findReplace:HasText() then
        local replaceLen = string.len(findReplace.replaceText)
        local editor = GetEditor()
        local findLen = string.len(findReplace.findText)
        local endTarget  = SetTarget(editor, findReplace.fDown, fReplaceAll)
        if fReplaceAll then
            SetSearchFlags(editor)
            local posFind = editor:SearchInTarget(findReplace.findText)
            if (posFind ~= -1)  then
                editor:BeginUndoAction()
                while posFind ~= -1 do
                    editor:ReplaceTarget(findReplace.replaceText)
                    editor:SetTargetStart(posFind + replaceLen)
                    endTarget = endTarget + replaceLen - findLen
                    editor:SetTargetEnd(endTarget)
                    posFind = editor:SearchInTarget(findReplace.findText)
                end
                editor:EndUndoAction()
            end
        else
            if findReplace.foundString then
                local start  = editor:GetSelectionStart()
                editor:ReplaceSelection(findReplace.replaceText)
                editor:SetSelection(start, start + replaceLen)
                findReplace.foundString = false
            end
            findReplace:FindString()
        end
    end
end

function CreateFindReplaceDialog(replace)
    local ID_FIND_NEXT   = 1
    local ID_REPLACE     = 2
    local ID_REPLACE_ALL = 3
    findReplace.replace  = replace

    local findDialog = wx.wxDialog(frame, wx.wxID_ANY, "Find",  wx.wxDefaultPosition, wx.wxDefaultSize)

    -- Create right hand buttons and sizer
    local findButton = wx.wxButton(findDialog, ID_FIND_NEXT, "&Find Next")
    findButton:SetDefault()
    local replaceButton =  wx.wxButton(findDialog, ID_REPLACE, "&Replace")
    local replaceAllButton = nil
    if (replace) then
        replaceAllButton =  wx.wxButton(findDialog, ID_REPLACE_ALL, "Replace &All")
    end
    local cancelButton =  wx.wxButton(findDialog, wx.wxID_CANCEL, "Cancel")

    local buttonsSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    buttonsSizer:Add(findButton,    0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    buttonsSizer:Add(replaceButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    if replace then
        buttonsSizer:Add(replaceAllButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    end
    buttonsSizer:Add(cancelButton, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER,  3)

    -- Create find/replace text entry sizer
    local findStatText  = wx.wxStaticText( findDialog, wx.wxID_ANY, "Find: ")
    local findTextCombo = wx.wxComboBox(findDialog, wx.wxID_ANY, findReplace.findText,  wx.wxDefaultPosition, wx.wxDefaultSize, findReplace.findTextArray, wx.wxCB_DROPDOWN)
    findTextCombo:SetFocus()

    local replaceStatText, replaceTextCombo
    if (replace) then
        replaceStatText  = wx.wxStaticText( findDialog, wx.wxID_ANY, "Replace: ")
        replaceTextCombo = wx.wxComboBox(findDialog, wx.wxID_ANY, findReplace.replaceText,  wx.wxDefaultPosition, wx.wxDefaultSize,  findReplace.replaceTextArray)
    end

    local findReplaceSizer = wx.wxFlexGridSizer(2, 2, 0, 0)
    findReplaceSizer:AddGrowableCol(1)
    findReplaceSizer:Add(findStatText,  0, wx.wxALL + wx.wxALIGN_LEFT, 0)
    findReplaceSizer:Add(findTextCombo, 1, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)

    if (replace) then
        findReplaceSizer:Add(replaceStatText,  0, wx.wxTOP + wx.wxALIGN_CENTER, 5)
        findReplaceSizer:Add(replaceTextCombo, 1, wx.wxTOP + wx.wxGROW + wx.wxCENTER, 5)
    end

    -- Create find/replace option checkboxes
    local wholeWordCheckBox  = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Match &whole word")
    local matchCaseCheckBox  = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Match &case")
    local wrapAroundCheckBox = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Wrap ar&ound")
    local regexCheckBox      = wx.wxCheckBox(findDialog, wx.wxID_ANY, "Regular &expression")
    wholeWordCheckBox:SetValue(findReplace.fWholeWord)
    matchCaseCheckBox:SetValue(findReplace.fMatchCase)
    wrapAroundCheckBox:SetValue(findReplace.fWrap)
    regexCheckBox:SetValue(findReplace.fRegularExpr)

    local optionSizer = wx.wxBoxSizer(wx.wxVERTICAL, findDialog)
    optionSizer:Add(wholeWordCheckBox,  0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(matchCaseCheckBox,  0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(wrapAroundCheckBox, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    optionSizer:Add(regexCheckBox,      0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 3)
    local optionsSizer = wx.wxStaticBoxSizer(wx.wxVERTICAL, findDialog, "Options" );
    optionsSizer:Add(optionSizer, 0, 0, 5)

    -- Create scope radiobox
    local scopeRadioBox = wx.wxRadioBox(findDialog, wx.wxID_ANY, "Scope", wx.wxDefaultPosition, wx.wxDefaultSize,  {"&Up", "&Down"}, 1, wx.wxRA_SPECIFY_COLS)
    scopeRadioBox:SetSelection(iff(findReplace.fDown, 1, 0))
    local scopeSizer = wx.wxBoxSizer(wx.wxVERTICAL, findDialog );
    scopeSizer:Add(scopeRadioBox, 0, 0, 0)

    -- Add all the sizers to the dialog
    local optionScopeSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    optionScopeSizer:Add(optionsSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)
    optionScopeSizer:Add(scopeSizer,   0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)

    local leftSizer = wx.wxBoxSizer(wx.wxVERTICAL)
    leftSizer:Add(findReplaceSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)
    leftSizer:Add(optionScopeSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 0)

    local mainSizer = wx.wxBoxSizer(wx.wxHORIZONTAL)
    mainSizer:Add(leftSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 10)
    mainSizer:Add(buttonsSizer, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 10)
    mainSizer:SetSizeHints( findDialog )
    findDialog:SetSizer(mainSizer)

    local function PrependToArray(t, s)
        if string.len(s) == 0 then return end
        for i, v in ipairs(t) do
            if v == s then
                table.remove(t, i) -- remove old copy
                break
            end
        end
        table.insert(t, 1, s)
        if #t > 15 then table.remove(t, #t) end -- keep reasonable length
    end

    local function TransferDataFromWindow()
        findReplace.fWholeWord   = wholeWordCheckBox:GetValue()
        findReplace.fMatchCase   = matchCaseCheckBox:GetValue()
        findReplace.fWrap        = wrapAroundCheckBox:GetValue()
        findReplace.fDown        = scopeRadioBox:GetSelection() == 1
        findReplace.fRegularExpr = regexCheckBox:GetValue()
        findReplace.findText     = findTextCombo:GetValue()
        PrependToArray(findReplace.findTextArray, findReplace.findText)
        if findReplace.replace then
            findReplace.replaceText = replaceTextCombo:GetValue()
            PrependToArray(findReplace.replaceTextArray, findReplace.replaceText)
        end
        return true
    end

    findDialog:Connect(ID_FIND_NEXT, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function(event)
            TransferDataFromWindow()
            findReplace:FindString()
        end)

    findDialog:Connect(ID_REPLACE, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function(event)
            TransferDataFromWindow()
            event:Skip()
            if findReplace.replace then
                ReplaceString()
            else
                findReplace.dialog:Destroy()
                findReplace.dialog = CreateFindReplaceDialog(true)
                findReplace.dialog:Show(true)
            end
        end)

    if replace then
        findDialog:Connect(ID_REPLACE_ALL, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function(event)
                TransferDataFromWindow()
                event:Skip()
                ReplaceString(true)
            end)
    end

    findDialog:Connect(wx.wxID_ANY, wx.wxEVT_CLOSE_WINDOW,
        function (event)
            TransferDataFromWindow()
            event:Skip()
            findDialog:Show(false)
            findDialog:Destroy()
        end)

    return findDialog
end

function findReplace:Show(replace)
    self.dialog = nil
    self.dialog = CreateFindReplaceDialog(replace)
    self.dialog:Show(true)
end

frame:Connect(ID_FIND, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            findReplace:GetSelectedString()
            findReplace:Show(false)
        end)
frame:Connect(ID_FIND, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_REPLACE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            findReplace:GetSelectedString()
            findReplace:Show(true)
        end)
frame:Connect(ID_REPLACE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_FINDNEXT, wx.wxEVT_COMMAND_MENU_SELECTED, function (event) findReplace:FindString() end)
frame:Connect(ID_FINDNEXT, wx.wxEVT_UPDATE_UI, function (event) findReplace:HasText() end)

frame:Connect(ID_FINDPREV, wx.wxEVT_COMMAND_MENU_SELECTED, function (event) findReplace:FindString(true) end)
frame:Connect(ID_FINDPREV, wx.wxEVT_UPDATE_UI, function (event) findReplace:HasText() end)

-------------------- Find replace end

frame:Connect(ID_GOTOLINE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            local linecur = editor:LineFromPosition(editor:GetCurrentPos())
            local linemax = editor:LineFromPosition(editor:GetLength()) + 1
            local linenum = wx.wxGetNumberFromUser( "Enter line number",
                                                    "1 .. "..tostring(linemax),
                                                    "Goto Line",
                                                    linecur, 1, linemax,
                                                    frame)
            if linenum > 0 then
                editor:GotoLine(linenum-1)
            end
        end)
frame:Connect(ID_GOTOLINE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

frame:Connect(ID_SORT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            local buf = {}
            for line in string.gmatch(editor:GetSelectedText()..'\n', "(.-)\r?\n") do
                table.insert(buf, line)
            end
            if #buf > 0 then
                table.sort(buf)
                editor:ReplaceSelection(table.concat(buf,"\n"))
            end
        end)
frame:Connect(ID_SORT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

-- ---------------------------------------------------------------------------
-- Create the Debug menu and attach the callback functions

debugMenu = wx.wxMenu{
        { ID_TOGGLEBREAKPOINT, "Toggle &Breakpoint\tF9", "Toggle Breakpoint" },
        { },
        { ID_COMPILE,          "&Compile\tF7",           "Test compile the wxLua program" },
        { ID_RUN,              "&Run\tF6",               "Execute the current file" },
        { ID_ATTACH_DEBUG,     "&Attach\tShift-F6",      "Allow a client to start a debugging session" },
        { ID_START_DEBUG,      "&Start Debugging\tShift-F5", "Start a debugging session" },
        { ID_USECONSOLE,       "Console",               "Use console when running",  wx.wxITEM_CHECK },
        { },
        { ID_STOP_DEBUG,       "S&top Debugging\tShift-F12", "Stop and end the debugging session" },
        { ID_STEP,             "St&ep\tF11",             "Step into the next line" },
        { ID_STEP_OVER,        "Step &Over\tShift-F11",  "Step over the next line" },
        { ID_STEP_OUT,         "Step O&ut\tF8",          "Step out of the current function" },
        { ID_CONTINUE,         "Co&ntinue\tF5",          "Run the program at full speed" },
        { ID_BREAK,            "&Break\tF12",            "Stop execution of the program at the next executed line of code" },
        { },
        { ID_VIEWCALLSTACK,    "V&iew Call Stack",       "View the LUA call stack" },
        { ID_VIEWWATCHWINDOW,  "View &Watches",          "View the Watch window" },
        { },
        { ID_SHOWHIDEWINDOW,   "View &Output Window\tF8", "View or Hide the output window" },
        { ID_CLEAROUTPUT,      "C&lear Output Window",    "Clear the output window before compiling or debugging", wx.wxITEM_CHECK },
        --{ }, { ID_DEBUGGER_PORT,    "Set debugger socket port...", "Chose what port to use for debugger sockets." }
        }
menuBar:Append(debugMenu, "&Debug")

menuBar:Check(ID_USECONSOLE, true)

function SetAllEditorsReadOnly(enable)
    for id, document in pairs(openDocuments) do
        local editor = document.editor
        editor:SetReadOnly(enable)
    end
end

function MakeDebugFileName(editor, filePath)
    if not filePath then
        filePath = "file"..tostring(editor)
    end
    return filePath
end

function ToggleDebugMarker(editor, line)
    local markers = editor:MarkerGet(line)
    if markers >= CURRENT_LINE_MARKER_VALUE then
        markers = markers - CURRENT_LINE_MARKER_VALUE
    end
    local id       = editor:GetId()
    local filePath = MakeDebugFileName(editor, openDocuments[id].filePath)
    if markers >= BREAKPOINT_MARKER_VALUE then
        editor:MarkerDelete(line, BREAKPOINT_MARKER)
        if debuggerServer then
            debuggerServer:RemoveBreakPoint(filePath, line)
        end
    else
        editor:MarkerAdd(line, BREAKPOINT_MARKER)
        if debuggerServer then
            debuggerServer:AddBreakPoint(filePath, line)
        end
    end
end

function ClearAllCurrentLineMarkers()
    for id, document in pairs(openDocuments) do
        local editor = document.editor
        editor:MarkerDeleteAll(CURRENT_LINE_MARKER)
    end
end

function DisplayOutput(message, dont_add_marker)
    if splitter:IsSplit() == false then
        local w, h = frame:GetClientSizeWH()
        splitter:SplitHorizontally(notebook, errorLog, (2 * h) / 3)
    end
    if not dont_add_marker then
        errorLog:MarkerAdd(errorLog:GetLineCount()-1, CURRENT_LINE_MARKER)
    end
    errorLog:SetReadOnly(false)
    errorLog:AppendText(message)
    errorLog:SetReadOnly(true)
    errorLog:GotoPos(errorLog:GetLength())
end

frame:Connect(ID_TOGGLEBREAKPOINT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            local line = editor:LineFromPosition(editor:GetCurrentPos())
            ToggleDebugMarker(editor, line)
        end)
frame:Connect(ID_TOGGLEBREAKPOINT, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

function CompileProgram(editor)
    local editorText = editor:GetText()
    local id         = editor:GetId()
    local filePath   = MakeDebugFileName(editor, openDocuments[id].filePath)
    local ret, errMsg, line_num = wxlua.CompileLuaScript(editorText, filePath)
    if menuBar:IsChecked(ID_CLEAROUTPUT) then
        ClearOutput()
    end

    if line_num > -1 then
        DisplayOutput("Compilation error on line number :"..tostring(line_num).."\n"..errMsg.."\n\n")
        editor:GotoLine(line_num-1)
    else
        DisplayOutput("Compilation successful!\n\n")
    end

    return line_num == -1 -- return true if it compiled ok
end

frame:Connect(ID_COMPILE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            CompileProgram(editor)
        end)
frame:Connect(ID_COMPILE, wx.wxEVT_UPDATE_UI, OnUpdateUIEditMenu)

function SaveIfModified(editor)
    local id = editor:GetId()
    if openDocuments[id].isModified then
        local saved = false
        if not openDocuments[id].filePath then
            local ret = wx.wxMessageBox("You must save the program before running it.\nPress cancel to abort running.",
                                         "Save file?",  wx.wxOK + wx.wxCANCEL + wx.wxCENTRE, frame)
            if ret == wx.wxOK then
                saved = SaveFileAs(editor)
            end
        else
            saved = SaveFile(editor, openDocuments[id].filePath)
        end

        if saved then
            openDocuments[id].isModified = false
        else
            return false -- not saved
        end
    end

    return true -- saved
end

frame:Connect(ID_RUN, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            -- FIXME - I don't understand why you would would want to run *all* the notebook pages?
--[[
            local fileList = {}
            SaveAll()
            for id, document in pairs(openDocuments) do
                local filePath = document.filePath
                if filePath == nil then
                    return
                end
                table.insert(fileList, ' "'..filePath..'"')
            end
            local cmd = '"'..programName..'" '..table.concat(fileList)
]]
            local editor = GetEditor();
            -- test compile it before we run it, if successful then ask to save
            if not CompileProgram(editor) then
                return
            end
            if not SaveIfModified(editor) then
                return
            end

            local id = editor:GetId();
            local console = iff(menuBar:IsChecked(ID_USECONSOLE), " -c ", "")
            local cmd = '"'..programName..'" '..console..openDocuments[id].filePath

            DisplayOutput("Running program: "..cmd.."\n")
            local pid = wx.wxExecute(cmd, wx.wxEXEC_ASYNC)

            if pid == -1 then
                DisplayOutput("Unknown ERROR Running program!\n", true)
            else
                DisplayOutput("Process id is: "..tostring(pid).."\n", true)
            end
        end)
frame:Connect(ID_RUN, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable((debuggerServer == nil) and (editor ~= nil))
        end)

frame:Connect(ID_ATTACH_DEBUG, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local ok = false
            debuggerServer = wxlua.wxLuaDebuggerServer(debuggerPortNumber)
            if debuggerServer then
                ok = debuggerServer:StartServer()
            end
            if ok then
                DisplayOutput("Waiting for client connect. Start client with wxLua -d"..wx.wxGetHostName()..":"..debuggerPortNumber.."\n")
            else
                DisplayOutput("Unable to create debugger server.\n")
            end
            NextDebuggerPort()
        end)
frame:Connect(ID_ATTACH_DEBUG, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable((debuggerServer == nil) and (editor ~= nil))
        end)

function NextDebuggerPort()
    -- limit the number if ports we use, for people who need to open
    -- their firewall
    debuggerPortNumber = debuggerPortNumber + 1
    if (debuggerPortNumber > 1559) then
        debuggerPortNumber = 1551
    end
end

function CreateDebuggerServer()
    if (debuggerServer) then
        -- we just delete it here, but this shouldn't happen
        debugger_destroy = 0
        local ds = debuggerServer
        debuggerServer = nil
        ds:Reset()
        ds:StopServer()
        ds:delete()
    end

    debuggee_running = false
    debuggerServer = wxlua.wxLuaDebuggerServer(debuggerPortNumber)

    debuggerServer:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_DEBUGGEE_CONNECTED,
        function (event)
            local ok = false
            -- FIXME why would you want to run all the notebook pages?
            --for id, document in pairs(openDocuments) do
                local editor     = GetEditor() -- MUST use document.editor userdata!
                local document   = openDocuments[editor:GetId()]
                local editor     = document.editor
                local editorText = editor:GetText()
                local filePath   = MakeDebugFileName(editor, document.filePath)
                ok = debuggerServer:Run(filePath, editorText)

                local nextLine = editor:MarkerNext(0, BREAKPOINT_MARKER_VALUE)
                while ok and (nextLine ~= -1) do
                    ok = debuggerServer:AddBreakPoint(filePath, nextLine)
                    nextLine = editor:MarkerNext(nextLine + 1, BREAKPOINT_MARKER_VALUE)
                end
            --end

            if ok then
                ok = debuggerServer:Step()
            end
            debuggee_running = ok

            UpdateUIMenuItems()

            if ok then
                DisplayOutput("Client connected ok.\n")
            else
                DisplayOutput("Error connecting to client.\n")
            end
        end)

    debuggerServer:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_DEBUGGEE_DISCONNECTED,
        function (event)
            DisplayOutput("Debug server disconnected.\n")
            DisplayOutput(event:GetMessage().."\n\n")
            DestroyDebuggerServer()
        end)

    local function DebuggerIgnoreFile(fileName)
        local ignoreFlag = false
        for idx, ignoreFile in pairs(ignoredFilesList) do
            if string.upper(ignoreFile) == string.upper(fileName) then
                ignoreFlag = true
            end
        end
        return ignoreFlag
    end

    debuggerServer:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_BREAK,
        function (event)
            if exitingProgram then return end
            local line = event:GetLineNumber()
            local eventFileName = event:GetFileName()

            if string.sub(eventFileName, 1, 1) == '@' then -- FIXME what is this?
                eventFileName = string.sub(eventFileName, 2, -1)
                if wx.wxIsAbsolutePath(eventFileName) == false then
                    eventFileName = wx.wxGetCwd().."/"..eventFileName
                end
            end
            if wx.__WXMSW__ then
                eventFileName = wx.wxUnix2DosFilename(eventFileName)
            end
            local fileFound = false
            DisplayOutput("At Breakpoint line: "..tostring(line).." file: "..eventFileName.."\n")
            for id, document in pairs(openDocuments) do
                local editor   = document.editor
                local filePath = MakeDebugFileName(editor, document.filePath)
                -- for running in cygwin, use same type of separators
                filePath = string.gsub(filePath, "\\", "/")
                local eventFileName_ = string.gsub(eventFileName, "\\", "/")
                if string.upper(filePath) == string.upper(eventFileName_) then
                    local selection = document.index
                    notebook:SetSelection(selection)
                    SetEditorSelection(selection)
                    editor:MarkerAdd(line, CURRENT_LINE_MARKER)
                    editor:EnsureVisibleEnforcePolicy(line)
                    fileFound = true
                    break
                end
            end
            -- if don't ignore file and its not in the notebook, ask to load
            if not DebuggerIgnoreFile(eventFileName) then
                if not fileFound then
                    local fileDialog = wx.wxFileDialog(frame,
                                                       "Select file for debugging",
                                                       "",
                                                       eventFileName,
                                                       "Lua files (*.lua)|*.lua|Text files (*.txt)|*.txt|All files (*)|*",
                                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
                    if fileDialog:ShowModal() == wx.wxID_OK then
                        local editor = LoadFile(fileDialog:GetPath(), nil, true)
                        if editor then
                            editor:MarkerAdd(line, CURRENT_LINE_MARKER)
                            editor:EnsureVisibleEnforcePolicy(line)
                            editor:SetReadOnly(true)
                            fileFound = true
                        end
                    end
                    fileDialog:Destroy()
                end
                if not fileFound then -- they canceled opening the file
                    table.insert(ignoredFilesList, eventFileName)
                end
            end

            if fileFound then
                debuggee_running = false
                ProcessWatches()
            elseif debuggerServer then
                debuggerServer:Continue()
                debuggee_running = true
            end
        end)

    debuggerServer:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_PRINT,
        function (event)
            DisplayOutput(event:GetMessage().."\n")
        end)

    debuggerServer:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_ERROR,
        function (event)
            DisplayOutput("wxLua ERROR: "..event:GetMessage().."\n\n")
        end)

    debuggerServer:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_EXIT,
        function (event)
            ClearAllCurrentLineMarkers()

            if debuggerServer then
                DestroyDebuggerServer()
            end
            SetAllEditorsReadOnly(false)
            ignoredFilesList = {}
        end)

    debuggerServer:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_EVALUATE_EXPR,
        function (event)
            if watchListCtrl then
                watchListCtrl:SetItem(event:GetReference(),
                                      1,
                                      event:GetMessage())
            end
        end)

    local ok = debuggerServer:StartServer()
    if not ok then
        DestroyDebuggerServer()
        DisplayOutput("Error starting the debug server.\n")
        return nil
    end

    return debuggerServer
end

function DestroyDebuggerServer()
    -- nil debuggerServer so it won't be used and set flag to destroy it in idle
    if (debuggerServer) then
        debuggerServer_ = debuggerServer
        debuggerServer = nil
        debugger_destroy = 1 -- set > 0 to initiate deletion in idle
    end
end

frame:Connect(wx.wxEVT_IDLE,
        function(event)

            if (debugger_destroy > 0) then
                debugger_destroy = debugger_destroy + 1
            end

            if (debugger_destroy == 5) then
                -- stop the server and let it end gracefully
                debuggee_running = false
                debuggerServer_:StopServer()
            end
            if (debugger_destroy == 10) then
                -- delete the server and let it die gracefully
                debuggee_running = false
                debuggerServer_:delete()
            end
            if (debugger_destroy > 15) then
                -- finally, kill the debugee process if it still exists
                debugger_destroy = 0;
                local ds = debuggerServer_
                debuggerServer_ = nil

                if (debuggee_pid > 0) then
                    if wx.wxProcess.Exists(debuggee_pid) then
                        local ret = wx.wxProcess.Kill(debuggee_pid, wx.wxSIGKILL, wx.wxKILL_CHILDREN)
                        if (ret ~= wx.wxKILL_OK) then
                            DisplayOutput("Unable to kill debuggee process "..debuggee_pid..", code "..tostring(ret)..".\n")
                        else
                            DisplayOutput("Killed debuggee process "..debuggee_pid..".\n")
                        end
                    end
                    debuggee_pid = 0
                end
            end
            event:Skip()
        end)

frame:Connect(ID_START_DEBUG, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            local editor = GetEditor()
            -- test compile it before we run it
            if not CompileProgram(editor) then
                return
            end

            debuggee_pid = 0
            debuggerServer = CreateDebuggerServer()
            if debuggerServer then
                debuggee_pid = debuggerServer:StartClient()
            end

            if debuggerServer and (debuggee_pid > 0) then
                SetAllEditorsReadOnly(true)
                DisplayOutput("Waiting for client connection, process "..tostring(debuggee_pid)..".\n")
            else
                DisplayOutput("Unable to start debuggee process.\n")
                if debuggerServer then
                    DestroyDebuggerServer()
                end
            end

            NextDebuggerPort()
        end)
frame:Connect(ID_START_DEBUG, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable((debuggerServer == nil) and (editor ~= nil))
        end)

frame:Connect(ID_STOP_DEBUG, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            ClearAllCurrentLineMarkers()

            if debuggerServer then
                debuggerServer:Reset();
                --DestroyDebuggerServer()
            end
            SetAllEditorsReadOnly(false)
            ignoredFilesList = {}
            debuggee_running = false
            DisplayOutput("\nDebuggee client stopped.\n\n")
        end)
frame:Connect(ID_STOP_DEBUG, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable((debuggerServer ~= nil) and (editor ~= nil))
        end)

frame:Connect(ID_STEP, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            ClearAllCurrentLineMarkers()

            if debuggerServer then
                debuggerServer:Step()
                debuggee_running = true
            end
        end)
frame:Connect(ID_STEP, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable((debuggerServer ~= nil) and (not debuggee_running) and (editor ~= nil))
        end)

frame:Connect(ID_STEP_OVER, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            ClearAllCurrentLineMarkers()

            if debuggerServer then
                debuggerServer:StepOver()
                debuggee_running = true
            end
        end)
frame:Connect(ID_STEP_OVER, wx.wxEVT_UPDATE_UI,
        function (event)
            local editor = GetEditor()
            event:Enable((debuggerServer ~= nil) and (not debuggee_running) and (editor ~= nil))
        end)

frame:Connect(ID_STEP_OUT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            ClearAllCurrentLineMarkers()

            if debuggerServer then
                debuggerServer:StepOut()
                debuggee_running = true
            end
        end)
frame:Connect(ID_STEP_OUT, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable((debuggerServer ~= nil) and (not debuggee_running))
        end)

frame:Connect(ID_CONTINUE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            ClearAllCurrentLineMarkers()

            if debuggerServer then
                debuggerServer:Continue()
                debuggee_running = true
            end
        end)
frame:Connect(ID_CONTINUE, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable((debuggerServer ~= nil) and (not debuggee_running))
        end)

frame:Connect(ID_BREAK, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if debuggerServer then
                debuggerServer:Break()
            end
        end)
frame:Connect(ID_BREAK, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable((debuggerServer ~= nil) and debuggee_running)
        end)

frame:Connect(ID_VIEWCALLSTACK, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if debuggerServer then
                debuggerServer:DisplayStackDialog(frame)
            end
        end)
frame:Connect(ID_VIEWCALLSTACK, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable((debuggerServer ~= nil) and (not debuggee_running))
        end)

frame:Connect(ID_VIEWWATCHWINDOW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if not watchWindow then
                CreateWatchWindow()
            end
        end)
frame:Connect(ID_VIEWWATCHWINDOW, wx.wxEVT_UPDATE_UI,
        function (event)
            event:Enable((debuggerServer ~= nil) and (not debuggee_running))
        end)

frame:Connect(ID_SHOWHIDEWINDOW, wx.wxEVT_COMMAND_MENU_SELECTED,
        function (event)
            if splitter:IsSplit() then
                splitter:Unsplit()
            else
                local w, h = frame:GetClientSizeWH()
                splitter:SplitHorizontally(notebook, errorLog, (2 * h) / 3)
            end
        end)

function ClearOutput(event)
    errorLog:SetReadOnly(false)
    errorLog:ClearAll()
    errorLog:SetReadOnly(true)
end

frame:Connect(ID_DEBUGGER_PORT, wx.wxEVT_COMMAND_MENU_SELECTED,
        function(event)
        end)
frame:Connect(ID_DEBUGGER_PORT, wx.wxEVT_UPDATE_UI,
        function(event)
            event:Enable(debuggerServer == nil)
        end)

-- ---------------------------------------------------------------------------
-- Create the Help menu and attach the callback functions

helpMenu = wx.wxMenu{
        { ID_ABOUT,      "&About\tF1",       "About wxLua IDE" }}
menuBar:Append(helpMenu, "&Help")

function DisplayAbout(event)
    local page = [[
        <html>
        <body bgcolor = "#FFFFFF">
        <table cellspacing = 4 cellpadding = 4 width = "100%">
          <tr>
            <td bgcolor = "#202020">
            <center>
                <font size = +2 color = "#FFFFFF"><br><b>]]..
                    wxlua.wxLUA_VERSION_STRING..[[</b></font><br>
                <font size = +1 color = "#FFFFFF">built with</font><br>
                <font size = +2 color = "#FFFFFF"><b>]]..
                    wx.wxVERSION_STRING..[[</b></font>
            </center>
            </td>
          </tr>
          <tr>
            <td bgcolor = "#DCDCDC">
            <b>Copyright (C) 2002-2005 Lomtick Software</b>
            <p>
            <font size=-1>
              <table cellpadding = 0 cellspacing = 0 width = "100%">
                <tr>
                  <td width = "65%">
                    J. Winwood (luascript@thersgb.net)<br>
                    John Labenski<p>
                  </td>
                  <td valign = top>
                    <img src = "memory:wxLua">
                  </td>
                </tr>
              </table>
            <font size = 1>
                Licenced under wxWindows Library Licence, Version 3.
            </font>
            </font>
            </td>
          </tr>
        </table>
        </body>
        </html>
    ]]

    local dlg = wx.wxDialog(frame, wx.wxID_ANY, "About wxLua IDE")

    local html = wx.wxLuaHtmlWindow(dlg, wx.wxID_ANY,
                                    wx.wxDefaultPosition, wx.wxSize(360, 150),
                                    wx.wxHW_SCROLLBAR_NEVER)
    local line = wx.wxStaticLine(dlg, wx.wxID_ANY)
    local button = wx.wxButton(dlg, wx.wxID_OK, "OK")

    button:SetDefault()

    html:SetBorders(0)
    html:SetPage(page)
    html:SetSize(html:GetInternalRepresentation():GetWidth(),
                 html:GetInternalRepresentation():GetHeight())

    local topsizer = wx.wxBoxSizer(wx.wxVERTICAL)
    topsizer:Add(html, 1, wx.wxALL, 10)
    topsizer:Add(line, 0, wx.wxEXPAND + wx.wxLEFT + wx.wxRIGHT, 10)
    topsizer:Add(button, 0, wx.wxALL + wx.wxALIGN_RIGHT, 10)

    dlg:SetAutoLayout(true)
    dlg:SetSizer(topsizer)
    topsizer:Fit(dlg)

    dlg:ShowModal()
    dlg:Destroy()
end

frame:Connect(ID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, DisplayAbout)

-- ---------------------------------------------------------------------------
-- Attach the handler for closing the frame

function CloseWindow(event)
    exitingProgram = true -- don't handle focus events

    if not SaveOnExit(event:CanVeto()) then
        event:Veto()
        exitingProgram = false
        return
    end

    if debuggerServer then
        local ds = debuggerServer
        debuggerServer = nil
        --ds:Reset()
        ds:KillDebuggee()
        ds:delete()
    end
    debuggee_running = false

    ConfigSaveFramePosition(frame, "MainFrame")
    config:delete() -- always delete the config
    event:Skip()
    CloseWatchWindow()
end
frame:Connect(wx.wxEVT_CLOSE_WINDOW, CloseWindow)

-- ---------------------------------------------------------------------------
-- Finish creating the frame and show it

frame:SetMenuBar(menuBar)
ConfigRestoreFramePosition(frame, "MainFrame")

-- ---------------------------------------------------------------------------
-- Load the args that this script is run with

--for k, v in pairs(arg) do print(k, v) end

if arg then
    -- arguments pushed into wxLua are
    --   [C++ app and it's args][lua prog at 0][args for lua start at 1]
    local n = 1
    while arg[n-1] do
        n = n - 1
        if arg[n] and not arg[n-1] then programName = arg[n] end
    end

    for index = 1, #arg do
        fileName = arg[index]
        if fileName ~= "--" then
            LoadFile(fileName, nil, true)
        end
    end

    if notebook:GetPageCount() > 0 then
        notebook:SetSelection(0)
    else
       local editor = CreateEditor("untitled.lua")
       SetupKeywords(editor, true)
    end
else
    local editor = CreateEditor("untitled.lua")
    SetupKeywords(editor, true)
end

--frame:SetIcon(wxLuaEditorIcon) --FIXME add this back
frame:Show(true)

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
