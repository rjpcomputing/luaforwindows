-------------------------------------------------------------------------=---
-- Name:      wxluasudoku.wx.lua
-- Purpose:   wxLuaSudoku - a wxLua program to generate/solve/play Sudoku puzzles
-- Author:    John Labenski
-- Created:   2006
-- Copyright: (c) 2006 John Labenski. All rights reserved.
-- Licence:   wxWindows licence
-------------------------------------------------------------------------=---

-- Load the wxLua module, does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit
package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"
require("wx")

-- Coding notes:
-- All non gui sudoku functions are in the "sudoku" table and all gui related
-- functions are in the "sudokuGui" table.

-- sudoku.GetXXX()  retrieve precalculated or set values from the sudoku table
-- sudoku.SetXXX()  set values to the sudoku table
-- sudoku.FindXXX() search the table for "stuff", but do not modify it, returns result
-- sudoku.CalcXXX() search the table for "stuff" and store the values to it for GetXXX functions

sudoku = sudoku or {} -- the table to hold the sudoku solver functions

-- ============================================================================
-- A simple function to implement "cond ? A : B", eg "result = iff(cond, A, B)"
--   note all terms must be able to be evaluated
function iff(cond, A, B) if cond then return A else return B end end

-- make the number or bool into a bool or number
function inttobool(n)
    if (n == nil) or (n == 0) then return false end
    return true
end
function booltoint(n)
    if (n == nil) or (n == false) then return 0 end
    return 1
end

-- ============================================================================
-- Simple functions to count the total number of elements in a table
-- Notes about speed : using for loop and pairs() in TableCount is 2X faster
--   than using while loop and next(table). However using next() is slightly
--   faster than using for k,v in pairs(t) do return true end in TableIsEmpty.

function TableCount(atable)
    local count = 0
    for k, v in pairs(atable) do count = count + 1 end
    return count
end
function TableIsEmpty(atable)
    return next(atable) == nil
end

