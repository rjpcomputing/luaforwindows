--- Operations on two-dimensional arrays.
-- See @{02-arrays.md.Operations_on_two_dimensional_tables|The Guide}
--
-- Dependencies: `pl.utils`, `pl.tablex`
-- @module pl.array2d

local require, type,tonumber,assert,tostring,io,ipairs,string,table =
 _G.require, _G.type,_G.tonumber,_G.assert,_G.tostring,_G.io,_G.ipairs,_G.string,_G.table
local setmetatable,getmetatable = setmetatable,getmetatable

local tablex = require 'pl.tablex'
local utils = require 'pl.utils'

local imap,tmap,reduce,keys,tmap2,tset,index_by = tablex.imap,tablex.map,tablex.reduce,tablex.keys,tablex.map2,tablex.set,tablex.index_by
local remove = table.remove
local splitv,fprintf,assert_arg = utils.splitv,utils.fprintf,utils.assert_arg
local byte = string.byte
local stdout = io.stdout

local array2d = {}

local function obj (int,out)
    local mt = getmetatable(int)
    if mt then
        setmetatable(out,mt)
    end
    return out
end

local function makelist (res)
    return setmetatable(res,utils.stdmt.List)
end


local function index (t,k)
    return t[k]
end

--- return the row and column size.
-- @param t a 2d array
-- @return number of rows
-- @return number of cols
function array2d.size (t)
    assert_arg(1,t,'table')
    return #t,#t[1]
end

--- extract a column from the 2D array.
-- @param a 2d array
-- @param key an index or key
-- @return 1d array
function array2d.column (a,key)
    assert_arg(1,a,'table')
    return makelist(imap(index,a,key))
end
local column = array2d.column

--- map a function over a 2D array
-- @param f a function of at least one argument
-- @param a 2d array
-- @param arg an optional extra argument to be passed to the function.
-- @return 2d array
function array2d.map (f,a,arg)
    assert_arg(1,a,'table')
    f = utils.function_arg(1,f)
    return obj(a,imap(function(row) return imap(f,row,arg) end, a))
end

--- reduce the rows using a function.
-- @param f a binary function
-- @param a 2d array
-- @return 1d array
-- @see pl.tablex.reduce
function array2d.reduce_rows (f,a)
    assert_arg(1,a,'table')
    return tmap(function(row) return reduce(f,row) end, a)
end

--- reduce the columns using a function.
-- @param f a binary function
-- @param a 2d array
-- @return 1d array
-- @see pl.tablex.reduce
function array2d.reduce_cols (f,a)
    assert_arg(1,a,'table')
    return tmap(function(c) return reduce(f,column(a,c)) end, keys(a[1]))
end

--- reduce a 2D array into a scalar, using two operations.
-- @param opc operation to reduce the final result
-- @param opr operation to reduce the rows
-- @param a 2D array
function array2d.reduce2 (opc,opr,a)
    assert_arg(3,a,'table')
    local tmp = array2d.reduce_rows(opr,a)
    return reduce(opc,tmp)
end

local function dimension (t)
    return type(t[1])=='table' and 2 or 1
end

--- map a function over two arrays.
-- They can be both or either 2D arrays
-- @param f function of at least two arguments
-- @param ad order of first array
-- @param bd order of second array
-- @param a 1d or 2d array
-- @param b 1d or 2d array
-- @param arg optional extra argument to pass to function
-- @return 2D array, unless both arrays are 1D
function array2d.map2 (f,ad,bd,a,b,arg)
    assert_arg(1,a,'table')
    assert_arg(2,b,'table')
    f = utils.function_arg(1,f)
    --local ad,bd = dimension(a),dimension(b)
    if ad == 1 and bd == 2 then
        return imap(function(row)
            return tmap2(f,a,row,arg)
        end, b)
    elseif ad == 2 and bd == 1 then
        return imap(function(row)
            return tmap2(f,row,b,arg)
        end, a)
    elseif ad == 1 and bd == 1 then
        return tmap2(f,a,b)
    elseif ad == 2 and bd == 2 then
        return tmap2(function(rowa,rowb)
            return tmap2(f,rowa,rowb,arg)
        end, a,b)
    end
end

--- cartesian product of two 1d arrays.
-- @param f a function of 2 arguments
-- @param t1 a 1d table
-- @param t2 a 1d table
-- @return 2d table
-- @usage product('..',{1,2},{'a','b'}) == {{'1a','2a'},{'1b','2b'}}
function array2d.product (f,t1,t2)
    f = utils.function_arg(1,f)
    assert_arg(2,t1,'table')
    assert_arg(3,t2,'table')
    local res, map = {}, tablex.map
    for i,v in ipairs(t2) do
        res[i] = map(f,t1,v)
    end
    return res
end

