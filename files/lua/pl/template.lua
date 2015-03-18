--- A template preprocessor.
-- Originally by [Ricki Lake](http://lua-users.org/wiki/SlightlyLessSimpleLuaPreprocessor)
--
-- There are two rules:
--
--  * lines starting with # are Lua
--  * otherwise, `$(expr)` is the result of evaluating `expr`
--
-- Example:
--
--    #  for i = 1,3 do
--       $(i) Hello, Word!
--    #  end
--    ===>
--    1 Hello, Word!
--    2 Hello, Word!
--    3 Hello, Word!
--
-- Other escape characters can be used, when the defaults conflict
-- with the output language.
--
--    > for _,n in pairs{'one','two','three'} do
--    static int l_${n} (luaState *state);
--    > end
--
-- See  @{03-strings.md.Another_Style_of_Template|the Guide}.
--
-- Dependencies: `pl.utils`
-- @module pl.template

local utils = require 'pl.utils'
local append,format = table.insert,string.format

local function parseHashLines(chunk,brackets,esc)
    local exec_pat = "()$(%b"..brackets..")()"

    local function parseDollarParen(pieces, chunk, s, e)
        local s = 1
        for term, executed, e in chunk:gmatch (exec_pat) do
            executed = '('..executed:sub(2,-2)..')'
            append(pieces,
              format("%q..(%s or '')..",chunk:sub(s, term - 1), executed))
            s = e
        end
        append(pieces, format("%q", chunk:sub(s)))
    end

    local esc_pat = esc.."+([^\n]*\n?)"
    local esc_pat1, esc_pat2 = "^"..esc_pat, "\n"..esc_pat
    local  pieces, s = {"return function(_put) ", n = 1}, 1
    while true do
        local ss, e, lua = chunk:find (esc_pat1, s)
        if not e then
            ss, e, lua = chunk:find(esc_pat2, s)
            append(pieces, "_put(")
            parseDollarParen(pieces, chunk:sub(s, ss))
            append(pieces, ")")
            if not e then break end
        end
        append(pieces, lua)
        s = e + 1
    end
    append(pieces, " end")
    return table.concat(pieces)
end

local template = {}

--- expand the template using the specified environment.
-- @param str the template string
-- @param env the environment (by default empty). <br>
-- There are three special fields in the environment table <ul>
-- <li><code>_parent</code> continue looking up in this table</li>
-- <li><code>_brackets</code>; default is '()', can be any suitable bracket pair</li>
-- <li><code>_escape</code>; default is '#' </li>
-- </ul>
function template.substitute(str,env)
    env = env or {}
    if rawget(env,"_parent") then
        setmetatable(env,{__index = env._parent})
    end
    local brackets = rawget(env,"_brackets") or '()'
    local escape = rawget(env,"_escape") or '#'
    local code = parseHashLines(str,brackets,escape)
    local fn,err = utils.load(code,'TMP','t',env)
    if not fn then return nil,err end
    fn = fn()
    local out = {}
    local res,err = xpcall(function() fn(function(s)
        out[#out+1] = s
    end) end,debug.traceback)
    if not res then
        if env._debug then print(code) end
        return nil,err
    end
    return table.concat(out)
end

return template




