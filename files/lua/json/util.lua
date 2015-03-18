--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local type = type
local print = print
local tostring = tostring
local pairs = pairs
local getmetatable, setmetatable = getmetatable, setmetatable
local select = select

module("json.util")
local function foreach(tab, func)
	for k, v in pairs(tab) do
		func(k,v)
	end
end
function printValue(tab, name)
        local parsed = {}
        local function doPrint(key, value, space)
                space = space or ''
                if type(value) == 'table' then
                        if parsed[value] then
                                print(space .. key .. '= <' .. parsed[value] .. '>')
                        else
                                parsed[value] = key
                                print(space .. key .. '= {')
                                space = space .. ' '
                                foreach(value, function(key, value) doPrint(key, value, space) end)
                        end
                else
					if type(value) == 'string' then
						value = '[[' .. tostring(value) .. ']]'
					end
					print(space .. key .. '=' .. tostring(value))
                end
        end
        doPrint(name, tab)
end

function clone(t)
	local ret = {}
	for k,v in pairs(t) do
		ret[k] = v
	end
	return ret
end

local function merge(t, from, ...)
	if not from then
		return t
	end
	for k,v in pairs(from) do
		t[k] = v
	end
	return merge(t, ...)
end
_M.merge = merge

-- Function to insert nulls into the JSON stream
function null()
	return null
end

-- Marker for 'undefined' values
function undefined()
	return undefined
end

local ArrayMT = {}

--[[
	Return's true if the metatable marks it as an array..
	Or false if it has no array component at all
	Otherwise nil to get the normal detection component working
]]
function IsArray(value)
	if type(value) ~= 'table' then return false end
	local ret = getmetatable(value) == ArrayMT
	if not ret then
		if #value == 0 then return false end
	else
		return ret
	end
end
function InitArray(array)
	setmetatable(array, ArrayMT)
	return array
end

local CallMT = {}

function isCall(value)
	return CallMT == getmetatable(value)
end

function buildCall(name, ...)
	local callData = {
		name = name,
		parameters = {n = select('#', ...), ...}
	}
	return setmetatable(callData, CallMT)
end

function decodeCall(callData)
	if not isCall(callData) then return nil end
	return callData.name, callData.parameters
end
