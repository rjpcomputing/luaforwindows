--- Additions to the string module
-- TODO: Pretty printing (use in getopt); see source for details.
module ("string", package.seeall)


-- Write pretty-printing based on:
--
--   John Hughes's and Simon Peyton Jones's Pretty Printer Combinators
--
--   Based on The Design of a Pretty-printing Library in Advanced
--   Functional Programming, Johan Jeuring and Erik Meijer (eds), LNCS 925
--   http://www.cs.chalmers.se/~rjmh/Papers/pretty.ps
--   Heavily modified by Simon Peyton Jones, Dec 96
--
--   Haskell types:
--   data Doc     list of lines
--   quote :: Char -> Char -> Doc -> Doc    Wrap document in ...
--   (<>) :: Doc -> Doc -> Doc              Beside
--   (<+>) :: Doc -> Doc -> Doc             Beside, separated by space
--   ($$) :: Doc -> Doc -> Doc              Above; if there is no overlap it "dovetails" the two
--   nest :: Int -> Doc -> Doc              Nested
--   punctuate :: Doc -> [Doc] -> [Doc]     punctuate p [d1, ... dn] = [d1 <> p, d2 <> p, ... dn-1 <> p, dn]
--   render      :: Int                     Line length
--               -> Float                   Ribbons per line
--               -> (TextDetails -> a -> a) What to do with text
--               -> a                       What to do at the end
--               -> Doc                     The document
--               -> a                       Result


--- Give strings a subscription operator.
-- @param s string
-- @param i index
-- @return <code>string.sub (s, i, i)</code> if i is a number, or
-- falls back to any previous metamethod (by default, string methods)
local old__index = getmetatable ("").__index
getmetatable ("").__index =
  function (s, i)
    if type (i) == "number" then
      return sub (s, i, i)
    -- Fall back to old metamethods
    elseif type (old__index) == "function" then
      return old__index (s, i)
    else
      return old__index[i]
    end
  end

--- Give strings an append metamethod.
-- @param s string
-- @param c character (1-character string)
-- @return <code>s .. c</code>
getmetatable ("").__append =
  function (s, c)
    return s .. c
  end

--- Capitalise each word in a string.
-- @param s string
-- @return capitalised string
function caps (s)
  return (gsub (s, "(%w)([%w]*)",
                function (l, ls)
                  return upper (l) .. ls
                end))
end

--- Remove any final newline from a string.
-- @param s string to process
-- @return processed string
function chomp (s)
  return (gsub (s, "\n$", ""))
end

--- Escape a string to be used as a pattern
-- @param s string to process
-- @return
--   @param s_: processed string
function escapePattern (s)
  return (gsub (s, "(%W)", "%%%1"))
end

-- Escape a string to be used as a shell token.
-- Quotes spaces, parentheses, brackets, quotes, apostrophes and
-- whitespace.
-- @param s string to process
-- @return processed string
function escapeShell (s)
  return (gsub (s, "([ %(%)%\\%[%]\"'])", "\\%1"))
end

--- Return the English suffix for an ordinal.
-- @param n number of the day
-- @return suffix
function ordinalSuffix (n)
  n = math.mod (n, 100)
  local d = math.mod (n, 10)
  if d == 1 and n ~= 11 then
    return "st"
  elseif d == 2 and n ~= 12 then
    return "nd"
  elseif d == 3 and n ~= 13 then
    return "rd"
  else
    return "th"
  end
end

--- Extend to work better with one argument.
-- If only one argument is passed, no formatting is attempted.
-- @param f format
-- @param ... arguments to format
-- @return formatted string
local _format = format
function format (f, arg1, ...)
  if arg1 == nil then
    return f
  else
    return _format (f, arg1, ...)
  end
end

--- Justify a string.
-- When the string is longer than w, it is truncated (left or right
-- according to the sign of w).
-- @param s string to justify
-- @param w width to justify to (-ve means right-justify; +ve means
-- left-justify)
-- @param p string to pad with (default: <code>" "</code>)
-- @return justified string
function pad (s, w, p)
  p = rep (p or " ", math.abs (w))
  if w < 0 then
    return sub (p .. s, w)
  end
  return sub (s .. p, 1, w)
end