-- Set a value in the table or subtable, first making sure that the subtables
--   are created first. Modifies the input table.
--   TableSetValue(3, atable, "How", "Are", 4, "You") ==> atable.How.Are[4].You = 3
function TableSetValue(value, atable, ...)
    if type(atable) ~= "table" then atable = {} end
    local t = atable -- t moves up levels through atable
    local args = {...}
    for n = 1, #args-1 do
        local a = args[n]
        if not t[a] then t[a] = {} end
        t = t[a]
    end
    t[args[#args]] = value
end
-- Remove a value in the table or subtable, first making sure that the subtables
--   exist. Modifies the input table.
--   TableRemoveValue(atable, false, "How", "Are", 4, "You") ==> atable.How.Are[4].You = nil
function TableRemoveValue(atable, only_if_empty, ...)
    if type(atable) ~= "table" then return end
    local t = atable -- t moves up levels through atable
    local args = {...}
    for n = 1, #args-1 do
        t = t[args[n]]
        if not t then return end -- already gone
    end
    if (not only_if_empty) or ((type(t[args[#args]]) == "table") and TableIsEmpty(t[args[#args]])) then
        t[args[#args]] = nil
    end
end

-- ============================================================================
-- completely dump the contents of a table
--   atable is the input table to dump the contents of
--   prefix is a string prefix for debugging purposes
--   tablelevel is tracker for recursive calls to TableDump (do not use initially)
function TableDump(atable, prefix, tablelevel)
    local function print_val(v)
        local t = type(v)
        if t == "number" then
            return tostring(v)
        elseif t == "string" then
            return "\""..v.."\""
        end
        return "'"..tostring(v).."'"
    end

    prefix = prefix or ""
    if tablelevel == nil then
        tablelevel = ""
        print(prefix.."-Dumping Table "..tostring(atable))
    end

    prefix = prefix.."  "
    local n = 0

    for k, v in pairs(atable) do
        n = n + 1

        print(string.format("%s %d: %s[%s] = %s", prefix, n, tablelevel, print_val(k), print_val(v)))

        if type(v) == "table" then
            TableDump(v, prefix.."  ", tablelevel.."["..print_val(k).."]")
        end
    end
end

-- ============================================================================
-- Make a deep copy of a table, including all sub tables, fails on recursive tables.
--   returns a new table
function TableCopy(atable)
    if not atable then return nil end
    local newtable = {}
    for k, v in pairs(atable) do
        if type(v) == "table" then
            newtable[k] = TableCopy(v)
        else
            newtable[k] = v
        end
    end
    return newtable
end

-- Merge the two tables together, adding or replacing values in original_table
--  with those in new_table, returns a new table and doesn't modify inputs
--  fails on recursive tables, returns the new table
function TableMerge(new_table, original_table)
    new_table       = new_table or {}
    local out_table = TableCopy(original_table or {})

    for k, v in pairs(new_table) do
        if type(v) == "table" then
            if out_table[k] and (type(out_table[k]) == "table") then
                out_table[k] = TableMerge(v, out_table[k])
            elseif out_table[k] then
                local ov = out_table[k]
                out_table[k] = TableCopy(v)
                table.insert(out_table[k], ov)
            else
                out_table[k] = TableCopy(v)
            end
        elseif out_table[k] and (type(out_table[k]) == "table") then
            table.insert(out_table[k], v)
        else
            out_table[k] = v
        end
    end

    return out_table
end

-- ============================================================================
-- Flags for the sudokuTable.flags[flag] = true/false/nil

sudoku.ELIMINATE_NAKED_PAIRS     = 1 -- for sudoku.CalcAllPossible(sudokuTable)
sudoku.ELIMINATE_HIDDEN_PAIRS    = 2 --   set to true to have it run
sudoku.ELIMINATE_NAKED_TRIPLETS  = 3 -- for sudoku.CalcAllPossible(sudokuTable)
sudoku.ELIMINATE_HIDDEN_TRIPLETS = 4 --   set to true to have it run
sudoku.ELIMINATE_NAKED_QUADS     = 5 -- for sudoku.CalcAllPossible(sudokuTable)
sudoku.ELIMINATE_HIDDEN_QUADS    = 6 --   set to true to have it run
sudoku.FILENAME                  = 7 -- store the fileName from Open/Save functions

sudoku.ELIMINATE_FLAG_MIN        = 1 -- for iterating the ELIMINATE flags
sudoku.ELIMINATE_FLAG_MAX        = 6

-- given the upper left cell of block you can iterate through the block using
--   for n = 1, 9 do cell = n + block_cell + sudoku.LinearBlockCellTable[n] ... end
sudoku.LinearBlockCellTable = { -1, -1, -1, 5, 5, 5, 11, 11, 11 }

sudoku.CellToRowTable   = {}
sudoku.CellToColTable   = {}
sudoku.BlockToRowTable  = {}
sudoku.BlockToColTable  = {}
sudoku.CellToBlockTable = {}
sudoku.BlockToCellTable = {}

for cell = 1, 81 do
    local row = math.floor(cell/9.1)+1
    local col = cell-(row-1)*9
    sudoku.CellToRowTable[cell] = row
    sudoku.CellToColTable[cell] = col

    local block_row = math.floor(row/3.5)+1
    local block_col = math.floor(col/3.5)+1
    sudoku.CellToBlockTable[cell] = (block_row-1)*3 + block_col
end

for block = 1, 9 do
    local row = math.floor(block/3.5)*3+1
    local col = math.fmod(block-1,3)*3+1
    sudoku.BlockToRowTable[block] = row
    sudoku.BlockToColTable[block] = col

    sudoku.BlockToCellTable[block] = (row-1)*9 + col
end

-- ============================================================================
-- Create a sudoku table to be used with the rest of the sudoku functions
function sudoku.CreateTable()
    local sudokuTable =
    {
        values       = {}, -- array (1-81) of values[cell#] = value (0 means unset)
        row_values   = {}, -- array (1-9) of values[row#][value] = { cell1, cell2... }
        col_values   = {}, -- array (1-9) of values[col#][value] = { cell1, cell2... }
        block_values = {}, -- array (1-9) of values[block#][value] = { cell1, cell2... }
        possible     = {}, -- possible values per cell, possible[cell# 1-81] = { val1, val2... }
        invalid      = {}, -- array (1-81) of known invalid[cell#] = true/nil
        flags        = {}  -- extra flags for puzzle, eg. ELIMINATE_NAKED_PAIRS
    }

    for i = 1, 81 do
        sudokuTable.values[i] = 0    -- initialize to unknown
        sudokuTable.possible[i] = {} -- initialize to empty
    end
    for i = 1, 9 do
        sudokuTable.row_values[i]   = {}
        sudokuTable.col_values[i]   = {}
        sudokuTable.block_values[i] = {}
    end

    sudoku.UpdateTable(sudokuTable)

    return sudokuTable
end

-- Update all the values in the table using only the cell values, modifies input sudokuTable.
function sudoku.UpdateTable(sudokuTable)
    sudoku.CalcRowColBlockValues(sudokuTable)
    sudoku.CalcInvalidCells(sudokuTable)
    sudoku.CalcAllPossible(sudokuTable)
end

-- Set the values table in the sudokuTable and update everything, modifies input sudokuTable.
function sudoku.SetValues(sudokuTable, values)
    sudokuTable.values = values
    sudoku.UpdateTable(sudokuTable)
end

-- Open a sudoku table from a file, the file should be formatted as 9x9 numbers
--  with 9 numbers per row and 9 columns.
--  returns a sudoku.CreateTable() with the values set and "" on success
--    or nil, error_message on failure
function sudoku.Open(fileName)
    local values      = {}
    local value_count = 0 -- number of cols in line
    local row_count   = 0 -- number of rows read
    local line_n      = 0 -- actual line number in file
    for line in io.lines(fileName) do
        line_n = line_n + 1
        local col_count = 0
        for k, v in string.gmatch(line, "%d") do
            k = tonumber(k)
            if (k >= 0) and (k <= 9) then
                table.insert(values, k)
                col_count = col_count + 1
                value_count = value_count + 1
            else
                return nil, string.format("Error loading sudoku file : '%s' invalid number '%d' on line %d.", fileName, k, line_n)
            end
        end

        if col_count == 9 then
            row_count = row_count + 1
        elseif (col_count ~= 0) and (col_count ~= 9) then
            return nil, string.format("Error loading sudoku file : '%s' on line %d.\nExpecting 9 columns, found %d.", fileName, line_n, col_count)
        end
    end

    if line_n == 0 then
        return nil, string.format("Error opening sudoku file : '%s'.", fileName)
    elseif row_count ~= 9 then
        return nil, string.format("Error loading sudoku file : '%s', expected 9 rows, found %d.", fileName, row_count)
    elseif value_count ~= 81 then
        return nil, string.format("Error loading sudoku file : '%s', expected 81 numbers, found %d.", fileName, value_count)
    end

    local s = sudoku.CreateTable()
    s.flags[sudoku.FILENAME] = fileName
    sudoku.SetValues(s, values)

    return s, ""
end

-- Save a sudoku grid as a 9x9 comma separated table to a file, returns success
function sudoku.Save(sudokuTable, fileName)
    local f = io.open(fileName, "w+")
    if not f then return false end

    local str = sudoku.ToString(sudokuTable)
    f:write(str)
    io.close(f)

    sudokuTable.flags[sudoku.FILENAME] = fileName

    return true
end

-- ============================================================================
-- Neatly print the sudoku grid
function sudoku.PrintGrid(sudokuTable)
    local str = string.rep("-", 13).."\n"
    for r = 1, 9 do
        str = str.."|"
        for c = 1, 9 do
            local v = " "
            if sudoku.HasValue(sudokuTable, r, c) then
                v = tostring(sudoku.GetValue(sudokuTable, r, c))
            end
            str = str..v
            if math.fmod(c, 3) == 0 then str = str.."|" end
        end
        str = str.."\n"
        if math.fmod(r, 3) == 0 then str = str..string.rep("-", 13).."\n" end
    end

    print(str)
end

-- Write the grid itself to a string as 9x9 with a space/line separating blocks
function sudoku.ToString(sudokuTable)
    local str = ""
    for r = 1, 9 do
        for c = 1, 9 do
            local v = "0"
            if sudoku.HasValue(sudokuTable, r, c) then
                v = tostring(sudoku.GetValue(sudokuTable, r, c))
            end
            str = str..v..","
            if math.fmod(c, 3) == 0 then str = str.." " end
        end
        str = str.."\n"
        if (r < 9) and (math.fmod(r, 3) == 0) then str = str.."\n" end
    end

    return str
end

-- Neatly print the possible values for each cell (you must calculate it first)
function sudoku.PrintPossible(sudokuTable)
    local str = string.rep("-", 103).."\n"
    for r = 1, 9 do
        str = str.."|"
        for c = 1, 9 do
            local has_value = sudoku.HasValue(sudokuTable, r, c)
            if has_value then str = str.."<" else str = str.."[" end
            local p = sudoku.GetPossible(sudokuTable, r, c)
            for i = 1, 9 do
                str = str..(p[i] or " ")
            end
            if has_value then str = str..">" else str = str.."]" end
            if math.fmod(c, 3) == 0 then str = str.."|" end
        end
        str = str.."\n"
        if math.fmod(r, 3) == 0 then str = str..string.rep("-", 103).."\n" end
    end

    print(str)
end

-- ============================================================================
-- Convert a row, col cell index (1-9) into a linear position in the grid (1-81)
function sudoku.RowColToCell(row, col)
    return (row-1)*9 + col
end
-- Convert a linear cell index (1-81) into a row, col cell index (1-9)
function sudoku.CellToRowCol(cell)
    return sudoku.CellToRowTable[cell], sudoku.CellToColTable[cell]
end
function sudoku.CellToRow(cell)
    return sudoku.CellToRowTable[cell]
end
function sudoku.CellToCol(cell)
    return sudoku.CellToColTable[cell]
end

-- ============================================================================
-- Check the validity of rows, cols, cells, blocks, values
function sudoku.IsValidValueN(value)
    return (value >= 1) and (value <= 9)
end

-- ============================================================================
-- Convert a row, col cell index (1-9) into the linear block number (1-9)
function sudoku.RowColToBlock(row, col)
    return sudoku.CellToBlockTable[sudoku.RowColToCell(row, col)]
end
-- Get the block (1-9) that this cell (1-81) is in
function sudoku.CellToBlock(cell)
    return sudoku.CellToBlockTable[cell]
end
-- Get the upper left cell of this block
function sudoku.BlockToCell(block)
    return sudoku.BlockToCellTable[block]
end
-- Convert a linear block index (1-9) into upper left row, col cell index (1-9)
function sudoku.BlockToRowCol(block)
    return sudoku.BlockToRowTable[block], sudoku.BlockToColTable[block]
end
function sudoku.BlockToRow(block)
    return sudoku.BlockToRowTable[block]
end
function sudoku.BlockToCol(block)
    return sudoku.BlockToColTable[block]
end
-- Get the upper left row, col cell of the block given by row, col
function sudoku.RowColToBlockRowCol(row, col)
    local block = sudoku.RowColToBlock(row, col)
    return sudoku.BlockToRowTable[block], sudoku.BlockToColTable[block]
end


-- Generate a table of {[cell] = {hash table of cells that are in the row, col, block of this cell}}
sudoku.cellToRowColBlockCellsTable = {}
for cell = 1, 81 do
    local row, col = sudoku.CellToRowCol(cell)
    local block_cell = sudoku.BlockToCell(sudoku.CellToBlock(cell))

    sudoku.cellToRowColBlockCellsTable[cell] = {}

    for rcb = 1, 9 do
        local c = sudoku.RowColToCell(rcb, col)
        sudoku.cellToRowColBlockCellsTable[cell][c] = true
        c = sudoku.RowColToCell(row, rcb)
        sudoku.cellToRowColBlockCellsTable[cell][c] = true
        c = rcb + block_cell + sudoku.LinearBlockCellTable[rcb]
        sudoku.cellToRowColBlockCellsTable[cell][c] = true
    end
end

-- Generate a table of {[cell] = {array of cells that are in the row, col, block of this cell}}
sudoku.cellToRowColBlockCellsArray = {}
for cell = 1, 81 do
    sudoku.cellToRowColBlockCellsArray[cell] = {}
    for k, v in pairs(sudoku.cellToRowColBlockCellsTable[cell]) do
        table.insert(sudoku.cellToRowColBlockCellsArray[cell], k)
    end
end

sudoku.RowCellTable = {}
sudoku.ColCellTable = {}
sudoku.BlockCellTable = {}
sudoku.BlockCellShiftTable = {0, 3, 6, 27, 30, 33, 54, 57, 60}

for n = 1, 9 do
    local nn = (n-1)*9
    sudoku.RowCellTable[n] = {1+nn, 2+nn, 3+nn, 4+nn, 5+nn, 6+nn, 7+nn, 8+nn, 9+nn}

    nn = n - 1
    sudoku.ColCellTable[n] = {1+nn, 10+nn, 19+nn, 28+nn, 37+nn, 46+nn, 55+nn, 64+nn, 73+nn}

    nn = sudoku.BlockCellShiftTable[n]
    sudoku.BlockCellTable[n] = {1+nn, 2+nn, 3+nn, 10+nn, 11+nn, 12+nn, 19+nn, 20+nn, 21+nn}
end

-- ============================================================================
-- Get the cell value at a specific row, col
function sudoku.GetValue(sudokuTable, row, col)
    return sudoku.GetCellValue(sudokuTable, sudoku.RowColToCell(row, col))
end
-- Set the cell value at a specific row, col, modifies input sudokuTable.
function sudoku.SetValue(sudokuTable, row, col, value)
    local cell      = sudoku.RowColToCell(row, col)
    local block     = sudoku.CellToBlock(cell)
    local old_value = sudokuTable.values[cell]

    if not sudoku.IsValidValueN(value) then value = 0 end
    sudokuTable.values[cell] = value

    --remove the old_value from the row, col, block values
    if sudoku.IsValidValueN(old_value) then
        if sudokuTable.row_values[row] and sudokuTable.row_values[row][old_value] then
            sudokuTable.row_values[row][old_value][cell] = nil
            if TableIsEmpty(sudokuTable.row_values[row][old_value]) then sudokuTable.row_values[row][old_value] = nil end
        end
        if sudokuTable.col_values[col] and sudokuTable.col_values[col][old_value] then
            sudokuTable.col_values[col][old_value][cell] = nil
            if TableIsEmpty(sudokuTable.col_values[col][old_value]) then sudokuTable.col_values[col][old_value] = nil end
        end
        if sudokuTable.block_values[block] and sudokuTable.block_values[block][old_value] then
            sudokuTable.block_values[block][old_value][cell] = nil
            if TableIsEmpty(sudokuTable.block_values[block][old_value]) then sudokuTable.block_values[block][old_value] = nil end
        end
    end
    --add new value to the row, col, block values
    if value ~= 0 then
        if not sudokuTable.row_values[row] then
            sudokuTable.row_values[row] = {[value] = {[cell] = cell}}
        elseif not sudokuTable.row_values[row][value] then
            sudokuTable.row_values[row][value] = {[cell] = cell}
        else
            sudokuTable.row_values[row][value][cell] = cell
        end

        if not sudokuTable.col_values[col] then
            sudokuTable.col_values[col] = {[value] = {[cell] = cell}}
        elseif not sudokuTable.col_values[col][value] then
            sudokuTable.col_values[col][value] = {[cell] = cell}
        else
            sudokuTable.col_values[col][value][cell] = cell
        end

        if not sudokuTable.block_values[block] then
            sudokuTable.block_values[block] = {[value] = {[cell] = cell}}
        elseif not sudokuTable.block_values[block][value] then
            sudokuTable.block_values[block][value] = {[cell] = cell}
        else
            sudokuTable.block_values[block][value][cell] = cell
        end
    end
end
-- Does the cell have a value at a specific row, col
function sudoku.HasValue(sudokuTable, row, col)
    return sudoku.HasCellValue(sudokuTable, sudoku.RowColToCell(row, col))
end

-- Set the cell value at a specific cell
function sudoku.GetCellValue(sudokuTable, cell)
    return sudokuTable.values[cell]
end
-- Set the cell value at a specific cell, modifies input sudokuTable.
function sudoku.SetCellValue(sudokuTable, cell, value)
    local row, col = sudoku.CellToRowCol(cell)
    sudoku.SetValue(sudokuTable, row, col, value)
end
-- Does the cell have a value at a specific cell
function sudoku.HasCellValue(sudokuTable, cell)
    return sudoku.IsValidValueN(sudokuTable.values[cell])
end

-- ============================================================================
-- Set the row_values, col_values, block_values tables of the input sudokuTable
-- eg. row values table is row_values[row#][value][cell#] = cell#
--     if no value then row_values[row#][value] = nil
function sudoku.CalcRowColBlockValues(sudokuTable)
    sudokuTable.row_values   = {}
    sudokuTable.col_values   = {}
    sudokuTable.block_values = {}

    for cell = 1, 81 do
        local row, col = sudoku.CellToRowCol(cell)
        local block    = sudoku.CellToBlock(cell)

        if not sudokuTable.row_values[row] then sudokuTable.row_values[row] = {} end
        if not sudokuTable.col_values[col] then sudokuTable.col_values[col] = {} end
        if not sudokuTable.block_values[block] then sudokuTable.block_values[block] = {} end

        local value = sudoku.GetCellValue(sudokuTable, cell)

        if sudoku.IsValidValueN(value) then
            if not sudokuTable.row_values[row][value] then
                sudokuTable.row_values[row][value] = {[cell] = cell}
            else
                sudokuTable.row_values[row][value][cell] = cell
            end
            if not sudokuTable.col_values[col][value] then
                sudokuTable.col_values[col][value] = {[cell] = cell}
            else
                sudokuTable.col_values[col][value][cell] = cell
            end
            if not sudokuTable.block_values[block][value] then
                sudokuTable.block_values[block][value] = {[cell] = cell}
            else
                sudokuTable.block_values[block][value][cell] =  cell
            end
        end
    end
end

-- ============================================================================
-- Can this value be put into this cell given the other existing values?
function sudoku.IsValidValue(sudokuTable, row, col, value)
    if sudokuTable.row_values[row][value] or
       sudokuTable.col_values[col][value] or
       sudokuTable.block_values[sudoku.RowColToBlock(row, col)][value] then
        return false
    end

    return true
end

-- Find all the invalid cells by looking for duplicates, modifies input sudokuTable.
--   fills sudokuTable.invalid table with the values
function sudoku.CalcInvalidCells(sudokuTable)
    sudokuTable.invalid = {} -- reset to all good

    for n = 1, 9 do
        for i, cell_table in pairs(sudokuTable.row_values[n]) do
            if TableCount(cell_table) > 1 then
                for j, cell in pairs(cell_table) do
                    sudokuTable.invalid[cell] = true
                end
            end
        end
        for i, cell_table in pairs(sudokuTable.col_values[n]) do
            if TableCount(cell_table) > 1 then
                for j, cell in pairs(cell_table) do
                    sudokuTable.invalid[cell] = true
                end
            end
        end
        for i, cell_table in pairs(sudokuTable.block_values[n]) do
            if TableCount(cell_table) > 1 then
                for j, cell in pairs(cell_table) do
                    sudokuTable.invalid[cell] = true
                end
            end
        end
    end
end

-- ============================================================================
-- Get the possible values at a specific row, col cell
--  Must be previously set from sudoku.CalcAllPossible
function sudoku.GetPossible(sudokuTable, row, col)
    return sudokuTable.possible[sudoku.RowColToCell(row, col)]
end
function sudoku.GetCellPossible(sudokuTable, cell)
    return sudokuTable.possible[cell]
end

-- Set the possible values at a specific row, col cell. Modifies input sudokuTable.
function sudoku.SetPossible(sudokuTable, row, col, possibleTable)
    sudokuTable.possible[sudoku.RowColToCell(row, col)] = possibleTable
end
function sudoku.SetCellPossible(sudokuTable, cell, possibleTable)
    sudokuTable.possible[cell] = possibleTable
end

-- Remove a possible value at a specific row, col cell only. Modifies input sudokuTable.
function sudoku.RemovePossible(sudokuTable, row, col, value)
    return sudoku.RemoveCellPossible(sudokuTable, sudoku.RowColToCell(row, col), value)
end
function sudoku.RemoveCellPossible(sudokuTable, cell, value)
    sudokuTable.possible[cell][value] = nil
end

-- Remove a possible values from the row, col, block. Modifies input sudokuTable.
--   if exceptTable then don't remove it from exceptTable[cell#] = true
function sudoku.RemovePossibleAll(sudokuTable, cell, value, exceptTable, break_if_empty)
    exceptTable = exceptTable or {}
    break_if_empty = break_if_empty or false

    for i, c in ipairs(sudoku.cellToRowColBlockCellsArray[cell]) do
        if (not exceptTable[c]) and sudokuTable.possible[c][value] then
            sudokuTable.possible[c][value] = nil
            if break_if_empty and (not sudoku.HasCellValue(sudokuTable, c)) and TableIsEmpty(sudokuTable.possible[c]) then
                return
            end
        end
    end
end
-- Remove a possible values from the row. Modifies input sudokuTable.
--   if exceptTable then don't remove it from exceptTable[cell#] = true
function sudoku.RemovePossibleRow(sudokuTable, row, value, exceptTable)
    exceptTable = exceptTable or {}
    for col = 1, 9 do
        local cell = sudoku.RowColToCell(row, col)
        if (not exceptTable[cell]) and sudokuTable.possible[cell][value] then
            sudokuTable.possible[cell][value] = nil
        end
    end
end
-- Remove a possible values from the col. Modifies input sudokuTable.
--   if exceptTable then don't remove it from exceptTable[cell#] = true
function sudoku.RemovePossibleCol(sudokuTable, col, value, exceptTable)
    exceptTable = exceptTable or {}
    for row = 1, 9 do
        local cell = sudoku.RowColToCell(row, col)
        if (not exceptTable[cell]) and sudokuTable.possible[cell][value] then
            sudokuTable.possible[cell][value] = nil
        end
    end
end
-- Remove a possible values from the block. Modifies input sudokuTable.
--   if exceptTable then don't remove it from exceptTable[cell#] = true
function sudoku.RemovePossibleBlock(sudokuTable, block, value, exceptTable)
    exceptTable = exceptTable or {}
    local block_cell = sudoku.BlockToCell(block)
    for n = 1, 9 do
        local cell = n + block_cell + sudoku.LinearBlockCellTable[n]
        if (not exceptTable[cell]) and sudokuTable.possible[cell][value] then
            sudokuTable.possible[cell][value] = nil
        end
    end
end

-- Get the count of all possible values for rows, cols, and blocks
--   returns 3 tables row_possible[row#][value] = #times possible value occurs in row
--   and the same for col_possible, block_possible
--   if no possible values (all values set) then row_possible[row#] = nil
function sudoku.FindPossibleCountRowColBlock(sudokuTable)
    local row_possible   = {}
    local col_possible   = {}
    local block_possible = {}

    for cell = 1, 81 do
        local row, col = sudoku.CellToRowCol(cell)
        local block    = sudoku.CellToBlock(cell)
        local cell_possible = sudoku.GetCellPossible(sudokuTable, cell)

        for pvalue, is_possible in pairs(cell_possible) do
            if not row_possible[row]     then row_possible[row] = {} end
            if not col_possible[col]     then col_possible[col] = {} end
            if not block_possible[block] then block_possible[block] = {} end

            row_possible[row][pvalue]     = (row_possible[row][pvalue] or 0) + 1
            col_possible[col][pvalue]     = (col_possible[col][pvalue] or 0) + 1
            block_possible[block][pvalue] = (block_possible[block][pvalue] or 0) + 1
        end
    end

    return row_possible, col_possible, block_possible
end

-- Find all the possible values for row, col cell
--  returns a table of possible[value] = true
function sudoku.FindPossibleCell(sudokuTable, row, col)
    local possible = {}

    -- gather up all the set values in row, col, and block
    local rowValues   = sudokuTable.row_values[row]
    local colValues   = sudokuTable.col_values[col]
    local blockValues = sudokuTable.block_values[sudoku.RowColToBlock(row, col)]
    -- remove the set values from the possible values
    for v = 1, 9 do
        if (rowValues[v] == nil) and (colValues[v] == nil) and (blockValues[v] == nil) then
            possible[v] = v
        end
    end

    return possible
end

-- Find all the possible values for the whole table by filling out the
--  possible table in the input sudokuTable. Modifies input sudokuTable.
function sudoku.CalcAllPossible(sudokuTable)
    for cell = 1, 81 do
        local row, col = sudoku.CellToRowCol(cell)
        local possible = {}

        if not sudoku.HasCellValue(sudokuTable, cell) then
            local block = sudoku.CellToBlock(cell)

            for v = 1, 9 do
                if (sudokuTable.row_values[row][v] == nil) and
                   (sudokuTable.col_values[col][v] == nil) and
                   (sudokuTable.block_values[block][v] == nil) then
                    possible[v] = v
                end
            end

        end

        sudoku.SetCellPossible(sudokuTable, cell, possible)
    end

    -- this function checks flags to see if it should run
    sudoku.RemovePossibleGroups(sudokuTable)
end

-- Find all the possible pairs, triplets, quads in the table
--  must run CalcAllPossible first, does not eliminate any.
--  returns 3 tables, possible_pairs.rows[row#][key] = { cell1, cell2... },
--                    possible_pairs.cols[col#][key] = { cell1, cell2... },
--                    possible_pairs.blocks[block#][key] = { cell1, cell2... },
--  and the same for possible_triplets, possible_quads
--  key is constructed from the number group as string.char(val1, val2...)
sudoku.FindAllPossibleGroups_Cache = {}

function sudoku.FindAllPossibleGroups(sudokuTable)
    local possible_pairs    = {rows = {}, cols = {}, blocks = {}}
    local possible_triplets = {rows = {}, cols = {}, blocks = {}}
    local possible_quads    = {rows = {}, cols = {}, blocks = {}}
    local char0 = string.byte("0")

    local cache_key_flags = 1*booltoint(sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_PAIRS]) +
                            2*booltoint(sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_TRIPLETS]) +
                            4*booltoint(sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_QUADS])

    local cache_keys = { 10^1, 10^2, 10^3, 10^4, 10^5, 10^6, 10^7, 10^8, 10^9 }

    local function add_possible(atable, rcb_key, key, cell)
        local a = atable[rcb_key]
        if not a then
            atable[rcb_key] = { [key] = {cell} }
        elseif not a[key] then
            a[key] = {cell}
        else
            a[key][#a[key]+1] = cell
        end
    end

    for cell = 1, 81 do
        local row, col = sudoku.CellToRowCol(cell)
        local block    = sudoku.CellToBlock(cell)

        local cell_possible = sudoku.GetCellPossible(sudokuTable, cell)
        local cell_possible_table = {}
        local cache_key = cache_key_flags

        -- convert key, value table to indexed table and a key for the cache
        local count = 0
        for n = 1, 9 do
            if cell_possible[n] then
                cell_possible_table[#cell_possible_table+1] = char0+n
                cache_key = cache_key + cache_keys[n]
                count = count + 1
            end
        end

        local possible_pairs_keys    = {}
        local possible_triplets_keys = {}
        local possible_quads_keys    = {}

        -- either use the cached key table or create a new key table for the possible
        -- Note: cache cuts time for 100 calls to this fn w/ empty puzzle from 8 to 1 sec

        if (count > 1) and sudoku.FindAllPossibleGroups_Cache[cache_key] then
            possible_pairs_keys    = sudoku.FindAllPossibleGroups_Cache[cache_key].possible_pairs
            possible_triplets_keys = sudoku.FindAllPossibleGroups_Cache[cache_key].possible_triplets
            possible_quads_keys    = sudoku.FindAllPossibleGroups_Cache[cache_key].possible_quads
        elseif (count > 1) then

            local elim_pairs    = (count == 2) or sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_PAIRS]
            local elim_triplets = (count == 3) or sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_TRIPLETS]
            local elim_quads    = (count == 4) or sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_QUADS]

            for i = 1, count do
                for j = i+1, count do
                    local pkey = string.char(cell_possible_table[i], cell_possible_table[j])
                    if elim_pairs then
                        possible_pairs_keys[#possible_pairs_keys+1] = pkey
                    end

                    for k = j+1, count do
                        local tkey = pkey..string.char(cell_possible_table[k])
                        if elim_triplets then
                            possible_triplets_keys[#possible_triplets_keys+1] = tkey
                        end

                        if elim_quads then
                            for l = k+1, count do
                                local qkey = tkey..string.char(cell_possible_table[l])
                                possible_quads_keys[#possible_quads_keys+1] = qkey
                            end
                        end
                    end
                end
            end

            sudoku.FindAllPossibleGroups_Cache[cache_key] = {}
            sudoku.FindAllPossibleGroups_Cache[cache_key].possible_pairs    = possible_pairs_keys
            sudoku.FindAllPossibleGroups_Cache[cache_key].possible_triplets = possible_triplets_keys
            sudoku.FindAllPossibleGroups_Cache[cache_key].possible_quads    = possible_quads_keys
        end

        for k, key in pairs(possible_pairs_keys) do
            add_possible(possible_pairs.rows,   row,   key, cell)
            add_possible(possible_pairs.cols,   col,   key, cell)
            add_possible(possible_pairs.blocks, block, key, cell)
        end
        for k, key in pairs(possible_triplets_keys) do
            add_possible(possible_triplets.rows,   row,   key, cell)
            add_possible(possible_triplets.cols,   col,   key, cell)
            add_possible(possible_triplets.blocks, block, key, cell)
        end
        for k, key in pairs(possible_quads_keys) do
            add_possible(possible_quads.rows,   row,   key, cell)
            add_possible(possible_quads.cols,   col,   key, cell)
            add_possible(possible_quads.blocks, block, key, cell)
        end
    end

    return possible_pairs, possible_triplets, possible_quads
end

-- Find all the naked and hidden pairs, triplets, quads in the table
--  must run CalcAllPossible first, does not eliminate any.
--  returns 2 tables, naked.rows[row#][key] = { cell1, cell2... },
--                    naked.cols[col#][key] = { cell1, cell2... },
--                    naked.blocks[block#][key] = { cell1, cell2... },
--  and the same for hidden
--  key is constructed from the number group as string.char(val1, val2...)
function sudoku.FindAllNakedHiddenGroups(sudokuTable, find_all)
    local flags = sudokuTable.flags

    if find_all == true then
        sudokuTable.flags = TableCopy(flags) -- unref the table
        -- turn all ELIMINATE_XXX on
        for n = sudoku.ELIMINATE_FLAG_MIN, sudoku.ELIMINATE_FLAG_MAX do
            sudokuTable.flags[n] = true
        end
    end

    local row_possible,   col_possible,      block_possible = sudoku.FindPossibleCountRowColBlock(sudokuTable)
    local possible_pairs, possible_triplets, possible_quads = sudoku.FindAllPossibleGroups(sudokuTable)
    local char0 = string.byte("0")
    local all_groups = { [2] = 36, [3] = 84, [4] = 126 } -- eg. 9!/(2! * (9-2)!)

    if find_all == true then
        sudokuTable.flags = flags -- put the flags back to how they were
    end

    local naked =
    {
        pairs    = {rows = {}, cols = {}, blocks = {}, cells = {}},
        triplets = {rows = {}, cols = {}, blocks = {}, cells = {}},
        quads    = {rows = {}, cols = {}, blocks = {}, cells = {}}
    }
    local hidden =
    {
        pairs    = {rows = {}, cols = {}, blocks = {}, cells = {}},
        triplets = {rows = {}, cols = {}, blocks = {}, cells = {}},
        quads    = {rows = {}, cols = {}, blocks = {}, cells = {}}
    }

    -- cache all the cell possible value counts
    local cell_possible_count = {}
    for n = 1, 81 do
        cell_possible_count[n] = TableCount(sudoku.GetCellPossible(sudokuTable, n) or {})
    end

    local function dofind(rcb_table, num, key, cell_table_, rcb, rcb_possible)
        local naked_cell_table  = {}
        local naked_cell_count  = 0
        local hidden_cell_table = {}
        local hidden_cell_count = 0
        local is_hidden = true

        -- can only be exactly as many nums in key as in rcb for hidden
        for n = 1, num do
            if rcb_possible[string.byte(key, n)-char0] ~= num then
                is_hidden = false
                break
            end
        end

        for n, cell in ipairs(cell_table_) do
            if cell_possible_count[cell] == num then
                naked_cell_table[#naked_cell_table+1] = cell
                naked_cell_count = naked_cell_count + 1
            end

            if is_hidden then
                hidden_cell_table[#hidden_cell_table+1] = cell
                hidden_cell_count = hidden_cell_count + 1
            end
        end

        -- has to be at least the same cell_count as num, if more then error, but...
        if (naked_cell_count >= num) then
            if not rcb_table.naked_table[rcb] then rcb_table.naked_table[rcb] = {} end
            rcb_table.naked_table[rcb][key] = naked_cell_table

            local cell_table = rcb_table.naked_table_base.cells
            for n, cell in pairs(naked_cell_table) do
                if not cell_table[cell] then cell_table[cell] = {} end
                table.insert(cell_table[cell], key)
            end
        end
        -- has to be at least the same cell_count as num, if more then error, but...
        if is_hidden and (hidden_cell_count >= num) then
            if not rcb_table.hidden_table[rcb] then rcb_table.hidden_table[rcb] = {} end
            rcb_table.hidden_table[rcb][key] = hidden_cell_table

            local cell_table = rcb_table.hidden_table_base.cells
            for n, cell in pairs(hidden_cell_table) do
                if not cell_table[cell] then cell_table[cell] = {} end
                table.insert(cell_table[cell], key)
            end
        end
    end

    local function find(naked_table, hidden_table, possible_table, num)
        local rcb_table = {}
        rcb_table.naked_table_base  = naked_table
        rcb_table.hidden_table_base = hidden_table

        rcb_table.naked_table  = naked_table.rows
        rcb_table.hidden_table = hidden_table.rows
        for row, key_table in pairs(possible_table.rows) do
            for key, cell_table in pairs(key_table) do
                dofind(rcb_table, num, key, cell_table, row, row_possible[row])
            end
        end

        rcb_table.naked_table  = naked_table.cols
        rcb_table.hidden_table = hidden_table.cols
        for col, key_table in pairs(possible_table.cols) do
            for key, cell_table in pairs(key_table) do
                dofind(rcb_table, num, key, cell_table, col, col_possible[col])
            end
        end

        rcb_table.naked_table  = naked_table.blocks
        rcb_table.hidden_table = hidden_table.blocks
        for block, key_table in pairs(possible_table.blocks) do
            for key, cell_table in pairs(key_table) do
                dofind(rcb_table, num, key, cell_table, block, block_possible[block])
            end
        end

        return naked_table, hidden_table
    end

    naked.pairs,    hidden.pairs    = find(naked.pairs,    hidden.pairs,    possible_pairs,    2)
    naked.triplets, hidden.triplets = find(naked.triplets, hidden.triplets, possible_triplets, 3)
    naked.quads,    hidden.quads    = find(naked.quads,    hidden.quads,    possible_quads,    4)

    return naked, hidden
end

-- ============================================================================
-- Find all pairs, triplets, quads of values in rows and reset the possible
--   values for the row to exclude these values. Modifies input sudokuTable.
function sudoku.RemovePossibleGroups(sudokuTable)
    -- must have at least one flag set
    local has_elim_flags = false
    for n = sudoku.ELIMINATE_FLAG_MIN, sudoku.ELIMINATE_FLAG_MAX do
        if sudokuTable.flags[n] == true then
            has_elim_flags = true
            break
        end
    end
    if has_elim_flags == false then
        return
    end

    local naked, hidden = sudoku.FindAllNakedHiddenGroups(sudokuTable, false)
    local char0 = string.byte("0")

    local function clear_possible(group_table, num, remove_fn)
        for n = 1, 9 do
            if group_table[n] then
                for key, cell_table in pairs(group_table[n]) do

                    local exceptTable = {}
                    for k, v in pairs(cell_table) do
                        exceptTable[v] = v
                    end

                    for k = 1, num do
                        local val = string.byte(key, k)-char0
                        remove_fn(sudokuTable, n, val, exceptTable)
                    end
                end
            end
        end
    end

    if (sudokuTable.flags[sudoku.ELIMINATE_NAKED_PAIRS] == true) then
        clear_possible(naked.pairs.rows,   2, sudoku.RemovePossibleRow)
        clear_possible(naked.pairs.cols,   2, sudoku.RemovePossibleCol)
        clear_possible(naked.pairs.blocks, 2, sudoku.RemovePossibleBlock)
    end
    if (sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_PAIRS] == true) then
        clear_possible(hidden.pairs.rows,   2, sudoku.RemovePossibleRow)
        clear_possible(hidden.pairs.cols,   2, sudoku.RemovePossibleCol)
        clear_possible(hidden.pairs.blocks, 2, sudoku.RemovePossibleBlock)
    end

    if (sudokuTable.flags[sudoku.ELIMINATE_NAKED_TRIPLETS] == true) then
        clear_possible(naked.triplets.rows,   3, sudoku.RemovePossibleRow)
        clear_possible(naked.triplets.cols,   3, sudoku.RemovePossibleCol)
        clear_possible(naked.triplets.blocks, 3, sudoku.RemovePossibleBlock)
    end
    if (sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_TRIPLETS] == true) then
        clear_possible(hidden.triplets.rows,   3, sudoku.RemovePossibleRow)
        clear_possible(hidden.triplets.cols,   3, sudoku.RemovePossibleCol)
        clear_possible(hidden.triplets.blocks, 3, sudoku.RemovePossibleBlock)
    end

    if (sudokuTable.flags[sudoku.ELIMINATE_NAKED_QUADS] == true) then
        clear_possible(naked.quads.rows,   4, sudoku.RemovePossibleRow)
        clear_possible(naked.quads.cols,   4, sudoku.RemovePossibleCol)
        clear_possible(naked.quads.blocks, 4, sudoku.RemovePossibleBlock)
    end
    if (sudokuTable.flags[sudoku.ELIMINATE_HIDDEN_QUADS] == true) then
        clear_possible(hidden.quads.rows,   4, sudoku.RemovePossibleRow)
        clear_possible(hidden.quads.cols,   4, sudoku.RemovePossibleCol)
        clear_possible(hidden.quads.blocks, 4, sudoku.RemovePossibleBlock)
    end
end

-- ============================================================================
-- Find all the cells that only have a single possible value and set it.
--   Modifies input sudokuTable.
function sudoku.SolveScanSingles(sudokuTable)
    sudoku.CalcAllPossible(sudokuTable)
    local changed_cells = {}

    for row = 1, 9 do
        for col = 1, 9 do
            if not sudoku.HasValue(sudokuTable, row, col) then
                local possible = sudoku.GetPossible(sudokuTable, row, col)
                local count = 0
                local value = nil
                for pvalue, is_possible in pairs(possible) do -- count possible values
                    count = count + 1
                    value = pvalue
                end
                if count == 1 then
                    local cell = sudoku.RowColToCell(row, col)
                    sudoku.SetValue(sudokuTable, row, col, value)
                    sudoku.RemovePossibleAll(sudokuTable, cell, value)
                    changed_cells[cell] = value
                end
            end
        end
    end

    if TableIsEmpty(changed_cells) then changed_cells = nil end -- reset if not used

    return changed_cells
end

-- Find all the cells that only have a single possible value per row and set it.
--   Modifies input sudokuTable.
function sudoku.SolveScanRows(sudokuTable)
    sudoku.SolveScanRowsCols(sudokuTable, true)
end
-- Find all the cells that only have a single possible value per col and set it
--   Modifies input sudokuTable.
function sudoku.SolveScanCols(sudokuTable)
    sudoku.SolveScanRowsCols(sudokuTable, false)
end
function sudoku.SolveScanRowsCols(sudokuTable, scan_rows)
    sudoku.CalcAllPossible(sudokuTable)
    local changed_cells = {}

    for row_col1 = 1, 9 do
        local row = nil -- set row or col depending on scan_rows
        local col = nil
        if scan_rows then row = row_col1 else col = row_col1 end

        local possible = {} -- all the possible values along the row or col
        for i = 1, 9 do possible[i] = {} end

        -- fill possible[pvalue] = { cell1, cell2... } along row or col
        for row_col2 = 1, 9 do
            if scan_rows then col = row_col2 else row = row_col2 end

            if not sudoku.HasValue(sudokuTable, row, col) then
                local cell_possible = sudoku.GetPossible(sudokuTable, row, col)
                for pvalue, is_possible in pairs(cell_possible) do
                    table.insert(possible[pvalue], sudoku.RowColToCell(row, col))
                end
            end
        end

        -- iterate through the values and if only one possibility set it
        for value = 1, 9 do
            if TableCount(possible[value]) == 1 then
                local cell = possible[value][1]
                sudoku.SetCellValue(sudokuTable, cell, value)
                sudoku.RemovePossibleAll(sudokuTable, cell, value)
                changed_cells[cell] = value
            end
        end
    end

    if TableIsEmpty(changed_cells) then changed_cells = nil end -- reset if not used

    return changed_cells
end

-- Find all the cells that only have a single possible value per block and set it
--   Modifies input sudokuTable.
function sudoku.SolveScanBlocks(sudokuTable)
    sudoku.CalcAllPossible(sudokuTable)
    local changed_cells = {}

    for block = 1, 9 do
        local block_row, block_col = sudoku.BlockToRowCol(block)

        local possible = {}
        for i = 1, 9 do possible[i] = {} end

        -- fill possible[pvalue] = { cell1, cell2... } for whole block
        for row = block_row, block_row+2 do
            for col = block_col, block_col+2 do
                if not sudoku.HasValue(sudokuTable, row, col) then
                    local cell_possible = sudoku.GetPossible(sudokuTable, row, col)
                    for pvalue, is_possible in pairs(cell_possible) do
                        table.insert(possible[pvalue], sudoku.RowColToCell(row, col))
                    end
                end
            end
        end

        -- iterate through the values and if only one possibility set it
        for value = 1, 9 do
            if TableCount(possible[value]) == 1 then
                local cell = possible[value][1]
                sudoku.SetCellValue(sudokuTable, cell, value)
                sudoku.RemovePossibleAll(sudokuTable, cell, value)
                changed_cells[cell] = value
            end
        end
    end

    if TableIsEmpty(changed_cells) then changed_cells = nil end -- reset if not used

    return changed_cells
end

-- Find all the cells that only have a single possible value per row, col, block and set it
--   Modifies input sudokuTable.
function sudoku.SolveScan(sudokuTable)
    local changed_single = {}
    local changed_rows   = {}
    local changed_cols   = {}
    local changed_blocks = {}
    local changed_cells  = {} -- total cells changed
    local count = 0

    local function add_changed(changed_table, changed_cells)
        if changed_table then
            changed_cells = TableMerge(changed_table, changed_cells)
        end
        return changed_cells
    end

    while (count < 10000) and (changed_single or changed_rows or changed_cols or changed_blocks) do
        changed_single = sudoku.SolveScanSingles(sudokuTable)
        changed_rows   = sudoku.SolveScanRows(sudokuTable)
        changed_cols   = sudoku.SolveScanCols(sudokuTable)
        changed_blocks = sudoku.SolveScanBlocks(sudokuTable)

        changed_cells = add_changed(changed_single, changed_cells)
        changed_cells = add_changed(changed_rows,   changed_cells)
        changed_cells = add_changed(changed_cols,   changed_cells)
        changed_cells = add_changed(changed_blocks, changed_cells)

        count = count + 1
    end

    if TableIsEmpty(changed_cells) then changed_cells = nil end -- nothing done

    return count, changed_cells
end

-- Brute force recursive solver, returns a new table and does not the input sudokuTable.
--   (call with only the SudokuTable, don't enter other parameters)
function sudoku.SolveBruteForce(sudokuTable, backwards)
    -- first time through find possible to limit choices, subsequent calls ok
    local s = sudoku.CreateTable()

    -- finding all the possibilities is slow, but at least do solve scan
    --s.flags[sudoku.ELIMINATE_NAKED_PAIRS]     = true
    --s.flags[sudoku.ELIMINATE_HIDDEN_PAIRS]    = true
    --s.flags[sudoku.ELIMINATE_NAKED_TRIPLETS]  = true
    --s.flags[sudoku.ELIMINATE_HIDDEN_TRIPLETS] = true
    --s.flags[sudoku.ELIMINATE_NAKED_QUADS]     = true
    --s.flags[sudoku.ELIMINATE_HIDDEN_QUADS]    = true

    s.values = TableCopy(sudokuTable.values)
    sudoku.CalcRowColBlockValues(s)
    sudoku.CalcAllPossible(s)
    sudoku.SolveScan(s)

    -- table consists of guesses[cell] = #num
    -- guesses.current is current guess #
    local guesses = { current = 0 }
    for n = 1, 81 do guesses[n] = 0 end
    -- we don't need these for this and they just slow TableCopy down
    --  they're recreated at the end using UpdateTable
    s.row_values   = nil
    s.col_values   = nil
    s.block_values = nil
    s.invalid      = nil
    s.flags        = nil

    return sudoku.DoSolveBruteForce(sudokuTable, backwards, s, guesses, 1)
end

function sudoku.DoSolveBruteForce(sudokuTable, backwards, simpleTable, guesses, cell)
    local s = simpleTable
    local g, empty_possible

    if sudoku.SolveBruteForceHook then
        if not sudoku.SolveBruteForceHook(guesses, cell) then
            return nil, guesses, cell
        end
    end

    while cell <= 81 do
        if not sudoku.HasCellValue(s, cell) then
            local possible = sudoku.GetCellPossible(s, cell)

            --for k, v in pairs(possible) do -- use for loop to ensure direction
            
            local start_n = iff(backwards, 9,  1)
            local end_n   = iff(backwards, 1,  9)
            local dir_n   = iff(backwards, -1, 1)
            
            for n = start_n, end_n, dir_n do
                if possible[n] then
                    -- try a number and remove it as a possibility
                    sudoku.RemoveCellPossible(s, cell, n)

                    -- start a new table and test out this guess
                    local s1 = TableCopy(s)
                    -- don't use SetValue since we only care about possible
                    s1.values[cell] = n --sudoku.SetValue(s1, row, col, n)
                    sudoku.RemovePossibleAll(s1, cell, n, nil, true)

                    guesses[cell]   = guesses[cell] + 1
                    guesses.current = guesses.current + 1

                    -- check for nil return from RemovePossibleAll for break_if_empty
                    if s1 then
                        s1, g = sudoku.DoSolveBruteForce(sudokuTable, backwards, s1, guesses, cell+1)
                        -- if s1 then success! we're all done
                        if s1 then
                            -- copy all original data back and just set the values
                            local s2 = TableCopy(sudokuTable)
                            sudoku.SetValues(s2, s1.values)
                            return s2, g
                        end
                    end
                end
            end

            return nil, guesses -- tried all values for cell with no solution
        end

        cell = cell + 1
    end

    local s2 = TableCopy(sudokuTable)
    sudoku.SetValues(s2, s.values)
    return s2, guesses
end

-- Does this puzzle have a unique solution. It works by trying the brute force
-- solution method iterating from low to high numbers and then from high to low.
-- This should always find if there are at least two solutions.
-- returns nil if no solution or [s1, s2] if at least two solutions, else
-- just the single unique solution.
-- Returns a new solved table or nil on failure, doesn't modify input sudokuTable.
function sudoku.IsUniquePuzzle(sudokuTable)

    local s1, g1 = sudoku.SolveBruteForce(sudokuTable, false)
    if not s1 then return nil end

    local s2, g2 = sudoku.SolveBruteForce(sudokuTable, true)
    if not s2 then return nil end

    if not sudoku.IsSamePuzzle(s1, s2) then return s1, s2 end

    return s1
end

-- Do these two puzzles have the same cell values? Returns true/false.
function sudoku.IsSamePuzzle(s1, s2)
    for cell = 1, 81 do
        if sudoku.GetCellValue(s1, cell) ~= sudoku.GetCellValue(s2, cell) then
            return false
        end
    end

    return true
end

-- ============================================================================
-- Create a full puzzle with all the values
--  returns sudokuTable, count where count is the number of iterations
function sudoku.GeneratePuzzle()
    local cell = 0
    local count = 0
    local stuck = {} -- count how many times we've backtracked stuck[cell/9] = count

    math.randomseed(os.time())
    local sudokuTable = sudoku.CreateTable()

    while cell < 81 do
        cell = cell + 1
        count = count + 1

        if sudoku.GeneratePuzzleHook then
            if not sudoku.GeneratePuzzleHook(count, cell) then
                return nil, count
            end
        end

        local value = math.random(9)
        local row, col = sudoku.CellToRowCol(cell)

        if sudoku.IsValidValue(sudokuTable, row, col, value) then
            sudoku.SetCellValue(sudokuTable, cell, value)
            sudoku.RemovePossibleAll(sudokuTable, cell, value)
        else
            -- try other values starting at value+1 and wrapping around
            local set_value = false
            local i = value + 1
            if i > 9 then i = 1 end
            while i ~= value do
                if sudoku.IsValidValue(sudokuTable, row, col, i) then
                    sudoku.SetCellValue(sudokuTable, cell, i)
                    sudoku.RemovePossibleAll(sudokuTable, cell, i)
                    set_value = true
                    break
                end
                i = i + 1
                if i > 9 then i = 1 end
            end

            -- whoops, go back a row or more and start over just to be sure
            if not set_value then
                local block = math.floor(cell/9) + 1
                stuck[block] = (stuck[block] or 0) + 1
                local goback = 9

                if stuck[block] and (stuck[block] > 5) then
                    goback = 2 * stuck[block] + 1
                end

                local cell_start = cell - goback
                if cell_start < 1 then
                    cell_start = 1
                elseif cell_start < 10 then
                    stuck = {} -- really start all over
                end

                for i = cell_start, cell do
                    sudoku.SetCellValue(sudokuTable, i, 0)
                end

                cell = cell_start - 1
            end
        end
    end

    return sudokuTable, count
end

function sudoku.GeneratePuzzleDifficulty(sudokuTable, num_cells_to_keep, ensure_unique)
    if num_cells_to_keep < 1 then
        return sudoku.CreateTable()
    end

    if ensure_unique == nil then ensure_unique = true end
    math.randomseed(os.time()+1)
    local trial = 1
    local i = 0
    local count = 0
    local soln = TableCopy(sudokuTable)
    local cellTable = {}
    for n = 1, 81 do cellTable[n] = n end

    local cell_count, cell_n, cell

    while i < 81 - num_cells_to_keep do
        cell_count = #cellTable

        -- restart this function if we run out of cells to try
        if (cell_count == 0) or (cell_count + i < num_cells_to_keep) then
            trial = trial + 1
            i = 0
            count = 0
            cellTable = {}
            for n = 1, 81 do cellTable[n] = n end
            cell_count = #cellTable
            cell_n = math.random(cell_count)
        elseif cell_count == 1 then
            cell_n = 1
        else
            cell_n = math.random(cell_count)
        end

        cell = cellTable[cell_n]
        count = count + 1

        if sudoku.GeneratePuzzleDifficultyHook then
            if not sudoku.GeneratePuzzleDifficultyHook(count, i, cell, cell_count, trial) then
                return nil, count
            end
        end

        if ensure_unique == true then
            -- test if soln going forward is same as soln backwards and original
            local s = TableCopy(sudokuTable)
            sudoku.SetCellValue(s, cell, 0)
            local soln1 = sudoku.SolveBruteForce(s, false)
            if not soln1 then return nil, count end

            if not sudoku.IsSamePuzzle(soln, soln1) then
                table.remove(cellTable, cell_n)
            else
                local soln2 = sudoku.SolveBruteForce(s, true)
                if not soln2 then return nil, count end

                if not sudoku.IsSamePuzzle(soln, soln2) then
                    table.remove(cellTable, cell_n)
                else
                    table.remove(cellTable, cell_n)
                    sudoku.SetCellValue(sudokuTable, cell, 0)
                    i = i + 1
                end
            end
        else
            table.remove(cellTable, cell_n)
            sudoku.SetCellValue(sudokuTable, cell, 0)
            i = i + 1
        end
    end

    return sudokuTable, count
end

-- ============================================================================
-- ============================================================================

sudokuGUIxpmdata =
{
    "16 15 7 1",
    "  c None",
    "a c Black",
    "b c #808080",
    "c c #FFFF00",
    "d c #FF0000",
    "e c #0000FF",
    "g c #00FF00",
    " aaaaaaaaaaaaa  ",
    " addaggaeeaccab ",
    " addaggaeeaccab ",
    " aaaaaaaaaaaaab ",
    " accaddaggaeeab ",
    " accaddaggaeeab ",
    " aaaaaaaaaaaaab ",
    " aeeaccaddaggab ",
    " aeeaccaddaggab ",
    " aaaaaaaaaaaaab ",
    " aggaeeaccaddab ",
    " aggaeeaccaddab ",
    " aaaaaaaaaaaaab ",
    "  bbbbbbbbbbbbb ",
    "                "
}

-- NOTE: HTML generated using NVU and "tidy -wrap 79 -i -omit -o l.html input.html"

sudokuGUIhelp =
[[
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<meta name="generator" content=
"HTML Tidy for Linux/x86 (vers 1st December 2004), see www.w3.org">

  <title>wxLuaSudoku</title>
  <meta content="John Labenski" name="author">
  <meta content="Documentation for the wxLuaSudoku program" name=
  "description">

<body bgcolor="#FFFFCC">
  <h1>wxLuaSudoku</h1>Copyright : John Labenski, 2006<br>
  License : wxWindows license.<br>
  <br>
  <i>This program is free software; you can redistribute it and/or modify it
  under the terms of the wxWindows License; either version 3 of the License,
  or (at your option) any later version.<br>
  <br>
  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the wxWindows License for more
  details.</i><br>
  <br>
  If you use this program and find any bugs or have added any features that
  you feel may be generally useful, please feel free to contact me by e-mail
  at jrl1[at]sourceforge[dot]net or on the wxlua-users mailing list.<br>

  <h2>Purpose</h2>The purpose of this program is to demonstrate programming in
  wxLua. It may not be the best, fastest, or most complete sudoku solver
  program available, but the code should be easily understandable with a
  straightforward implementation. However, you may find that it is capable
  enough and since it's free, you got what you paid for.<br>
  <br>
  wxLua is a binding of the wxWidgets cross-platform GUI library to the Lua
  programming language. It is available as an application, library, or source
  code for MSW, Unix like systems, and OSX. More information about wxLua can
  be found on <a href=
  "http://wxlua.sourceforge.net">wxlua.sourceforge.net</a>. Information about
  the wxWidgets library can be found on <a href=
  "http://www.wxwidgets.org">www.wxwidgets.org</a> and the Lua programming
  language on <a href="http://www.lua.org">www.lua.org</a>.<br>

  <h2>Program features</h2>

  <ul>
    <li>Enter your own initial values for a puzzle to solve

    <li>Generate random unique new puzzles

    <li>Load/Save puzzles to files

    <li>Print the puzzle

    <li>Undo/Redo of the steps you've taken

    <li>Mark errors and/or mistakes

    <li>Show calculated possible values for each cell

    <li>Pencil marks, possible values for cells that you have determined

    <li>Automatic marking of hidden/naked pairs, triplets, and quads of
    possible values

    <li>Eliminate possible values by finding hidden/naked pairs, triplets, and
    quads of possible values

    <li>Solve the puzzle by scanning for values, can use eliminate
    naked/hidden groups to do better

    <li>Solve the puzzle by brute force, by guessing values from the possible
    values

    <li>No installer, registry entries, or other nonsense. Merely delete the
    program when you're done with it.
  </ul>

  <h2>How to play</h2>Sudoku is a puzzle game of choosing where to place the
  numbers 1 to 9 in a 9x9 grid of cells. There are many varieties of this
  game, but wxLuaSudoku only works with the 9x9 grid. The grid of 81 cells has
  9 rows, 9 columns, and 9 blocks that consist of smaller 3x3 grids of cells.
  Each cell in the grid can take a value of 1 to 9, but there are limitations.
  Each row, column, and block must have the full array of numbers from 1 to 9.
  Therefore, there can be no duplicate values in any row, column, or block.
  For a well formed puzzle there's just one possible solution for the initial
  seed of values. There are numerous tutorials on the internet, for example
  <a href=
  "http://en.wikipedia.org/wiki/Sudoku">http://en.wikipedia.org/wiki/Sudoku</a>,
  so lets move on...<br>

  <h2><a name="Some_Sudoku_terms" id="Some_Sudoku_terms"></a>Some Sudoku
  terms</h2>

  <ul>
    <li><b>Initial values :</b> These are values for the cells that the puzzle
    starts with. The minimum number of initial values that a puzzle can start
    with is thought to be 17 in order for the puzzle to have a single unique
    solution.

    <li><b>Possible values :</b> These are values that an empty cell might
    take given the existing values in the row, col, and block that the cell is
    in.

    <li>
      <b>Naked pairs, triplets, quads :</b> When looking though the possible
      values for the cells you may find that two or more cells have the
      identical possible values and only those values. Those would be called
      naked because they're immediately visible.

      <ul>
        <li>Pair example: If two cells in a row have the possible values of 2
        and 4 then either 2 or 4 has to be in those two cells. You can
        therefore eliminate 2 and 4 from the possible values in the rest of
        the row and if they're both in the same block, the block too.
      </ul>

    <li>
      <b>Hidden pairs, triplets, quads :</b> A hidden group is defined as a
      set of numbers that appear in as many cells as the size of the group.
      They are similar to naked groups, but there may also be some other
      possible values that make them a little harder to find.

      <ul>
        <li>Pair example: If two cells in a row have the possible values 1, 2,
        4 and 1, 2, 4, 5, 6 respectively and the numbers 2 and 4 do not appear
        in any other cell in the row you know that either 2 or 4 must go into
        either cell and eliminate the other possible values from those two
        cells.
      </ul>
    </ul>

  <h2>Entering values</h2>Enter values into the cells by clicking on a cell to
  highlight it and then type a number. Use 0, space, or any non number to
  clear the cell's value. The cells that the puzzle is initialized with are
  read-only, meaning that you cannot change their values unless you are
  actually creating a puzzle using the menu item <i>File-&gt;Create</i>.
  Navigate through the cells with the cursor keys or mouse.<br>

  <h2><a name="Pencil_marks" id="Pencil_marks"></a>Pencil marks</h2>You can
  annotate the empty cells with a list of possible values that may work by
  checking the menu item <i>Possible-&gt;Show/Edit pencil marks</i>. If you
  want initialize the pencil marks to be all selected, none selected, or set
  to the calculated values use the menu items under <i>Possible-&gt;Pencil
  marks</i>. In order to toggle the values, hold down the shift key and all of
  the possible values will be shown. Click on a value to either select or
  deselect it. Alternatively, you can use shift-Number to toggle the selection
  state of the pencil marks.<br>
  <br>
  Note that this is different than the menu item <i>Possible-&gt;Show
  calculated possible</i> in that, obviously, this will show a list of
  calculated possible values that could go into the cells based on the current
  state of the puzzle. You can switch between the two views or not show the
  possible values altogether by unchecking both of them.

  <h2><a name="Creating_a_puzzle" id="Creating_a_puzzle"></a>Creating a
  puzzle</h2>To create a new puzzle by hand check the menu item
  <i>File-&gt;Create</i>. You've now put the program in a state where any
  values that you enter will be the initial values of the puzzle. Error
  checking of invalid values, values that appear more than once in the same
  row, column, or block, is automatically turned on since it's fairly
  pointless to create puzzles that cannot be solved, though this program
  generously allows you to do so. Enter the values as described above and when
  done be sure to uncheck the <i>File-&gt;Create</i> item. The program will
  then try to find a solution to the puzzle and verify that there is only one
  unique solution.<br>
  <br>
  If you want to check the state of the puzzle during creation to confirm that
  it has a unique solution, use the <i>Solve-&gt;Verify unique solution</i>
  menu item. If you're determined to create an invalid sudoku puzzle this
  program will not stop you and you can merely cancel out of the warning
  dialogs to continue and you're on your own. However, showing mistakes will
  be disabled and "solving" using the scanning technique may yield strange
  results that are mathematically consistent with the rules of the game, but
  bring you no closer to the nonexistent solution. If at some later point you
  wish to have mistakes shown using <i>View-&gt;Mark mistakes</i>, the program
  will try to solve the initial puzzle again, with the same result, no
  solution.<br>
  <br>
  If you want to start with a completely empty grid use <i>File-&gt;New</i>.
  If on the other hand, you want to start with a completely filled grid of
  random values, use <i>File-&gt;Generate</i> with the number of cell values
  to show set to 81, all shown.

  <h2>Cell markings</h2>The colors and fonts for the cells can be changed with
  the preferences dialog from the menu item <i>View-&gt;Preferences</i>. The
  values in the cells have one color if it's an initial value and a different
  color if you've entered the value into the cell during play. The possible
  values that could go into a particular cell use a smaller font and can be
  drawn as a 3x3 grid or in a single line which may be useful if you want to
  print it and work it out by hand.<br>
  <br>
  Possible groups of values for the cells may be set to be marked if they are
  naked and or hidden. Note: It may happen that, for example, there's a
  triplet of possible values in a row and some of the values are shared by a
  pair in a column. In that case the pair values get the appropriate markings
  overriding the triplet markings since it's usually best to try to work with
  them first. Also, if you get really off track the program will happily mark
  groups that would obviously make no sense if there weren't any mistakes.
  This is by design since some people apparently find it interesting to do
  whatever it is that they want to do.

  <h2>Menu item descriptions</h2>All items followed by ... denote that a
  dialog will be shown that can be canceled before any action is taken.

  <ul>
    <li>
      <b>File</b>

      <ul>
        <li><b>New...</b> : Clear the whole puzzle to an uninitialized state so
        that you can then "Create" it from scratch.

        <li>
          <b>Create...</b> : Check this item to enter the initial values,
          uncheck when done to play.

          <ul>
            <li>See the section on <a href="#Creating_a_puzzle">Creating a
            puzzle</a>.
          </ul>

        <li>
          <b>Generate...</b> : Have the program create a new random unique
          puzzle for you.

          <ul>
            <li>Set the number of cell values to show, the more that are
            visible, the easier it'll probably be.

            <li>This program does not try to categorize how difficult the
            generated puzzle is.

            <li>Note: If you have less than 17 cells shown there will not be a
            unique solution.&nbsp;

            <li>The less cells you have shown the longer it will take to find
            a unique puzzle, but the program will try for as long as it takes.
            If you get impatient, just cancel the generation and you will be
            asked if you want the program to just randomly remove cell values
            which may or may not yield a unique solution.
          </ul>

        <li>
          <b>Open...</b> : Open a puzzle from a file, the puzzle should be a
          9x9 grid of numbers separated by spaces or commas.

          <ul>
            <li>After opening, the program will try to solve the puzzle and let
            you know if there is a problem, such as a non unique solution. You
            can just cancel out if you'd like to skip this check.
          </ul>

        <li><b>Save as...</b> : Save the current puzzle to disk.

        <li><b>Page Setup...</b> : Adjust the paper and margins for printing.

        <li><b>Print Preview...</b> : Preview what the printout will look
        like.

        <li><b>Print...</b> : Print the current puzzle, WYSIWYG, what you see
        is what you get.

        <li><b>Exit</b> : Exit the program.
      </ul>

    <li>
      <b>Edit</b>

      <ul>
        <li><b>Copy puzzle</b> : Copy the puzzle to the clipboard to paste
        into other programs.

        <li><b>Reset...</b> : Clear all the values you've entered to return
        back to the initial state. This is the same as just undoing back to
        the beginning.

        <li><b>Undo/Redo</b> : You can undo and redo values that you've
        entered into the puzzle. If you undo a couple steps and enter a new
        value you cannot then redo back to where you were.

        <li><b>Preferences</b> : Set the colors to use and whatnot in a
        dialog. See the <a href="#Preferences_dialog">preferences dialog</a>
        section.

        <li>
          <b>Save preferences</b> : Save the current preferences, including
          what you've set to show and exclude.

          <ul>
            <li>This program does not automatically save the preferences on
            exit, but rather only when you explicitly request it to do so.

            <li>MSW : preferences are stored in "Documents and
            Settings\username\wxLuaSudoku.ini"

            <li>Unix : preferences are stored in "~/.wxLuaSudoku.ini"

            <li>You may delete these files if you want to reset the program to
            the defaults or are done using it.
          </ul>
        </ul>

    <li>
      <b>View</b>

      <ul>
        <li><b>Mark errors</b> : Mark the cells that have obviously invalid
        values, not invalid from the standpoint of it being the "correct"
        value, but whether or not it's in conflict with another value that has
        already exists in same row, column, or block in the puzzle.

        <li>
          <b>Mark mistakes</b> : Mark the cells that have "wrong" values that
          will not lead to a solution by comparing the values to a
          precalculated solution.

          <ul>
            <li>If the solution has not been already found, perhaps you've
            canceled the initial check, the program will have to work it out.
            If you cancel this process and then want any mistakes shown again,
            it'll have to try to solve it again. In the case that the program
            cannot find a solution or there isn't a unique solution, a warning
            dialog will be shown and marking the mistakes will be
            automatically unchecked.
          </ul>

        <li><b>Show toolbar</b> : Show or hide the toolbar at the top of the
        program.

        <li><b>Show statusbar</b> : Show or hide the statusbar at the bottom
        of the program.
      </ul>

    <li>
      <b>Possible</b>

      <ul>
        <li>
          <b>Show calculated possible</b> : Show the possible values that the
          program has calculated for the empty cells.

          <ul>
            <li>Note that this does not take into account any invalid or
            erroneous values you may have entered, it just shows you possible
            values given the current state of the puzzle.
          </ul>

        <li>
          <b>Show/Edit pencil marks</b> : Allows you to enter the possible
          values for the cells by hand.

          <ul>
            <li>See the section above about <a href="#Pencil_marks">entering
            pencil marks</a>.

            <li>You can show the calculated possible values or the pencil
            marks or neither, but not both at the same time.
          </ul>

        <li><b>Show possible line</b> : Show the possible values in a single
        line, useful if you want to print it out to play later.

        <li>
          <b>Pencil marks</b>

          <ul>
            <li><b>Clear all...</b> : Clear all the pencil marks for the whole
            puzzle.

            <li><b>Set all...</b> : Set all values for the pencil marks for
            the whole puzzle.

            <li><b>Calculate...</b> : Set all the pencil marks to the same
            values as the calculated possible values.
          </ul>

        <li>
          <b>Mark groups</b>

          <ul>
            <li><b>Mark naked groups</b> : Mark all naked groups of cells;
            pairs, triplets, and quads.

            <li><b>Mark hidden groups</b> : Mark all hidden groups of cells;
            pairs, triplets, and quads.

            <li>... mark each group individually

            <li><i>Note: See Solve-&gt;Eliminate to remove possible values
            that can be excluded once the groups have been found. You do not
            have to show the groups to eliminate values or vice versa.</i>
          </ul>
        </ul>

    <li>
      <b>Solve</b>

      <ul>
        <li>
          <b>Verify unique solution...</b> : Use the brute force solver to
          find if there is more than one solution for the initial values of
          the puzzle or if there is a solution at all.

          <ul>
            <li>Typically this is not necessary since the program
            automatically tries to verify the puzzle after opening or creating
            a puzzle, but if you had canceled the check you can verify it by
            hand using this.
          </ul>

        <li>
          <b>Show solution</b> : Show the solution to the puzzle that should
          have been automatically found after opening, creating, or generating
          a puzzle.

          <ul>
            <li>If you had canceled out of the puzzle verification procedure
            the program will have to solve it using the initial values in the
            puzzle.

            <li>Use undo to return back to playing the game if you wish to
            just take a peek at some answers.
          </ul>

        <li>
          <b>Eliminate groups</b>

          <ul>
            <li><b>Eliminate naked groups</b> : Remove all calculated possible
            values that can be excluded by evaluating the naked groups of
            pairs, triplets, and quads. This does not work on the pencil
            marks. See the <a href="#Some_Sudoku_terms">Sudoku terms</a>
            section about naked groups.

            <li><b>Eliminate hidden groups</b> : Remove all calculated
            possible values that can be excluded by evaluating the hidden
            groups of pairs, triplets, and quads. This does not work on the
            pencil marks. See the <a href="#Some_Sudoku_terms">Sudoku
            terms</a> section about hidden groups.

            <li>... eliminate each group individually

            <li><i>Note: This updates the View-&gt;Show calculated possible
            and also for solving using Solve (scan ...) since the more
            possible values you remove the easier it is to narrow down the
            correct values.</i>
          </ul>

        <li><i><u>Note on solving</u>: Solving works on the current puzzle
        state which means that if you have inadvertently entered a wrong value
        the solver stops at the point where no new values can be placed. The
        values it finds will be logically correct based on the rules of the
        game, but probably wrong. Use mark mistakes if you want to check how
        you're doing.</i>

        <li><b>Solve (scan singles)</b> : Fill in the values for all cells
        that can only take one value.

        <li><b>Solve (scan rows)</b> : Fill in the values of cells that are
        the only ones in the row to have a particular possible value.

        <li><b>Solve (scan cols)</b> : Same for columns

        <li><b>Solve (scan blocks)</b> : Same for blocks

        <li><i><u>Note on solve scanning</u> : You can try iterating through
        scanning singles, rows, columns, blocks to see which new values can be
        found after other values have been set.</i>

        <li>
          <b>Solve (scanning)</b> : Try solving the puzzle by scanning over
          and over until no new cell values can be found.

          <ul>
            <li>Check different eliminate groups to allow the solver to take
            advantage of the reduced number of possible values.
          </ul>

        <li>
          <b>Solve (brute force)</b> : Solve the puzzle by guessing values
          from the possible values using the current puzzle values.

          <ul>
            <li>This will fail if the puzzle cannot be solved (maybe you've
            made a mistake?)
          </ul>
        </ul>

    <li>
      <b>Help</b>

      <ul>
        <li><b>About...</b> : A simple about this program dialog.

        <li><b>Help...</b> : Show this document.
      </ul>
    </ul>

  <h2><a name="Preferences_dialog" id="Preferences_dialog"></a>Preferences
  dialog</h2>In the preferences dialog you can adjust the colors to use for
  the different elements in a cell. A sample cell is shown to give you an idea
  of what it'll look like when done. Note that some fonts you may choose will
  not render properly or may be badly placed in the cells. This is a problem
  with the font itself, just pick a different font. Also, bitmapped fonts only
  come in a limited number of sizes and cannot be scaled to arbitrary sizes,
  again, pick another font that works better on your system.<br>
  <br>
  Additionally, a simpler interface to the menu items <i>Possible-&gt;Mark
  groups</i> and <i>Solve-&gt;Eliminate groups</i> is provided to make it
  easier to check and uncheck multiple items.
]]

-- Simple way to generate unique window or menu ids and ensure they're in order
function NewID()
    if not sudokuGUI_ID_New then sudokuGUI_ID_New = wx.wxID_HIGHEST end
    sudokuGUI_ID_New = sudokuGUI_ID_New + 1
    return sudokuGUI_ID_New
end

sudokuGUI =
{
    frame             = nil, -- The wxFrame of the program
    panel             = nil, -- The main wxPanel child of the wxFrame
    cellWindows       = {},  -- The 81 grid cell wxWindows, children of panel
    cellTextCtrl      = nil, -- Single wxTextCtrl editor for entering cell values

    focused_cell_id   = 0,   -- window id of the currently focused cell, 0 for none

    block_refresh     = false, -- temporarily block refreshing when true

    filePath          = "",  -- last opened filePath
    fileName          = "",  -- last opened fileName

    printData         = wx.wxPrintData(),
    pageSetupData     = wx.wxPageSetupDialogData(),

    config            = nil, -- the wxFileConfig for saving preferences

    Colours                = {}, -- table of wxColours to use, indexes below
    VALUE_COLOUR           = 1,
    INIT_VALUE_COLOUR      = 2,
    POSS_VALUE_COLOUR      = 3,
    INVALID_VALUE_COLOUR   = 4,
    BACKGROUND_COLOUR      = 5,
    ODD_BACKGROUND_COLOUR  = 6,
    FOCUS_CELL_COLOUR      = 7,

    NAKED_PAIRS_COLOUR     = 8,
    NAKED_TRIPLETS_COLOUR  = 9,
    NAKED_QUADS_COLOUR     = 10,
    HIDDEN_PAIRS_COLOUR    = 11,
    HIDDEN_TRIPLETS_COLOUR = 12,
    HIDDEN_QUADS_COLOUR    = 13,
    COLOUR_MAX             = 13,

                           -- A large wxFont for the cell values
    valueFont            = { wxfont = nil, size = 8, width = 0, height = 0 },
                           -- A smallish wxFont for the possible values
    possibleFont         = { wxfont = nil, size = 6, width = 0, height = 0 },

    valueFont_cache      = {}, -- valueFont_cache[size]    = { width, height }
    possibleFont_cache   = {}, -- possibleFont_cache[size] = { width, height }

                               -- calc positions once in PaintCell
                               -- recalc if any of these parameters change
                               -- pos[value].x and .y are upper left corners
    possiblePosCache     = { pos = {}, width = 1, height = 1, line = false, cell_width = 1, cell_height = 1 },

    query_save_prefs     = true, -- tell user that prefs are stored as fileconfig

    ID_NEW               = NewID(),
    ID_CREATE            = NewID(),
    ID_GENERATE          = NewID(),
    ID_OPEN              = NewID(),
    ID_SAVEAS            = NewID(),
    ID_PAGESETUP         = NewID(),
    ID_PRINTSETUP        = NewID(),
    ID_PRINTPREVIEW      = NewID(),
    ID_PRINT             = NewID(),
    ID_EXIT              = wx.wxID_EXIT,

    ID_COPY_PUZZLE       = NewID(),
    ID_RESET             = NewID(),
    ID_UNDO              = NewID(),
    ID_REDO              = NewID(),
    ID_PREFERENCES       = NewID(), -- show preferences dialog
    ID_SAVE_PREFERENCES  = NewID(), -- save preferences

    ID_SHOW_TOOLBAR        = NewID(),
    ID_SHOW_TOOLBAR_LABELS = NewID(),
    ID_SHOW_STATUSBAR      = NewID(),
    ID_SHOW_ERRORS         = NewID(), -- Show errors in the grid
    ID_SHOW_MISTAKES       = NewID(), -- Show mistakes in the grid

    ID_SHOW_POSSIBLE       = NewID(), -- Show the possible values
    ID_SHOW_USER_POSSIBLE  = NewID(), -- Show the user's possible values
    ID_SHOW_POSSIBLE_LINE  = NewID(), -- Show the possible values in a line

    ID_USER_POSSIBLE_MENU     = NewID(),
      ID_USER_POSSIBLE_CLEAR  = NewID(),
      ID_USER_POSSIBLE_SETALL = NewID(),
      ID_USER_POSSIBLE_INIT   = NewID(),

    ID_SHOW_MENU             = NewID(),
      ID_SHOW_NAKED          = NewID(), -- mark naked groups
      ID_SHOW_HIDDEN         = NewID(), -- mark hidden groups
      ID_SHOW_NAKEDPAIRS     = NewID(), -- mark naked pairs
      ID_SHOW_HIDDENPAIRS    = NewID(), -- mark hidden pairs
      ID_SHOW_NAKEDTRIPLETS  = NewID(), -- mark naked triplets
      ID_SHOW_HIDDENTRIPLETS = NewID(), -- mark hidden triplets
      ID_SHOW_NAKEDQUADS     = NewID(), -- mark naked quads
      ID_SHOW_HIDDENQUADS    = NewID(), -- mark hidden quads

    ID_VERIFY_PUZZLE              = NewID(),
    ID_SHOW_SOLUTION              = NewID(), -- Show the solution to the puzzle
    ID_ELIMINATE_MENU             = NewID(),
      ID_ELIMINATE_NAKED          = NewID(), -- eliminate naked groups
      ID_ELIMINATE_HIDDEN         = NewID(), -- eliminate hidden groups
      ID_ELIMINATE_NAKEDPAIRS     = NewID(), -- eliminate naked pairs
      ID_ELIMINATE_HIDDENPAIRS    = NewID(), -- eliminate hidden pairs
      ID_ELIMINATE_NAKEDTRIPLETS  = NewID(), -- eliminate naked triplets
      ID_ELIMINATE_HIDDENTRIPLETS = NewID(), -- eliminate hidden triplets
      ID_ELIMINATE_NAKEDQUADS     = NewID(), -- eliminate naked quads
      ID_ELIMINATE_HIDDENQUADS    = NewID(), -- eliminate hidden quads
    ID_SOLVE_SCANSINGLES   = NewID(), -- Solve for single lone values
    ID_SOLVE_SCANROWS      = NewID(), -- Solve for single values in rows
    ID_SOLVE_SCANCOLS      = NewID(), -- Solve for single values in cols
    ID_SOLVE_SCANBLOCKS    = NewID(), -- Solve for single values in blocks
    ID_SOLVE_SCANNING      = NewID(), -- Solve the puzzle by scanning
    ID_SOLVE_BRUTEFORCE    = NewID(), -- Solve the puzzle by brute force

    ID_ABOUT               = NewID(),
    ID_HELP                = NewID(),

    menuCheckIDs        = {}, -- the current state of the check menu items
                              --  GTK doesn't like to access them in EVT_PAINT
                              --  we don't have to set them since nil == false

    sudokuTables        = {}, -- A table of the sudoku tables for undoing, should always be 1
    sudokuTables_pos    = 0,  -- Current position in the tables

    sudokuSolnTable       = nil, -- solution to the current puzzle
    nonunique_init_puzzle = nil, -- nil for don't know, is true/false once verified

    possNakedTable         = nil,
    possHiddenTable        = nil,

    pencilMarks            = {},  -- pencilMarks[cell][value] = true/nil
    pencilMarksNakedTable  = nil,
    pencilMarksHiddenTable = nil,

    difficulty             = 30, -- number of cells to keep for new puzzle

    sayings_n = 0,               -- number of sayings, calculated later
    sayings = {
        "Pondering...     ",
        "Musing...        ",
        "Meditating...    ",
        "Contemplating... ",
        "Reflecting...    ",
        "Mulling...       ",
        "Considering...   ",
        "Deliberating...  ",
        "Thinking...      ",
        "Working...       ",
        "Grinding...      ",
        "Brooding...      ",
        "Languishing?     ",
        "Despairing...    ",

        "To be, or not to be that is the question ",
        "Whether 'tis nobler in the mind to suffer ",
        "The slings and arrows of outrageous fortune, ",
        "Or to take arms against a sea of troubles, ",
        "And by opposing end them? ",
        "To die: to sleep; ",
        "No more; and by a sleep to say we end ",
        "The heart-ache and the thousand natural shocks",
        "That flesh is heir to, 'tis a consummation",
        "Devoutly to be wish'd. To die, to sleep;",
        "To sleep: perchance to dream:",
        "ay, there's the rub;",
        "For in that sleep of death what dreams may come",
        "When we have shuffled off this mortal coil,",
        "Must give us pause: there's the respect",
        "That makes calamity of so long life;",
        "For who would bear the whips and scorns of time,",
        "The oppressor's wrong, the proud man's contumely,",
        "The pangs of despised love, the law's delay,",
        "The insolence of office and the spurns",
        "That patient merit of the unworthy takes,",
        "When he himself might his quietus make",
        "With a bare bodkin? who would fardels bear,",
        "To grunt and sweat under a weary life,",
        "But that the dread of something after death,",
        "The undiscover'd country from whose bourn",
        "No traveller returns, puzzles the will",
        "And makes us rather bear those ills we have",
        "Than fly to others that we know not of?",
        "Thus conscience does make cowards of us all;",
        "And thus the native hue of resolution",
        "Is sicklied o'er with the pale cast of thought,",
        "And enterprises of great pitch and moment",
        "With this regard their currents turn awry,",
        "And lose the name of action.-- Soft you now!",
        "The fair Ophelia! Nymph, in thy orisons",
        "Be all my sins remember'd..."
    }
}

sudokuGUI.sayings_n = #sudokuGUI.sayings -- calc number of sayings

for cell = 1, 81 do
    sudokuGUI.pencilMarks[cell] = {}
end

-- ----------------------------------------------------------------------------
-- Run this function once to find the best font sizes to use and store them
--   if height/width = nil then use a default size,
--   else try to fit a font size to given height/width
function sudokuGUI.GetCellBestSize(cell_width, cell_height)
    local dc = wx.wxClientDC(sudokuGUI.frame)

    local size = sudokuGUI.DoGetCellBestSize(dc, cell_width, cell_height,
                        sudokuGUI.valueFont, sudokuGUI.possibleFont,
                        sudokuGUI.valueFont_cache, sudokuGUI.possibleFont_cache)

    dc:delete() -- ALWAYS delete() any wxDCs created when done
    return size
end

function sudokuGUI.DoGetCellBestSize(dc, cell_width, cell_height,
                                     valueFont, possibleFont,
                                     valueFont_cache, possibleFont_cache) -- cache are optional

    local function GetBestFontSize(dc, width, height, fontTable, font_cache)

        local function DoGetBestFontSize(step, largest)
            for s = fontTable.size, largest, step do
                fontTable.size = s

                if font_cache[fontTable.size] then
                    fontTable.width  = font_cache[fontTable.size].width
                    fontTable.height = font_cache[fontTable.size].height
                else
                    fontTable.wxfont:SetPointSize(fontTable.size)
                    dc:SetFont(fontTable.wxfont)
                    fontTable.width, fontTable.height = dc:GetTextExtent("5")

                    font_cache[fontTable.size] = {}
                    font_cache[fontTable.size].width  = fontTable.width
                    font_cache[fontTable.size].height = fontTable.height
                end

                if (fontTable.height > height) or (fontTable.width > width) then
                    break
                end
            end
        end

        fontTable.size = 2
        if not font_cache then font_cache = {} end -- use local font cache

        -- skip font sizes by 4 to get a rough estimate of the size
        DoGetBestFontSize(4, 1000)
        local largest = fontTable.size
        fontTable.size = iff(fontTable.size-3 > 1, fontTable.size-3, 2)
        -- get the best size to use
        DoGetBestFontSize(1, largest)

        -- use next smaller value that actually fits
        fontTable.size = iff(fontTable.size-1 > 1, fontTable.size-1, 2)
        fontTable.wxfont:SetPointSize(fontTable.size)
        fontTable.width  = font_cache[fontTable.size].width
        fontTable.height = font_cache[fontTable.size].height

        return fontTable
    end

    if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_POSSIBLE_LINE) then
        possibleFont = GetBestFontSize(dc, (cell_width-2)/10, (cell_height-2), possibleFont, possibleFont_cache)
    else
        possibleFont = GetBestFontSize(dc, (cell_width-2)/3, (cell_height-2)/3, possibleFont, possibleFont_cache)
    end

    valueFont = GetBestFontSize(dc, cell_width-4, cell_height-4, valueFont, valueFont_cache)

    return wx.wxSize(valueFont.height+4, valueFont.height+4)
end

-- ----------------------------------------------------------------------------
-- Is this cell in an "odd" block for colouring the blocks
function sudokuGUI.IsOddBlockCell(cell)
    return math.fmod(sudoku.CellToBlock(cell), 2) ~= 0
end

-- ----------------------------------------------------------------------------
-- Create one of the 81 cell windows and connect the events to it
function sudokuGUI.CreateCellWindow(parent, winID, size)
    local win = wx.wxWindow(parent, winID,
                            wx.wxDefaultPosition, wx.wxDefaultSize,
                            wx.wxWANTS_CHARS+wx.wxSIMPLE_BORDER) --wxSUNKEN_BORDER)

    -- set the background colour to reduce flicker
    if sudokuGUI.IsOddBlockCell(winID) then
        win:SetBackgroundColour(sudokuGUI.Colours[sudokuGUI.BACKGROUND_COLOUR])
    else
        win:SetBackgroundColour(sudokuGUI.Colours[sudokuGUI.ODD_BACKGROUND_COLOUR])
    end

    win:Connect(wx.wxEVT_ERASE_BACKGROUND, function(event) end)
    win:Connect(wx.wxEVT_PAINT,       sudokuGUI.OnPaintCellWindow)
    win:Connect(wx.wxEVT_KEY_DOWN,    sudokuGUI.OnKeyDownCellWindow )
    win:Connect(wx.wxEVT_KEY_UP,      sudokuGUI.OnKeyUpCellWindow )
    win:Connect(wx.wxEVT_LEFT_DOWN,   sudokuGUI.OnLeftClickCellWindow )
    win:Connect(wx.wxEVT_LEFT_DCLICK, sudokuGUI.OnLeftDClickCellWindow )
    return win
end

-- ----------------------------------------------------------------------------
-- wxPaintEvent handler for all of the cell windows
function sudokuGUI.OnPaintCellWindow(event)
    local win = event:GetEventObject():DynamicCast("wxWindow")

    -- ALWAYS create a wxPaintDC in a wxEVT_PAINT handler, even if unused
    local dc = wx.wxPaintDC(win)
    if not sudokuGUI.block_refresh then
        local cell = win:GetId()
        local width, height = win:GetClientSizeWH()
        sudokuGUI.PaintCell(dc, cell, width, height, sudokuGUI.valueFont, sudokuGUI.possibleFont)
    end
    dc:delete() -- ALWAYS delete() any wxDCs created when done
end

function sudokuGUI.PaintCell(dc, cell, width, height, valueFont, possibleFont)
    -- clear the window before drawing
    dc:SetPen(wx.wxTRANSPARENT_PEN)
    local bgColour
    if sudokuGUI.focused_cell_id ~= cell then
        if sudokuGUI.IsOddBlockCell(cell) then
            bgColour = sudokuGUI.Colours[sudokuGUI.BACKGROUND_COLOUR]
        else
            bgColour = sudokuGUI.Colours[sudokuGUI.ODD_BACKGROUND_COLOUR]
        end
    else
        bgColour = sudokuGUI.Colours[sudokuGUI.FOCUS_CELL_COLOUR]
    end
    local brush = wx.wxBrush(bgColour, wx.wxSOLID)
    dc:SetBrush(brush)
    dc:DrawRectangle(0, 0, width, height)
    brush:delete()

    local sudokuTable = sudokuGUI.GetCurrentTable()
    local value_str, is_init = sudokuGUI.GetCellValueString(cell)
    local has_cell_value = string.len(value_str) ~= 0

    -- Draw the possible values
    local show_possible      = sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_POSSIBLE)
    local show_possible_user = sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_USER_POSSIBLE)
    local show_possible_line = sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_POSSIBLE_LINE)

    if (show_possible or show_possible_user) and (not has_cell_value) then
        local possible = sudoku.GetCellPossible(sudokuTable, cell)
        if show_possible_user then
            possible = sudokuGUI.pencilMarks[cell]
        end

        dc:SetTextForeground(sudokuGUI.Colours[sudokuGUI.POSS_VALUE_COLOUR])
        dc:SetFont(possibleFont.wxfont)

        -- find the positions of each possible value
        local pos = sudokuGUI.CalcPossiblePositions(width, height, possibleFont)

        local show_possible_user_all = false
        if show_possible_user and (cell == sudokuGUI.focused_cell_id) then
            show_possible_user_all = wx.wxGetKeyState(wx.WXK_SHIFT)
        end

        -- draw each one separately, even for line to ensure monospace
        for i = 1, 9 do
            if possible and possible[i] then
                dc:DrawText(tostring(i), pos[i].x, pos[i].y)
            elseif show_possible_user_all then
                dc:SetBackgroundMode(wx.wxSOLID)
                dc:SetTextForeground(bgColour)
                dc:SetTextBackground(sudokuGUI.Colours[sudokuGUI.POSS_VALUE_COLOUR])
                dc:DrawText(tostring(i), pos[i].x, pos[i].y)
                dc:SetTextForeground(sudokuGUI.Colours[sudokuGUI.POSS_VALUE_COLOUR])
                dc:SetTextBackground(bgColour)
                dc:SetBackgroundMode(wx.wxTRANSPARENT)
            end
        end

        local nakedTable  = sudokuGUI.possNakedTable
        local hiddenTable = sudokuGUI.possHiddenTable
        if show_possible_user then
            nakedTable  = sudokuGUI.pencilMarksNakedTable
            hiddenTable = sudokuGUI.pencilMarksHiddenTable
        end

        if nakedTable and hiddenTable then
            dc:SetBrush(wx.wxTRANSPARENT_BRUSH)
            local char0 = string.byte("0")

            local function draw_nakedhidden(colourID, num, key_table, hidden)
                if (not key_table) or (#key_table < 1) then return end

                local pen = wx.wxPen(sudokuGUI.Colours[colourID], 1, wx.wxSOLID)
                dc:SetPen(pen)

                for k = 1, #key_table do
                    for n = 1, num do
                        local val = string.byte(key_table[k], n)-char0
                        if hidden ~= true then
                            dc:DrawRectangle(pos[val].x, pos[val].y,
                                             possibleFont.width, possibleFont.height)
                        else
                            dc:DrawRoundedRectangle(pos[val].x, pos[val].y,
                                                    possibleFont.width, possibleFont.height,
                                                    20)
                        end
                    end
                end

                pen:delete()
            end

            -- draw pair marker last so it's on top of the others
            if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_HIDDENQUADS) then
                draw_nakedhidden(sudokuGUI.HIDDEN_QUADS_COLOUR, 4, hiddenTable.quads.cells[cell], true)
            end
            if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_NAKEDQUADS) then
                draw_nakedhidden(sudokuGUI.NAKED_QUADS_COLOUR, 4, nakedTable.quads.cells[cell])
            end

            if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_HIDDENTRIPLETS) then
                draw_nakedhidden(sudokuGUI.HIDDEN_TRIPLETS_COLOUR, 3, hiddenTable.triplets.cells[cell], true)
            end
            if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_NAKEDTRIPLETS) then
                draw_nakedhidden(sudokuGUI.NAKED_TRIPLETS_COLOUR, 3, nakedTable.triplets.cells[cell])
            end

            if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_HIDDENPAIRS) then
                draw_nakedhidden(sudokuGUI.HIDDEN_PAIRS_COLOUR, 2, hiddenTable.pairs.cells[cell], true)
            end
            if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_NAKEDPAIRS) then
                draw_nakedhidden(sudokuGUI.NAKED_PAIRS_COLOUR, 2, nakedTable.pairs.cells[cell])
            end
        end
    end

    -- mark invalid cells, always mark invalid if creating
    local show_errors = sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_ERRORS)
    if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_CREATE) then show_errors = true end
    if show_errors then show_errors = sudokuGUI.GetCurrentTable().invalid[cell] end

    local show_mistakes = sudokuGUI.sudokuSolnTable and sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_MISTAKES)

    if show_errors then
        dc:SetPen(wx.wxPen(sudokuGUI.Colours[sudokuGUI.INVALID_VALUE_COLOUR], 1, wx.wxSOLID))
        dc:DrawLine(0, 0, width, height)
        dc:DrawLine(width, 0, 0, height)
    elseif show_mistakes then
        if sudoku.HasCellValue(sudokuTable, cell) and
            (sudoku.GetCellValue(sudokuGUI.sudokuSolnTable, cell) ~=
             sudoku.GetCellValue(sudokuTable, cell)) then
            local pen = wx.wxPen(sudokuGUI.Colours[sudokuGUI.INVALID_VALUE_COLOUR], 1, wx.wxSOLID)
            dc:SetPen(pen)
            pen:delete()
            dc:DrawLine(0, 0, width, height)
        end
    end

    -- Draw the set value, if any
    if has_cell_value then
        local fgColour = sudokuGUI.Colours[sudokuGUI.VALUE_COLOUR]
        if is_init then
            fgColour = sudokuGUI.Colours[sudokuGUI.INIT_VALUE_COLOUR]
        end

        dc:SetTextForeground(fgColour)

        dc:SetFont(valueFont.wxfont)
        dc:DrawText(value_str, width/2  - valueFont.width/2,
                               height/2 - valueFont.height/2)
    end
end

-- ----------------------------------------------------------------------------

function sudokuGUI.CalcPossiblePositions(width, height, possibleFont)
    local pos = {}
    local show_possible_line = sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_POSSIBLE_LINE)

    if (sudokuGUI.possiblePosCache.pos and
        (sudokuGUI.possiblePosCache.cell_width  == width) and
        (sudokuGUI.possiblePosCache.cell_height == height) and
        (sudokuGUI.possiblePosCache.width  == possibleFont.width) and
        (sudokuGUI.possiblePosCache.height == possibleFont.height) and
        (sudokuGUI.possiblePosCache.line   == show_possible_line)) then
        pos = sudokuGUI.possiblePosCache.pos
    else
        if show_possible_line then
            for i = 1, 9 do
                pos[i] = { x = (1+ (i-1)*possibleFont.width), y = 1 }
            end
        else
            local c = 0
            local horiz_space = (width  - 3*possibleFont.width)/4
            local vert_space  = (height - 3*possibleFont.height)/4
            local h_space = horiz_space
            local v_space = vert_space

            for j = 1, 3 do
                -- try to center it a little better
                if (j == 1) and (vert_space - math.floor(vert_space) > .3) then
                    v_space = vert_space+1
                else
                    v_space = vert_space
                end

                for i = 1, 3 do
                    c = c + 1
                    if (i == 1) and (horiz_space - math.floor(horiz_space) > .3) then
                        h_space = horiz_space+1
                    else
                        h_space = horiz_space
                    end
                    pos[c] = { x = i*h_space + (i-1)*possibleFont.width,
                               y = j*v_space + (j-1)*possibleFont.height }
                end
            end
        end

        -- cache these values for next cell
        sudokuGUI.possiblePosCache.pos         = pos
        sudokuGUI.possiblePosCache.cell_width  = width
        sudokuGUI.possiblePosCache.cell_height = height
        sudokuGUI.possiblePosCache.width       = possibleFont.width
        sudokuGUI.possiblePosCache.height      = possibleFont.height
        sudokuGUI.possiblePosCache.line        = show_possible_line
    end

    return pos
end

-- ----------------------------------------------------------------------------

function sudokuGUI.ConnectPrintEvents(printOut)
    printOut:SetPageInfo(1, 1, 1, 1)
    printOut.HasPage = function(self, pageNum) return pageNum == 1 end
    --printOut.GetPageInfo = function(self) return 1, 1, 1, 1 end

    printOut.OnPrintPage = function(self, pageNum)
        local dc = self:GetDC()

        local ppiScr_width, ppiScr_height = self:GetPPIScreen()
        local ppiPrn_width, ppiPrn_height = self:GetPPIPrinter()
        local ppi_scale_x = ppiPrn_width/ppiScr_width
        local ppi_scale_y = ppiPrn_height/ppiScr_height

        -- Get the size of DC in pixels and the number of pixels in the page
        local dc_width, dc_height = dc:GetSize()
        local pagepix_width, pagepix_height = self:GetPageSizePixels()

        local dc_pagepix_scale_x = dc_width/pagepix_width
        local dc_pagepix_scale_y = dc_height/pagepix_height

        -- If printer pageWidth == current DC width, then this doesn't
        -- change. But w might be the preview bitmap width, so scale down.
        local dc_scale_x = ppi_scale_x * dc_pagepix_scale_x
        local dc_scale_y = ppi_scale_y * dc_pagepix_scale_y

        -- calculate the pixels / mm (25.4 mm = 1 inch)
        local ppmm_x = ppiScr_width / 25.4
        local ppmm_y = ppiScr_height / 25.4

        -- Adjust the page size for the pixels / mm scaling factor
        local pageMM_width, pageMM_height = self:GetPageSizeMM()
        local pagerect_x, pagerect_y = 0, 0
        local pagerect_w, pagerect_h = pageMM_width * ppmm_x, pageMM_height * ppmm_y

        -- get margins informations and convert to printer pixels
        local topLeft     = sudokuGUI.pageSetupData:GetMarginTopLeft()
        local bottomRight = sudokuGUI.pageSetupData:GetMarginBottomRight()

        local top    = topLeft:GetY()     * ppmm_y
        local bottom = bottomRight:GetY() * ppmm_y
        local left   = topLeft:GetX()     * ppmm_x
        local right  = bottomRight:GetX() * ppmm_x

        local printrect_x, printrect_y = left, top
        local printrect_w, printrect_h = pagerect_w-(left+right), pagerect_h-(top+bottom)

        dc:SetUserScale(dc_scale_x, dc_scale_y);

        local cell_width  = (printrect_w)/11
        local cell_height = (printrect_h)/11
        if cell_width < cell_height then cell_height = cell_width end
        if cell_width > cell_height then cell_width  = cell_height end

        -- calculate font sizes for the printout, copy font since we'll recalc the size
        local valueFont    = { wxfont = wx.wxFont(sudokuGUI.valueFont.wxfont),    size = 8, width = 0, height = 0 }
        local possibleFont = { wxfont = wx.wxFont(sudokuGUI.possibleFont.wxfont), size = 6, width = 0, height = 0 }
        sudokuGUI.DoGetCellBestSize(dc, cell_width, cell_height,
                                    valueFont, possibleFont)

        local function RowOrigin(row) return printrect_x + row*cell_height + row end
        local function ColOrigin(col) return printrect_y + col*cell_width + col end

        local old_focused_cell_id = sudokuGUI.focused_cell_id -- clear focus
        sudokuGUI.focused_cell_id = 0

        for row = 1, 9 do
            for col = 1, 9 do
                local x = ColOrigin(col)
                local y = RowOrigin(row)
                dc:SetDeviceOrigin(x*dc_scale_x, y*dc_scale_x)
                local cell = sudoku.RowColToCell(row, col)
                sudokuGUI.PaintCell(dc, cell, cell_width, cell_height, valueFont, possibleFont)
            end
        end

        valueFont.wxfont:delete()
        possibleFont.wxfont:delete()

        sudokuGUI.focused_cell_id = old_focused_cell_id -- restore focus

        dc:SetDeviceOrigin(0, 0)
        local borders = { [1]=true, [4]=true, [7]=true, [10]=true }
        for i = 1, 10 do
            local pen = wx.wxPen(wx.wxBLACK, iff(borders[i], 4, 2), wx.wxSOLID)
            dc:SetPen(pen)
            pen:delete()
            dc:DrawLine(ColOrigin(1), RowOrigin(i), ColOrigin(10), RowOrigin(i))
            dc:DrawLine(ColOrigin(i), RowOrigin(1), ColOrigin(i),  RowOrigin(10))
        end

        return true
   end
end

function sudokuGUI.Print()
    local printDialogData = wx.wxPrintDialogData(sudokuGUI.printData)
    local printer = wx.wxPrinter(printDialogData)

    local luaPrintout = wx.wxLuaPrintout("wxLuaSudoku Printout")
    sudokuGUI.ConnectPrintEvents(luaPrintout)

    if printer:Print(sudokuGUI.frame, luaPrintout, true) == false then
        if printer:GetLastError() == wx.wxPRINTER_ERROR then
            wx.wxMessageBox("There was a problem printing.\n"..
                            "Perhaps your current printer is not setup correctly?",
                            "wxLuaSudoku Printout",
                            wx.wxOK, sudokuGUI.frame)
        end
    else
        sudokuGUI.printData = printer:GetPrintDialogData():GetPrintData():Copy()
    end
end

function sudokuGUI.PrintPreview()
    luaPrintout      = wx.wxLuaPrintout("wxLuaSudoku Print Preview")
    luaPrintPrintout = wx.wxLuaPrintout("wxLuaSudoku Printout")
    sudokuGUI.ConnectPrintEvents(luaPrintout)
    sudokuGUI.ConnectPrintEvents(luaPrintPrintout)

    local printDialogData = wx.wxPrintDialogData(sudokuGUI.printData):GetPrintData()
    local preview         = wx.wxPrintPreview(luaPrintout, luaPrintPrintout, printDialogData)

    local result = preview:Ok()
    if result == false then
        wx.wxMessageBox("There was a problem previewing.\n"..
                        "Perhaps your current printer is not setup correctly?",
                        "wxLuaSudoku print preview error",
                        wx.wxOK, sudokuGUI.frame)
    else
        local previewFrame = wx.wxPreviewFrame(preview, sudokuGUI.frame,
                                               "wxLuaSudoku print preview",
                                               wx.wxDefaultPosition, wx.wxSize(600, 600))

        previewFrame:Connect(wx.wxEVT_CLOSE_WINDOW,
                function (event)
                    previewFrame:Destroy()
                    event:Skip()
                end )

        previewFrame:Centre(wx.wxBOTH)
        previewFrame:Initialize()
        previewFrame:Show(true)
    end
end

function sudokuGUI.PrintSetup() -- FIXME DEPRICATED IN WXWIDGETS?
    local printDialogData = wx.wxPrintDialogDataFromPrintData(sudokuGUI.printData)
    local printerDialog   = wx.wxPrintDialog(sudokuGUI.frame, printDialogData)
    printerDialog:GetPrintDialogData():SetSetupDialog(true)
    printerDialog:ShowModal()
    sudokuGUI.printData = printerDialog:GetPrintDialogData():GetPrintData():Copy()
	--printerDialog:Destroy()
end

function sudokuGUI.PageSetup()
    sudokuGUI.printData = sudokuGUI.pageSetupData:GetPrintData():Copy()
    local pageSetupDialog = wx.wxPageSetupDialog(sudokuGUI.frame, sudokuGUI.pageSetupData)
    pageSetupDialog:ShowModal()
    sudokuGUI.printData     = pageSetupDialog:GetPageSetupDialogData():GetPrintData():Copy()
    sudokuGUI.pageSetupData = pageSetupDialog:GetPageSetupDialogData():Copy()
	--pageSetupDialog:Destroy()
end

-- ----------------------------------------------------------------------------
-- Set the currently focused window, refresh new and old
function sudokuGUI.SetFocusWindow(cell)
    local last_id = sudokuGUI.focused_cell_id
    sudokuGUI.focused_cell_id = iff((cell>=1) and (cell<=81), cell, 0)

    if sudokuGUI.cellWindows[last_id] then
        sudokuGUI.cellWindows[last_id]:Refresh()
    end
    if sudokuGUI.cellWindows[cell] then
        sudokuGUI.cellWindows[cell]:Refresh()
    end
end

-- ----------------------------------------------------------------------------

function sudokuGUI.OnKeyUpCellWindow(event)
    event:Skip()
    -- we don't care who actually got this event, just use the "focused cell"
    if (sudokuGUI.focused_cell_id < 1) then return end

    local key = event:GetKeyCode()

    if (sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_USER_POSSIBLE) == true) and
        (key == wx.WXK_SHIFT) then
        sudokuGUI.cellWindows[sudokuGUI.focused_cell_id]:Refresh(false)
        return
    end

end

-- Left down click handler for the cell windows, hide the cell editor
function sudokuGUI.OnKeyDownCellWindow(event)
    event:Skip()
    -- we don't care who actually got this event, just use the "focused cell"
    if (sudokuGUI.focused_cell_id < 1) then return end

    local key = event:GetKeyCode()

    if (sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_USER_POSSIBLE) == true) and
        (key == wx.WXK_SHIFT) then
        sudokuGUI.cellWindows[sudokuGUI.focused_cell_id]:Refresh(false)
    end

    if event:HasModifiers() or event:AltDown() or event:ControlDown() then
        sudokuGUI.cellWindows[sudokuGUI.focused_cell_id]:Refresh(false)
        return
    end
    -- clear the current focused window
    if (key == wx.WXK_ESCAPE) then
        sudokuGUI.SetFocusWindow(0)
        return
    end

    -- the cursor keys move the focus cell
    local movefocus =
    {
        [wx.WXK_LEFT]       = -1, [wx.WXK_NUMPAD_LEFT]  = -1,
        [wx.WXK_UP]         = -9, [wx.WXK_NUMPAD_UP]    = -9,
        [wx.WXK_RIGHT]      = 1,  [wx.WXK_NUMPAD_RIGHT] = 1,
        [wx.WXK_DOWN]       = 9,  [wx.WXK_NUMPAD_DOWN]  = 9,

        [wx.WXK_PAGEUP]     = -9, [wx.WXK_PRIOR] = -9,
        [wx.WXK_PAGEDOWN]   = 9,  [wx.WXK_NEXT]  = 9,

        [wx.WXK_NUMPAD_HOME]     = -10,
        [wx.WXK_NUMPAD_PAGEUP]   = -8, [wx.WXK_NUMPAD_PRIOR] = -8,
        [wx.WXK_NUMPAD_END]      = 8,
        [wx.WXK_NUMPAD_PAGEDOWN] = 10, [wx.WXK_NUMPAD_NEXT]  = 10,

        [wx.WXK_TAB]          = 1,
        [wx.WXK_RETURN]       = 1,
        [wx.WXK_NUMPAD_ENTER] = 1
    }

    if (key == wx.WXK_HOME) then
        sudokuGUI.SetFocusWindow(1)
        return
    elseif (key == wx.WXK_END) then
        sudokuGUI.SetFocusWindow(81)
        return
    elseif movefocus[key] then
        local cell = sudokuGUI.focused_cell_id + movefocus[key]
        if (cell >= 1) and (cell <= 81) then
            sudokuGUI.SetFocusWindow(cell)
        end
        return
    end

    -- translate number pad keys to numbers
    local numpad =
    {
        [wx.WXK_NUMPAD0] = 0,
        [wx.WXK_NUMPAD1] = 1,
        [wx.WXK_NUMPAD2] = 2,
        [wx.WXK_NUMPAD3] = 3,
        [wx.WXK_NUMPAD4] = 4,
        [wx.WXK_NUMPAD5] = 5,
        [wx.WXK_NUMPAD6] = 6,
        [wx.WXK_NUMPAD7] = 7,
        [wx.WXK_NUMPAD8] = 8,
        [wx.WXK_NUMPAD9] = 9,

        [wx.WXK_DELETE]         = 0,
        [wx.WXK_BACK]           = 0,
        [wx.WXK_SPACE]          = 0,
        [wx.WXK_NUMPAD_INSERT]  = 0,
        [wx.WXK_NUMPAD_DECIMAL] = 0,
        [wx.WXK_NUMPAD_DELETE]  = 0,
    }

    local zero = string.byte("0")
    if numpad[key] then key = zero + numpad[key] end

    if (key < 32) or (key > 127) then return end -- normal ASCII key

    local one  = string.byte("1")
    local nine = string.byte("9")

    if (key >= one) and (key <= nine) then
        key = key - one + 1
    else
        key = 0
    end

    if event:ShiftDown() and sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_USER_POSSIBLE) then
        if (key >= 1) and (key <= 9) then
            sudokuGUI.pencilMarks[sudokuGUI.focused_cell_id][key] = iff(sudokuGUI.pencilMarks[sudokuGUI.focused_cell_id][key], nil, key)
            sudokuGUI.UpdateTable()
        end
    else
        sudokuGUI.SetCellValue(sudokuGUI.focused_cell_id, key)
    end
end

-- ----------------------------------------------------------------------------
-- Test to see if one of the possible values has been clicked on
function sudokuGUI.HitTestPossibleValue(mx, my)
    local cell = sudokuGUI.focused_cell_id
    if (cell < 1) or (cell > 81) then return nil end

    local w = sudokuGUI.possiblePosCache.width
    local h = sudokuGUI.possiblePosCache.height
    local rect = wx.wxRect(0, 0, w, h)

    for n = 1, 9 do
        rect.X = sudokuGUI.possiblePosCache.pos[n].x
        rect.Y = sudokuGUI.possiblePosCache.pos[n].y
        if rect:Inside(mx, my) then
            return n
        end
    end

    return nil
end

-- ----------------------------------------------------------------------------
-- Left down click handler for the cell windows, hide the cell editor
function sudokuGUI.OnLeftClickCellWindow(event)
    event:Skip()

    local win = event:GetEventObject():DynamicCast("wxWindow")
    local winId = win:GetId()

    if sudokuGUI.cellTextCtrl then
        sudokuGUI.SaveCellTextCtrlValue()
        sudokuGUI.DestroyCellTextCtrl()
    end

    sudokuGUI.SetFocusWindow(winId)

    if event:ShiftDown() and sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_USER_POSSIBLE) then
        local p = sudokuGUI.HitTestPossibleValue(event:GetX(), event:GetY())
        if p then
            sudokuGUI.pencilMarks[sudokuGUI.focused_cell_id][p] = iff(sudokuGUI.pencilMarks[sudokuGUI.focused_cell_id][p], nil, p)
            sudokuGUI.cellWindows[winId]:Refresh(false)
        end
    end

end
-- Left double click handler for the cell windows, hide old, show new cell editor
function sudokuGUI.OnLeftDClickCellWindow(event)
    event:Skip()
    local win = event:GetEventObject():DynamicCast("wxWindow")
    local winId = win:GetId()
    local winWidth, winHeight = win:GetSizeWH()

    if event:ShiftDown() then return end

    if sudokuGUI.cellTextCtrl then
        if sudokuGUI.cellTextCtrl:GetId() == winId then
            sudokuGUI.cellTextCtrl:Show(true)
            return
        end
        sudokuGUI.SaveCellTextCtrlValue()
        sudokuGUI.DestroyCellTextCtrl()
    end

    local is_creating = sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_CREATE)
    local value, is_init = sudokuGUI.GetCellValueString(winId)
    if is_init and (not is_creating) then return end

    sudokuGUI.cellTextCtrl = wx.wxTextCtrl(win, winId, value,
                            wx.wxPoint(0, 0), wx.wxSize(winWidth, winHeight),
                            wx.wxTE_PROCESS_ENTER+wx.wxTE_CENTRE)
    sudokuGUI.cellTextCtrl:SetFont(sudokuGUI.valueFont.wxfont)
    sudokuGUI.cellTextCtrl:SetMaxLength(1)
    --local valid = wx.wxTextValidator(wx.wxFILTER_INCLUDE_LIST)
    --valid:SetIncludeList(
    --cellTextCtrl:SetValidator(valid)

    sudokuGUI.cellTextCtrl:Connect(winId, wx.wxEVT_COMMAND_TEXT_ENTER,
            function (event)
                local win = event:GetEventObject():DynamicCast("wxWindow")
                sudokuGUI.SaveCellTextCtrlValue()
                win:Show(false) -- just hide it, we'll destroy it later
            end)

    sudokuGUI.cellTextCtrl:Connect(wx.wxEVT_CHAR,
            function (event)
                if (event:GetKeyCode() == wx.WXK_ESCAPE) then
                    sudokuGUI.cellTextCtrl:Show(false)
                    sudokuGUI.cellTextCtrl:SetValue("")
                end
                event:Skip()
            end)
end

function sudokuGUI.DestroyCellTextCtrl()
    if sudokuGUI.cellTextCtrl then
        sudokuGUI.cellTextCtrl:Show(false)
        sudokuGUI.cellTextCtrl:Destroy()
        sudokuGUI.cellTextCtrl = nil
    end
end

-- Save the value of the text editor back to the grid
function sudokuGUI.SaveCellTextCtrlValue()
    if not sudokuGUI.cellTextCtrl then return end
    local value = sudokuGUI.cellTextCtrl:GetValue()
    local cell = sudokuGUI.cellTextCtrl:GetId()
    sudokuGUI.SetCellValue(cell, value)
end

-- ----------------------------------------------------------------------------
-- Set the value of the cell from the value string
function sudokuGUI.SetCellValue(cell, value)
    -- fix the value to something reasonable
    if type(value) == "string" then
        if (value == "") or (value == " ") or (value == "0") then
            value = 0
        elseif (string.len(value) ~= 1) or (not string.find("123456789", value)) then
            return
        else
            value = tonumber(value)
        end
    end

    -- if value is still bad, just exit
    if not ((value == 0) or sudoku.IsValidValueN(value)) then return end

    local is_creating = sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_CREATE)
    local row, col = sudoku.CellToRowCol(cell)
    local is_init = sudoku.HasCellValue(sudokuGUI.sudokuTables[1], cell)

    if is_creating then
        if sudoku.GetCellValue(sudokuGUI.sudokuTables[1], cell) ~= value then
            -- add the value to all the tables since it's an init value
            for n = 1, TableCount(sudokuGUI.sudokuTables) do
                sudoku.SetValue(sudokuGUI.sudokuTables[n], row, col, value)
                sudoku.UpdateTable(sudokuGUI.sudokuTables[n])
            end
            -- refresh all in case it's invalid also if not at 1st table update possible
            sudokuGUI.UpdateTable(true)
            sudokuGUI.sudokuSolnTable = nil -- don't know anymore
        end
    else
        local s = sudokuGUI.GetCurrentTable()
        if (not is_init) and (sudoku.GetCellValue(s, cell) ~= value) then
            local s = TableCopy(s)
            sudoku.SetValue(s, row, col, value)
            sudokuGUI.AddTable(s)
        end
    end

    sudokuGUI.UpdateGUI()
end

-- ----------------------------------------------------------------------------
-- Get the initial sudoku table
function sudokuGUI.GetInitTable()
    return sudokuGUI.sudokuTables[1]
end
-- Set the initial sudoku table, clearing all others
function sudokuGUI.SetInitTable(sudokuTable, solnTable)
    sudokuGUI.sudokuSolnTable = solnTable
    sudokuGUI.sudokuTables_pos = 1
    sudokuGUI.sudokuTables = {}
    table.insert(sudokuGUI.sudokuTables, sudokuTable)
    sudokuGUI.UpdateTable() -- resets possible and refreshes too
end

-- ----------------------------------------------------------------------------
-- Get the current sudoku table to use
function sudokuGUI.GetCurrentTable()
    return sudokuGUI.sudokuTables[sudokuGUI.sudokuTables_pos]
end
-- Set the current sudoku table to this table
function sudokuGUI.SetCurrentTable(sudokuTable)
    sudokuGUI.sudokuTables[sudokuGUI.sudokuTables_pos] = sudokuTable
end

-- ----------------------------------------------------------------------------
-- Add a sudoku table to the list of tables, removing any past the current position,
--   find possible, and refresh
function sudokuGUI.AddTable(sudokuTable)
    while TableCount(sudokuGUI.sudokuTables) > sudokuGUI.sudokuTables_pos do
        table.remove(sudokuGUI.sudokuTables)
    end

    -- clear calculated values to save memory
    for n = 2, sudokuGUI.sudokuTables_pos do
        sudokuGUI.sudokuTables[n].row_values   = {}
        sudokuGUI.sudokuTables[n].col_values   = {}
        sudokuGUI.sudokuTables[n].block_values = {}
        sudokuGUI.sudokuTables[n].possible = {}
        sudokuGUI.sudokuTables[n].invalid  = {}
    end

    table.insert(sudokuGUI.sudokuTables, sudokuTable)
    sudokuGUI.sudokuTables_pos = sudokuGUI.sudokuTables_pos + 1

    sudokuGUI.UpdateTable()
end

-- ----------------------------------------------------------------------------
-- Get the value of the cell as a printable string
function sudokuGUI.GetCellValueString(cell)
    local value = ""

    if sudoku.HasCellValue(sudokuGUI.sudokuTables[1], cell) then
        return tostring(sudoku.GetCellValue(sudokuGUI.sudokuTables[1], cell)), true
    elseif sudoku.HasCellValue(sudokuGUI.GetCurrentTable(), cell) then
        value = tostring(sudoku.GetCellValue(sudokuGUI.GetCurrentTable(), cell))
    end

    return value, false
end

-- ----------------------------------------------------------------------------
-- refresh all the grid cells
function sudokuGUI.Refresh()
    for i = 1, 81 do
        if sudokuGUI.cellWindows[i] then
            sudokuGUI.cellWindows[i]:Refresh(false)
        end
    end

    sudokuGUI.UpdateGUI()
end

-- ----------------------------------------------------------------------------
-- Create a new empty puzzle
function sudokuGUI.NewPuzzle()
    local ret = wx.wxMessageBox("Clear all the values in the current puzzle and start anew?\n"..
                                "Use 'Create' to enter the initial values.",
                                "wxLuaSudoku - New puzzle?",
                                wx.wxOK + wx.wxCANCEL + wx.wxICON_INFORMATION,
                                sudokuGUI.frame )

    if ret == wx.wxOK then
        sudokuGUI.SetInitTable(sudoku.CreateTable(), nil)
    end
end

-- ----------------------------------------------------------------------------
-- Create a puzzle by hand
function sudokuGUI.CreatePuzzle(init)
    local enableIds =
    {
        sudokuGUI.ID_GENERATE,
        sudokuGUI.ID_OPEN,
        sudokuGUI.ID_SAVEAS,

        sudokuGUI.ID_RESET,
        sudokuGUI.ID_UNDO,
        sudokuGUI.ID_REDO,

        sudokuGUI.ID_SOLVE_SCANSINGLES,
        sudokuGUI.ID_SOLVE_SCANROWS,
        sudokuGUI.ID_SOLVE_SCANCOLS,
        sudokuGUI.ID_SOLVE_SCANBLOCKS,
        sudokuGUI.ID_SOLVE_SCANNING,
        sudokuGUI.ID_SOLVE_BRUTEFORCE
    }

    sudokuGUI.CheckMenuItem(sudokuGUI.ID_CREATE, init)

    if init then
        local ret = wx.wxMessageBox(
            "Enter values in the cells to initialize the puzzle with.\n"..
            "Previous cell values will be overwritten.\n"..
            "Don't forget to uncheck 'Create' before playing.",
            "wxLuaSudoku - Initialize puzzle?",
            wx.wxOK + wx.wxCANCEL + wx.wxICON_INFORMATION,
            sudokuGUI.frame )

        if ret == wx.wxCANCEL then
            sudokuGUI.CheckMenuItem(sudokuGUI.ID_CREATE, false)
            return
        end
    else
        sudokuGUI.sudokuSolnTable = nil -- reset to unknown

        if not TableIsEmpty(sudokuGUI.sudokuTables[1].invalid) then
            -- try to make them correct the puzzle
            local ret = wx.wxMessageBox(
                "The initial puzzle you've created has invalid values.\n"..
                "Press 'Ok' to correct them before continuing.\n"..
                "If you press 'Cancel' showing mistakes will be disabled and "..
                "don't blame me if things don't work out for you.",
                "wxLuaSudoku - Invalid initial puzzle!",
                wx.wxOK + wx.wxCANCEL + wx.wxICON_ERROR,
                sudokuGUI.frame )

            if ret == wx.wxOK then
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_CREATE, true)
                init = true
            end
        else --if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_MISTAKES) then
            sudokuGUI.sudokuSolnTable = sudokuGUI.VerifyUniquePuzzle(sudokuGUI.GetInitTable())
        end

        if (not sudokuGUI.sudokuSolnTable) and sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_MISTAKES) then
            sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_MISTAKES, false)
        end
    end

    for n, id in pairs(enableIds) do
        sudokuGUI.frame:GetMenuBar():Enable(id, not init)
        sudokuGUI.frame:GetToolBar():EnableTool(id, not init)
    end

    sudokuGUI.UpdateTable()
end

-- ----------------------------------------------------------------------------
-- Generate a new puzzle automatically
function sudokuGUI.GeneratePuzzle()
    local keep = wx.wxGetNumberFromUser("Set the difficulty of the new puzzle by clearing cells.\n"..
                                        "Note: The minimum number of cells to show for a unique puzzle is 17.",
                                        "Number of cell values to show",
                                        "wxLuaSudoku - Generate puzzle?",
                                        sudokuGUI.difficulty, 1, 81,
                                        sudokuGUI.frame)
    if keep < 1 then return end -- canceled

    sudokuGUI.difficulty = keep

    local solve_progress = 0
    local start_time     = os.time()
    local last_time      = start_time
    local solve_ok       = true
    local msg_idx        = 1

    local progressDialog = wx.wxProgressDialog("wxLuaSudoku - Generating...",
                           string.format("%s\nIteration # %d, current cell %d            ", sudokuGUI.sayings[1], 0, 0),
                           1000, sudokuGUI.frame,
                           wx.wxPD_AUTO_HIDE+wx.wxPD_CAN_ABORT+wx.wxPD_ELAPSED_TIME)

    -- define handler function here so it'll work w/o gui
    function sudoku.GeneratePuzzleHook(count, cell)
        if solve_ok == false then return false end -- canceled
        solve_progress = iff(solve_progress+1 >= 1000, 0, solve_progress + 1)
        if solve_progress%10 ~= 0 then return true end
        if (msg_idx < sudokuGUI.sayings_n) and (os.time() - last_time > 4) then
            msg_idx = msg_idx + 1
            last_time = os.time()
        end
        local msg = string.format("%s\nIteration # %d, current cell %d            ", sudokuGUI.sayings[msg_idx], count, cell)
        solve_ok = progressDialog:Update(solve_progress, msg)
        return solve_ok
    end

    local s, count = sudoku.GeneratePuzzle()
    progressDialog:Destroy()
    if not s then return end

    -- have complete puzzle, now remove cells

    local diff_count = 0
    local diff_i     = 0
    local diff_cell  = 0
    local diff_open  = 0
    local diff_trial = 0

    -- define handler function here so it'll work w/o gui
    function sudoku.GeneratePuzzleDifficultyHook(count, i, cell, open_cells, trial)
        diff_count     = count
        diff_i         = i
        diff_cell      = cell
        diff_open      = open_cells
        diff_trial     = trial
        if solve_ok == false then return false end -- canceled
        if (msg_idx < sudokuGUI.sayings_n) and (os.time() - last_time > 4) then
            msg_idx = msg_idx + 1
            last_time = os.time()
        end
        local msg = string.format("%s\nTrial %d, Iteration # %d, current cell %d, cells to go %d, available cells %d ", sudokuGUI.sayings[msg_idx], trial, count, cell, 81-keep-i, open_cells)
        solve_ok = progressDialog:Update(i, msg)
        return solve_ok
    end

    -- hook into brute force solver to update the generate puzzle progress dialog
    function sudoku.SolveBruteForceHook(guesses, cell)
        solve_progress = iff(solve_progress+1 >= 1000, 0, solve_progress + 1)
        if solve_progress%10 ~= 0 then return true end
        return sudoku.GeneratePuzzleDifficultyHook(diff_count, diff_i, diff_cell, diff_open, diff_trial)
    end

    local ensure_unique = true

    while 1 do
        diff_count = 0
        diff_i     = 0
        diff_cell  = 0
        diff_open  = 0
        diff_trial = 0

        solve_progress = 0
        start_time     = os.time()
        last_time      = start_time
        solve_ok       = true
        msg_idx        = 1

        local caption = "wxLuaSudoku - Ensuring unique solution..."
        if ensure_unique == false then
            caption = "wxLuaSudoku - Removing values randomly..."
        end

        progressDialog = wx.wxProgressDialog(caption,
                            string.format("%s\nTrial %d, Iteration # %d, current cell %d, cells to go %d, available cells %d ", sudokuGUI.sayings[msg_idx], 0, count, 0, 81, 0),
                            81 - sudokuGUI.difficulty + 1, sudokuGUI.frame,
                            wx.wxPD_AUTO_HIDE+wx.wxPD_CAN_ABORT+wx.wxPD_ELAPSED_TIME)

        local s1 = sudoku.GeneratePuzzleDifficulty(TableCopy(s), sudokuGUI.difficulty, ensure_unique)
        progressDialog:Destroy()

        if s1 then
            if ensure_unique then
                sudokuGUI.SetInitTable(s1, TableCopy(s))
            else
                -- verify the puzzle anyway to let them know the status
                local s2 = sudokuGUI.VerifyUniquePuzzle(s1)
                sudokuGUI.SetInitTable(s1, s2)
            end
            break
        else
            local ret = wx.wxMessageBox("The puzzle was not fully generated. "..
                                        "Press 'Ok' to randomly remove cell values which may or may not "..
                                        "yield a unique puzzle or 'Cancel' to abort",
                                        "wxLuaSudoku - Unfinished generation",
                                        wx.wxOK + wx.wxCANCEL + wx.wxICON_ERROR,
                                        sudokuGUI.frame)

            if ret == wx.wxOK then
                ensure_unique = false
            else
                break
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- Open a puzzle from a file
function sudokuGUI.OpenPuzzle()
    local fileDialog = wx.wxFileDialog(sudokuGUI.frame, "Open file",
                                       sudokuGUI.filePath, sudokuGUI.fileName,
                                       "wxLuaSudoku files (*.sudoku)|*.sudoku|All files (*)|*",
                                       wx.wxOPEN + wx.wxFILE_MUST_EXIST)
    if fileDialog:ShowModal() == wx.wxID_OK then
        local fileName = fileDialog:GetPath()
        local fn = wx.wxFileName(fileName)
        sudokuGUI.filePath = fn:GetPath()
        sudokuGUI.fileName = fn:GetFullName()

        local s, msg = sudoku.Open(fileName)
        if s then
            sudokuGUI.frame:SetTitle("wxLuaSudoku - "..sudokuGUI.fileName)

            sudokuGUI.SetInitTable(s, nil)

            if not TableIsEmpty(sudokuGUI.sudokuTables[1].invalid) then
                -- make them correct the puzzle
                local ret = wx.wxMessageBox(
                    "The puzzle you've opened has invalid values.\n"..
                    "Press 'Ok' to correct them using 'Create' before continuing "..
                    "otherwise 'Cancel' to ignore them.",
                    "wxLuaSudoku - Invalid puzzle",
                    wx.wxOK + wx.wxCANCEL + wx.wxICON_ERROR,
                    sudokuGUI.frame )

                if ret == wx.wxOK then
                    sudokuGUI.CreatePuzzle(true)
                end
            else --if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_MISTAKES) then
                sudokuGUI.sudokuSolnTable = sudokuGUI.VerifyUniquePuzzle(sudokuGUI.GetInitTable())
            end
        else
            wx.wxMessageBox( msg,
                             "wxLuaSudoku - Open file error",
                             wx.wxOK + wx.wxICON_ERROR,
                             sudokuGUI.frame )
        end
    end
    fileDialog:Destroy()
end

-- ----------------------------------------------------------------------------
-- Save the puzzle to a file
function sudokuGUI.SaveAsPuzzle()
    local fileDialog = wx.wxFileDialog(sudokuGUI.frame, "Save puzzle",
                                       sudokuGUI.filePath, sudokuGUI.fileName,
                                       "wxLuaSudoku files (*.sudoku)|*.sudoku|All files (*)|*",
                                       wx.wxSAVE + wx.wxOVERWRITE_PROMPT)
    local result = false
    if fileDialog:ShowModal() == wx.wxID_OK then
        local fileName = fileDialog:GetPath()
        local fn = wx.wxFileName(fileName)
        sudokuGUI.filePath = fn:GetPath()
        sudokuGUI.fileName = fn:GetFullName()

        result = sudoku.Save(sudokuGUI.GetCurrentTable(), fileName)
        if result then
            sudokuGUI.frame:SetTitle("wxLuaSudoku - "..sudokuGUI.fileName)
        else
            wx.wxMessageBox( "Unable to save file\n'"..fileName.."'",
                             "wxLuaSudoku - Save file error",
                             wx.wxOK + wx.wxICON_ERROR,
                             sudokuGUI.frame )

        end
    end
    fileDialog:Destroy()
    return result
end

-- ----------------------------------------------------------------------------

function sudokuGUI.Undo()
    if sudokuGUI.sudokuTables_pos > 1 then
        sudokuGUI.sudokuTables_pos = sudokuGUI.sudokuTables_pos - 1
        sudokuGUI.UpdateTable(true)
    end
end
function sudokuGUI.Redo()
    if sudokuGUI.sudokuTables_pos < TableCount(sudokuGUI.sudokuTables) then
        sudokuGUI.sudokuTables_pos = sudokuGUI.sudokuTables_pos + 1
        sudokuGUI.UpdateTable(true)
    end
end

-- ----------------------------------------------------------------------------
-- Try to fix the invalid cells if possible
function sudokuGUI.FixInvalid(sudokuTable, show_dialog)
    local s = TableCopy(sudokuTable)
    local solnTable = sudokuGUI.sudokuSolnTable
    if solnTable and TableIsEmpty(solnTable.invalid) then
        for cell = 1, 81 do
            if sudoku.HasCellValue(s, cell) then
                local current_value = sudoku.GetCellValue(s, cell)
                local correct_value = sudoku.GetCellValue(solnTable, cell)
                if current_value ~= correct_value then
                    sudoku.SetCellValue(s, cell, correct_value)
                end
            end
        end
        sudoku.UpdateTable(s)
        return s
    else
        if show_dialog then
            local msg = "The initial puzzle must be solved first.\n"..
                        "Would you like me to try to solve it?"
            local flags = wx.wxYES_NO

            local invalid = true
            if solnTable and not TableIsEmpty(solnTable.invalid) then
                invalid = true
            end
            if invalid then
                msg = "The initial puzzle has invalid values.\n"..
                      "Please correct them first using Create."
                flags = wx.wxOK
            end
            local ret = wx.wxMessageBox(msg,
                                        "wxLuaSudoku - Invalid puzzle",
                                        flags + wx.wxICON_INFORMATION,
                                        sudokuGUI.frame )

            if not invalid and (ret == wx.wxOK) then
                s = sudokuGUI.SolveBruteForce(sudokuGUI.sudokuTables[1])
                if not s then
                    wx.wxMessageBox("Unable to solve or or solving was aborted, giving up.",
                                    "wxLuaSudoku - Invalid puzzle",
                                    wx.wxOK + wx.wxICON_INFORMATION,
                                    sudokuGUI.frame )
                    return nil
                end
                sudokuGUI.sudokuSolnTable = s
                sudoku.UpdateTable(sudokuGUI.sudokuSolnTable)
                return sudokuGUI.FixInvalid(sudokuTable, show_dialog)
            else
                return nil
            end
        else
            return nil
        end
    end
end

-- ----------------------------------------------------------------------------

function sudokuGUI.VerifyUniquePuzzle(sudokuTable)
    sudoku.CalcInvalidCells(sudokuTable)
    local invalid_count = TableCount(sudokuTable.invalid)

    if invalid_count > 0 then
        local ret = wx.wxMessageBox(
                string.format("The initial values of the puzzle are invalid.\n"..
                              "There are %d cells with duplicate values.\n"..
                              "Please select Create and fix them before trying to solve.\n", invalid_count),
                              "wxLuaSudoku - Invalid puzzle",
                              wx.wxOK + wx.wxICON_ERROR,
                              sudokuGUI.frame )
        return
    end

    local solve_progress = 0
    local start_time     = os.time()
    local last_time      = start_time
    local solve_ok       = true
    local msg_idx        = 1

    -- define handler function here so it'll work w/o gui
    function sudoku.SolveBruteForceHook(guesses, cell)
        if solve_ok == false then return false end -- canceled
        solve_progress = iff(solve_progress+1 >= 1000, 0, solve_progress + 1)
        if (solve_progress-1)%10 ~= 0 then return true end
        if (msg_idx < sudokuGUI.sayings_n) and (os.time() - last_time > 4) then
            msg_idx = msg_idx + 1
            last_time = os.time()
        end
        local msg = string.format("%s\nIteration # %d, current cell %d            ", sudokuGUI.sayings[msg_idx], guesses.current, cell)
        solve_ok = progressDialog:Update(solve_progress, msg)
        return solve_ok
    end

    local ret = wx.wxOK
    while ret == wx.wxOK do
        solve_progress = 0
        start_time     = os.time()
        last_time      = start_time
        solve_ok       = true
        msg_idx        = 1

        progressDialog = wx.wxProgressDialog("wxLuaSudoku - Verifying puzzle...",
                            string.format("%s\nIteration # %d, current cell %d            ", sudokuGUI.sayings[1], 0, 0),
                            1000, sudokuGUI.frame,
                            wx.wxPD_AUTO_HIDE+wx.wxPD_CAN_ABORT+wx.wxPD_ELAPSED_TIME)

        local s1, s2 = sudoku.IsUniquePuzzle(sudokuTable)
        progressDialog:Destroy()

        if s1 and (s2 == nil) then
            return s1
        elseif solve_ok == false then
            ret = wx.wxMessageBox("The puzzle was not fully verified and therefore may not have a unique solution or a solution at all.\n"..
                                  "Press 'Ok' to restart checking or 'Cancel' to quit.",
                                  "wxLuaSudoku - Unfinished check",
                                  wx.wxOK + wx.wxCANCEL + wx.wxICON_ERROR,
                                  sudokuGUI.frame)
        elseif s1 and s2 then
            wx.wxMessageBox("The puzzle does not have a unique solution.\n"..
                            "Use 'Create' to fix the problem, showing mistakes will be disabled.",
                            "wxLuaSudoku - Nonunique puzzle",
                            wx.wxOK + wx.wxICON_ERROR,
                            sudokuGUI.frame)

            sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_MISTAKES, false)
            return nil
        else
            wx.wxMessageBox("The puzzle does not have a solution.\n"..
                            "Use 'Create' to fix the problem, showing mistakes will be disabled.",
                            "wxLuaSudoku - Unsolvable puzzle",
                            wx.wxOK + wx.wxICON_ERROR,
                            sudokuGUI.frame)

            sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_MISTAKES, false)
            return nil
        end
    end

    return nil
