--- Reading and querying simple tabular data.
--
--    data.read 'test.txt'
--    ==> {{10,20},{2,5},{40,50},fieldnames={'x','y'},delim=','}
--
-- Provides a way of creating basic SQL-like queries.
--
--    require 'pl'
--    local d = data.read('xyz.txt')
--    local q = d:select('x,y,z where x > 3 and z < 2 sort by y')
--    for x,y,z in q do
--        print(x,y,z)
--    end
--
-- See @{06-data.md.Reading_Columnar_Data|the Guide}
--
-- Dependencies: `pl.utils`, `pl.array2d` (fallback methods)
-- @module pl.data

local utils = require 'pl.utils'
local _DEBUG = rawget(_G,'_DEBUG')

local patterns,function_arg,usplit = utils.patterns,utils.function_arg,utils.split
local append,concat = table.insert,table.concat
local gsub = string.gsub
local io = io
local _G,print,type,tonumber,ipairs,setmetatable,pcall,error,setfenv = _G,print,type,tonumber,ipairs,setmetatable,pcall,error,setfenv


local data = {}

local parse_select

local function count(s,chr)
    chr = utils.escape(chr)
    local _,cnt = s:gsub(chr,' ')
    return cnt
end

local function rstrip(s)
    return s:gsub('%s+$','')
end

local function make_list(l)
    return setmetatable(l,utils.stdmt.List)
end

local function split(s,delim)
    return make_list(usplit(s,delim))
end

local function map(fun,t)
    local res = {}
    for i = 1,#t do
        append(res,fun(t[i]))
    end
    return res
end

local function find(t,v)
    for i = 1,#t do
        if v == t[i] then return i end
    end
end

local DataMT = {
    column_by_name = function(self,name)
        if type(name) == 'number' then
            name = '$'..name
        end
        local arr = {}
        for res in data.query(self,name) do
            append(arr,res)
        end
        return make_list(arr)
    end,

    copy_select = function(self,condn)
        condn = parse_select(condn,self)
        local iter = data.query(self,condn)
        local res = {}
        local row = make_list{iter()}
        while #row > 0 do
            append(res,row)
            row = make_list{iter()}
        end
        res.delim = self.delim
        return data.new(res,split(condn.fields,','))
    end,

    column_names = function(self)
        return self.fieldnames
    end,
}

local array2d

DataMT.__index = function(self,name)
    local f = DataMT[name]
    if f then return f end
    if not array2d then
        array2d = require 'pl.array2d'
    end
    return array2d[name]
end

--- return a particular column as a list of values (method).
-- @param name either name of column, or numerical index.
-- @function Data.column_by_name

--- return a query iterator on this data (method).
-- @param condn the query expression
-- @function Data.select
-- @see data.query

--- return a row iterator on this data (method).
-- @param condn the query expression
-- @function Data.select_row

--- return a new data object based on this query (method).
-- @param condn the query expression
-- @function Data.copy_select

--- return the field names of this data object (method).
-- @function Data.column_names

--- write out a row (method).
-- @param f file-like object
-- @function Data.write_row

--- write data out to file (method).
-- @param f file-like object
-- @function Data.write


-- [guessing delimiter] We check for comma, tab and spaces in that order.
-- [issue] any other delimiters to be checked?
local delims = {',','\t',' ',';'}

local function guess_delim (line)
    if line=='' then return ' ' end
    for _,delim in ipairs(delims) do
        if count(line,delim) > 0 then
            return delim == ' ' and '%s+' or delim
        end
    end
    return ' '
end

-- [file parameter] If it's a string, we try open as a filename. If nil, then
-- either stdin or stdout depending on the mode. Otherwise, check if this is
-- a file-like object (implements read or write depending)
local function open_file (f,mode)
    local opened, err
    local reading = mode == 'r'
    if type(f) == 'string' then
        if f == 'stdin'  then
            f = io.stdin
        elseif f == 'stdout'  then
            f = io.stdout
        else
            f,err = io.open(f,mode)
            if not f then return nil,err end
            opened = true
        end
    end
    if f and ((reading and not f.read) or (not reading and not f.write)) then
        return nil, "not a file-like object"
    end
    return f,nil,opened
end

local function all_n ()

end

