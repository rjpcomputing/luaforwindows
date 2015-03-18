--
-- Project:  LuaIDL
-- Version:  0.8.9b
-- Author:   Ricardo Cosme <rcosme@tecgraf.puc-rio.br>
-- Filename: lex.lua
--

local type     = type
local pairs    = pairs
local tonumber = tonumber
local error    = error
local ipairs   = ipairs
local table    = table
local string   = require "string"

module 'luaidl.lex'

tab_tokens = { TK_ID = 257, TK_ABSTRACT = 258, TK_ANY = 259, TK_ATTRIBUTE = 260,
              TK_BOOLEAN = 261, TK_CASE = 262, TK_CHAR = 263, TK_COMPONENT = 264,
              TK_CONST = 265, TK_CONSUMES = 266, TK_CONTEXT = 267, TK_CUSTOM = 268,
              TK_DEFAULT = 269, TK_DOUBLE = 270, TK_EXCEPTION = 271, TK_EMITS = 272,
              TK_ENUM = 273, TK_EVENTTYPE = 274, TK_FACTORY = 275, TK_FALSE = 276,
              TK_FINDER = 277, TK_FIXED = 278, TK_FLOAT = 279, TK_GETRAISES = 280,
              TK_HOME = 281, TK_IMPORT = 282, TK_IN = 283, TK_INOUT = 284,
              TK_INTERFACE = 285, TK_LOCAL = 286, TK_LONG = 287, TK_MODULE = 288,
              TK_MULTIPLE = 289, TK_NATIVE = 290, TK_OBJECT = 291, TK_OCTET = 292,
              TK_ONEWAY = 293, TK_OUT = 294, TK_PRIMARYKEY = 295, TK_PRIVATE = 296,
              TK_PROVIDES = 297, TK_PUBLIC = 298, TK_PUBLISHES = 299, TK_RAISES = 300,
              TK_READONLY = 301, TK_SETRAISES = 302, TK_SEQUENCE = 303, TK_SHORT = 304,
              TK_STRING = 305, TK_STRUCT = 306, TK_SUPPORTS = 307, TK_SWITCH = 308,
              TK_TRUE = 309, TK_TRUNCATABLE = 310, TK_TYPEDEF = 311, TK_TYPEID = 312,
              TK_TYPEPREFIX = 313, TK_UNSIGNED = 314, TK_UNION = 315, TK_USES = 316,
              TK_VALUEBASE = 317, TK_VALUETYPE = 318, TK_VOID = 319, TK_WCHAR = 320,
              TK_WSTRING = 321, TK_INTEGER_LITERAL = 322, TK_FLOAT_LITERAL = 323,
              TK_CHAR_LITERAL = 324, TK_WCHAR_LITERAL = 325, TK_STRING_LITERAL = 326,
              TK_WSTRING_LITERAL = 327, TK_FIXED_LITERAL = 328, TK_PRAGMA_PREFIX = 329,
              TK_PRAGMA_ID = 330, TK_MANAGES = 332,
             }

