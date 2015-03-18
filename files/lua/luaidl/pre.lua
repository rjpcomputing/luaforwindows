--
-- Project:  LuaIDL
-- Version:  0.8.9b
-- Author:   Ricardo Cosme <rcosme@tecgraf.puc-rio.br>
-- Filename: pre.lua
--

local error  = error
local io     = require "io"
local os     = require "os"
local ipairs = ipairs
local pairs  = pairs
local string = require "string"
local table  = require "table"
local type   = type

module 'luaidl.pre'


local tab_macros
local currNumLine
local currFilename
local READ
local homedir
local incpath
local tab_options

local _run

local function newStack ()
  return{""}
end

local function addString (stack, s)
  table.insert(stack, s)
  for i=table.getn(stack)-1, 1, -1 do
    if string.len(stack[i]) > string.len(stack[i+1]) then
      break
    end
    stack[i] = stack[i] .. table.remove(stack)
  end
end

local function processDirective(...)
  local directive = arg[ 1 ]
  if ( directive == 'endif' ) then
    READ = true
    return ''
  end --if
  if ( READ ) then
    if ( directive == 'define' ) then
      local macro = arg[ 2 ]
      local value = arg[ 3 ]
      tab_macros[ macro ] = value
    elseif ( directive == 'include' ) then
      local incFilename = string.sub( arg[ 2 ], 2, -2 )
      local path = homedir..incFilename
      local fh, msg = io.open( path )
      if not fh then
        for _, v in ipairs( incpath ) do
          path = v..'/'..incFilename
          fh, msg = io.open( path )
          if fh then
            break
          end --if
        end --for
      end --if
      if not fh then
        error( msg, 2 )
      end --if
      local incSource = fh:read( '*a' )
      local incENDNumLine = currNumLine + 1
      local OUTFilename = currFilename
      incSource = _run( incSource, tab_options )
      return string.format( '# %d "%s" 1\n%s# %d "%s" 2\n',
                            1, path,
                            incSource,
                            incENDNumLine, OUTFilename
                          )
    elseif ( directive == 'ifndef' ) then
      local macro = arg[ 2 ]
      if ( tab_macros[ macro ] ) then
        READ = false
      end --if
    else
      return '#'..table.concat( arg, ' ' )
    end --if
  end --if
  return ''
end

local function macroExpansion( str )
  for name, value in pairs( tab_macros ) do
    str = string.gsub( str, '([^%w])'..name..'([^%w])', '%1'..value..'%2' )
  end --for
  return str
end

function _run( source, ptab_options )
  local output = newStack()
  local numLine
  if ( not homedir ) then
    addString( output, string.format( '# 1 "%s"\n', currFilename ) )
    homedir, numLine = string.gsub( currFilename, '(.*/).*', '%1' )
    if ( numLine == 0 ) then
      homedir = ''
    end --if
  end --if
  numLine = 1
  -- ugly!
  source = source..'\n'
  for strLine in string.gfind( source, "(.-\n)" ) do
    strLine = string.gsub( strLine, '^%s*#%s*(%w+)%s*([^%s]*)%s*([^%s]*)', processDirective )
    if ( READ ) then
      strLine = macroExpansion( strLine )
      addString( output, strLine )
    end --if
    numLine = numLine + 1
    currNumLine = numLine
  end --for
  return table.concat( output )
end

function run( source, ptab_options )
  tab_macros = { }
  currNumLine = 1
  currFilename = nil
  READ = true
  homedir = nil
  incpath = nil
  tab_options = ptab_options
  if tab_options then
    if tab_options.filename then
      currFilename = tab_options.filename
      if type(currFilename) ~= 'string' then
        error( 'Invalid filename', 2 )
      end --if
    end --if
    if tab_options.incpath then
      incpath = tab_options.incpath
      if type( incpath ) ~= 'table' then
        error( "'incpath' must be a table", 2 )
      end --if
    end --if
  end
  if not currFilename then
    currFilename = ''
  end --if
  if not incpath then
    incpath = { }
  end --if
  return _run( source, tab_options )
end
