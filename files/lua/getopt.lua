--- Simplified getopt, based on Svenne Panne's Haskell GetOpt.<br>
-- Usage:
-- <ul>
-- <li><code>options = Options {Option {...} ...}</br>
-- getopt.processArgs ()</code></li>
-- <li>Assumes <code>prog = {name[, banner] [, purpose] [, notes] [, usage]}</code></li>
-- <li>Options take a single dash, but may have a double dash.</li>
-- <li>Arguments may be given as <code>-opt=arg</code> or <code>-opt arg</code>.</li>
-- <li>If an option taking an argument is given multiple times, only the
-- last value is returned; missing arguments are returned as 1.</li>
-- </ul>
-- getOpt, usageInfo and usage can be called directly (see
-- below, and the example at the end). Set _DEBUG.std to a non-nil
-- value to run the example.
-- <ul>
-- <li>TODO: Sort out the packaging. getopt.Option is tedious to type, but
-- surely Option shouldn't be in the root namespace?</li>
-- <li>TODO: Wrap all messages; do all wrapping in processArgs, not
-- usageInfo; use sdoc-like library (see string.format todos).</li>
-- <li>TODO: Don't require name to be repeated in banner.</li>
-- <li>TODO: Store version separately (construct banner?).</li>
-- </ul>
module ("getopt", package.seeall)

require "base"
require "list"
require "string_ext"
require "object"
require "io_ext"


--- Perform argument processing
-- @param argIn list of command-line args
-- @param options options table
-- @return table of remaining non-options
-- @return table of option key-value list pairs
-- @return table of error messages
function getOpt (argIn, options)
  local noProcess = nil
  local argOut, optOut, errors = {[0] = argIn[0]}, {}, {}
  -- get an argument for option opt
  local function getArg (o, opt, arg, oldarg)
    if o.type == nil then
      if arg ~= nil then
        table.insert (errors, "option `" .. opt .. "' doesn't take an argument")
      end
    else
      if arg == nil and argIn[1] and
        string.sub (argIn[1], 1, 1) ~= "-" then
        arg = argIn[1]
        table.remove (argIn, 1)
      end
      if arg == nil and o.type == "Req" then
        table.insert (errors,  "option `" .. opt ..
                      "' requires an argument `" .. o.var .. "'")
        return nil
      end
    end
    if o.func then
      return o.func (arg, oldarg)
    end
    return arg or 1 -- make sure arg has a value
  end
  -- parse an option
  local function parseOpt (opt, arg)
    local o = options.name[opt]
    if o ~= nil then
      optOut[o.name[1]] = getArg (o, opt, arg, optOut[o.name[1]])
    else
      table.insert (errors, "unrecognized option `-" .. opt .. "'")
    end
  end
  while argIn[1] do
    local v = argIn[1]
    table.remove (argIn, 1)
    local _, _, dash, opt = string.find (v, "^(%-%-?)([^=-][^=]*)")
    local _, _, arg = string.find (v, "=(.*)$")
    if v == "--" then
      noProcess = 1
    elseif dash == nil or noProcess then -- non-option
      table.insert (argOut, v)
    else -- option
      parseOpt (opt, arg)
    end
  end
  return argOut, optOut, errors
end


--- Options table type.
-- @class table
-- @name _G.Option
-- @field name list of names
-- @field desc description of this option
-- @field type type of argument (if any): <code>Req</code>(uired),
-- <code>Opt</code>(ional)
-- @field var descriptive name for the argument
-- @field func optional function (newarg, oldarg) to convert argument
-- into actual argument, (if omitted, argument is left as it
-- is)
_G.Option = Object {_init = {"name", "desc", "type", "var", "func"}}

--- Options table constructor: adds lookup tables for the option names
function _G.Options (t)
  local name = {}
  for _, v in ipairs (t) do
    for j, s in pairs (v.name) do
      if name[s] then
        warn ("duplicate option '%s'", s)
      end
      name[s] = v
    end
  end
  t.name = name
  return t
end