local tab_keywords = {
                ['abstract']      = { token = tab_tokens.TK_ABSTRACT },
                ['any']           = { token = tab_tokens.TK_ANY },
                ['attribute']     = { token = tab_tokens.TK_ATTRIBUTE },
                ['boolean']       = { token = tab_tokens.TK_BOOLEAN },
                ['case']          = { token = tab_tokens.TK_CASE },
                ['char']          = { token = tab_tokens.TK_CHAR },
                ['component']     = { token = tab_tokens.TK_COMPONENT },
                ['const']         = { token = tab_tokens.TK_CONST },
                ['consumes']      = { token = tab_tokens.TK_CONSUMES },
                ['context']       = { token = tab_tokens.TK_CONTEXT },
                ['custom']        = { token = tab_tokens.TK_CUSTOM },
                ['default']       = { token = tab_tokens.TK_DEFAULT },
                ['double']        = { token = tab_tokens.TK_DOUBLE },
                ['exception']     = { token = tab_tokens.TK_EXCEPTION },
                ['emits']         = { token = tab_tokens.TK_EMITS },
                ['enum']          = { token = tab_tokens.TK_ENUM },
                ['eventtype']     = { token = tab_tokens.TK_EVENTTYPE },
                ['factory']       = { token = tab_tokens.TK_FACTORY },
                ['FALSE']         = { token = tab_tokens.TK_FALSE },
                ['finder']        = { token = tab_tokens.TK_FINDER },
                ['fixed']         = { token = tab_tokens.TK_FIXED },
                ['float']         = { token = tab_tokens.TK_FLOAT },
                ['getraises']     = { token = tab_tokens.TK_GETRAISES },
                ['home']          = { token = tab_tokens.TK_HOME },
                ['import']        = { token = tab_tokens.TK_IMPORT },
                ['in']            = { token = tab_tokens.TK_IN },
                ['inout']         = { token = tab_tokens.TK_INOUT },
                ['interface']     = { token = tab_tokens.TK_INTERFACE },
                ['local']         = { token = tab_tokens.TK_LOCAL },
                ['long']          = { token = tab_tokens.TK_LONG },
                ['manages']       = { token = tab_tokens.TK_MANAGES },
                ['module']        = { token = tab_tokens.TK_MODULE },
                ['multiple']      = { token = tab_tokens.TK_MULTIPLE },
                ['native']        = { token = tab_tokens.TK_NATIVE },
                ['Object']        = { token = tab_tokens.TK_OBJECT },
                ['octet']         = { token = tab_tokens.TK_OCTET },
                ['oneway']        = { token = tab_tokens.TK_ONEWAY },
                ['out']           = { token = tab_tokens.TK_OUT },
                ['primarykey']    = { token = tab_tokens.TK_PRIMARYKEY },
                ['private']       = { token = tab_tokens.TK_PRIVATE },
                ['provides']      = { token = tab_tokens.TK_PROVIDES },
                ['public']        = { token = tab_tokens.TK_PUBLIC },
                ['publishes']     = { token = tab_tokens.TK_PUBLISHES },
                ['raises']        = { token = tab_tokens.TK_RAISES },
                ['readonly']      = { token = tab_tokens.TK_READONLY },
                ['setraises']     = { token = tab_tokens.TK_SETRAISES },
                ['sequence']      = { token = tab_tokens.TK_SEQUENCE },
                ['short']         = { token = tab_tokens.TK_SHORT },
                ['string']        = { token = tab_tokens.TK_STRING },
                ['struct']        = { token = tab_tokens.TK_STRUCT },
                ['supports']      = { token = tab_tokens.TK_SUPPORTS },
                ['switch']        = { token = tab_tokens.TK_SWITCH },
                ['TRUE']          = { token = tab_tokens.TK_TRUE },
                ['truncatable']   = { token = tab_tokens.TK_TRUNCATABLE },
                ['typedef']       = { token = tab_tokens.TK_TYPEDEF },
                ['typeid']        = { token = tab_tokens.TK_TYPEID },
                ['typeprefix']    = { token = tab_tokens.TK_TYPEPREFIX },
                ['unsigned']      = { token = tab_tokens.TK_UNSIGNED },
                ['union']         = { token = tab_tokens.TK_UNION },
                ['uses']          = { token = tab_tokens.TK_USES },
                ['ValueBase']     = { token = tab_tokens.TK_VALUEBASE },
                ['valuetype']     = { token = tab_tokens.TK_VALUETYPE },
                ['void']          = { token = tab_tokens.TK_VOID },
                ['wchar']         = { token = tab_tokens.TK_WCHAR },
                ['wstring']       = { token = tab_tokens.TK_WSTRING },
              }

local tab_symbols

PRAGMA_VERSION    = '1.0'
ERROR_MSG_TYPE    = '[lexical error]:_LINE:_ERRORMSG.'

local token
local lookahead
local i
local stridllen
local linemarkDeclared

local function is_blank( char )
  if ( lookahead == ' ' or lookahead == '\f' or lookahead == '\r' or
       lookahead == '\t' or lookahead == '\v' ) then
    return true
  else
    return false
  end
end

local function is_digit( char )
  return string.find(char , '%d')
end

local function is_hex_digit( char )
  return string.find(char , '%x')
end

local function is_octal_digit( char )
  return string.find(char , '[0-7]')
end

local function is_alpha( char )
  return string.find(char , '%w')
end