--- flatten a 2D array.
-- (this goes over columns first.)
-- @param t 2d table
-- @return a 1d table
-- @usage flatten {{1,2},{3,4},{5,6}} == {1,2,3,4,5,6}
function array2d.flatten (t)
    local res = {}
    local k = 1
    for _,a in ipairs(t) do -- for all rows
        for i = 1,#a do
            res[k] = a[i]
            k = k + 1
        end
    end
    return makelist(res)
end

--- reshape a 2D array.
-- @param t 2d array
-- @param nrows new number of rows
-- @param co column-order (Fortran-style) (default false)
-- @return a new 2d array
function array2d.reshape (t,nrows,co)
    local nr,nc = array2d.size(t)
    local ncols = nr*nc / nrows
    local res = {}
    local ir,ic = 1,1
    for i = 1,nrows do
        local row = {}
        for j = 1,ncols do
            row[j] = t[ir][ic]
            if not co then
                ic = ic + 1
                if ic > nc then
                    ir = ir + 1
                    ic = 1
                end
            else
                ir = ir + 1
                if ir > nr then
                    ic = ic + 1
                    ir = 1
                end
            end
        end
        res[i] = row
    end
    return obj(t,res)
end

--- swap two rows of an array.
-- @param t a 2d array
-- @param i1 a row index
-- @param i2 a row index
function array2d.swap_rows (t,i1,i2)
    assert_arg(1,t,'table')
    t[i1],t[i2] = t[i2],t[i1]
end

--- swap two columns of an array.
-- @param t a 2d array
-- @param j1 a column index
-- @param j2 a column index
function array2d.swap_cols (t,j1,j2)
    assert_arg(1,t,'table')
    for i = 1,#t do
        local row = t[i]
        row[j1],row[j2] = row[j2],row[j1]
    end
end

--- extract the specified rows.
-- @param t 2d array
-- @param ridx a table of row indices
function array2d.extract_rows (t,ridx)
    return obj(t,index_by(t,ridx))
end

--- extract the specified columns.
-- @param t 2d array
-- @param cidx a table of column indices
function array2d.extract_cols (t,cidx)
    assert_arg(1,t,'table')
    local res = {}
    for i = 1,#t do
        res[i] = index_by(t[i],cidx)
    end
    return obj(t,res)
end

--- remove a row from an array.
-- @class function
-- @name array2d.remove_row
-- @param t a 2d array
-- @param i a row index
array2d.remove_row = remove

--- remove a column from an array.
-- @param t a 2d array
-- @param j a column index
function array2d.remove_col (t,j)
    assert_arg(1,t,'table')
    for i = 1,#t do
        remove(t[i],j)
    end
end

local Ai = byte 'A'

local function _parse (s)
    local c,r
    if s:sub(1,1) == 'R' then
        r,c = s:match 'R(%d+)C(%d+)'
        r,c = tonumber(r),tonumber(c)
    else
        c,r = s:match '(.)(.)'
        c = byte(c) - byte 'A' + 1
        r = tonumber(r)
    end
    assert(c ~= nil and r ~= nil,'bad cell specifier: '..s)
    return r,c
end

--- parse a spreadsheet range.
-- The range can be specified either as 'A1:B2' or 'R1C1:R2C2';
-- a special case is a single element (e.g 'A1' or 'R1C1')
-- @param s a range.
-- @return start col
-- @return start row
-- @return end col
-- @return end row
function array2d.parse_range (s)
    if s:find ':' then
        local start,finish = splitv(s,':')
        local i1,j1 = _parse(start)
        local i2,j2 = _parse(finish)
        return i1,j1,i2,j2
    else -- single value
        local i,j = _parse(s)
        return i,j
    end
end

--- get a slice of a 2D array using spreadsheet range notation. @see parse_range
-- @param t a 2D array
-- @param rstr range expression
-- @return a slice
-- @see array2d.parse_range
-- @see array2d.slice
function array2d.range (t,rstr)
    assert_arg(1,t,'table')
    local i1,j1,i2,j2 = array2d.parse_range(rstr)
    if i2 then
        return array2d.slice(t,i1,j1,i2,j2)
    else -- single value
        return t[i1][j1]
    end
end

local function default_range (t,i1,j1,i2,j2)
    local nr, nc = array2d.size(t)
    i1,j1 = i1 or 1, j1 or 1
    i2,j2 = i2 or nr, j2 or nc
    if i2 < 0 then i2 = nr + i2 + 1 end
    if j2 < 0 then j2 = nc + j2 + 1 end
    return i1,j1,i2,j2
end

