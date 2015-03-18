-- demonstrates how to capture multiple key sequences, like 'ctrl-k 1', with extman.
-- This is used to implement Borland-style markers.
scite_Command {
  'ctrl-k|do_ctrl_command k|Ctrl+K',
  'ctrl-q|do_ctrl_command q|Ctrl+Q',  
} 

local gMarksMap = {}
local gMarks = {}

scite_OnOpen(function(f)
  gMarksMap[f] = {}
 end)

scite_OnSwitchFile(function(f)
 gMarks = gMarksMap[f]
end)

function current_line()
	return editor:LineFromPosition(editor.CurrentPos)+1
end

local markers_defined = false
local base = 9

function define_markers()
  local zero = string.byte('0')
  for i = 1,9 do
      editor:MarkerDefine(i+base,SC_MARK_CHARACTER + zero + i)
  end
  markers_defined = true
end

function do_ctrl_command(key)
    editor:BeginUndoAction()
    scite_OnChar('once',function (ch)
       editor:EndUndoAction()
       editor:Undo()
       local num = tonumber(ch)
       local mark = num and gMarks[num]
       local line = current_line()
       if key == 'k' and num then
          if not markers_defined then define_markers() end
          if mark then -- clear mark
             gMarks[num] = nil
             editor:MarkerDelete(line-1,num+base)
          else
             gMarks[num] = line
             editor:MarkerAdd(line-1,num+base)
			 print 'mark'
          end
       elseif key == 'q' and mark then
            editor:GotoLine(mark-1)
			if ctags_center_pos then ctags_center_pos(mark-1) end
       end
       return true
     end)
end     