end

-- ----------------------------------------------------------------------------
-- Use the scanning method to solve it
function sudokuGUI.SolveScanning()
    local s = TableCopy(sudokuGUI.GetCurrentTable())
--[[
    local invalid = not TableIsEmpty(s.invalid)
    if invalid then
        if not TableIsEmpty(sudokuGUI.sudokuTables[1].invalid) then
            local ret = wx.wxMessageBox("The initial values in the puzzle are invalid.\n"..
                                        "Please select Create and fix them before trying to solve.\n"..
                                        "Press 'Cancel' to try to solve it anyway.",
                                        "wxLuaSudoku - Invalid puzzle",
                                        wx.wxOK + wx.wxCANCEL + wx.wxICON_ERROR,
                                        sudokuGUI.frame )

            if ret == wx.wxOK then return end
        else
            local ret = wx.wxMessageBox("The current puzzle has invalid cell values.\n"..
                                        "Would you like me to try to fix those cells or press cancel to abort solving.",
                                        "wxLuaSudoku - Invalid puzzle",
                                        wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_INFORMATION,
                                        sudokuGUI.frame )

            if ret == wx.wxCANCEL then
                return
            elseif ret == wx.wxYES then
                local fixedS = sudokuGUI.FixInvalid(s, true)
                if fixedS then
                    sudokuGUI.AddTable(fixedS)
                    s = TableCopy(sudokuGUI.GetCurrentTable())
                else
                    return
                end
            end
        end
    end
]]
    local count, changed_cells = sudoku.SolveScan(s)
    local changed_count = 0
    if changed_cells then
        sudokuGUI.AddTable(s)
        changed_count = TableCount(changed_cells)
    end

    local msg = string.format("Scanned rows, cols, and blocks %d times.\n"..
                              "Found %d new values.\n"..
                              "You may be able to do better using 'Eliminate groups'", count, changed_count)
    wx.wxMessageBox( msg,
                     "wxLuaSudoku - Finished scanning",
                     wx.wxOK + wx.wxICON_INFORMATION,
                     sudokuGUI.frame )