--- Wrap a string into a paragraph.
-- @param s string to wrap
-- @param w width to wrap to (default: 78)
-- @param ind indent (default: 0)
-- @param ind1 indent of first line (default: ind)
-- @return wrapped paragraph
function wrap (s, w, ind, ind1)
  w = w or 78
  ind = ind or 0
  ind1 = ind1 or ind
  assert (ind1 < w and ind < w,
          "the indents must be less than the line width")
  s = rep (" ", ind1) .. s
  local lstart, len = 1, len (s)
  while len - lstart > w - ind do
    local i = lstart + w - ind
    while i > lstart and sub (s, i, i) ~= " " do
      i = i - 1
    end
    local j = i
    while j > lstart and sub (s, j, j) == " " do
      j = j - 1
    end
    s = sub (s, 1, j) .. "\n" .. rep (" ", ind) ..
      sub (s, i + 1, -1)
    local change = ind + 1 - (i - j)
    lstart = j + change
    len = len + change
  end
  return s
end

--- Write a number using SI suffixes.
-- The number is always written to 3 s.f.
-- @param n number
-- @return string
function numbertosi (n)
  local SIprefix = {
    [-8] = "y", [-7] = "z", [-6] = "a", [-5] = "f",
    [-4] = "p", [-3] = "n", [-2] = "mu", [-1] = "m",
    [0] = "", [1] = "k", [2] = "M", [3] = "G",
    [4] = "T", [5] = "P", [6] = "E", [7] = "Z",
    [8] = "Y"
  }
  local t = format("% #.2e", n)
  local _, _, m, e = t:find(".(.%...)e(.+)")
  local man, exp = tonumber (m), tonumber (e)
  local siexp = math.floor (exp / 3)
  local shift = exp - siexp * 3
  local s = SIprefix[siexp] or "e" .. tostring (siexp)
  man = man * (10 ^ shift)
  return tostring (man) .. s
end

--- Do find, returning captures as a list.
-- @param s target string
-- @param p pattern
-- @param init start position (default: 1)
-- @param plain inhibit magic characters (default: nil)
-- @return start of match, end of match, table of captures
function tfind (s, p, init, plain)
  local function pack (from, to, ...)
    return from, to, {...}
  end
  return pack (p.find (s, p, init, plain))
end

--- Do multiple <code>find</code>s on a string.
-- @param s target string
-- @param p pattern
-- @param init start position (default: 1)
-- @param plain inhibit magic characters (default: nil)
-- @return list of <code>{from, to; capt = {captures}}</code>
function finds (s, p, init, plain)
  init = init or 1
  local l = {}
  local from, to, r
  repeat
    from, to, r = tfind (s, p, init, plain)
    if from ~= nil then
      table.insert (l, {from, to, capt = r})
      init = to + 1
    end
  until not from
  return l
end

--- Perform multiple calls to gsub.
-- @param s string to call gsub on
-- @param sub <code>{pattern1=replacement1 ...}</code>
-- @param n upper limit on replacements (default: infinite)
-- @return result string
-- @return number of replacements made
function gsubs (s, sub, n)
  local r = 0
  for i, v in pairs (sub) do
    local rep
    if n ~= nil then
      s, rep = gsub (s, i, v, n)
      r = r + rep
      n = n - rep
      if n == 0 then
        break
      end
    else
      s, rep = i.gsub (s, i, v)
      r = r + rep
    end
  end
  return s, r
end

--- Split a string at a given separator.
-- FIXME: Consider Perl and Python versions.
-- @param s string to split
-- @param sep separator regex
-- @return list of strings
function split (s, sep)
  -- finds gets a list of {from, to, capt = {}} lists; we then
  -- flatten the result, discarding the captures, and prepend 0 (1
  -- before the first character) and append 0 (1 after the last
  -- character), and then read off the result in pairs.
  local pairs = list.concat ({0}, list.flatten (finds (s, sep)), {0})
  local l = {}
  for i = 1, #pairs, 2 do
    table.insert (l, sub (s, pairs[i] + 1, pairs[i + 1] - 1))
  end
  return l
end

--- Remove leading matter from a string.
-- @param s string
-- @param r leading regex (default: <code>"%s+"</code>)
-- @return string without leading r
function ltrim (s, r)
  r = r or "%s+"
  return (gsub (s, "^" .. r, ""))
end

--- Remove trailing matter from a string.
-- @param s string
-- @param r trailing regex (default: <code>"%s+"</code>)
-- @return string without trailing r
function rtrim (s, r)
  r = r or "%s+"
  return (gsub (s, r .. "$", ""))
end

--- Remove leading and trailing matter from a string.
-- @param s string
-- @param r leading/trailing regex (default: <code>"%s+"</code>)
-- @return string without leading/trailing r
function trim (s, r)
  return rtrim (ltrim (s, r), r)
end
