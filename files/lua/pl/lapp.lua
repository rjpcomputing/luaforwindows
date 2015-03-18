--- Simple command-line parsing using human-readable specification.
-- Supports GNU-style parameters.
--
--      lapp = require 'pl.lapp'
--      local args = lapp [[
--      Does some calculations
--        -o,--offset (default 0.0)  Offset to add to scaled number
--        -s,--scale  (number)  Scaling factor
--         &lt;number&gt; (number )  Number to be scaled
--      ]]
--
--      print(args.offset + args.scale * args.number)
--
-- Lines begining with '-' are flags; there may be a short and a long name;
-- lines begining wih '<var>' are arguments.  Anything in parens after
-- the flag/argument is either a default, a type name or a range constraint.
--
-- >See @{08-additional.md.Command_line_Programs_with_Lapp|the Guide}
--
-- Dependencies: `pl.sip`
-- @module pl.lapp

local status,sip = pcall(require,'pl.sip')
if not status then
    sip = require 'sip'
end
local match = sip.match_at_start
local append,tinsert = table.insert,table.insert

sip.custom_pattern('X','(%a[%w_%-]*)')

local function lines(s) return s:gmatch('([^\n]*)\n') end
local function lstrip(str)  return str:gsub('^%s+','')  end
local function strip(str)  return lstrip(str):gsub('%s+$','') end
local function at(s,k)  return s:sub(k,k) end
local function isdigit(s) return s:find('^%d+$') == 1 end

local lapp = {}

local open_files,parms,aliases,parmlist,usage,windows,script

lapp.callback = false -- keep Strict happy

local filetypes = {
    stdin = {io.stdin,'file-in'}, stdout = {io.stdout,'file-out'},
    stderr = {io.stderr,'file-out'}
}

--- controls whether to dump usage on error.
-- Defaults to true
lapp.show_usage_error = true

--- quit this script immediately.
-- @param msg optional message
-- @param no_usage suppress 'usage' display
function lapp.quit(msg,no_usage)
    if no_usage == 'throw' then
        error(msg)
    end
    if msg then
        io.stderr:write(msg..'\n\n')
    end
    if not no_usage then
        io.stderr:write(usage)
    end
    os.exit(1)
end

--- print an error to stderr and quit.
-- @param msg a message
-- @param no_usage suppress 'usage' display
function lapp.error(msg,no_usage)
    if not lapp.show_usage_error then
        no_usage = true
    elseif lapp.show_usage_error == 'throw' then
        no_usage = 'throw'
    end
    lapp.quit(script..': '..msg,no_usage)
end

--- open a file.
-- This will quit on error, and keep a list of file objects for later cleanup.
-- @param file filename
-- @param opt same as second parameter of <code>io.open</code>
function lapp.open (file,opt)
    local val,err = io.open(file,opt)
    if not val then lapp.error(err,true) end
    append(open_files,val)
    return val
end

--- quit if the condition is false.
-- @param condn a condition
-- @param msg an optional message
function lapp.assert(condn,msg)
    if not condn then
        lapp.error(msg)
    end
end

local function range_check(x,min,max,parm)
    lapp.assert(min <= x and max >= x,parm..' out of range')
end

local function xtonumber(s)
    local val = tonumber(s)
    if not val then lapp.error("unable to convert to number: "..s) end
    return val
end

local types

local builtin_types = {string=true,number=true,['file-in']='file',['file-out']='file',boolean=true}

local function convert_parameter(ps,val)
    if ps.converter then
        val = ps.converter(val)
    end
    if ps.type == 'number' then
        val = xtonumber(val)
    elseif builtin_types[ps.type] == 'file' then
        val = lapp.open(val,(ps.type == 'file-in' and 'r') or 'w' )
    elseif ps.type == 'boolean' then
        val = true
    end
    if ps.constraint then
        ps.constraint(val)
    end
    return val
end