end

-- ----------------------------------------------------------------------------
-- Use the brute force method to solve it
function sudokuGUI.SolveBruteForce(sudokuTable)

    local s
    if sudokuTable then
        s = TableCopy(sudokuTable)
    else
        s = TableCopy(sudokuGUI.GetCurrentTable())
    end
--[[
    local invalid = not TableIsEmpty(s.invalid)
    if invalid then
        if (sudokuTable == nil) and (not TableIsEmpty(sudokuGUI.sudokuTables[1].invalid)) then
            wx.wxMessageBox("The initial values in the puzzle are invalid.\n"..
                            "Please select Create and fix them before trying to solve.",
                            "wxLuaSudoku - Invalid puzzle",
                            wx.wxOK + wx.wxICON_ERROR,
                            sudokuGUI.frame )

            return
        end

        local ret = wx.wxMessageBox("The current puzzle has invalid cell values.\n"..
                                    "Would you like me to try to fix those cells or press cancel to abort solving.",
                                    "wxLuaSudoku - Invalid puzzle",
                                    wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_INFORMATION,
                                    sudokuGUI.frame )

        if ret == wx.wxCANCEL then
            return
        elseif ret == wx.wxYES then
            local fixedS = sudokuGUI.FixInvalid(s, true)
            if fixedS then
                sudokuGUI.AddTable(fixedS)
                s = TableCopy(sudokuGUI.GetCurrentTable())
            else
                return
            end
        end
    end
]]
    local progressDialog = wx.wxProgressDialog("wxLuaSudoku - Solving...",
                           string.format("%s\nIteration # %d, current cell %d            ", sudokuGUI.sayings[1], 0, 0),
                           1000, sudokuGUI.frame,
                           wx.wxPD_AUTO_HIDE+wx.wxPD_CAN_ABORT+wx.wxPD_ELAPSED_TIME)

    local solve_progress = 0
    local start_time     = os.time()
    local last_time      = start_time
    local solve_ok       = true
    local msg_idx        = 1

    -- define handler function here so it'll work w/o gui
    function sudoku.SolveBruteForceHook(guesses, cell)
        if solve_ok == false then return false end -- canceled
        solve_progress = iff(solve_progress+1 >= 1000, 0, solve_progress + 1)
        if (solve_progress-1)%10 ~= 0 then return true end
        if (msg_idx < sudokuGUI.sayings_n) and (os.time() - last_time > 4) then
            msg_idx = msg_idx + 1
            last_time = os.time()
        end
        local msg = string.format("%s\nIteration # %d, current cell %d            ", sudokuGUI.sayings[msg_idx], guesses.current, cell)
        solve_ok = progressDialog:Update(solve_progress, msg)
        return solve_ok
    end

    -- "cheat" a little by using SolveScan to get easy to find values
    --local flags = TableCopy(s.flags)
    --for n = sudoku.ELIMINATE_FLAG_MIN, sudoku.ELIMINATE_FLAG_MAX do
    --    s.flags[n] = true
    --end

    --local count, changed_cells = sudoku.SolveScan(s)
    local s, g = sudoku.SolveBruteForce(s)

    progressDialog:Destroy()

    if not s then
        if solve_ok then
            wx.wxMessageBox("Sorry, no solutions found!",
                            "wxLuaSudoku - error",
                            wx.wxOK + wx.wxICON_INFORMATION,
                            sudokuGUI.frame )
        end
    elseif not sudokuTable then
        --s.flags = flags         -- restore flags
        sudokuGUI.AddTable(s)    -- we solved the current grid
    else
        --s.flags = flags         -- restore flags
        return s                -- we solved the input grid
    end
