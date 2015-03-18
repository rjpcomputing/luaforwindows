--switch_buffers.lua
--drops down a list of buffers, in recently-used order

--~ scite_Command 'Switch Buffer|do_buffer_list|Alt+F12'
--~ scite_Command 'Last Buffer|last_buffer|Ctrl+F12'

local buffers = {}
local remove = table.remove
local insert = table.insert
local current_path
local _DirChange = {}

function scite_OnDirChange(fn,rem)
  ex_append_unique(_DirChange,fn,rem)
end

scite_OnOpenSwitch(function(f)
--- swop the new current buffer with the last one!
    local idx  
    for i,file in ipairs(buffers) do
        if file == f then  idx = i; break end
    end
    if idx then 
        remove(buffers,idx)
        insert(buffers,1,f)
    else
        insert(buffers,1,f)
    end
	if current_path ~= props['FileDir'] then
		current_path = props['FileDir']
		DoDispatchOne(_DirChange,current_path)	
	end
end)

function last_buffer()
    if #buffers > 1 then
        scite.Open(buffers[2])
    end
end

function do_buffer_list()
    if not scite_GetPropBool('buffer.switch.fullpath',false) then
        local files = {}
        for i = 1,#buffers do
            files[i] = basename(buffers[i])
        end
        scite_UserListShow(files,2,function(s)
            for i = 1,#files do
                if s == files[i] then
                    scite.Open(buffers[i])
                end
            end
        end)
    else
        scite_UserListShow(buffers,2,scite.Open)
    end
end