--- add a new type to Lapp. These appear in parens after the value like
-- a range constraint, e.g. '<ival> (integer) Process PID'
-- @param name name of type
-- @param converter either a function to convert values, or a Lua type name.
-- @param constraint optional function to verify values, should use lapp.error
-- if failed.
function lapp.add_type (name,converter,constraint)
    types[name] = {converter=converter,constraint=constraint}
end

local function force_short(short)
    lapp.assert(#short==1,short..": short parameters should be one character")
end

local function process_default (sval,vtype)
    local val
    if not vtype or vtype == 'number' then
        val = tonumber(sval)
    end
    if val then -- we have a number!
        return val,'number'
    elseif filetypes[sval] then
        local ft = filetypes[sval]
        return ft[1],ft[2]
    else
        if sval:match '^["\']' then sval = sval:sub(2,-2) end
        return sval,vtype or 'string'
    end
end

--- process a Lapp options string.
-- Usually called as lapp().
-- @param str the options text
-- @param args a table of arguments (default is `_G.arg`)
-- @return a table with parameter-value pairs
function lapp.process_options_string(str,args)
    local results = {}
    local opts = {at_start=true}
    local varargs
    local arg = args or _G.arg
    open_files = {}
    parms = {}
    aliases = {}
    parmlist = {}
    types = {}

    local function check_varargs(s)
        local res,cnt = s:gsub('^%.%.%.%s*','')
        return res, (cnt > 0)
    end

    local function set_result(ps,parm,val)
        if not ps.varargs then
            results[parm] = val
        else
            if not results[parm] then
                results[parm] = { val }
            else
                append(results[parm],val)
            end
        end
    end

    usage = str

    for line in lines(str) do
        local res = {}
        local optspec,optparm,i1,i2,defval,vtype,constraint,rest
        line = lstrip(line)
        local function check(str)
            return match(str,line,res)
        end

        -- flags: either '-<short>', '-<short>,--<long>' or '--<long>'
        if check '-$v{short}, --$v{long} $' or check '-$v{short} $' or check '--$X{long} $' then
            if res.long then
                optparm = res.long:gsub('%W','_') -- so foo-bar becomes foo_bar in Lua
                if res.short then aliases[res.short] = optparm  end
            else
                optparm = res.short
            end
            if res.short then force_short(res.short) end
            res.rest, varargs = check_varargs(res.rest)
        elseif check '$<{name} $'  then -- is it <parameter_name>?
            -- so <input file...> becomes input_file ...
            optparm,rest = res.name:match '([^%.]+)(.*)'
            optparm = optparm:gsub('%A','_')
            varargs = rest == '...'
            append(parmlist,optparm)
        end
        -- this is not a pure doc line and specifies the flag/parameter type
        if res.rest then
            line = res.rest
            res = {}
            -- do we have ([<type>] [default <val>])?
            if match('$({def} $',line,res) or match('$({def}',line,res) then
                local typespec = strip(res.def)
                local ftype, rest = typespec:match('^(%S+)(.*)$')
                rest = strip(rest)
                local default
                if ftype == 'default' then
                    default = true
                    if rest == '' then lapp.error("value must follow default") end
                else -- a type specification
                    if match('$f{min}..$f{max}',ftype,res) then
                        -- a numerical range like 1..10
                        local min,max = res.min,res.max
                        vtype = 'number'
                        constraint = function(x)
                            range_check(x,min,max,optparm)
                        end
                    elseif not ftype:match '|' then -- plain type
                        vtype = ftype
                    else
                        -- 'enum' type is a string which must belong to
                        -- one of several distinct values
                        local enums = ftype
                        local enump = '|' .. enums .. '|'
                        vtype = 'string'
                        constraint = function(s)
                            lapp.assert(enump:match('|'..s..'|'),
                              "value '"..s.."' not in "..enums
                            )
                        end
                    end
                end
                res.rest = rest
                typespec = res.rest
                -- optional 'default value' clause. Type is inferred as
                -- 'string' or 'number' if there's no explicit type
                if default or match('default $r{rest}',typespec,res) then
                    defval,vtype = process_default(res.rest,vtype)
                end
                --print('val',optparm,defval,vtype)
            else -- must be a plain flag, no extra parameter required
                defval = false
                vtype = 'boolean'
            end
            local ps = {
                type = vtype,
                defval = defval,
                required = defval == nil,
                comment = res.rest or optparm,
                constraint = constraint,
                varargs = varargs
            }
            varargs = nil
            if types[vtype] then
                local converter = types[vtype].converter
                if type(converter) == 'string' then
                    ps.type = converter
                else
                    ps.converter = converter
                end
                ps.constraint = types[vtype].constraint
            elseif not builtin_types[vtype] then
                lapp.error(vtype.." is unknown type")
            end
            parms[optparm] = ps
        end
    end
    -- cool, we have our parms, let's parse the command line args
    local iparm = 1
    local iextra = 1
    local i = 1
    local parm,ps,val

    local function check_parm (parm)
        local eqi = parm:find '='
        if eqi then
            tinsert(arg,i+1,parm:sub(eqi+1))
            parm = parm:sub(1,eqi-1)
        end
        return parm,eqi
    end

    while i <= #arg do
        local theArg = arg[i]
        local res = {}
        -- look for a flag, -<short flags> or --<long flag>
        if match('--$S{long}',theArg,res) or match('-$S{short}',theArg,res) then
            if res.long then -- long option
                parm = check_parm(res.long)
            elseif #res.short == 1 then
                parm = res.short
            else
                local parmstr,eq = check_parm(res.short)
                if not eq then
                    parm = at(parmstr,1)
                    if isdigit(at(parmstr,2)) then
                        -- a short option followed by a digit is an exception (for AW;))
                        -- push ahead into the arg array
                        tinsert(arg,i+1,parmstr:sub(2))
                    else
                        -- push multiple flags into the arg array!
                        for k = 2,#parmstr do
                            tinsert(arg,i+k-1,'-'..at(parmstr,k))
                        end
                    end
                else
                    parm = parmstr
                end
            end
            if parm == 'h' or parm == 'help' then
                lapp.quit()
            end
            if aliases[parm] then parm = aliases[parm] end
        else -- a parameter
            parm = parmlist[iparm]
            if not parm then
               -- extra unnamed parameters are indexed starting at 1
               parm = iextra
               ps = { type = 'string' }
               parms[parm] = ps
               iextra = iextra + 1
            else
                ps = parms[parm]
            end
            if not ps.varargs then
                iparm = iparm + 1
            end
            val = theArg
        end
        ps = parms[parm]
        if not ps then lapp.error("unrecognized parameter: "..parm) end
        if ps.type ~= 'boolean' then -- we need a value! This should follow
            if not val then
                i = i + 1
                val = arg[i]
            end
            lapp.assert(val,parm.." was expecting a value")
        end
        ps.used = true
        val = convert_parameter(ps,val)
        set_result(ps,parm,val)
        if builtin_types[ps.type] == 'file' then
            set_result(ps,parm..'_name',theArg)
        end
        if lapp.callback then
            lapp.callback(parm,theArg,res)
        end
        i = i + 1
        val = nil
    end
    -- check unused parms, set defaults and check if any required parameters were missed
    for parm,ps in pairs(parms) do
        if not ps.used then
            if ps.required then lapp.error("missing required parameter: "..parm) end
            set_result(ps,parm,ps.defval)
        end
    end
    return results
end

if arg then
    script = arg[0]:gsub('.+[\\/]',''):gsub('%.%a+$','')
else
    script = "inter"
end


setmetatable(lapp, {
    __call = function(tbl,str,args) return lapp.process_options_string(str,args) end,
})


return lapp