--- read a delimited file in a Lua table.
-- By default, attempts to treat first line as separated list of fieldnames.
-- @param file a filename or a file-like object (default stdin)
-- @param cnfg options table: can override delim (a string pattern), fieldnames (a list),
-- specify no_convert (default is to convert), numfields (indices of columns known
-- to be numbers) and thousands_dot (thousands separator in Excel CSV is '.')
function data.read(file,cnfg)
    local convert,err,opened
    local D = {}
    if not cnfg then cnfg = {} end
    local f,err,opened = open_file(file,'r')
    if not f then return nil, err end
    local thousands_dot = cnfg.thousands_dot

    local function try_tonumber(x)
        if thousands_dot then x = x:gsub('%.(...)','%1') end
        return tonumber(x)
    end

    local line = f:read()
    if not line then return nil, "empty file" end
    -- first question: what is the delimiter?
    D.delim = cnfg.delim and cnfg.delim or guess_delim(line)
    local delim = D.delim
    local collect_end = cnfg.last_field_collect
    local numfields = cnfg.numfields
    -- some space-delimited data starts with a space.  This should not be a column,
    -- although it certainly would be for comma-separated, etc.
    local strip
    if delim == '%s+' and line:find(delim) == 1 then
        strip = function(s)  return s:gsub('^%s+','') end
        line = strip(line)
    end
    -- first line will usually be field names. Unless fieldnames are specified,
    -- we check if it contains purely numerical values for the case of reading
    -- plain data files.
    if not cnfg.fieldnames then
        local fields = split(line,delim)
        local nums = map(tonumber,fields)
        if #nums == #fields then
            convert = tonumber
            append(D,nums)
            numfields = {}
            for i = 1,#nums do numfields[i] = i end
        else
            cnfg.fieldnames = fields
        end
        line = f:read()
        if strip then line = strip(line) end
    elseif type(cnfg.fieldnames) == 'string' then
        cnfg.fieldnames = split(cnfg.fieldnames,delim)
    end
    -- at this point, the column headers have been read in. If the first
    -- row consisted of numbers, it has already been added to the dataset.
    if cnfg.fieldnames then
        D.fieldnames = cnfg.fieldnames
        -- [conversion] unless @no_convert, we need the numerical field indices
        -- of the first data row. Can also be specified by @numfields.
        if not cnfg.no_convert then
            if not numfields then
                numfields = {}
                local fields = split(line,D.delim)
                for i = 1,#fields do
                    if tonumber(fields[i]) then
                        append(numfields,i)
                    end
                end
            end
            if #numfields > 0 then -- there are numerical fields
                -- note that using dot as the thousands separator (@thousands_dot)
                -- requires a special conversion function!
                convert = thousands_dot and try_tonumber or tonumber
            end
        end
    end
    -- keep going until finished
    while line do
        if not line:find ('^%s*$') then
            if strip then line = strip(line) end
            local fields =  split(line,delim)
            if convert then
                for k = 1,#numfields do
                    local i = numfields[k]
                    local val = convert(fields[i])
                    if val == nil then
                        return nil, "not a number: "..fields[i]
                    else
                        fields[i] = val
                    end
                end
            end
            -- [collecting end field] If @last_field_collect then we will collect
            -- all extra space-delimited fields into a single last field.
            if collect_end and #fields > #D.fieldnames then
                local ends,N = {},#D.fieldnames
                for i = N+1,#fields do
                    append(ends,fields[i])
                end
                ends = concat(ends,' ')
                local cfields = {}
                for i = 1,N do cfields[i] = fields[i] end
                cfields[N] = cfields[N]..' '..ends
                fields = cfields
            end
            append(D,fields)
        end
        line = f:read()
    end
    if opened then f:close() end
    if delim == '%s+' then D.delim = ' ' end
    if not D.fieldnames then D.fieldnames = {} end
    return data.new(D)
end

local function write_row (data,f,row,delim)
    f:write(concat(row,delim),'\n')
end

function DataMT:write_row(f,row)
    write_row(self,f,row,self.delim)
end

