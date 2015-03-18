--- Additions to the io module
module ("io", package.seeall)

require "base"
require "package_ext"


-- Get file handle metatable
local file_metatable = getmetatable (io.stdin)


--- Read a file into a list of lines and close it.
-- @param h file handle or name (default: <code>io.input ()</code>)
-- @return list of lines
function readlines (h)
  if h == nil then
    h = input ()
  elseif _G.type (h) == "string" then
    h = io.open (h)
  end
  local l = {}
  for line in h:lines () do
    table.insert (l, line)
  end
  h:close ()
  return l
end
file_metatable.readlines = readlines

--- Write values adding a newline after each.
-- @param h file handle (default: <code>io.output ()</code>
-- @param ... values to write (as for write)
function writeline (h, ...)
  if io.type (h) ~= "file" then
    io.write (h, "\n")
    h = io.output ()
  end
  for _, v in ipairs ({...}) do
    h:write (v, "\n")
  end
end
file_metatable.writeline = writeline

--- Split a directory path into components.
-- Empty components are retained: the root directory becomes <code>{"", ""}</code>.
-- @param path path
-- @return list of path components
function splitdir (path)
  return string.split (path, package.dirsep)
end

--- Concatenate one or more directories and a filename into a path.
-- @param ... path components
-- @return path
function catfile (...)
  return table.concat ({...}, package.dirsep)
end

--- Concatenate two or more directories into a path, removing the trailing slash.
-- @param ... path components
-- @return path
function catdir (...)
  return (string.gsub (catfile (...), "^$", package.dirsep))
end

--- Perform a shell command and return its output.
-- @param c command
-- @return output, or nil if error
function shell (c)
  local h = io.popen (c)
  local o
  if h then
    o = h:read ("*a")
    h:close ()
  end
  return o
end

--- Process files specified on the command-line.
-- If no files given, process <code>io.stdin</code>; in list of files,
-- <code>-</code> means <code>io.stdin</code>.
-- <br>FIXME: Make the file list an argument to the function.
-- @param f function to process files with, which is passed
-- <code>(name, arg_no)</code>
function processFiles (f)
  -- N.B. "arg" below refers to the global array of command-line args
  if #arg == 0 then
    table.insert (arg, "-")
  end
  for i, v in ipairs (arg) do
    if v == "-" then
      io.input (io.stdin)
    else
      io.input (v)
    end
    prog.file = v
    f (v, i)
  end
end