--- Produce usage info for the given options
-- @param header header string
-- @param optDesc option descriptors
-- @param pageWidth width to format to [78]
-- @return formatted string
function usageInfo (header, optDesc, pageWidth)
  pageWidth = pageWidth or 78
  -- Format the usage info for a single option
  -- @param opt the Option table
  -- @return options
  -- @return description
  local function fmtOpt (opt)
    local function fmtName (o)
      return "-" .. o
    end
    local function fmtArg ()
      if opt.type == nil then
        return ""
      elseif opt.type == "Req" then
        return "=" .. opt.var
      else
        return "[=" .. opt.var .. "]"
      end
    end
    local textName = list.map (fmtName, opt.name)
    textName[1] = textName[1] .. fmtArg ()
    return {table.concat ({table.concat (textName, ", ")}, ", "),
      opt.desc}
  end
  local function sameLen (xs)
    local n = math.max (unpack (list.map (string.len, xs)))
    for i, v in pairs (xs) do
      xs[i] = string.sub (v .. string.rep (" ", n), 1, n)
    end
    return xs, n
  end
  local function paste (x, y)
    return "  " .. x .. "  " .. y
  end
  local function wrapper (w, i)
    return function (s)
             return string.wrap (s, w, i, 0)
           end
  end
  local optText = ""
  if #optDesc > 0 then
    local cols = list.transpose (list.map (fmtOpt, optDesc))
    local width
    cols[1], width = sameLen (cols[1])
    cols[2] = list.map (wrapper (pageWidth, width + 4), cols[2])
    optText = "\n\n" ..
      table.concat (list.mapWith (paste,
                                  list.transpose ({sameLen (cols[1]),
                                                    cols[2]})),
                    "\n")
  end
  return header .. optText
end

--- Emit a usage message.
function usage ()
  local name = prog.name
  prog.name = nil
  local usage, purpose, notes = "[OPTION...] FILE...", "", ""
  if prog.usage then
    usage = prog.usage
  end
  if prog.purpose then
    purpose = "\n" .. prog.purpose
  end
  if prog.notes then
    notes = "\n\n"
    if not string.find (prog.notes, "\n") then
      notes = notes .. string.wrap (prog.notes)
    else
      notes = notes .. prog.notes
    end
  end
  warn (getopt.usageInfo ("Usage: " .. name .. " " .. usage .. purpose,
                          options)
        .. notes)
end


--- Simple getOpt wrapper.
-- Adds <code>-version</code>/<code>-v</code> and
-- <code>-help</code>/<code>-h</code>/<code>-?</code> automatically;
-- stops program if there was an error, or if <code>-help</code> or
-- <code>-version</code> was used.
function processArgs ()
  local totArgs = #arg
  options = Options (list.concat (options or {},
                                  {Option {{"version", "v"},
                                      "show program version"},
                                    Option {{"help", "h", "?"},
                                      "show this help"}}
                              ))
  local errors
  _G.arg, opt, errors = getopt.getOpt (arg, options)
  if (opt.version or opt.help) and prog.banner then
    io.stderr:write (prog.banner .. "\n")
  end
  if #errors > 0 or opt.help then
    local name = prog.name
    prog.name = nil
    if #errors > 0 then
      warn (table.concat (errors, "\n") .. "\n")
    end
    prog.name = name
    getopt.usage ()
    if #errors > 0 then
      error ()
    end
  end
  if opt.version or opt.help then
    os.exit ()
  end
end
_G.options = nil


-- A small and hopefully enlightening example:
if type (_DEBUG) == "table" and _DEBUG.std then

  function out (o)
    return o or io.stdout
  end

  options = Options {
    Option {{"verbose", "v"}, "verbosely list files"},
    Option {{"version", "release", "V", "?"}, "show version info"},
    Option {{"output", "o"}, "dump to FILE", "Opt", "FILE", out},
    Option {{"name", "n"}, "only dump USER's files", "Req", "USER"},
  }

  function test (cmdLine)
    local nonOpts, opts, errors = getopt.getOpt (cmdLine, options)
    if #errors == 0 then
      print ("options=" .. tostring (opts) ..
             "  args=" .. tostring (nonOpts) .. "\n")
    else
      print (table.concat (errors, "\n") .. "\n" ..
             getopt.usageInfo ("Usage: foobar [OPTION...] FILE...",
                               options))
    end
  end

  -- FIXME: Turn the following documentation into unit tests
  prog = {name = "foobar"} -- in case of errors
  -- example runs:
  test {"foo", "-v"}
  -- options={verbose=1}  args={1=foo,n=1}
  test {"foo", "--", "-v"}
  -- options={}  args={1=foo,2=-v,n=2}
  test {"-o", "-?", "-name", "bar", "--name=baz"}
  -- options={output=userdata(?): 0x????????,version=1,name=baz}  args={}
  test {"-foo"}
  -- unrecognized option `foo'
  -- Usage: foobar [OPTION...] FILE...
  --   -verbose, -v                verbosely list files
  --   -version, -release, -V, -?  show version info
  --   -output[=FILE], -o          dump to FILE
  --   -name=USER, -n              only dump USER's files

end