end

-- ----------------------------------------------------------------------------
-- Reset the grid to the original values
function sudokuGUI.ResetPuzzle(dont_query_user)
    dont_query_user = dont_query_user or false
    local ret = wx.wxOK
    if not dont_query_user then
        ret = wx.wxMessageBox("Reset the puzzle to the initial state?",
                              "wxLuaSudoku - reset puzzle?",
                               wx.wxOK + wx.wxCANCEL + wx.wxICON_INFORMATION,
                               sudokuGUI.frame )
    end

    if ret == wx.wxCANCEL then
        return
    else
        sudokuGUI.sudokuTables_pos = 1
        while TableCount(sudokuGUI.sudokuTables) > 1 do
            table.remove(sudokuGUI.sudokuTables, 2)
        end
    end

    sudokuGUI.UpdateTable() -- redo it anyway
end

-- ----------------------------------------------------------------------------

function sudokuGUI.UpdateTable(refresh)
    if refresh == nil then refresh = true end

    local sudokuTable = sudokuGUI.GetCurrentTable()

    sudokuGUI.block_refresh = true

    local has_show_flag = false
    for n = sudoku.ELIMINATE_FLAG_MIN, sudoku.ELIMINATE_FLAG_MAX do
        local id = n + sudokuGUI.ID_ELIMINATE_NAKEDPAIRS - sudoku.ELIMINATE_FLAG_MIN
        sudokuTable.flags[n] = sudokuGUI.IsCheckedMenuItem(id)

        local show_id = n + sudokuGUI.ID_SHOW_NAKEDPAIRS - sudoku.ELIMINATE_FLAG_MIN
        if (not has_show_flag) and (sudokuGUI.IsCheckedMenuItem(show_id) == true) then
            has_show_flag = true
        end
    end

    sudoku.UpdateTable(sudokuTable)

    if has_show_flag == true then
        -- swap out the possible table temporarily to calc pencil marks
        if sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_SHOW_USER_POSSIBLE) then
            local p = sudokuTable.possible
            sudokuTable.possible = sudokuGUI.pencilMarks
            sudokuGUI.pencilMarksNakedTable, sudokuGUI.pencilMarksHiddenTable = sudoku.FindAllNakedHiddenGroups(sudokuTable, true)
            sudokuTable.possible = p
        else
            sudokuGUI.possNakedTable, sudokuGUI.possHiddenTable = sudoku.FindAllNakedHiddenGroups(sudokuTable, true)
        end
    end

    sudokuGUI.SetCurrentTable(sudokuTable)

    sudokuGUI.block_refresh = false

    if (refresh == true) then
        sudokuGUI.Refresh()
    end

    sudokuGUI.UpdateGUI()