local function is_near_value( lookahead )
  if string.find(lookahead , '%w') then
    return ' near \''..lookahead..'\''
  else
    return ''
  end
end

local function insert_symbols( lexeme )
  tab_symbols[lexeme] = {token = tab_tokens.TK_ID ,descriptions = {}}
end

local function search_symbols( lexeme , tab_symbols )
  if tab_symbols[lexeme] then
    return lexeme ,tab_symbols[lexeme].token
  else
    for key, value in pairs(tab_symbols) do
      if string.upper(lexeme) == string.upper(key) then
        return key ,'collide'
      end
    end
  end
  return nil ,nil
end

local function search_symbols_wocollide( lexeme , tab_symbols )
  if tab_symbols[lexeme] then
    return lexeme ,tab_symbols[lexeme].token
  else
    for key, value in pairs(tab_symbols) do
--      if string.upper( lexeme ) == string.upper( key ) then
--        return key , 'collide'
--      end
    end
  end
  return nil ,nil
end

local function error_lex( error_msg )
  if (type(ERROR_MSG_TYPE) ~= 'string') then
    error('bad value to \'error_msg_type\' variable (string expected)' ,2)
  end
  init()
  local _LINE =  line
  error( string.gsub( string.gsub( ERROR_MSG_TYPE , '_LINE' , _LINE) ,
         '_ERRORMSG' , error_msg ) , 3 )
end

function get_constructor ( symbol_name )
  if tab_symbols[symbol_name] then
    return tab_symbols[symbol_name].descriptions
  else
    return nil
  end
end

function set_constructor ( symbol_name , field_name , value )
  for k , v in ipairs(tab_symbols) do
    if (v.lexeme == symbol_name) then
      v.descriptions[field_name] = value
    end
  end
  return nil
end

local function lineCount()
  line = line + 1
end

local function getchar(stridl)
  if (i > stridllen) then
    return nil
  else
    local c =  string.sub(stridl, i, i)
    i = i + 1
    prevtokenvalue = tokenvalue_previous
    return c
  end
end

function init()
  tab_symbols           = { }
  token                 = nil
  tokenvalue            = '<EOF>'
  tokenvalue_previous   = '<EOF>'
  line                  = 1
  srcfilename           = ''
  tab_linemarks         = { }
  lookahead             = ' '
  i                     = 1
  stridllen             = nil
end