--- write 2D data to a file.
-- Does not assume that the data has actually been
-- generated with `new` or `read`.
-- @param data 2D array
-- @param file filename or file-like object
-- @param fieldnames list of fields (optional)
-- @param delim delimiter (default tab)
function data.write (data,file,fieldnames,delim)
    local f,err,opened = open_file(file,'w')
    if not f then return nil, err end
    if fieldnames and #fieldnames > 0 then
        f:write(concat(data.fieldnames,delim),'\n')
    end
    delim = delim or '\t'
    for i = 1,#data do
        write_row(data,f,data[i],delim)
    end
    if opened then f:close() end
end


function DataMT:write(file)
    data.write(self,file,self.fieldnames,self.delim)
end

local function massage_fieldnames (fields)
    -- fieldnames must be valid Lua identifiers; ignore any surrounding padding
    for i = 1,#fields do
        fields[i] = rstrip(fields[i]):gsub('^%s*',''):gsub('%W','_')
    end
end

--- create a new dataset from a table of rows.
-- Can specify the fieldnames, else the table must have a field called
-- 'fieldnames', which is either a string of delimiter-separated names,
-- or a table of names. <br>
-- If the table does not have a field called 'delim', then an attempt will be
-- made to guess it from the fieldnames string, defaults otherwise to tab.
-- @param d the table.
-- @param fieldnames optional fieldnames
-- @return the table.
function data.new (d,fieldnames)
    d.fieldnames = d.fieldnames or fieldnames or ''
    if not d.delim and type(d.fieldnames) == 'string' then
        d.delim = guess_delim(d.fieldnames)
        d.fieldnames = split(d.fieldnames,d.delim)
    end
    d.fieldnames = make_list(d.fieldnames)
    massage_fieldnames(d.fieldnames)
    setmetatable(d,DataMT)
    -- a query with just the fieldname will return a sequence
    -- of values, which seq.copy turns into a table.
    return d
end