end

-- ----------------------------------------------------------------------------

function sudokuGUI.UpdateGUI()
    local table_count = #sudokuGUI.sudokuTables
    local table_pos   = sudokuGUI.sudokuTables_pos
    sudokuGUI.frame:GetMenuBar():Enable(sudokuGUI.ID_UNDO, table_pos > 1)
    sudokuGUI.frame:GetMenuBar():Enable(sudokuGUI.ID_REDO, table_pos < table_count)
    sudokuGUI.frame:GetToolBar():EnableTool(sudokuGUI.ID_UNDO, table_pos > 1)
    sudokuGUI.frame:GetToolBar():EnableTool(sudokuGUI.ID_REDO, table_pos < table_count)

    sudokuGUI.frame:SetStatusText(string.format("Step : %d", table_pos), 1)
end

-- ----------------------------------------------------------------------------
-- The preference pages are in a table so they can be accessed easily

sudokuGUI.PreferencesDialogPageUI = {}

function sudokuGUI.PreferencesDialogPageUI.Create(parent)
    local panel = wx.wxPanel(parent, wx.wxID_ANY)

    local ID_LISTBOX        = 10
    local ID_SAMPLE_TEXT    = 11
    local ID_FONT_BUTTON    = 12
    local ID_COLOUR_BUTTON  = 13
    local ID_RESET_BUTTON   = 14

    local listStrings = -- in same order as the colours
    {
        "Values",
        "Initial values",
        "Possible values",
        "Invalid values",
        "Background",
        "Odd background",
        "Focused cell",
        "Naked pairs",
        "Naked triplets",
        "Naked quads",
        "Hidden pairs",
        "Hidden triplets",
        "Hidden quads"
    }

    local listBoxValues = {}
    for n = 1, sudokuGUI.COLOUR_MAX do
        table.insert(listBoxValues, {colour = wx.wxColour(sudokuGUI.Colours[n])})
    end
    listBoxValues[sudokuGUI.VALUE_COLOUR].font      = wx.wxFont(sudokuGUI.valueFont.wxfont)
    listBoxValues[sudokuGUI.POSS_VALUE_COLOUR].font = wx.wxFont(sudokuGUI.possibleFont.wxfont)

    local reset_fonts = true

    -- Create the dialog ------------------------------------------------------

    local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )

    local fcFlexSizer = wx.wxFlexGridSizer( 1, 2, 0, 0 )
    fcFlexSizer:AddGrowableCol( 0 )
    fcFlexSizer:AddGrowableRow( 0 )

    local fcListBox = wx.wxListBox( panel, ID_LISTBOX, wx.wxDefaultPosition, wx.wxSize(80,100), listStrings, wx.wxLB_SINGLE )
    fcListBox:SetSelection(0)
    fcFlexSizer:Add( fcListBox, 0, wx.wxGROW+wx.wxALIGN_CENTER_HORIZONTAL+wx.wxALL, 5 )

    local fcBoxSizer = wx.wxBoxSizer( wx.wxVERTICAL )

    local sampleWin = wx.wxWindow(panel, ID_SAMPLE_TEXT, wx.wxDefaultPosition, wx.wxSize(140,140))
    fcBoxSizer:Add( sampleWin, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 );

    local fontButton = wx.wxButton( panel, ID_FONT_BUTTON, "Choose Font", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    fcBoxSizer:Add( fontButton, 0, wx.wxGROW+wx.wxALIGN_CENTER_VERTICAL+wx.wxALL, 5 )
    local colourButton = wx.wxButton( panel, ID_COLOUR_BUTTON, "Choose Color", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    fcBoxSizer:Add( colourButton, 0, wx.wxGROW+wx.wxALIGN_CENTER_VERTICAL+wx.wxALL, 5 )
    local resetButton = wx.wxButton( panel, ID_RESET_BUTTON, "Reset Value...", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    fcBoxSizer:Add( resetButton, 0, wx.wxGROW+wx.wxALIGN_CENTER_VERTICAL+wx.wxALL, 5 )

    fcFlexSizer:Add( fcBoxSizer, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 )

    mainSizer:Add( fcFlexSizer, 1, wx.wxGROW+wx.wxALIGN_CENTER_VERTICAL, 5 )
    panel:SetSizer( mainSizer )

    sampleWin:Connect(wx.wxEVT_PAINT,
        function (event)
            local win = event:GetEventObject():DynamicCast("wxWindow")
            local sel = fcListBox:GetSelection() + 1
            local width, height = win:GetClientSizeWH()
            local dc = wx.wxPaintDC(win)

            local function SetFontSize(size, width, height, font)
                -- alternate way, but it fails for fonts that can't scale large enough
                --local f = wx.wxNullFont:NewSize(wx.wxSize(width, height), font:GetFamily(), font:GetStyle(), font:GetWeight(), font:GetUnderlined(), font:GetFaceName())
                --font:SetPointSize(f:GetPointSize())

                local font_width = 0
                local font_height = 0
                while (font_width < width) and (font_height < height) do
                    font:SetPointSize(size)
                    dc:SetFont(font)
                    font_width, font_height = dc:GetTextExtent("5")
                    size = size + 2
                    if size > 200 then break end -- oops bad font?
                end
                font:SetPointSize(size-1)
            end

            -- clear background
            local c = listBoxValues[sudokuGUI.BACKGROUND_COLOUR].colour
            if (sel == sudokuGUI.ODD_BACKGROUND_COLOUR) or (sel == sudokuGUI.FOCUS_CELL_COLOUR) then
                c = listBoxValues[sel].colour
            end
            local brush = wx.wxBrush(c, wx.wxSOLID)
            dc:SetBrush(brush)
            brush:delete()
            dc:DrawRectangle(0, 0, width, height)

            -- draw possible values
            dc:SetTextForeground(listBoxValues[sudokuGUI.POSS_VALUE_COLOUR].colour)
            local font = listBoxValues[sudokuGUI.POSS_VALUE_COLOUR].font
            if reset_fonts then SetFontSize(4, width/4, height/4, font) end
            dc:SetFont(font)
            local font_width, font_height = dc:GetTextExtent("5")

            local pos =
            {
                [1] = { x = 2,                  y = 2 },
                [3] = { x = width-font_width-2, y = 2 },
                [4] = { x = 2,                  y = (height-font_height)/2-2 },
                [6] = { x = width-font_width-2, y = (height-font_height)/2-2 },
                [7] = { x = 2,                  y = height-font_height-2 },
                [9] = { x = width-font_width-2, y = height-font_height-2 }
            }

            dc:SetBrush(wx.wxTRANSPARENT_BRUSH)

            local function DrawPossible(idx, n, value, hidden)
                dc:DrawText(value, pos[n].x, pos[n].y)
                local pen = wx.wxPen(listBoxValues[idx].colour, 1, wx.wxSOLID)
                dc:SetPen(pen); pen:delete()
                if hidden ~= true then
                    dc:DrawRectangle(pos[n].x, pos[n].y, font_width, font_height)
                else
                    dc:DrawRoundedRectangle(pos[n].x, pos[n].y, font_width, font_height, 20)
                end
            end

            DrawPossible(sudokuGUI.NAKED_PAIRS_COLOUR,     1, "2")
            DrawPossible(sudokuGUI.NAKED_TRIPLETS_COLOUR,  4, "3")
            DrawPossible(sudokuGUI.NAKED_QUADS_COLOUR,     7, "4")
            DrawPossible(sudokuGUI.HIDDEN_PAIRS_COLOUR,    3, "2", true)
            DrawPossible(sudokuGUI.HIDDEN_TRIPLETS_COLOUR, 6, "3", true)
            DrawPossible(sudokuGUI.HIDDEN_QUADS_COLOUR,    9, "4", true)

            -- draw invalid marker
            local pen = wx.wxPen(listBoxValues[sudokuGUI.INVALID_VALUE_COLOUR].colour, 1, wx.wxSOLID)
            dc:SetPen(pen); pen:delete()
            dc:DrawLine(0, 0, width, height)

            -- draw value
            if (sel == sudokuGUI.INIT_VALUE_COLOUR) then
                dc:SetTextForeground(listBoxValues[sudokuGUI.INIT_VALUE_COLOUR].colour)
            else
                dc:SetTextForeground(listBoxValues[sudokuGUI.VALUE_COLOUR].colour)
            end

            local old_font = font
            local font = listBoxValues[sudokuGUI.VALUE_COLOUR].font
            if reset_fonts then SetFontSize(old_font:GetPointSize(), width-2, height-2, font) end
            dc:SetFont(font)
            local font_width, font_height = dc:GetTextExtent("9")
            dc:DrawText("9", (width-font_width)/2, (height-font_height)/2)

            reset_fonts = false
            dc:delete()
        end)

    panel:Connect(ID_LISTBOX, wx.wxEVT_COMMAND_LISTBOX_SELECTED,
        function (event)
            local sel = event:GetSelection() + 1
            panel:FindWindow(ID_FONT_BUTTON):Enable(listBoxValues[sel].font ~= nil)
            colourButton:SetForegroundColour(listBoxValues[sel].colour)
            sampleWin:Refresh(false)
        end)

    panel:Connect(ID_FONT_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function (event)
            local sel = fcListBox:GetSelection() + 1
            local f = listBoxValues[sel].font
            f = wx.wxGetFontFromUser(panel, f)
            if f:Ok() then
                listBoxValues[sel].font:delete()
                listBoxValues[sel].font = f
                reset_fonts = true
            else
                f:delete()
            end
            sampleWin:Refresh(false)
        end)
    panel:Connect(ID_COLOUR_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function (event)
            local sel = fcListBox:GetSelection() + 1
            local c = listBoxValues[sel].colour
            c = wx.wxGetColourFromUser(panel, c)
            if c:Ok() then
                listBoxValues[sel].colour:delete()
                listBoxValues[sel].colour = c
                colourButton:SetForegroundColour(c)
            else
                c:delete()
            end
            sampleWin:Refresh(false)
        end)
    panel:Connect(ID_RESET_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function (event)
            local sel = fcListBox:GetSelection() + 1

            local ret = wx.wxMessageBox(
                "Press 'Yes' to reset all the colors and fonts or 'No' to reset only just the selected item.",
                "wxLuaSudoku - Reset colors or fonts?",
                wx.wxYES_NO + wx.wxCANCEL + wx.wxICON_INFORMATION,
                panel )

            if ret == wx.wxYES then
                for n = 1, sudokuGUI.COLOUR_MAX do
                    listBoxValues[n].colour:delete()
                    listBoxValues[n].colour = wx.wxColour(sudokuGUI.Colours_[n])
                end

                listBoxValues[sudokuGUI.VALUE_COLOUR].font:delete()
                listBoxValues[sudokuGUI.POSS_VALUE_COLOUR].font:delete()
                listBoxValues[sudokuGUI.VALUE_COLOUR].font      = wx.wxFont(sudokuGUI.valueFont_wxfont_)
                listBoxValues[sudokuGUI.POSS_VALUE_COLOUR].font = wx.wxFont(sudokuGUI.possibleFont_wxfont_)
            elseif ret == wx.wxNO then
                listBoxValues[sel].colour:delete()
                listBoxValues[sel].colour = wx.wxColour(sudokuGUI.Colours_[sel])

                if (sel == sudokuGUI.VALUE_COLOUR) then
                    listBoxValues[sel].font:delete()
                    listBoxValues[sel].font = wx.wxFont(sudokuGUI.valueFont_wxfont_)
                elseif (sel == sudokuGUI.POSS_VALUE_COLOUR) then
                    listBoxValues[sel].font:delete()
                    listBoxValues[sel].font = wx.wxFont(sudokuGUI.possibleFont_wxfont_)
                end
            end

            colourButton:SetForegroundColour(listBoxValues[sel].colour)
            reset_fonts = true
            sampleWin:Refresh(false)
        end)

    function sudokuGUI.PreferencesDialogPageUI.Apply()
        for n = 1, sudokuGUI.COLOUR_MAX do
            sudokuGUI.Colours[n]:delete()
            sudokuGUI.Colours[n] = wx.wxColour(listBoxValues[n].colour)
        end

        -- copy the fonts since when applied their size will change
        sudokuGUI.valueFont.wxfont:delete()
        sudokuGUI.valueFont.wxfont    = wx.wxFont(listBoxValues[sudokuGUI.VALUE_COLOUR].font)
        sudokuGUI.possibleFont.wxfont:delete()
        sudokuGUI.possibleFont.wxfont = wx.wxFont(listBoxValues[sudokuGUI.POSS_VALUE_COLOUR].font)
        sudokuGUI.valueFont_cache    = {} -- clear cache so GetCellBestSize recreates it
        sudokuGUI.possibleFont_cache = {}

        for winID = 1, 81 do
            if sudokuGUI.IsOddBlockCell(winID) then
                sudokuGUI.cellWindows[winID]:SetBackgroundColour(sudokuGUI.Colours[sudokuGUI.BACKGROUND_COLOUR])
            else
                sudokuGUI.cellWindows[winID]:SetBackgroundColour(sudokuGUI.Colours[sudokuGUI.ODD_BACKGROUND_COLOUR])
            end
        end

        local width, height = sudokuGUI.cellWindows[1]:GetClientSizeWH()
        sudokuGUI.GetCellBestSize(width, height)
        sudokuGUI.Refresh()
    end

    function sudokuGUI.PreferencesDialogPageUI.Destroy()
        for n = 1, sudokuGUI.COLOUR_MAX do
            listBoxValues[n].colour:delete()
            if listBoxValues[n].font then listBoxValues[n].font:delete() end
        end
    end

    return panel
end


function sudokuGUI.CheckListBoxCheck(clBox, n_start, n_end, check)
    for n = n_start, n_end do
        clBox:Check(n, check)
    end
end
function sudokuGUI.CheckListBoxIsChecked(clBox, n_start, n_end)
    for n = n_start, n_end do
        if not clBox:IsChecked(n) then return false end
    end
    return true
end

sudokuGUI.PreferencesDialogPageShow = {}

function sudokuGUI.PreferencesDialogPageShow.Create(parent)
    local panel = wx.wxPanel(parent, wx.wxID_ANY)

    local ID_LISTBOX  = 10

    local listStrings =
    {
        "All naked groups",
        "All hidden groups",
        "Naked pairs",
        "Naked triplets",
        "Naked quads",
        "Hidden pairs",
        "Hidden triplets",
        "Hidden quads"
    }

    local listBoxValues =
    {
        sudokuGUI.ID_SHOW_NAKED,
        sudokuGUI.ID_SHOW_HIDDEN,
        sudokuGUI.ID_SHOW_NAKEDPAIRS,
        sudokuGUI.ID_SHOW_NAKEDTRIPLETS,
        sudokuGUI.ID_SHOW_NAKEDQUADS,
        sudokuGUI.ID_SHOW_HIDDENPAIRS,
        sudokuGUI.ID_SHOW_HIDDENTRIPLETS,
        sudokuGUI.ID_SHOW_HIDDENQUADS
    }

    -- Create the dialog ------------------------------------------------------

    local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )
    local showListBox = wx.wxCheckListBox( panel, ID_LISTBOX, wx.wxDefaultPosition, wx.wxSize(80,100), listStrings, wx.wxLB_SINGLE )
    mainSizer:Add( showListBox, 1, wx.wxGROW+wx.wxALIGN_CENTER_HORIZONTAL+wx.wxALL, 5 )
    panel:SetSizer( mainSizer )

    for n = 1, showListBox:GetCount() do
        showListBox:Check(n-1, sudokuGUI.IsCheckedMenuItem(listBoxValues[n]))
    end

    panel:Connect(ID_LISTBOX, wx.wxEVT_COMMAND_CHECKLISTBOX_TOGGLED,
        function (event)
            local sel = event:GetSelection()
            local checked = showListBox:IsChecked(sel)
            local id = listBoxValues[sel+1]
            if id == sudokuGUI.ID_SHOW_NAKED then
                sudokuGUI.CheckListBoxCheck(showListBox, 2, 4, checked)
            elseif id == sudokuGUI.ID_SHOW_HIDDEN then
                sudokuGUI.CheckListBoxCheck(showListBox, 5, 7, checked)
            else
                showListBox:Check(0, sudokuGUI.CheckListBoxIsChecked(showListBox, 2, 4))
                showListBox:Check(1, sudokuGUI.CheckListBoxIsChecked(showListBox, 5, 7))
            end
        end)

    function sudokuGUI.PreferencesDialogPageShow.Apply()
        for n = 1, showListBox:GetCount() do
            sudokuGUI.CheckMenuItem(listBoxValues[n], showListBox:IsChecked(n-1))
        end
        sudokuGUI.UpdateTable()
    end

    function sudokuGUI.PreferencesDialogPageShow.Destroy()
    end

    return panel
end

sudokuGUI.PreferencesDialogPageSolve = {}

function sudokuGUI.PreferencesDialogPageSolve.Create(parent)
    local panel = wx.wxPanel(parent, wx.wxID_ANY)

    local ID_LISTBOX  = 10

    local listStrings =
    {
        "All naked groups",
        "All hidden groups",
        "Naked pairs",
        "Naked triplets",
        "Naked quads",
        "Hidden pairs",
        "Hidden triplets",
        "Hidden quads"
    }

    local listBoxValues =
    {
        sudokuGUI.ID_ELIMINATE_NAKED,
        sudokuGUI.ID_ELIMINATE_HIDDEN,
        sudokuGUI.ID_ELIMINATE_NAKEDPAIRS,
        sudokuGUI.ID_ELIMINATE_NAKEDTRIPLETS,
        sudokuGUI.ID_ELIMINATE_NAKEDQUADS,
        sudokuGUI.ID_ELIMINATE_HIDDENPAIRS,
        sudokuGUI.ID_ELIMINATE_HIDDENTRIPLETS,
        sudokuGUI.ID_ELIMINATE_HIDDENQUADS
    }

    -- Create the dialog ------------------------------------------------------

    local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )
    local showListBox = wx.wxCheckListBox( panel, ID_LISTBOX, wx.wxDefaultPosition, wx.wxSize(80,100), listStrings, wx.wxLB_SINGLE )
    mainSizer:Add( showListBox, 1, wx.wxGROW+wx.wxALIGN_CENTER_HORIZONTAL+wx.wxALL, 5 )
    panel:SetSizer( mainSizer )

    for n = 1, showListBox:GetCount() do
        showListBox:Check(n-1, sudokuGUI.IsCheckedMenuItem(listBoxValues[n]))
    end

    panel:Connect(ID_LISTBOX, wx.wxEVT_COMMAND_CHECKLISTBOX_TOGGLED,
        function (event)
            local sel = event:GetSelection()
            local checked = showListBox:IsChecked(sel)
            local id = listBoxValues[sel+1]
            if id == sudokuGUI.ID_ELIMINATE_NAKED then
                sudokuGUI.CheckListBoxCheck(showListBox, 2, 4, checked)
            elseif id == sudokuGUI.ID_ELIMINATE_HIDDEN then
                sudokuGUI.CheckListBoxCheck(showListBox, 5, 7, checked)
            else
                showListBox:Check(0, sudokuGUI.CheckListBoxIsChecked(showListBox, 2, 4))
                showListBox:Check(1, sudokuGUI.CheckListBoxIsChecked(showListBox, 5, 7))
            end
        end)

    function sudokuGUI.PreferencesDialogPageSolve.Apply()
        for n = 1, showListBox:GetCount() do
            sudokuGUI.CheckMenuItem(listBoxValues[n], showListBox:IsChecked(n-1))
        end
        sudokuGUI.UpdateTable()
    end

    function sudokuGUI.PreferencesDialogPageSolve.Destroy()
    end

    return panel
end

function sudokuGUI.PreferencesDialog()
    local dialog = wx.wxDialog(sudokuGUI.frame, wx.wxID_ANY,
                               "wxLuaSudoku - Preferences",
                               wx.wxDefaultPosition, wx.wxDefaultSize,
                               wx.wxDEFAULT_DIALOG_STYLE+wx.wxRESIZE_BORDER)

    local panel = wx.wxPanel(dialog, wx.wxID_ANY)
    local notebook = wx.wxNotebook(panel, wx.wxID_ANY)

    local notebookPages = {}

    local page1 = sudokuGUI.PreferencesDialogPageUI.Create(notebook)
    notebook:AddPage(page1, "Fonts and Colors", true)
    table.insert(notebookPages, sudokuGUI.PreferencesDialogPageUI)

    local page2 = sudokuGUI.PreferencesDialogPageShow.Create(notebook)
    notebook:AddPage(page2, "Mark groups", false)
    table.insert(notebookPages, sudokuGUI.PreferencesDialogPageShow)

    local page3 = sudokuGUI.PreferencesDialogPageSolve.Create(notebook)
    notebook:AddPage(page3, "Eliminate groups", false)
    table.insert(notebookPages, sudokuGUI.PreferencesDialogPageSolve)

    local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )

    local buttonSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )
    local okButton = wx.wxButton( panel, wx.wxID_OK, "&OK", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    buttonSizer:Add( okButton, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 )
    local cancelButton = wx.wxButton( panel, wx.wxID_CANCEL, "&Cancel", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    buttonSizer:Add( cancelButton, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 )
    local applyButton = wx.wxButton( panel, wx.wxID_APPLY, "&Apply", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    buttonSizer:Add( applyButton, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 )

    mainSizer:Add( notebook, 1, wx.wxGROW+wx.wxALIGN_CENTER, 0 )
    mainSizer:Add( buttonSizer, 0, wx.wxALIGN_CENTER+wx.wxALL, 5 )
    panel:SetSizer( mainSizer )
    mainSizer:SetSizeHints( dialog )

    dialog:Connect(wx.wxID_APPLY, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function (event)
            --local sel = notebook:GetSelection()
            --if sel >= 0 then notebookPages[sel+1].Apply() end
            for n = 1, #notebookPages do
                notebookPages[n].Apply()
            end

        end)
    dialog:Connect(wx.wxID_OK, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function (event)
            for n = 1, #notebookPages do
                notebookPages[n].Apply()
                notebookPages[n].Destroy()
            end

            event:Skip() -- wxDialog will cancel automatically
        end)
    dialog:Connect(wx.wxID_CANCEL, wx.wxEVT_COMMAND_BUTTON_CLICKED,
        function (event)
            for n = 1, #notebookPages do
                notebookPages[n].Destroy()
            end

            event:Skip() -- wxDialog will cancel automatically
        end)

    dialog:ShowModal()
end

-- ----------------------------------------------------------------------------

function sudokuGUI.ConfigSave(save_prefs)
    if not sudokuGUI.config then
        sudokuGUI.config = wx.wxFileConfig("wxLuaSudoku", "wxLua")
    end

    if not sudokuGUI.config then return end

    -- write the frame position so we can restore it
    local x, y = sudokuGUI.frame:GetPositionXY()
    local w, h = sudokuGUI.frame:GetClientSizeWH()
    local max  = booltoint(sudokuGUI.frame:IsMaximized())
    sudokuGUI.config:Write("wxLuaSudoku/Frame", string.format("x:%d y:%d w:%d h:%d maximized:%d", x, y, w, h, max))

    if not save_prefs then return end

    if sudokuGUI.query_save_prefs then
        local ret = wx.wxMessageBox(
            "Preferences are stored in an ini file which you may delete:\n"..
            "MSW : Documents and Settings\\user\\wxLuaSudoku.ini\n"..
            "Unix : /home/user/.wxLuaSudoku",
            "wxLuaSudoku - Save preferences?",
            wx.wxOK + wx.wxCANCEL + wx.wxICON_INFORMATION,
            sudokuGUI.frame )

        if ret == wx.wxCANCEL then
            return
        end

        sudokuGUI.query_save_prefs = false
    end

    if sudokuGUI.config then
        sudokuGUI.ConfigReadWrite(false, sudokuGUI.config)
        sudokuGUI.config:Flush(true)
    end
end

function sudokuGUI.ConfigLoad()
    if not sudokuGUI.config then
        sudokuGUI.config = wx.wxFileConfig("wxLuaSudoku", "wxLua")
    end

    if sudokuGUI.config then
        local dispX, dispY, dispW, dispH = wx.wxClientDisplayRect()
        local _, str = sudokuGUI.config:Read("wxLuaSudoku/Frame")
        local x, y, w, h, max = string.match(str, "x:(%d+) y:(%d+) w:(%d+) h:(%d+) maximized:(%d+)")
        if (x ~= nil) and (y ~= nil) and (w ~= nil) and (h ~= nil) and (max ~= nil) then
            x = tonumber(x); y = tonumber(y); w = tonumber(w); h = tonumber(h)
            max = inttobool(tonumber(max))
            if max then
                sudokuGUI.frame:Maximize(true)
            else
                if x < dispX - 5 then x = 0 end
                if y < dispY - 5 then y = 0 end
                if w > dispW then w = dispW end
                if h > dispH then h = dispH end

                sudokuGUI.frame:Move(x, y)
                sudokuGUI.frame:SetClientSize(w, h)
            end
        end

        sudokuGUI.ConfigReadWrite(true, sudokuGUI.config)
    end

    for winID = 1, 81 do
        if sudokuGUI.IsOddBlockCell(winID) then
            sudokuGUI.cellWindows[winID]:SetBackgroundColour(sudokuGUI.Colours[sudokuGUI.BACKGROUND_COLOUR])
        else
            sudokuGUI.cellWindows[winID]:SetBackgroundColour(sudokuGUI.Colours[sudokuGUI.ODD_BACKGROUND_COLOUR])
        end
    end

    local show_toolbar = sudokuGUI.frame:GetMenuBar():IsChecked(sudokuGUI.ID_SHOW_TOOLBAR)
    if sudokuGUI.frame:GetToolBar():IsShown() ~= show_toolbar then
        -- generate fake event to simplify processing
        local evt = wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED, sudokuGUI.ID_SHOW_TOOLBAR)
        evt:SetInt(booltoint(show_toolbar))
        sudokuGUI.OnMenuEvent(evt)
    end

    local show_toolbar_labels = sudokuGUI.frame:GetMenuBar():IsChecked(sudokuGUI.ID_SHOW_TOOLBAR_LABELS)
    if (bit.band(sudokuGUI.frame:GetToolBar():GetWindowStyleFlag(), wx.wxTB_TEXT) ~= 0) ~= show_toolbar_labels then
        -- generate fake event to simplify processing
        local evt = wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED, sudokuGUI.ID_SHOW_TOOLBAR_LABELS)
        evt:SetInt(booltoint(show_toolbar_labels))
        sudokuGUI.OnMenuEvent(evt)
    end

    local show_statusbar = sudokuGUI.frame:GetMenuBar():IsChecked(sudokuGUI.ID_SHOW_STATUSBAR)
    if sudokuGUI.frame:GetStatusBar():IsShown() ~= show_statusbar then
        -- generate fake event to simplify processing
        local evt = wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED, sudokuGUI.ID_SHOW_STATUSBAR)
        evt:SetInt(booltoint(show_statusbar))
        sudokuGUI.OnMenuEvent(evt)
    end

    sudokuGUI.valueFont_cache    = {} -- clear cache in case the font has changed
    sudokuGUI.possibleFont_cache = {}

    -- update font size
    local width, height = sudokuGUI.cellWindows[1]:GetClientSizeWH()
    sudokuGUI.GetCellBestSize(width, height)
    -- update for preferences
    sudokuGUI.UpdateTable()
    sudokuGUI.Refresh()
