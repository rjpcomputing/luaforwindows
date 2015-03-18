--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Simple Expression Parser                                          --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------

local luaerror = error
local pairs = pairs
local ipairs = ipairs
local unpack = unpack
local select = select

require "string"
local oo = require "loop.base"

--[[VERBOSE]] local verbose = require("loop.debug.Verbose"){
--[[VERBOSE]] 	groups = { expression = {"operator","value","parse"} }
--[[VERBOSE]] }
--[[VERBOSE]] verbose:flag("expression", false)

module("loop.compiler.Expression", oo.class)

pos = 1
count = 0
precedence = {}

local pattern = "^ *%s"
function __init(self, object)
	self = oo.rawnew(self, object)

	if not self.operands and self.values then
		local operands = {}
		for kind, spec in pairs(self.values) do
			operands[kind] = pattern:format(spec)
		end
		self.operands = operands
	end
	
	if not self.format and self.operators then
		local opformat = {}
		for name, spec in pairs(self.operators) do
			local format = {}
			local pos = 1
			while pos <= #spec do
				if spec:find("^ ", pos) then
					format[#format+1] = true
					pos = pos + 1
				else
					local keyword = spec:match("^[^ ]+", pos)
					format[#format+1] = keyword
					pos = pos + #keyword
				end
			end
			opformat[name] = format
		end
		self.format = opformat
	end

	self.values = self.values or {}
	
	return self
end

function push(self, kind, value)
	self[#self+1] = kind
	if kind == true then
		self.count = self.count + 1
		self.values[self.count] = value
	end
end

function pop(self)
	local kind = self[#self]
	self[#self] = nil
	local value
	if kind == true then
		value = self.values[self.count]
		self.count = self.count - 1
	end
	return kind, value
end

function get(self, count)
	local nvals = 0
	for _=1, count do
		if self[#self] == true then
			nvals = nvals + 1
		end
		self[#self] = nil
	end
	self.count = self.count - nvals
	return unpack(self.values, self.count + 1, self.count + nvals)
end

local errmsg = "%s at position %d"
function error(self, msg)
	return luaerror(errmsg:format(msg, self.pos))
end

function done(self)
	return (self.text:match("^%s*$", self.pos))
end

function token(self, token)
	local pos = select(2, self.text:find("^%s*[^%s]", self.pos))
	if pos and (self.text:find(token, pos, true) == pos) then
		self.pos = pos + #token
		return true
	end
end

function match(self, pattern)
	local first, last, value = self.text:find(pattern, self.pos)
	if first then
		self.pos = last + 1
		return value
	end
end

function operator(self, name, level, start)
	local format = self.format[name]
	for index, kind in ipairs(format) do
		local parsed = self[start + index]
		if parsed then
			if parsed ~= kind then                                                    --[[VERBOSE]] verbose:operator("parsed value mismatch, got '",parsed,"' ('",kind,"' expected)")
				return false                                                            --[[VERBOSE]] else verbose:operator("parsed value matched, got '",parsed,"'")
			end
		else
			if kind == true then                                                      --[[VERBOSE]] verbose:operator(true, "operand expected, parsing...")
				if not self:parse(level + 1, #self) then                                --[[VERBOSE]] verbose:operator(false, "operand parsing failed")
					return false
				end                                                                     --[[VERBOSE]] verbose:operator(false, "operand parsed successfully")
			else                                                                      --[[VERBOSE]] verbose:operator("token ",kind," expected")
				if self:token(kind) then                                                --[[VERBOSE]] verbose:operator("token found successfully")
					self:push(kind)
				else                                                                    --[[VERBOSE]] verbose:operator("token not found")
					return false
				end
			end
		end
	end                                                                           --[[VERBOSE]] verbose:operator(true, "operator ",name," matched")
	self:push(true, self[name](self, self:get(#format)))                          --[[VERBOSE]] verbose:operator(false, "operator ",name," callback called")
	return true
end

function value(self)
	if self:token("(") then                                                       --[[VERBOSE]] verbose:value(true, "'(' found at ",self.pos)
		local start = #self
		if not self:parse(1, start) then                                            --[[VERBOSE]] verbose:value(false, "error in enclosed expression")
			self:error("value expected")
		elseif #self ~= start + 1 or self[#self] ~= true then                       --[[VERBOSE]] verbose:value(false, "enclosed expression incomplete (too many parsed values left)")
			self:error("incomplete expression")
		elseif not self:token(")") then                                             --[[VERBOSE]] verbose:value(false, "')' not found")
			self:error("')' expected")
		end                                                                         --[[VERBOSE]] verbose:value(false, "matching ')' found")
		return true
	else                                                                          --[[VERBOSE]] verbose:value(true, "parsing value at ",self.pos)
		for kind, pattern in pairs(self.operands) do                                --[[VERBOSE]] verbose:value("attempt to match value as ",kind)
			local value = self:match(pattern)
			if value then                                                             --[[VERBOSE]] verbose:value(true, "value found as ",kind)
				self:push(true, self[kind](self, value))                                --[[VERBOSE]] verbose:value(false, "value evaluated to ",self.values[self.count])
				return true                                                             --[[VERBOSE]],verbose:value(false)
			end
		end                                                                         --[[VERBOSE]] verbose:value(false, "no value found at ",self.pos)
		return false
	end
end

function parse(self, level, start)
	if not self:done() then
		local ops = self.precedence[level]
		if ops then                                                                 --[[VERBOSE]] verbose:parse(true, "parsing operators of level ",level)
			local i = 1
			while ops[i] do
				local op = ops[i]                                                       --[[VERBOSE]] verbose:parse(true, "attempt to match operator ",op)
				if self:operator(ops[i], level, start) then                             --[[VERBOSE]] verbose:parse(false, "operator ",op," successfully matched")
					i = 1
				else                                                                    --[[VERBOSE]] verbose:parse(false, "operator ",op," not matched")
					i = i + 1
				end
			end
			if #self == start then                                                    --[[VERBOSE]] verbose:parse(false, "no value evaluated by operators of level ",level)
				return self:parse(level + 1, start)
			elseif self[start + 1] == true then                                       --[[VERBOSE]] verbose:parse(false, "values evaluated by operators of level ",level)
				return true
			end
		else                                                                        --[[VERBOSE]] verbose:parse(true, "parsing value")
			return self:value()                                                       --[[VERBOSE]] ,verbose:parse(false)
		end
	end
end

function evaluate(self, text, pos)
	if text then
		self.text = text
		self.pos = pos
	end
	if not self:parse(1, 0) then
		self:error("parsing failed")
	elseif not self:done() then
		self:error("malformed expression")
	elseif #self ~= 1 or self[1] ~= true then
		self:error("incomplete expression")
	end
	return self:get(1)
end