function lexer(stridl)
  if not stridllen then
    init()
    stridllen = string.len(stridl)
  end

  while true do
    tokenvalue_previous = tokenvalue

    if not lookahead then
      init()
      token = nil
      return token
    elseif (lookahead == '#') then
      lookahead = getchar(stridl)
    -- C preprocessor
    -- # <linenum> "<filename>" <flags>*
      if (lookahead == ' ') then
        linemarkDeclared = true
      -- linenum
        local linenum = getchar(stridl)
        lookahead = getchar(stridl)
        while is_digit(lookahead) do
          linenum = linenum..lookahead
          lookahead = getchar(stridl)
        end
        line = tonumber(linenum)
      -- filename
      -- '"' char
        local _ = getchar(stridl)
        local filename = ''
        lookahead = getchar(stridl)
        while (lookahead ~= '"') do
          filename = filename..lookahead
          lookahead = getchar(stridl)
        end
        srcfilename = filename
        lookahead = getchar(stridl)
      -- flags
        local flags = { }
        while (lookahead == ' ') do
          lookahead = getchar(stridl)
          if is_digit(lookahead) then
            flags[lookahead] = true
          end
          lookahead = getchar(stridl)
        end
        table.insert(tab_linemarks, flags)
    -- pragma declarations
      elseif (lookahead == 'p') then
        lookahead = getchar(stridl)
        if (lookahead == 'r') then
          lookahead = getchar(stridl)
          if (lookahead == 'a') then
            lookahead = getchar(stridl)
            if (lookahead == 'g') then
              lookahead = getchar(stridl)
              if (lookahead == 'm') then
                lookahead = getchar(stridl)
                if (lookahead == 'a') then
                  lookahead = getchar(stridl)
                  if is_blank(lookahead) then
                    lookahead = getchar(stridl)
                  end
                -- pragma prefix
                  if (lookahead == 'p') then
                    lookahead = getchar(stridl)
                    if (lookahead == 'r') then
                      lookahead = getchar(stridl)
                      if (lookahead == 'e') then
                        lookahead = getchar(stridl)
                        if (lookahead == 'f') then
                          lookahead = getchar(stridl)
                          if (lookahead == 'i') then
                            lookahead = getchar(stridl)
                            if (lookahead == 'x') then
                              lookahead = getchar(stridl)
                              token = tab_tokens.TK_PRAGMA_PREFIX
                              return token
                            end
                          end
                        end
                      end
                    end
                -- pragma ID
                  elseif (lookahead == 'I') then
                    lookahead = getchar(stridl)
                    if (lookahead == 'D') then
                      lookahead = getchar(stridl)
                      token = tab_tokens.TK_PRAGMA_ID
                      return token
                    end
                  end
                end
              end
            end
          end
        end
      end
  -- new lines
    elseif (lookahead == '\n') then
    -- We does not consider linemark declarations to line counts.
      if not linemarkDeclared then
        lineCount()
      else
        linemarkDeclared = false
      end
      lookahead = getchar(stridl)
  -- blank characters
    elseif is_blank(lookahead) then
      lookahead = getchar(stridl)
  -- comments
    elseif (lookahead == '/') then
      lookahead = getchar(stridl)
      if (lookahead == '/') then
        while (lookahead ~= '\n') do
          lookahead = getchar(stridl)
        end
        lineCount()
        lookahead = getchar(stridl)
      elseif (lookahead == '*') then
        local first_line = line
        lookahead = getchar(stridl)
        while true do
          if (lookahead == '\n') then
            lookahead = getchar(stridl)
            lineCount()
          elseif not lookahead then
          -- where begin nonterminated comment ?
            line = first_line
            error_lex('nonterminated comment')
          elseif (lookahead == '*') then
             lookahead = getchar(stridl)
             if (lookahead == '/') then
               break
             end
          else
             lookahead = getchar(stridl)
          end
        end
        lookahead = getchar(stridl)
      else
        tokenvalue = '/'
        token = tokenvalue
        return token
      end
  -- floating-point literals
  -- fixed-point literals
    elseif (lookahead == '.') then
      tokenvalue = '.'
      lookahead = getchar(stridl)
      if is_digit(lookahead) then
        tokenvalue = tokenvalue..lookahead
        lookahead = getchar(stridl)
        while is_digit(lookahead) do
          tokenvalue = tokenvalue..lookahead
          lookahead  = getchar()
        end
        if (lookahead == 'e' or lookahead == 'E') then
          tokenvalue = tokenvalue..lookahead
          lookahead = getchar(stridl)
          if (lookahead == '-') then
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
            if not is_digit(lookahead) then
              error_lex('malformed number'..is_near_value(tokenvalue))
            else
              tokenvalue = tokenvalue..lookahead
              lookahead = getchar(stridl)
              while is_digit(lookahead) do
                tokenvalue = tokenvalue..lookahead
                lookahead = getchar(stridl)
              end
            end
          elseif is_digit(lookahead) then
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
            while is_digit(lookahead) do
              tokenvalue = tokenvalue..lookahead
              lookahead = getchar(stridl)
            end
          else
            error_lex('malformed number'..is_near_value(tokenvalue))
          end
          tokenvalue = tonumber(tokenvalue ,10)
          token = tab_tokens.TK_FLOAT_LITERAL
          return token
        elseif (lookahead == 'd' or lookahead == 'D') then
          tokenvalue = tonumber(tokenvalue ,10)
          lookahead = getchar(stridl)
          token = tab_tokens.TK_FIXED_LITERAL
          return token
        else
          tokenvalue = tonumber(tokenvalue ,10)
          token = tab_tokens.TK_FLOAT_LITERAL
          return token
        end
      else
        tokenvalue = '.'
        token = tokenvalue
        return token
      end
  -- integer literal (decimal)
  -- integer literal (hexa)
  -- integer literal (octal)
  -- floating-point literals
  -- fixed-point literals
    elseif (lookahead == '0') then
      tokenvalue = '0'
      lookahead = getchar(stridl)
      if (lookahead == 'x' or lookahead == 'X') then
        tokenvalue = tokenvalue..lookahead
        lookahead = getchar(stridl)
        while is_hex_digit(lookahead) do
          tokenvalue = tokenvalue..lookahead
          lookahead = getchar(stridl)
        end
        tokenvalue = tonumber(tokenvalue ,10)
        token = tab_tokens.TK_INTEGER_LITERAL
        return token
      end
      while is_digit(lookahead) do
        tokenvalue = tokenvalue..lookahead
        lookahead = getchar(stridl)
      end
      if (lookahead == '.' or lookahead == 'e' or lookahead == 'E' or
          lookahead == 'd' or lookahead == 'd')
      then
        if (lookahead == '.') then
          tokenvalue = tokenvalue..'.'
          lookahead = getchar(stridl)
          if is_digit(lookahead) then
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
            while is_digit(lookahead) do
              tokenvalue = tokenvalue..lookahead
              lookahead = getchar(stridl)
            end
          end
        end
        if (lookahead == 'e' or lookahead == 'E') then
          tokenvalue = tokenvalue..lookahead
          lookahead = getchar(stridl)
          if (lookahead == '-') then
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
            if not is_digit(lookahead) then
              error_lex('malformed number near'..is_near_value(tokenvalue))
            else
              tokenvalue = tokenvalue..lookahead
              lookahead = getchar(stridl)
              while is_digit(lookahead) do
                tokenvalue = tokenvalue..lookahead
                lookahead = getchar(stridl)
              end
            end
          elseif is_digit(lookahead) then
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
            while is_digit(lookahead) do
              tokenvalue = tokenvalue..lookahead
              lookahead = getchar(stridl)
            end
          else
            error_lex('malformed number near'..is_near_value(tokenvalue))
          end
          tokenvalue = tonumber(tokenvalue ,10)
          token = tab_tokens.TK_FLOAT_LITERAL
          return token
        elseif (lookahead == 'd' or lookahead == 'D') then
          tokenvalue = tonumber(tokenvalue ,10)
          lookahead = getchar(stridl)
          token = tab_tokens.TK_FIXED_LITERAL
          return token
        else
          tokenvalue = tonumber(tokenvalue ,10)
          token = tab_tokens.TK_FLOAT_LITERAL
          return token
        end
      else
        if not (string.find(tokenvalue ,'8') or string.find(tokenvalue ,'9')) then
          tokenvalue = tonumber(tokenvalue ,8)
        end
        token = tab_tokens.TK_INTEGER_LITERAL
        return token
      end
  -- integer literal (decimal)
  -- floating-point literals
  -- fixed-point literals
    elseif is_digit(lookahead) then
      tokenvalue = lookahead
      lookahead = getchar(stridl)
      while is_digit(lookahead) do
        tokenvalue = tokenvalue..lookahead
        lookahead = getchar(stridl)
      end
      if (lookahead == '.' or lookahead == 'e' or lookahead == 'E' or
          lookahead == 'd' or lookahead == 'd')
      then
        if (lookahead == '.') then
          tokenvalue = tokenvalue..'.'
          lookahead = getchar(stridl)
          if is_digit(lookahead) then
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
            while is_digit(lookahead) do
              tokenvalue = tokenvalue..lookahead
              lookahead = getchar(stridl)
            end
          end
        end
        if (lookahead == 'e' or lookahead == 'E') then
          tokenvalue = tokenvalue..lookahead
          lookahead = getchar( stridl )
          if (lookahead == '-') then
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
            if not is_digit(lookahead) then
              error_lex('malformed number near'..is_near_value(tokenvalue))
            else
              tokenvalue = tokenvalue..lookahead
              lookahead = getchar(stridl)
              while is_digit(lookahead) do
                tokenvalue = tokenvalue..lookahead
                lookahead = getchar(stridl)
              end
            end
          elseif is_digit(lookahead) then
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
            while is_digit(lookahead) do
              tokenvalue = tokenvalue..lookahead
              lookahead = getchar(stridl)
            end
          else
            error_lex('malformed number near'..is_near_value(tokenvalue))
          end
          tokenvalue = tonumber(tokenvalue ,10)
          token = tab_tokens.TK_FLOAT_LITERAL
          return token
        elseif (lookahead == 'd' or lookahead == 'D') then
          tokenvalue = tonumber(tokenvalue ,10)
          lookahead = getchar(stridl)
          token = tab_tokens.TK_FIXED_LITERAL
          return token
        else
          tokenvalue = tonumber(tokenvalue ,10)
          token = tab_tokens.TK_FLOAT_LITERAL
          return token
        end
      else
        token = tab_tokens.TK_INTEGER_LITERAL
        return token
      end
  -- char literal
  -- "The value of a null is 0" ????
    elseif (lookahead == '\'') then
      tokenvalue = ''
      lookahead = getchar(stridl)
      if (lookahead == '\\') then
        lookahead = getchar(stridl)
        if (lookahead == 'n') then
          tokenvalue = tokenvalue..'\n'
          lookahead = getchar(stridl)
        elseif (lookahead == 't') then
          tokenvalue = tokenvalue..'\t'
          lookahead = getchar(stridl)
        elseif (lookahead == 'v') then
          tokenvalue = tokenvalue..'\v'
          lookahead = getchar(stridl)
        elseif (lookahead == 'b') then
          tokenvalue = tokenvalue..'\b'
          lookahead = getchar(stridl)
        elseif (lookahead == 'r') then
          tokenvalue = tokenvalue..'\r'
          lookahead = getchar(stridl)
        elseif (lookahead == 'f') then
          tokenvalue = tokenvalue..'\f'
          lookahead = getchar(stridl)
        elseif (lookahead == 'a') then
          tokenvalue = tokenvalue..'\a'
          lookahead = getchar(stridl)
        elseif (lookahead == '\\') then
          tokenvalue = tokenvalue..'\\'
          lookahead = getchar(stridl)
        elseif (lookahead == '?') then
          tokenvalue = tokenvalue..'?'
          lookahead = getchar(stridl)
        elseif (lookahead == '\'') then
          tokenvalue = tokenvalue..'\''
          lookahead = getchar(stridl)
        elseif (lookahead == '"') then
          tokenvalue = tokenvalue..'"'
          lookahead = getchar(stridl)
        elseif is_octal_digit(lookahead) then
          local num_digits = 1
          local tokenvalue_tmp = lookahead
          lookahead = getchar(stridl)
          while is_octal_digit(lookahead) do
            tokenvalue_tmp = tokenvalue_tmp..lookahead
            lookahead = getchar(stridl)
            num_digits = num_digits + 1
            if (num_digits == 3) then
              lookahed = getchar(stridl)
              break
            end
          end
          tokenvalue = tokenvalue..string.char(tonumber(tokenvalue_tmp ,8))
        elseif (lookahead == 'x') then
          local tokenvalue_tmp = '0x'
          lookahead = getchar(stridl)
          if is_hex_digit(lookahead) then
            tokenvalue_tmp = tokenvalue_tmp..lookahead
            lookahead = getchar(stridl)
            if is_hex_digit(lookahead) then
              tokenvalue_tmp = tokenvalue_tmp..lookahead
              lookahead = getchar(stridl)
            end
          end
          tokenvalue = tokenvalue..string.char(tonumber(tokenvalue_tmp ,10))
        elseif (lookahead == 'u') then
          error_lex('it doest not permited unicode characters in char type')
        else
        -- When occur an unknown escape sequence, then we apply a common
        -- behavior that is to return a proper character. Ex.: '\e' -> e
          tokenvalue = tokenvalue..lookahead
          lookahead = getchar(stridl)
        end
      elseif (lookahead ~= '\'') then
        tokenvalue = lookahead
        lookahead = getchar(stridl)
      end
      if (lookahead ~= '\'') then
        if not lookahead then
          error_lex('"\'" expected near \'<eof>\'')
        else
          error_lex('"\'" expected'..is_near_value(tokenvalue))
        end
      end
      lookahead = getchar(stridl)
      token = tab_tokens.TK_CHAR_LITERAL
      return token
  -- string literal
    elseif (lookahead == '"') then
      lookahead = getchar(stridl)
      tokenvalue = ''
      while true do
        if (lookahead == '\\') then
          lookahead = getchar(stridl)
          if (lookahead == 'n') then
            tokenvalue = tokenvalue..'\n'
            lookahead = getchar(stridl)
          elseif (lookahead == 't') then
            tokenvalue = tokenvalue..'\t'
            lookahead = getchar(stridl)
          elseif (lookahead == 'v') then
            tokenvalue = tokenvalue..'\v'
            lookahead = getchar(stridl)
          elseif (lookahead == 'b') then
            tokenvalue = tokenvalue..'\b'
            lookahead = getchar(stridl)
          elseif (lookahead == 'r') then
            tokenvalue = tokenvalue..'\r'
            lookahead = getchar(stridl)
          elseif (lookahead == 'f') then
            tokenvalue = tokenvalue..'\f'
            lookahead = getchar(stridl)
          elseif (lookahead == 'a') then
            tokenvalue = tokenvalue..'\a'
            lookahead = getchar(stridl)
          elseif (lookahead == '\\') then
            tokenvalue = tokenvalue..'\\'
            lookahead = getchar(stridl)
          elseif (lookahead == '?') then
            tokenvalue = tokenvalue..'?'
            lookahead = getchar( stridl )
          elseif (lookahead == '\'') then
            tokenvalue = tokenvalue..'\''
            lookahead = getchar(stridl)
          elseif (lookahead == '"') then
            tokenvalue = tokenvalue..'"'
            lookahead = getchar(stridl)
          elseif is_octal_digit(lookahead) then
            local num_digits = 1
            local tokenvalue_tmp = lookahead
            lookahead = getchar(stridl)
            while is_octal_digit(lookahead) do
              tokenvalue_tmp = tokenvalue_tmp..lookahead
              lookahead = getchar(stridl)
              num_digits = num_digits + 1
              if (num_digits == 3) then
                lookahed = getchar(stridl)
                break
              end
            end
            tokenvalue = tokenvalue..string.char(tonumber(tokenvalue_tmp ,8))
          elseif (lookahead == 'x') then
            local tokenvalue_tmp = '0x'
            lookahead = getchar(stridl)
            if is_hex_digit(lookahead) then
              tokenvalue_tmp = tokenvalue_tmp..lookahead
              lookahead = getchar(stridl)
              if is_hex_digit(lookahead) then
                tokenvalue_tmp = tokenvalue_tmp..lookahead
                lookahead = getchar(stridl)
              end
            end
            tokenvalue = tokenvalue..string.char(tonumber(tokenvalue_tmp , 10))
          elseif (lookahead == 'u') then
            error_lex('it doest not permited unicode characters in char type')
          else
          -- When occur an unknown escape sequence, then we apply a common
          -- behavior that is to return a proper character. Ex.: '\e' -> e
            tokenvalue = tokenvalue..lookahead
            lookahead = getchar(stridl)
          end
        elseif (lookahead == '"') then
          break
        elseif not lookahead then
          error_lex('nonterminated string')
        else
          tokenvalue = tokenvalue..lookahead
          lookahead = getchar(stridl)
        end
      end
      lookahead = getchar(stridl)
      token = tab_tokens.TK_STRING_LITERAL
      return token
  -- identifiers
  -- keywords
    elseif is_alpha(lookahead) or (lookahead == '_') then
      local lexbuf = lookahead
      lookahead = getchar(stridl)
      while is_alpha(lookahead) or (lookahead == '_') or is_digit(lookahead) do
        lexbuf = lexbuf..lookahead
        lookahead = getchar(stridl)
      end
      if (string.sub(lexbuf ,1 ,1) ~= '_') then
        tokenvalue, tk = search_symbols(lexbuf , tab_keywords)
        if tk == "collide" then
          error_lex("'"..lexbuf.."' collides with keyword '"..tokenvalue.."'")
        elseif tk then
          token = tk
          return token
        end
      else
        lexbuf = string.sub(lexbuf ,2)
      end
      tokenvalue, token = search_symbols_wocollide(lexbuf ,tab_symbols)
--      if token == "collide" then
--        error_lex( "'"..lexbuf.."' and '"..tokenvalue.."' collide" )
      if not token then
        insert_symbols(lexbuf)
        tokenvalue = lexbuf
      end
      token = tab_tokens.TK_ID
      return token
  -- operators and other characters
    else
      tokenvalue = lookahead
      lookahead = getchar(stridl)
      token = tokenvalue
      return token
    end
  end
end