end

function sudokuGUI.ConfigReadWrite(read, config)
    local path = "wxLuaSudoku"

    local function ReadWriteColour(key, c)
        if read then
            if config:HasEntry(key) then
                local _, str = config:Read(key)
                local r, g, b = string.match(str, "r:(%d+) g:(%d+) b:(%d+)")
                if (r == nil) or (g == nil) or (b == nil) then return end
                r = tonumber(r); g = tonumber(g); b = tonumber(b)
                if (r < 0) or (r > 255) then return end -- sanity check
                if (g < 0) or (g > 255) then return end
                if (b < 0) or (b > 255) then return end
                c:Set(r, g, b)
            end
        else
            config:Write(key, string.format("r:%d g:%d b:%d", c:Red(), c:Green(), c:Blue()))
        end
    end

    local function ReadWriteFont(key, f)
        if read then
            if config:HasEntry(key) then
                local _, str = config:Read(key)
                local face, family, style, underlined, weight = string.match(str, "face:(\"[%w ]+\") family:(%d+) style:(%d+) underlined:(%d+) weight:(%d+)")
                if (face == nil) or (family == nil) or (style == nil) or (underlined == nil) or (weight == nil) then return end
                family = tonumber(family); style = tonumber(style);
                underlined = inttobool(tonumber(underlined)); weight = tonumber(weight)
                -- remove quotes
                if string.len(face) > 2 then face = string.sub(face, 2, -2) end

                -- test so see if the values are any good
                local ff = wx.wxFont(12, family, style, weight, underlined, face)
                if not ff:Ok() then return end

                local tempF = wx.wxFont(f)
                f:SetFaceName(face)
                f:SetFamily(family)
                f:SetStyle(style)
                f:SetUnderlined(underlined)
                f:SetWeight(weight)

                -- shouldn't happen but we always want a usable font
                if not f:Ok() then
                    f:SetFaceName(tempF:GetFaceName())
                    f:SetFamily(tempF:GetFamily())
                    f:SetStyle(tempF:GetStyle())
                    f:SetUnderlined(tempF:GetUnderlined())
                    f:SetWeight(tempF:GetWeight())
                end
            end
        else
            config:Write(key, string.format("face:\"%s\" family:%d style:%d underlined:%d weight:%d",
                f:GetFaceName(), f:GetFamily(), f:GetStyle(), booltoint(f:GetUnderlined()), f:GetWeight()))
        end
    end

    if read then
        local _
        if config:HasEntry(path.."/LastOpenedFilepath") then
            _, sudokuGUI.filePath   = config:Read(path.."/LastOpenedFilepath", "")
        end
        if config:HasEntry(path.."/LastOpenedFilename") then
            _, sudokuGUI.fileName   = config:Read(path.."/LastOpenedFilename", "")
        end
        if config:HasEntry(path.."/GenerateDifficulty") then
            _, sudokuGUI.difficulty = config:Read(path.."/GenerateDifficulty", 0)
        end
    else
        config:Write(path.."/LastOpenedFilepath", sudokuGUI.filePath)
        config:Write(path.."/LastOpenedFilename", sudokuGUI.fileName)
        config:Write(path.."/GenerateDifficulty", sudokuGUI.difficulty)
    end

    ReadWriteColour(path.."/Colours/Value",             sudokuGUI.Colours[sudokuGUI.VALUE_COLOUR])
    ReadWriteColour(path.."/Colours/ValueInit",         sudokuGUI.Colours[sudokuGUI.INIT_VALUE_COLOUR])
    ReadWriteColour(path.."/Colours/ValuePossible",     sudokuGUI.Colours[sudokuGUI.POSS_VALUE_COLOUR])
    ReadWriteColour(path.."/Colours/ValueInvalid",      sudokuGUI.Colours[sudokuGUI.INVALID_VALUE_COLOUR])
    ReadWriteColour(path.."/Colours/CellBackground",    sudokuGUI.Colours[sudokuGUI.BACKGROUND_COLOUR])
    ReadWriteColour(path.."/Colours/CellOddBackground", sudokuGUI.Colours[sudokuGUI.ODD_BACKGROUND_COLOUR])
    ReadWriteColour(path.."/Colours/CellFocus",         sudokuGUI.Colours[sudokuGUI.FOCUS_CELL_COLOUR])

    ReadWriteColour(path.."/Colours/NakedPairs",     sudokuGUI.Colours[sudokuGUI.NAKED_PAIRS_COLOUR])
    ReadWriteColour(path.."/Colours/NakedTriplets",  sudokuGUI.Colours[sudokuGUI.NAKED_TRIPLETS_COLOUR])
    ReadWriteColour(path.."/Colours/NakedQuads",     sudokuGUI.Colours[sudokuGUI.NAKED_QUADS_COLOUR])
    ReadWriteColour(path.."/Colours/HiddenPairs",    sudokuGUI.Colours[sudokuGUI.HIDDEN_PAIRS_COLOUR])
    ReadWriteColour(path.."/Colours/HiddenTriplets", sudokuGUI.Colours[sudokuGUI.HIDDEN_TRIPLETS_COLOUR])
    ReadWriteColour(path.."/Colours/HiddenQuads",    sudokuGUI.Colours[sudokuGUI.HIDDEN_QUADS_COLOUR])

    ReadWriteFont(path.."/Fonts/Value",         sudokuGUI.valueFont.wxfont)
    ReadWriteFont(path.."/Fonts/ValuePossible", sudokuGUI.possibleFont.wxfont)

    local function ReadWritePref(key, pref)
        if read then
            if config:HasEntry(key) then
                local _, v = config:Read(key, 0)
                sudokuGUI.CheckMenuItem(pref, inttobool(v))
            end
        else
            config:Write(key, booltoint(sudokuGUI.IsCheckedMenuItem(pref)))
        end
    end

    ReadWritePref(path.."/Preferences/SHOW_ERRORS",          sudokuGUI.ID_SHOW_ERRORS)
    ReadWritePref(path.."/Preferences/SHOW_MISTAKES",        sudokuGUI.ID_SHOW_MISTAKES)
    ReadWritePref(path.."/Preferences/SHOW_TOOLBAR",         sudokuGUI.ID_SHOW_TOOLBAR)
    ReadWritePref(path.."/Preferences/SHOW_TOOLBAR_LABELS",  sudokuGUI.ID_SHOW_TOOLBAR_LABELS)
    ReadWritePref(path.."/Preferences/SHOW_STATUSBAR",       sudokuGUI.ID_SHOW_STATUSBAR)

    ReadWritePref(path.."/Preferences/SHOW_POSSIBLE",        sudokuGUI.ID_SHOW_POSSIBLE)
    ReadWritePref(path.."/Preferences/SHOW_USER_POSSIBLE",   sudokuGUI.ID_SHOW_USER_POSSIBLE)
    ReadWritePref(path.."/Preferences/SHOW_POSSIBLE_LINE",   sudokuGUI.ID_SHOW_POSSIBLE_LINE)

    ReadWritePref(path.."/Preferences/SHOW_NAKED",               sudokuGUI.ID_SHOW_NAKED)
    ReadWritePref(path.."/Preferences/SHOW_HIDDEN",              sudokuGUI.ID_SHOW_HIDDEN)
    ReadWritePref(path.."/Preferences/SHOW_NAKEDPAIRS",          sudokuGUI.ID_SHOW_NAKEDPAIRS)
    ReadWritePref(path.."/Preferences/SHOW_HIDDENPAIRS",         sudokuGUI.ID_SHOW_HIDDENPAIRS)
    ReadWritePref(path.."/Preferences/SHOW_NAKEDTRIPLETS",       sudokuGUI.ID_SHOW_NAKEDTRIPLETS)
    ReadWritePref(path.."/Preferences/SHOW_HIDDENTRIPLETS",      sudokuGUI.ID_SHOW_HIDDENTRIPLETS)
    ReadWritePref(path.."/Preferences/SHOW_NAKEDQUADS",          sudokuGUI.ID_SHOW_NAKEDQUADS)
    ReadWritePref(path.."/Preferences/SHOW_HIDDENQUADS",         sudokuGUI.ID_SHOW_HIDDENQUADS)

    ReadWritePref(path.."/Preferences/ELIMINATE_NAKED",          sudokuGUI.ID_ELIMINATE_NAKED)
    ReadWritePref(path.."/Preferences/ELIMINATE_HIDDEN",         sudokuGUI.ID_ELIMINATE_HIDDEN)
    ReadWritePref(path.."/Preferences/ELIMINATE_NAKEDPAIRS",     sudokuGUI.ID_ELIMINATE_NAKEDPAIRS)
    ReadWritePref(path.."/Preferences/ELIMINATE_HIDDENPAIRS",    sudokuGUI.ID_ELIMINATE_HIDDENPAIRS)
    ReadWritePref(path.."/Preferences/ELIMINATE_NAKEDTRIPLETS",  sudokuGUI.ID_ELIMINATE_NAKEDTRIPLETS)
    ReadWritePref(path.."/Preferences/ELIMINATE_HIDDENTRIPLETS", sudokuGUI.ID_ELIMINATE_HIDDENTRIPLETS)
    ReadWritePref(path.."/Preferences/ELIMINATE_NAKEDQUADS",     sudokuGUI.ID_ELIMINATE_NAKEDQUADS)
    ReadWritePref(path.."/Preferences/ELIMINATE_HIDDENQUADS",    sudokuGUI.ID_ELIMINATE_HIDDENQUADS)
end

-- ----------------------------------------------------------------------------

function sudokuGUI.InitFontsAndColours()
    sudokuGUI.Colours =
    {
        [sudokuGUI.VALUE_COLOUR]           = wx.wxColour(0, 0, 230),
        [sudokuGUI.INIT_VALUE_COLOUR]      = wx.wxColour(0, 0, 0),
        [sudokuGUI.POSS_VALUE_COLOUR]      = wx.wxColour(0, 0, 0),
        [sudokuGUI.INVALID_VALUE_COLOUR]   = wx.wxColour(255, 0, 0),
        [sudokuGUI.BACKGROUND_COLOUR]      = wx.wxColour(255, 255, 255),
        [sudokuGUI.ODD_BACKGROUND_COLOUR]  = wx.wxColour(250, 250, 210),
        [sudokuGUI.FOCUS_CELL_COLOUR]      = wx.wxColour(200, 220, 250),

        [sudokuGUI.NAKED_PAIRS_COLOUR]     = wx.wxColour(255, 0, 0),
        [sudokuGUI.NAKED_TRIPLETS_COLOUR]  = wx.wxColour(255, 180, 0),
        [sudokuGUI.NAKED_QUADS_COLOUR]     = wx.wxColour(255, 255, 0),
        [sudokuGUI.HIDDEN_PAIRS_COLOUR]    = wx.wxColour(0, 220, 0),
        [sudokuGUI.HIDDEN_TRIPLETS_COLOUR] = wx.wxColour(0, 240, 160),
        [sudokuGUI.HIDDEN_QUADS_COLOUR]    = wx.wxColour(0, 220, 220)
    }

    sudokuGUI.Colours_ = {}
    for n = 1, sudokuGUI.COLOUR_MAX do
        sudokuGUI.Colours_[n] = wx.wxColour(sudokuGUI.Colours[n])
    end

    --   just use defaults since some XP systems may not even have wxMODERN
    sudokuGUI.possibleFont_wxfont_ = wx.wxFont(wx.wxNORMAL_FONT)
    sudokuGUI.valueFont_wxfont_    = wx.wxFont(wx.wxNORMAL_FONT)
    sudokuGUI.valueFont_wxfont_:SetWeight(wx.wxFONTWEIGHT_BOLD)
    if not sudokuGUI.valueFont_wxfont_:Ok() then
        sudokuGUI.valueFont_wxfont_:Destroy()
        sudokuGUI.valueFont_wxfont_ = wx.wxFont(wx.wxNORMAL_FONT)
    end

    sudokuGUI.possibleFont.wxfont = wx.wxFont(sudokuGUI.possibleFont_wxfont_)
    sudokuGUI.valueFont.wxfont    = wx.wxFont(sudokuGUI.valueFont_wxfont_)
end

-- ----------------------------------------------------------------------------
-- Create a table of the menu IDs to use as a "case" type statement
sudokuGUI.MenuId = {}
-- ----------------------------------------------------------------------------
sudokuGUI.MenuId[sudokuGUI.ID_NEW]          = function() sudokuGUI.NewPuzzle(true) end
sudokuGUI.MenuId[sudokuGUI.ID_CREATE]       = function(event) sudokuGUI.CreatePuzzle(event:IsChecked()) end
sudokuGUI.MenuId[sudokuGUI.ID_GENERATE]     = function() sudokuGUI.GeneratePuzzle() end
sudokuGUI.MenuId[sudokuGUI.ID_OPEN]         = function() sudokuGUI.OpenPuzzle() end
sudokuGUI.MenuId[sudokuGUI.ID_SAVEAS]       = function() sudokuGUI.SaveAsPuzzle() end
sudokuGUI.MenuId[sudokuGUI.ID_PAGESETUP]    = function() sudokuGUI.PageSetup() end
sudokuGUI.MenuId[sudokuGUI.ID_PRINTSETUP]   = function() sudokuGUI.PrintSetup() end
sudokuGUI.MenuId[sudokuGUI.ID_PRINTPREVIEW] = function() sudokuGUI.PrintPreview() end
sudokuGUI.MenuId[sudokuGUI.ID_PRINT]        = function() sudokuGUI.Print() end
sudokuGUI.MenuId[sudokuGUI.ID_EXIT]         = function() sudokuGUI.frame:Close() end
-- ----------------------------------------------------------------------------
sudokuGUI.MenuId[sudokuGUI.ID_COPY_PUZZLE] =
            function (event)
                local str = sudoku.ToString(sudokuGUI.GetCurrentTable())
                if wx.wxClipboard.Get():Open() then
                    wx.wxClipboard.Get():SetData(wx.wxTextDataObject(str))
                    wx.wxClipboard.Get():Close()
                end
            end
sudokuGUI.MenuId[sudokuGUI.ID_RESET] = function() sudokuGUI.ResetPuzzle() end
sudokuGUI.MenuId[sudokuGUI.ID_UNDO]  = function() sudokuGUI.Undo() end
sudokuGUI.MenuId[sudokuGUI.ID_REDO]  = function() sudokuGUI.Redo() end
sudokuGUI.MenuId[sudokuGUI.ID_PREFERENCES]      = function() sudokuGUI.PreferencesDialog() end
sudokuGUI.MenuId[sudokuGUI.ID_SAVE_PREFERENCES] = function() sudokuGUI.ConfigSave(true) end
-- ----------------------------------------------------------------------------
-- Makes sure that menu and tool items are in sync and updates the table
function sudokuGUI.MenuCheckUpdate(event)
    sudokuGUI.CheckMenuItem(event:GetId(), event:IsChecked())
    sudokuGUI.UpdateTable()
end

sudokuGUI.MenuId[sudokuGUI.ID_SHOW_ERRORS]   = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_MISTAKES] =
            function (event)
                -- need to solve it ourselves first
                if (not sudokuGUI.IsCheckedMenuItem(sudokuGUI.ID_CREATE)) and
                    (event:IsChecked()) and (not sudokuGUI.sudokuSolnTable) then
                    sudokuGUI.sudokuSolnTable = sudokuGUI.VerifyUniquePuzzle(sudokuGUI.GetInitTable())

                    if not sudokuGUI.sudokuSolnTable then
                        event:SetInt(0) -- uncheck for MenuCheckUpdate function
                        sudokuGUI.frame:GetMenuBar():Check(sudokuGUI.ID_SHOW_MISTAKES, false)
                    end
                end
                sudokuGUI.MenuCheckUpdate(event)
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_TOOLBAR]  =
            function(event)
                sudokuGUI.frame:GetToolBar():Show(event:IsChecked())
                -- hack to make the wxFrame layout the child panel
                local w, h = sudokuGUI.frame:GetSizeWH()
                sudokuGUI.frame:SetSize(wx.wxSize(w, h+1))
                sudokuGUI.frame:SetSize(wx.wxSize(w, h))
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_TOOLBAR, event:IsChecked())
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_TOOLBAR_LABELS]  =
            function(event)
                local style = wx.wxNO_BORDER
                if event:IsChecked() then
                    style = style + wx.wxTB_TEXT
                end

                sudokuGUI.frame:GetToolBar():SetWindowStyle(style)
                sudokuGUI.frame:GetToolBar():Realize()
                -- hack to make the wxFrame layout the child panel
                local w, h = sudokuGUI.frame:GetSizeWH()
                sudokuGUI.frame:SetSize(wx.wxSize(w, h+1))
                sudokuGUI.frame:SetSize(wx.wxSize(w, h))
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_TOOLBAR_LABELS, event:IsChecked())
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_STATUSBAR]  =
            function(event)
                sudokuGUI.frame:GetStatusBar():Show(event:IsChecked())
                -- hack to make the wxFrame layout the child panel
                local w, h = sudokuGUI.frame:GetSizeWH()
                sudokuGUI.frame:SetSize(wx.wxSize(w, h+1))
                sudokuGUI.frame:SetSize(wx.wxSize(w, h))
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_STATUSBAR, event:IsChecked())
            end
-- ----------------------------------------------------------------------------
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_POSSIBLE] =
            function (event)
                if event:IsChecked() then
                    -- make this act like a radio item that can be unchecked
                    sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_USER_POSSIBLE, false)
                end
                sudokuGUI.MenuCheckUpdate(event)
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_USER_POSSIBLE] =
            function (event)
                if event:IsChecked() then
                    -- make this act like a radio item that can be unchecked
                    sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_POSSIBLE, false)
                end
                sudokuGUI.MenuCheckUpdate(event)
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_POSSIBLE_LINE] =
            function (event)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_POSSIBLE_LINE, event:IsChecked())
                local width, height = sudokuGUI.cellWindows[1]:GetClientSizeWH()
                sudokuGUI.GetCellBestSize(width-1, height-1)
                sudokuGUI.Refresh()
            end
sudokuGUI.MenuId[sudokuGUI.ID_USER_POSSIBLE_CLEAR] =
            function (event)
                local ret = wx.wxMessageBox("Clear all of your pencil marks?",
                                            "wxLuaSudoku - clear pencil marks?",
                                            wx.wxOK + wx.wxCANCEL + wx.wxICON_INFORMATION,
                                            sudokuGUI.frame )
                if ret == wx.wxOK then
                    sudokuGUI.pencilMarks = {}
                    for cell = 1, 81 do
                        sudokuGUI.pencilMarks[cell] = {}
                    end
                    sudokuGUI.UpdateTable()
                end
            end
sudokuGUI.MenuId[sudokuGUI.ID_USER_POSSIBLE_SETALL] =
            function (event)
                local ret = wx.wxMessageBox("Set all values as possible in the pencil marks?",
                                            "wxLuaSudoku - set all pencil marks?",
                                            wx.wxOK + wx.wxCANCEL + wx.wxICON_INFORMATION,
                                            sudokuGUI.frame )
                if ret == wx.wxOK then
                    sudokuGUI.pencilMarks = {}
                    for cell = 1, 81 do
                        sudokuGUI.pencilMarks[cell] = {}
                        for v = 1, 9 do
                            sudokuGUI.pencilMarks[cell][v] = v
                        end
                    end
                    sudokuGUI.UpdateTable()
                end
            end
sudokuGUI.MenuId[sudokuGUI.ID_USER_POSSIBLE_INIT] =
            function (event)
                local ret = wx.wxMessageBox("Initialize the pencil marks to the calculated possible values?",
                                            "wxLuaSudoku - initialize pencil marks?",
                                            wx.wxOK + wx.wxCANCEL + wx.wxICON_INFORMATION,
                                            sudokuGUI.frame )
                if ret == wx.wxOK then
                    local s  = sudokuGUI.GetCurrentTable()
                    for cell = 1, 81 do
                        sudokuGUI.pencilMarks[cell] = {}
                        for v = 1, 9 do
                            sudokuGUI.pencilMarks[cell][v] = s.possible[cell][v]
                        end
                    end
                    sudokuGUI.UpdateTable()
                end
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_NAKED] =
            function (event)
                local checked = event:IsChecked()
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_NAKEDPAIRS, checked)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_NAKEDTRIPLETS, checked)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_NAKEDQUADS, checked)
                sudokuGUI.UpdateTable()
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_HIDDEN] =
            function (event)
                local checked = event:IsChecked()
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_HIDDENPAIRS, checked)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_HIDDENTRIPLETS, checked)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_SHOW_HIDDENQUADS, checked)
                sudokuGUI.UpdateTable()
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_NAKEDPAIRS]     = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_HIDDENPAIRS]    = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_NAKEDTRIPLETS]  = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_HIDDENTRIPLETS] = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_NAKEDQUADS]     = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_HIDDENQUADS]    = sudokuGUI.MenuCheckUpdate
-- ----------------------------------------------------------------------------
sudokuGUI.MenuId[sudokuGUI.ID_VERIFY_PUZZLE] =
            function (event)
                local s = sudokuGUI.VerifyUniquePuzzle(sudokuGUI.GetInitTable())
                if s then
                    sudokuGUI.sudokuSolnTable = s
                end
            end
