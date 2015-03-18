--------------
-- Entry point for loading all PL libraries only on demand.
-- Requiring 'pl' means that whenever a module is implicitly accesssed
-- (e.g. `utils.split`)
-- then that module is dynamically loaded. The submodules are all brought into
-- the global space.
-- @module pl

local modules = {
    utils = true,path=true,dir=true,tablex=true,stringio=true,sip=true,
    input=true,seq=true,lexer=true,stringx=true,
    config=true,pretty=true,data=true,func=true,text=true,
    operator=true,lapp=true,array2d=true,
    comprehension=true,xml=true,
    test = true, app = true, file = true, class = true, List = true,
    Map = true, Set = true, OrderedMap = true, MultiMap = true,
    Date = true,
    -- classes --
}
_G.utils = require 'pl.utils'

for name,klass in pairs(_G.utils.stdmt) do
    klass.__index = function(t,key)
        return require ('pl.'..name)[key]
    end;
end

-- ensure that we play nice with libraries that also attach a metatable
-- to the global table; always forward to a custom __index if we don't
-- match

local _hook,_prev_index
local gmt = {}
local prev_gmt = getmetatable(_G)
if prev_gmt then
    _prev_index = prev_gmt.__index
    if prev_gmt.__newindex then
        gmt.__index = prev_gmt.__newindex
    end
end

function gmt.hook(handler)
    _hook = handler
end

function gmt.__index(t,name)
    local found = modules[name]
    -- either true, or the name of the module containing this class.
    -- either way, we load the required module and make it globally available.
    if found then
        -- e..g pretty.dump causes pl.pretty to become available as 'pretty'
        rawset(_G,name,require('pl.'..name))
        return _G[name]
    else
        local res
        if _hook then
            res = _hook(t,name)
            if res then return res end
        end
        if _prev_index then
            return _prev_index(t,name)
        end
    end
end

setmetatable(_G,gmt)

if rawget(_G,'PENLIGHT_STRICT') then require 'pl.strict' end