local sorted_query = [[
return function (t)
    local i = 0
    local v
    local ls = {}
    for i,v in ipairs(t) do
        if CONDITION then
            ls[#ls+1] = v
        end
    end
    table.sort(ls,function(v1,v2)
        return SORT_EXPR
    end)
    local n = #ls
    return function()
        i = i + 1
        v = ls[i]
        if i > n then return end
        return FIELDLIST
    end
end
]]

-- question: is this optimized case actually worth the extra code?
local simple_query = [[
return function (t)
    local n = #t
    local i = 0
    local v
    return function()
        repeat
            i = i + 1
            v = t[i]
        until i > n or CONDITION
        if i > n then return end
        return FIELDLIST
    end
end
]]

local function is_string (s)
    return type(s) == 'string'
end

local field_error

local function fieldnames_as_string (data)
    return concat(data.fieldnames,',')
end

local function massage_fields(data,f)
    local idx
    if f:find '^%d+$' then
        idx = tonumber(f)
    else
        idx = find(data.fieldnames,f)
    end
    if idx then
        return 'v['..idx..']'
    else
        field_error = f..' not found in '..fieldnames_as_string(data)
        return f
    end
end


local function process_select (data,parms)
    --- preparing fields ----
    local res,ret
    field_error = nil
    local fields = parms.fields
    local numfields = fields:find '%$'  or #data.fieldnames == 0
    if fields:find '^%s*%*%s*' then
        if not numfields then
            fields = fieldnames_as_string(data)
        else
            local ncol = #data[1]
            fields = {}
            for i = 1,ncol do append(fields,'$'..i) end
            fields = concat(fields,',')
        end
    end
    local idpat = patterns.IDEN
    if numfields then
        idpat = '%$(%d+)'
    else
        -- massage field names to replace non-identifier chars
        fields = rstrip(fields):gsub('[^,%w]','_')
    end
    local massage_fields = utils.bind1(massage_fields,data)
    ret = gsub(fields,idpat,massage_fields)
    if field_error then return nil,field_error end
    parms.fields = fields
    parms.proc_fields = ret
    parms.where = parms.where or  'true'
    if is_string(parms.where) then
        parms.where = gsub(parms.where,idpat,massage_fields)
        field_error = nil
    end
    return true
end


parse_select = function(s,data)
    local endp
    local parms = {}
    local w1,w2 = s:find('where ')
    local s1,s2 = s:find('sort by ')
    if w1 then -- where clause!
        endp = (s1 or 0)-1
        parms.where = s:sub(w2+1,endp)
    end
    if s1 then -- sort by clause (must be last!)
        parms.sort_by = s:sub(s2+1)
    end
    endp = (w1 or s1 or 0)-1
    parms.fields = s:sub(1,endp)
    local status,err = process_select(data,parms)
    if not status then return nil,err
    else return parms end
end

--- create a query iterator from a select string.
-- Select string has this format: <br>
-- FIELDLIST [ where LUA-CONDN [ sort by FIELD] ]<br>
-- FIELDLIST is a comma-separated list of valid fields, or '*'. <br> <br>
-- The condition can also be a table, with fields 'fields' (comma-sep string or
-- table), 'sort_by' (string) and 'where' (Lua expression string or function)
-- @param data table produced by read
-- @param condn select string or table
-- @param context a list of tables to be searched when resolving functions
-- @param return_row if true, wrap the results in a row table
-- @return an iterator over the specified fields, or nil
-- @return an error message
function data.query(data,condn,context,return_row)
    local err
    if is_string(condn) then
        condn,err = parse_select(condn,data)
        if not condn then return nil,err end
    elseif type(condn) == 'table' then
        if type(condn.fields) == 'table' then
            condn.fields = concat(condn.fields,',')
        end
        if not condn.proc_fields then
            local status,err = process_select(data,condn)
            if not status then return nil,err end
        end
    else
        return nil, "condition must be a string or a table"
    end
    local query, k
    if condn.sort_by then -- use sorted_query
        query = sorted_query
    else
        query = simple_query
    end
    local fields = condn.proc_fields or condn.fields
    if return_row then
        fields = '{'..fields..'}'
    end
    query,k = query:gsub('FIELDLIST',fields)
    if is_string(condn.where) then
        query = query:gsub('CONDITION',condn.where)
        condn.where = nil
    else
       query = query:gsub('CONDITION','_condn(v)')
       condn.where = function_arg(0,condn.where,'condition.where must be callable')
    end
    if condn.sort_by then
        local expr,sort_var,sort_dir
        local sort_by = condn.sort_by
        local i1,i2 = sort_by:find('%s+')
        if i1 then
            sort_var,sort_dir = sort_by:sub(1,i1-1),sort_by:sub(i2+1)
        else
            sort_var = sort_by
            sort_dir = 'asc'
        end
        if sort_var:match '^%$' then sort_var = sort_var:sub(2) end
        sort_var = massage_fields(data,sort_var)
        if field_error then return nil,field_error end
        if sort_dir == 'asc' then
            sort_dir = '<'
        else
            sort_dir = '>'
        end
        expr = ('%s %s %s'):format(sort_var:gsub('v','v1'),sort_dir,sort_var:gsub('v','v2'))
        query = query:gsub('SORT_EXPR',expr)
    end
    if condn.where then
        query = 'return function(_condn) '..query..' end'
    end
    if _DEBUG then print(query) end

    local fn,err = loadstring(query,'tmp')
    if not fn then return nil,err end
    fn = fn() -- get the function
    if condn.where then
        fn = fn(condn.where)
    end
    local qfun = fn(data)
    if context then
        -- [specifying context for condition] @context is a list of tables which are
        -- 'injected'into the condition's custom context
        append(context,_G)
        local lookup = {}
        setfenv(qfun,lookup)
        setmetatable(lookup,{
            __index = function(tbl,key)
               -- _G.print(tbl,key)
                for k,t in ipairs(context) do
                    if t[key] then return t[key] end
                end
            end
        })
    end
    return qfun
end


DataMT.select = data.query
DataMT.select_row = function(d,condn,context)
    return data.query(d,condn,context,true)
end

--- Filter input using a query.
-- @param Q a query string
-- @param infile filename or file-like object
-- @param outfile filename or file-like object
-- @param dont_fail true if you want to return an error, not just fail
function data.filter (Q,infile,outfile,dont_fail)
    local err
    local d = data.read(infile or 'stdin')
    local out = open_file(outfile or 'stdout')
    local iter,err = d:select(Q)
    local delim = d.delim
    if not iter then
        err = 'error: '..err
        if dont_fail then
            return nil,err
        else
            utils.quit(1,err)
        end
    end
    while true do
        local res = {iter()}
        if #res == 0 then break end
        out:write(concat(res,delim),'\n')
    end
end

return data