sudokuGUI.MenuId[sudokuGUI.ID_SHOW_SOLUTION] =
            function (event)
                if not sudokuGUI.sudokuSolnTable then
                    local s = sudokuGUI.VerifyUniquePuzzle(sudokuGUI.GetInitTable())
                    if s then
                        sudokuGUI.sudokuSolnTable = s
                    end
                end

                if sudokuGUI.sudokuSolnTable then
                    sudokuGUI.AddTable(sudokuGUI.sudokuSolnTable)
                end
            end

sudokuGUI.MenuId[sudokuGUI.ID_ELIMINATE_NAKED] =
            function (event)
                local checked = event:IsChecked()
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_ELIMINATE_NAKEDPAIRS, checked)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_ELIMINATE_NAKEDTRIPLETS, checked)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_ELIMINATE_NAKEDQUADS, checked)
                sudokuGUI.UpdateTable()
            end
sudokuGUI.MenuId[sudokuGUI.ID_ELIMINATE_HIDDEN] =
            function (event)
                local checked = event:IsChecked()
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_ELIMINATE_HIDDENPAIRS, checked)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_ELIMINATE_HIDDENTRIPLETS, checked)
                sudokuGUI.CheckMenuItem(sudokuGUI.ID_ELIMINATE_HIDDENQUADS, checked)
                sudokuGUI.UpdateTable()
            end
sudokuGUI.MenuId[sudokuGUI.ID_ELIMINATE_NAKEDPAIRS]     = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_ELIMINATE_HIDDENPAIRS]    = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_ELIMINATE_NAKEDTRIPLETS]  = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_ELIMINATE_HIDDENTRIPLETS] = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_ELIMINATE_NAKEDQUADS]     = sudokuGUI.MenuCheckUpdate
sudokuGUI.MenuId[sudokuGUI.ID_ELIMINATE_HIDDENQUADS]    = sudokuGUI.MenuCheckUpdate

sudokuGUI.MenuId[sudokuGUI.ID_SOLVE_SCANSINGLES] =
            function (event)
                local s = TableCopy(sudokuGUI.GetCurrentTable())
                local changed_cells = sudoku.SolveScanSingles(s)
                if changed_cells then sudokuGUI.AddTable(s) end
            end
sudokuGUI.MenuId[sudokuGUI.ID_SOLVE_SCANROWS] =
            function (event)
                local s = TableCopy(sudokuGUI.GetCurrentTable())
                local changed_cells = sudoku.SolveScanRows(s)
                if changed_cells then sudokuGUI.AddTable(s) end
            end
sudokuGUI.MenuId[sudokuGUI.ID_SOLVE_SCANCOLS] =
            function (event)
                local s = TableCopy(sudokuGUI.GetCurrentTable())
                local changed_cells = sudoku.SolveScanCols(s)
                if changed_cells then sudokuGUI.AddTable(s) end
            end
sudokuGUI.MenuId[sudokuGUI.ID_SOLVE_SCANBLOCKS] =
            function (event)
                local s = TableCopy(sudokuGUI.GetCurrentTable())
                local changed_cells = sudoku.SolveScanBlocks(s)
                if changed_cells then sudokuGUI.AddTable(s) end
            end

sudokuGUI.MenuId[sudokuGUI.ID_SOLVE_SCANNING]   = function (event) sudokuGUI.SolveScanning() end
sudokuGUI.MenuId[sudokuGUI.ID_SOLVE_BRUTEFORCE] = function (event) sudokuGUI.SolveBruteForce() end
-- ----------------------------------------------------------------------------
sudokuGUI.MenuId[sudokuGUI.ID_ABOUT] =
            function (event)
                wx.wxMessageBox("Welcome to wxLuaSudoku!\nWritten by John Labenski\nCopyright 2006.\n"..
                                wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
                                "About wxLuaSudoku",
                                wx.wxOK + wx.wxICON_INFORMATION,
                                sudokuGUI.frame )
            end
sudokuGUI.MenuId[sudokuGUI.ID_HELP] =
            function (event)
                local helpFrame = wx.wxFrame(sudokuGUI.frame, wx.wxID_ANY, "Help on wxLuaSudoku", wx.wxDefaultPosition, wx.wxSize(600,400))
                local htmlWin = wx.wxHtmlWindow(helpFrame)
                if (htmlWin:SetPage(sudokuGUIhelp)) then
                    helpFrame:Centre()
                    helpFrame:Show(true)
                else
                    helpFrame:Destroy()
                end
            end

-- ----------------------------------------------------------------------------

function sudokuGUI.OnMenuEvent(event)
    local id = event:GetId()

    if sudokuGUI.MenuId[id] then
        sudokuGUI.MenuId[id](event)
        return
    end
end

-- ----------------------------------------------------------------------------
-- Unify all checking and unchecking of the menu items and
--   make sure menu/toolbar are in sync

function sudokuGUI.CheckMenuItem(id, check)
    sudokuGUI.frame:GetMenuBar():Check(id, check)
    sudokuGUI.frame:GetToolBar():ToggleTool(id, check) -- doesn't care if id doesn't exist
    sudokuGUI.menuCheckIDs[id] = check
end
function sudokuGUI.IsCheckedMenuItem(id)
    if sudokuGUI.menuCheckIDs[id] == nil then
        sudokuGUI.menuCheckIDs[id] = sudokuGUI.frame:GetMenuBar():IsChecked(id)
    end

    return sudokuGUI.menuCheckIDs[id]
end

-- ----------------------------------------------------------------------------

function main()

    sudokuGUI.block_refresh = true

    -- initialize the fonts and colours to use (must always exist)
    sudokuGUI.InitFontsAndColours()

    -- initialize the printing defaults
    sudokuGUI.printData:SetPaperId(wx.wxPAPER_LETTER);
    sudokuGUI.pageSetupData:SetMarginTopLeft(wx.wxPoint(25, 25));
    sudokuGUI.pageSetupData:SetMarginBottomRight(wx.wxPoint(25, 25));

    -- Create the main frame for the program
    sudokuGUI.frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, "wxLuaSudoku",
                                 wx.wxDefaultPosition, wx.wxSize(300,320))

    sudokuGUI.frame:SetSizeHints(300, 300);
    local bitmap = wx.wxBitmap(sudokuGUIxpmdata)
    local icon = wx.wxIcon()
    icon:CopyFromBitmap(bitmap)
    sudokuGUI.frame:SetIcon(icon)

    local function MItem(menu, id, text, help, bmp)
        local m = wx.wxMenuItem(menu, id, text, help)
        m:SetBitmap(bmp)
        bmp:delete()
        return m
    end

    local fileMenu = wx.wxMenu("", 0)
    fileMenu:Append(MItem(fileMenu, sudokuGUI.ID_NEW,      "&New...\tCtrl-N",      "Clear the current puzzle", wx.wxArtProvider.GetBitmap(wx.wxART_NEW, wx.wxART_TOOLBAR)))
    fileMenu:AppendCheckItem(sudokuGUI.ID_CREATE,              "&Create...\tCtrl-T",   "Enter the initial values for the puzzle")
    fileMenu:Append(MItem(fileMenu, sudokuGUI.ID_GENERATE, "&Generate...\tCtrl-G", "Generate a new puzzle", wx.wxArtProvider.GetBitmap(wx.wxART_EXECUTABLE_FILE, wx.wxART_TOOLBAR)))
    fileMenu:Append(MItem(fileMenu, sudokuGUI.ID_OPEN,     "&Open...\tCtrl-O",     "Open a puzzle file", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_OPEN, wx.wxART_TOOLBAR)))
    fileMenu:Append(MItem(fileMenu, sudokuGUI.ID_SAVEAS,   "&Save as...\tCtrl-S",  "Save the current puzzle", wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_TOOLBAR)))
    fileMenu:AppendSeparator()
    fileMenu:Append(sudokuGUI.ID_PAGESETUP,    "Page S&etup...",    "Setup the printout page")
    --fileMenu:Append(sudokuGUI.ID_PRINTSETUP, "Print Se&tup...",   "Setup the printer")
    fileMenu:Append(sudokuGUI.ID_PRINTPREVIEW, "Print Pre&view...", "Preview the printout")
    fileMenu:Append(MItem(fileMenu, sudokuGUI.ID_PRINT,        "&Print...",         "Print the puzzle", wx.wxArtProvider.GetBitmap(wx.wxART_PRINT, wx.wxART_TOOLBAR)))
    fileMenu:AppendSeparator()
    fileMenu:Append(sudokuGUI.ID_EXIT, "E&xit\tCtrl-X", "Quit the program")

    local editMenu = wx.wxMenu("", 0)
    editMenu:Append(sudokuGUI.ID_COPY_PUZZLE, "Copy puzzle", "Copy the puzzle to the clipboard")
    editMenu:AppendSeparator()
    editMenu:Append(sudokuGUI.ID_RESET, "Re&set...\tCtrl-R", "Reset the puzzle to the initial state")
    editMenu:AppendSeparator()
    editMenu:Append(MItem(editMenu, sudokuGUI.ID_UNDO, "&Undo\tCtrl-Z", "Undo the last entry", wx.wxArtProvider.GetBitmap(wx.wxART_UNDO, wx.wxART_TOOLBAR)))
    editMenu:Append(MItem(editMenu, sudokuGUI.ID_REDO, "&Redo\tCtrl-Y", "Redo the last entry", wx.wxArtProvider.GetBitmap(wx.wxART_REDO, wx.wxART_TOOLBAR)))
    editMenu:AppendSeparator()
    editMenu:Append(sudokuGUI.ID_PREFERENCES, "P&references...", "Show the preferences dialog")
    editMenu:AppendSeparator()
    editMenu:Append(sudokuGUI.ID_SAVE_PREFERENCES, "Sa&ve preferences...", "Save the preferences")

    local viewMenu = wx.wxMenu("", 0)
    viewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_ERRORS,   "Mark &errors\tCtrl-E",   "Mark duplicate values in puzzle")
    viewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_MISTAKES, "Mark &mistakes\tCtrl-M", "Mark wrong values in puzzle")
    viewMenu:AppendSeparator()
    viewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_TOOLBAR,        "Show toolbar",        "Show the toolbar")
    viewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_TOOLBAR_LABELS, "Show toolbar labels", "Show labels on the toolbar")
    viewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_STATUSBAR,      "Show statusbar",      "Show the statusbar")
    viewMenu:Check(sudokuGUI.ID_SHOW_TOOLBAR, true)
    viewMenu:Check(sudokuGUI.ID_SHOW_TOOLBAR_LABELS, true)
    viewMenu:Check(sudokuGUI.ID_SHOW_STATUSBAR, true)

    local possibleMenu = wx.wxMenu("", 0)
    possibleMenu:AppendCheckItem( sudokuGUI.ID_SHOW_POSSIBLE,      "Show calculated &possible\tCtrl-P", "Show calculated possible values for the cells")
    possibleMenu:AppendCheckItem( sudokuGUI.ID_SHOW_USER_POSSIBLE, "Show/Edit pencil marks\tCtrl-l", "Show and edit user set possible values for the cells")
    possibleMenu:AppendSeparator()
    possibleMenu:AppendCheckItem( sudokuGUI.ID_SHOW_POSSIBLE_LINE, "Show possible in a &line",    "Show possible values for the cells in a line")
    possibleMenu:AppendSeparator()
    local userPossMenu = wx.wxMenu("", 0)
      userPossMenu:Append( sudokuGUI.ID_USER_POSSIBLE_CLEAR,  "Clear all...",  "Clear all pencil marks")
      userPossMenu:Append( sudokuGUI.ID_USER_POSSIBLE_SETALL, "Set all...",    "Set all pencil marks")
      userPossMenu:Append( sudokuGUI.ID_USER_POSSIBLE_INIT,   "Calculate...", "Initialize pencil marks to calculated possible")
    possibleMenu:Append(sudokuGUI.ID_USER_POSSIBLE_MENU, "Pencil marks", userPossMenu, "Setup user possible values")

    possibleMenu:AppendSeparator()
    local possViewMenu = wx.wxMenu("", 0)
      possViewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_NAKED,  "Mark &naked groups",  "Mark all naked groups in possible values")
      possViewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_HIDDEN, "Mark &hidden groups", "Mark all hidden groups in possible values")
      possViewMenu:AppendSeparator()
      possViewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_NAKEDPAIRS,     "Mark naked pairs",     "Mark naked pairs in possible values")
      possViewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_HIDDENPAIRS,    "Mark hidden pairs",    "Mark hidden pairs in possible values")
      possViewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_NAKEDTRIPLETS,  "Mark naked triplets",  "Mark naked triplets in possible values")
      possViewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_HIDDENTRIPLETS, "Mark hidden triplets", "Mark hidden triplets in possible values")
      possViewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_NAKEDQUADS,     "Mark naked quads",     "Mark naked quads in possible values")
      possViewMenu:AppendCheckItem( sudokuGUI.ID_SHOW_HIDDENQUADS,    "Mark hidden quads",    "Mark hidden quads in possible values")
    possibleMenu:Append(sudokuGUI.ID_SHOW_MENU, "Mark &groups", possViewMenu, "Mark naked/hidden groups")

    local solveMenu = wx.wxMenu("", 0)
    solveMenu:Append(sudokuGUI.ID_VERIFY_PUZZLE, "Verify unique solution...", "Verify that the puzzle has only one solution")
    solveMenu:AppendSeparator()
    solveMenu:Append(sudokuGUI.ID_SHOW_SOLUTION, "Show solution", "Show the solution to the puzzle")
    solveMenu:AppendSeparator()
    local elimSolveMenu = wx.wxMenu("", 0)
      elimSolveMenu:AppendCheckItem(sudokuGUI.ID_ELIMINATE_NAKED, "Eliminate &naked groups", "Eliminate all naked groups from possible values")
      elimSolveMenu:AppendCheckItem(sudokuGUI.ID_ELIMINATE_HIDDEN, "Eliminate &hidden groups", "Eliminate all hidden groups from possible values")
      elimSolveMenu:AppendSeparator()
      elimSolveMenu:AppendCheckItem(sudokuGUI.ID_ELIMINATE_NAKEDPAIRS, "Eliminate naked pairs", "Eliminate naked pairs from possible values")
      elimSolveMenu:AppendCheckItem(sudokuGUI.ID_ELIMINATE_HIDDENPAIRS, "Eliminate hidden pairs", "Eliminate hidden pairs from possible values")
      elimSolveMenu:AppendCheckItem(sudokuGUI.ID_ELIMINATE_NAKEDTRIPLETS, "Eliminate naked triplets", "Eliminate naked triplets from possible values")
      elimSolveMenu:AppendCheckItem(sudokuGUI.ID_ELIMINATE_HIDDENTRIPLETS, "Eliminate hidden triplets", "Eliminate hidden triplets from possible values")
      elimSolveMenu:AppendCheckItem(sudokuGUI.ID_ELIMINATE_NAKEDQUADS, "Eliminate naked quads", "Eliminate naked quads from possible values")
      elimSolveMenu:AppendCheckItem(sudokuGUI.ID_ELIMINATE_HIDDENQUADS, "Eliminate hidden quads", "Eliminate hidden quads from possible values")
    solveMenu:Append(sudokuGUI.ID_ELIMINATE_MENU, "&Eliminate groups", elimSolveMenu, "Remove possible values using naked and hidden groups")
    solveMenu:AppendSeparator()
    solveMenu:Append(sudokuGUI.ID_SOLVE_SCANSINGLES, "Solve (scan singles)\tCtrl-1", "Solve all cells with only one possibility")
    solveMenu:Append(sudokuGUI.ID_SOLVE_SCANROWS, "Solve (scan rows)\tCtrl-2", "Solve cells in rows with only one possible value")
    solveMenu:Append(sudokuGUI.ID_SOLVE_SCANCOLS, "Solve (scan cols)\tCtrl-3", "Solve cells in cols with only one possible value")
    solveMenu:Append(sudokuGUI.ID_SOLVE_SCANBLOCKS, "Solve (scan blocks)\tCtrl-4", "Solve cells in blocks with only one possible value")
    solveMenu:AppendSeparator()
    solveMenu:Append(sudokuGUI.ID_SOLVE_SCANNING, "Solve (&scanning)\tCtrl-L", "Solve the puzzle by only scanning")
    solveMenu:Append(sudokuGUI.ID_SOLVE_BRUTEFORCE, "Solve (&brute force)\tCtrl-B", "Solve the puzzle by guessing values")

    local helpMenu = wx.wxMenu("", 0)
    helpMenu:Append(sudokuGUI.ID_ABOUT, "&About...", "About the wxLuaSudoku Application")
    helpMenu:Append(MItem(helpMenu, sudokuGUI.ID_HELP, "&Help...", "Help using the wxLuaSudoku application", wx.wxArtProvider.GetBitmap(wx.wxART_HELP, wx.wxART_TOOLBAR)))

    local menuBar = wx.wxMenuBar()
    menuBar:Append(fileMenu,     "&File")
    menuBar:Append(editMenu,     "&Edit")
    menuBar:Append(viewMenu,     "&View")
    menuBar:Append(possibleMenu, "&Possible")
    menuBar:Append(solveMenu,    "&Solve")
    menuBar:Append(helpMenu,     "&Help")

    sudokuGUI.frame:SetMenuBar(menuBar)

    local toolBar = sudokuGUI.frame:CreateToolBar(wx.wxNO_BORDER + wx.wxTB_TEXT)
    local tbSize = toolBar:GetToolBitmapSize() -- required to force help icon to right size in MSW
    toolBar:AddTool(sudokuGUI.ID_NEW,       "New",    wx.wxArtProvider.GetBitmap(wx.wxART_NEW, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, wx.wxITEM_NORMAL, "New...", "Clear the current puzzle")
    toolBar:AddCheckTool(sudokuGUI.ID_CREATE, "Create", wx.wxArtProvider.GetBitmap(wx.wxART_ADD_BOOKMARK, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, "Create...", "Enter initial values for the puzzle")
    toolBar:AddTool(sudokuGUI.ID_GENERATE,  "Generate", wx.wxArtProvider.GetBitmap(wx.wxART_EXECUTABLE_FILE, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, wx.wxITEM_NORMAL, "Generate...", "Generate a new puzzle")
    toolBar:AddTool(sudokuGUI.ID_OPEN,      "Open",   wx.wxArtProvider.GetBitmap(wx.wxART_FILE_OPEN, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, wx.wxITEM_NORMAL, "Open...", "Open a puzzle file")
    toolBar:AddTool(sudokuGUI.ID_SAVEAS,    "Save",   wx.wxArtProvider.GetBitmap(wx.wxART_FILE_SAVE_AS, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, wx.wxITEM_NORMAL, "Save as...", "Save the current puzzle")
    toolBar:AddTool(sudokuGUI.ID_PRINT,     "Print",  wx.wxArtProvider.GetBitmap(wx.wxART_PRINT, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, wx.wxITEM_NORMAL, "Print...", "Print the puzzle")
    toolBar:AddSeparator()
    toolBar:AddTool(sudokuGUI.ID_UNDO,      "Undo",   wx.wxArtProvider.GetBitmap(wx.wxART_UNDO, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, wx.wxITEM_NORMAL, "Undo", "Undo the last entry")
    toolBar:AddTool(sudokuGUI.ID_REDO,      "Redo",   wx.wxArtProvider.GetBitmap(wx.wxART_REDO, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, wx.wxITEM_NORMAL, "Redo", "Redo the last entry")
    toolBar:AddSeparator()
    toolBar:AddTool(sudokuGUI.ID_HELP,      "Help",   wx.wxArtProvider.GetBitmap(wx.wxART_HELP, wx.wxART_TOOLBAR, tbSize), wx.wxNullBitmap, wx.wxITEM_NORMAL, "Help...", "Help on wxLuaSudoku")
    toolBar:Realize()

    sudokuGUI.frame:CreateStatusBar(2)
    local stat_width = sudokuGUI.frame:GetStatusBar():GetTextExtent("Step : 00000")
    sudokuGUI.frame:SetStatusWidths({-1, stat_width})
    sudokuGUI.frame:SetStatusText("Welcome to wxLuaSudoku.", 0)

    -- ------------------------------------------------------------------------
    -- Use single centralized menu/toolbar event handler
    sudokuGUI.frame:Connect(wx.wxID_ANY, wx.wxEVT_COMMAND_MENU_SELECTED,
                            sudokuGUI.OnMenuEvent)

    -- ------------------------------------------------------------------------

    local values =
    {
        5,0,0, 8,0,3, 0,6,0,
        1,0,6, 0,9,2, 0,8,5,
        0,0,8, 5,0,7, 0,4,0,

        0,0,1, 0,3,4, 0,7,0,
        0,9,0, 0,0,8, 1,3,4,
        3,0,0, 0,2,0, 5,9,0,

        0,0,5, 1,0,0, 0,0,3,
        0,0,0, 0,0,9, 0,0,0,
        0,0,7, 3,0,0, 4,0,9
    }

    local solution =
    {
        5,4,9, 8,1,3, 2,6,7,
        1,7,6, 4,9,2, 3,8,5,
        2,3,8, 5,6,7, 9,4,1,

        8,5,1, 9,3,4, 6,7,2,
        7,9,2, 6,5,8, 1,3,4,
        3,6,4, 7,2,1, 5,9,8,

        9,8,5, 1,4,6, 7,2,3,
        4,1,3, 2,7,9, 8,5,6,
        6,2,7, 3,8,5, 4,1,9
    }

    local s = sudoku.CreateTable()
    sudoku.SetValues(s, values)
    sudokuGUI.sudokuTables_pos = 1
    sudokuGUI.sudokuTables[1] = s

    sudokuGUI.sudokuSolnTable = sudoku.CreateTable()
    sudoku.SetValues(sudokuGUI.sudokuSolnTable, solution)

    sudokuGUI.panel = wx.wxPanel(sudokuGUI.frame, wx.wxID_ANY)
    --sudokuGUI.panel:SetBackgroundColour(wx.wxColour(0,0,0))
    local gridsizer = wx.wxGridSizer(9, 9, 2, 2)

    for i = 1, 81 do
        local win = sudokuGUI.CreateCellWindow( sudokuGUI.panel, i, size )
        gridsizer:Add(win, 1, wx.wxALL+wx.wxGROW+ wx.wxALIGN_CENTER, 0)
        sudokuGUI.cellWindows[i] = win
    end

    local topsizer = wx.wxBoxSizer(wx.wxVERTICAL)
    topsizer:Add(gridsizer, 1, wx.wxALL+wx.wxGROW+wx.wxALIGN_CENTER, 0)
    sudokuGUI.panel:SetSizer( topsizer )
    --topsizer:Fit(sudokuGUI.frame)
    --topsizer:SetSizeHints( sudokuGUI.frame )

    -- ------------------------------------------------------------------------
    -- After being created - connect the size event to help MSW repaint the
    --  child windows
    sudokuGUI.cellWindows[1]:Connect(wx.wxEVT_SIZE,
            function (event)
                local width, height = sudokuGUI.cellWindows[1]:GetClientSizeWH()
                sudokuGUI.GetCellBestSize(width, height)
                sudokuGUI.Refresh()
                event:Skip(true)
            end )

    -- save the config when closing the frame
    sudokuGUI.frame:Connect(wx.wxEVT_CLOSE_WINDOW,
            function (event)
                event:Skip(true) -- allow it to really exit
                sudokuGUI.ConfigSave(false)
            end )

    local cell_width, cell_height = sudokuGUI.cellWindows[1]:GetClientSizeWH()
    sudokuGUI.GetCellBestSize(cell_width, cell_height)
    --sudokuGUI.UpdateTable()

    sudokuGUI.frame:SetClientSize(300,300)
    sudokuGUI.block_refresh = false
    sudokuGUI.ConfigLoad()
    sudokuGUI.frame:Show(true)

    collectgarbage("collect") -- cleanup any locals
end

main()



if false then
function ProfileBegin()
    Profile_Counters = {}
    Profile_Names = {}
    local function hook ()
      local f = debug.getinfo(2, "f").func
      if Profile_Counters[f] == nil then    -- first time `f' is called?
        Profile_Counters[f] = 1
        Profile_Names[f] = debug.getinfo(2, "Sn")
        --TableDump(Profile_Names[f])
      else  -- only increment the counter
        Profile_Counters[f] = Profile_Counters[f] + 1
      end
    end

    debug.sethook(hook, "c")  -- turn on the hook
end

function ProfileEnd()
    debug.sethook()   -- turn off the hook
    function getname (func)
      local n = Profile_Names[func]
      if n.what == "C" then
        return n.name
      end
      local loc = string.format("[%s]:%s", n.short_src, n.linedefined)
      if n.namewhat ~= "" then
        return string.format("%s (%s)", loc, n.name)
      else
        return string.format("%s", loc)
      end
    end
    for func, count in pairs(Profile_Counters) do
      print(getname(func), count)
    end
end

s = sudoku.CreateTable()
s.flags[sudoku.ELIMINATE_HIDDEN_PAIRS] = true
s.flags[sudoku.ELIMINATE_HIDDEN_TRIPLETS] = true
s.flags[sudoku.ELIMINATE_HIDDEN_QUADS] = true

t = os.time()

--ProfileBegin()
for n = 1, 10 do
    a, b = sudoku.FindAllNakedHiddenGroups(s, true)
    --a, b, c = sudoku.FindPossibleCountRowColBlock(s)
    --a, b, c = sudoku.FindAllPossibleGroups(s)
end
--ProfileEnd()

print(os.time()-t)
end


--[[
for i = 1, 1 do
    local s = sudoku.GeneratePuzzle()
    s = sudoku.GeneratePuzzleDifficulty(s, 35, true)
    sudoku.UpdateTable(s)
    local n, h = sudoku.FindAllNakedHiddenGroups(s, true)

    --TableDump(n)
    --TableDump(h)
    local c = 0
    cnp = TableCount(n.pairs.cells)
    cnt = TableCount(n.triplets.cells)
    cnq = TableCount(n.quads.cells)

    chp = TableCount(h.pairs.cells)
    cht = TableCount(h.triplets.cells)
    chq = TableCount(h.quads.cells)


    print(i, string.format("n %03d %03d %03d h %03d %03d %03d", cnp, cnt, cnq, chp, cht, chq))
    a[string.format("n %03d %03d %03d h %03d %03d %03d", cnp, cnt, cnq, chp, cht, chq)] = TableCopy(s.values)

    if (cnp > 0) and (cnt > 0) and (cnq > 0) and (chp > 0) and (cht > 0) and (chq > 0) then
        break
    end
end
]]

-- Call wx.wxGetApp():MainLoop() last to start the wxWidgets event loop,
-- otherwise the wxLua program will exit immediately.
-- Does nothing if running from wxLua, wxLuaFreeze, or wxLuaEdit since the
-- MainLoop is already running or will be started by the C++ program.
wx.wxGetApp():MainLoop()
