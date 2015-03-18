--- Reads configuration files into a Lua table.
--  Understands INI files, classic Unix config files, and simple
-- delimited columns of values.
--
--    # test.config
--    # Read timeout in seconds
--    read.timeout=10
--    # Write timeout in seconds
--    write.timeout=5
--    #acceptable ports
--    ports = 1002,1003,1004
--
--    -- readconfig.lua
--    require 'pl'
--    local t = config.read 'test.config'
--    print(pretty.write(t))
--
--    ### output #####
--    {
--      ports = {
--        1002,
--        1003,
--        1004
--      },
--      write_timeout = 5,
--      read_timeout = 10
--    }
--
-- See the Guide for further @{06-data.md.Reading_Configuration_Files|discussion}
--
-- Dependencies: none
-- @module pl.config

local type,tonumber,ipairs,io, table = _G.type,_G.tonumber,_G.ipairs,_G.io,_G.table

local function split(s,re)
    local res = {}
    local t_insert = table.insert
    re = '[^'..re..']+'
    for k in s:gmatch(re) do t_insert(res,k) end
    return res
end

local function strip(s)
    return s:gsub('^%s+',''):gsub('%s+$','')
end

local function strip_quotes (s)
    return s:gsub("['\"](.*)['\"]",'%1')
end

local config = {}

--- like io.lines(), but allows for lines to be continued with '\'.
-- @param file a file-like object (anything where read() returns the next line) or a filename.
-- Defaults to stardard input.
-- @return an iterator over the lines, or nil
-- @return error 'not a file-like object' or 'file is nil'
function config.lines(file)
    local f,openf,err
    local line = ''
    if type(file) == 'string' then
        f,err = io.open(file,'r')
        if not f then return nil,err end
        openf = true
    else
        f = file or io.stdin
        if not file.read then return nil, 'not a file-like object' end
    end
    if not f then return nil, 'file is nil' end
    return function()
        local l = f:read()
        while l do
            -- does the line end with '\'?
            local i = l:find '\\%s*$'
            if i then -- if so,
                line = line..l:sub(1,i-1)
            elseif line == '' then
                return l
            else
                l = line..l
                line = ''
                return l
            end
            l = f:read()
        end
        if openf then f:close() end
    end
end

--- read a configuration file into a table
-- @param file either a file-like object or a string, which must be a filename
-- @param cnfg a configuration table that may contain these fields:
--
--  * `variablilize` make names into valid Lua identifiers (default `true`)
--  * `convert_numbers` function to convert values into numbers (default `tonumber`)
--  * `trim_space` ensure that there is no starting or trailing whitespace with values (default `true`)
--  * `trim_quotes` remove quotes from strings (default `false`)
--  * `list_delim` delimiter to use when separating columns (default ',')
--  * `ignore_assign` ignore any key-pair assignments (default `false`)
--  * `kepsep` use this as key-pair separator (default '=')
--
-- @return a table containing items, or nil
-- @return error message (same as @{config.lines})
function config.read(file,cnfg)
    local f,openf,err
    cnfg = cnfg or {}
    local function check_cnfg (var,def)
        local val = cnfg[var]
        if val == nil then return def else return val end
    end
    local t = {}
    local top_t = t
    local variablilize = check_cnfg ('variabilize',true)
    local list_delim = check_cnfg('list_delim',',')
    local convert_numbers = check_cnfg('convert_numbers',tonumber)
    if convert_numbers==true then convert_numbers = tonumber end
    local trim_space = check_cnfg('trim_space',true)
    local trim_quotes = check_cnfg('trim_quotes',false)
    local ignore_assign = check_cnfg('ignore_assign',false)
    local keysep = check_cnfg('keysep','=')
    local keypat = keysep == ' ' and '%s+' or '%s*'..keysep..'%s*'

    local function process_name(key)
        if variablilize then
            key = key:gsub('[^%w]','_')
        end
        return key
    end

    local function process_value(value)
        if list_delim and value:find(list_delim) then
            value = split(value,list_delim)
            for i,v in ipairs(value) do
                value[i] = process_value(v)
            end
        elseif convert_numbers and value:find('^[%d%+%-]') then
            local val = convert_numbers(value)
            if val then value = val end
        end
        if type(value) == 'string' then
           if trim_space then value = strip(value) end
           if trim_quotes then value = strip_quotes(value) end
        end
        return value
    end

    local iter,err = config.lines(file)
    if not iter then return nil,err end
    for line in iter do
        -- strips comments
        local ci = line:find('%s*[#;]')
        if ci then line = line:sub(1,ci-1) end
        -- and ignore blank lines
        if  line:find('^%s*$') then
        elseif line:find('^%[') then -- section!
            local section = process_name(line:match('%[([^%]]+)%]'))
            t = top_t
            t[section] = {}
            t = t[section]
        else
            line = line:gsub('^%s*','')
            local i1,i2 = line:find(keypat)
            if i1 and not ignore_assign then -- key,value assignment
                local key = process_name(line:sub(1,i1-1))
                local value = process_value(line:sub(i2+1))
                t[key] = value
            else -- a plain list of values...
                t[#t+1] = process_value(line)
            end
        end
    end
    return top_t
end

return config