--- get a slice of a 2D array. Note that if the specified range has
-- a 1D result, the rank of the result will be 1.
-- @param t a 2D array
-- @param i1 start row (default 1)
-- @param j1 start col (default 1)
-- @param i2 end row   (default N)
-- @param j2 end col   (default M)
-- @return an array, 2D in general but 1D in special cases.
function array2d.slice (t,i1,j1,i2,j2)
    assert_arg(1,t,'table')
    i1,j1,i2,j2 = default_range(t,i1,j1,i2,j2)
    local res = {}
    for i = i1,i2 do
        local val
        local row = t[i]
        if j1 == j2 then
            val = row[j1]
        else
            val = {}
            for j = j1,j2 do
                val[#val+1] = row[j]
            end
        end
        res[#res+1] = val
    end
    if i1 == i2 then res = res[1] end
    return obj(t,res)
end

--- set a specified range of an array to a value.
-- @param t a 2D array
-- @param value the value (may be a function)
-- @param i1 start row (default 1)
-- @param j1 start col (default 1)
-- @param i2 end row   (default N)
-- @param j2 end col   (default M)
-- @see tablex.set
function array2d.set (t,value,i1,j1,i2,j2)
    i1,j1,i2,j2 = default_range(t,i1,j1,i2,j2)
    for i = i1,i2 do
        tset(t[i],value,j1,j2)
    end
end

--- write a 2D array to a file.
-- @param t a 2D array
-- @param f a file object (default stdout)
-- @param fmt a format string (default is just to use tostring)
-- @param i1 start row (default 1)
-- @param j1 start col (default 1)
-- @param i2 end row   (default N)
-- @param j2 end col   (default M)
function array2d.write (t,f,fmt,i1,j1,i2,j2)
    assert_arg(1,t,'table')
    f = f or stdout
    local rowop
    if fmt then
        rowop = function(row,j) fprintf(f,fmt,row[j]) end
    else
        rowop = function(row,j) f:write(tostring(row[j]),' ') end
    end
    local function newline()
        f:write '\n'
    end
    array2d.forall(t,rowop,newline,i1,j1,i2,j2)
end

--- perform an operation for all values in a 2D array.
-- @param t 2D array
-- @param row_op function to call on each value
-- @param end_row_op function to call at end of each row
-- @param i1 start row (default 1)
-- @param j1 start col (default 1)
-- @param i2 end row   (default N)
-- @param j2 end col   (default M)
function array2d.forall (t,row_op,end_row_op,i1,j1,i2,j2)
    assert_arg(1,t,'table')
    i1,j1,i2,j2 = default_range(t,i1,j1,i2,j2)
    for i = i1,i2 do
        local row = t[i]
        for j = j1,j2 do
            row_op(row,j)
        end
        if end_row_op then end_row_op(i) end
    end
end

local min, max = math.min, math.max

---- move a block from the destination to the source.
-- @param dest a 2D array
-- @param di start row in dest
-- @param dj start col in dest
-- @param src a 2D array
-- @param i1 start row (default 1)
-- @param j1 start col (default 1)
-- @param i2 end row   (default N)
-- @param j2 end col   (default M)
function array2d.move (dest,di,dj,src,i1,j1,i2,j2)
    assert_arg(1,dest,'table')
    assert_arg(4,src,'table')
    i1,j1,i2,j2 = default_range(src,i1,j1,i2,j2)
    local nr,nc = array2d.size(dest)
    i2, j2 = min(nr,i2), min(nc,j2)
    --i1, j1 = max(1,i1), max(1,j1)
    dj = dj - 1
    for i = i1,i2 do
        local drow, srow = dest[i+di-1], src[i]
        for j = j1,j2 do
            drow[j+dj] = srow[j]
        end
    end
end

--- iterate over all elements in a 2D array, with optional indices.
-- @param a 2D array
-- @param indices with indices (default false)
-- @param i1 start row (default 1)
-- @param j1 start col (default 1)
-- @param i2 end row   (default N)
-- @param j2 end col   (default M)
-- @return either value or i,j,value depending on indices
function array2d.iter (a,indices,i1,j1,i2,j2)
    assert_arg(1,a,'table')
    local norowset = not (i2 and j2)
    i1,j1,i2,j2 = default_range(a,i1,j1,i2,j2)
    local n,i,j = i2-i1+1,i1-1,j1-1
    local row,nr = nil,0
    local onr = j2 - j1 + 1
    return function()
        j = j + 1
        if j > nr then
            j = j1
            i = i + 1
            if i > i2 then return nil end
            row = a[i]
            nr = norowset and #row or onr
        end
        if indices then
            return i,j,row[j]
        else
            return row[j]
        end
    end
end

--- iterate over all columns.
-- @param a a 2D array
-- @return each column in turn
function array2d.columns (a)
    assert_arg(1,a,'table')
    local n = a[1][1]
    local i = 0
    return function()
        i = i + 1
        if i > n then return nil end
        return column(a,i)
    end
end

--- new array of specified dimensions
-- @param rows number of rows
-- @param cols number of cols
-- @param val initial value; if it's a function then use `val(i,j)`
-- @return new 2d array
function array2d.new(rows,cols,val)
    local res = {}
    local fun = utils.is_callable(val)
    for i = 1,rows do
        local row = {}
        if fun then
            for j = 1,cols do row[j] = val(i,j) end
        else
            for j = 1,cols do row[j] = val end
        end
        res[i] = row
    end
    return res
end

return array2d


