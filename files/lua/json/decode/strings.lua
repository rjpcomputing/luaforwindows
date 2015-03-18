--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local lpeg = require("lpeg")
local util = require("json.decode.util")
local merge = require("json.util").merge

local tonumber = tonumber
local string_char = require("string").char
local floor = require("math").floor
local table_concat = require("table").concat

local error = error
module("json.decode.strings")
local function get_error(item)
	local fmt_string = item .. " in string [%q] @ %i:%i"
	return function(data, index)
		local line, line_index, bad_char, last_line = util.get_invalid_character_info(data, index)
		local err = fmt_string:format(bad_char, line, line_index)
		error(err)
	end
end

local bad_unicode   = get_error("Illegal unicode escape")
local bad_hex       = get_error("Illegal hex escape")
local bad_character = get_error("Illegal character")
local bad_escape    = get_error("Illegal escape")

local knownReplacements = {
	["'"] = "'",
	['"'] = '"',
	['\\'] = '\\',
	['/'] = '/',
	b = '\b',
	f = '\f',
	n = '\n',
	r = '\r',
	t = '\t',
	v = '\v',
	z = '\z'
}

-- according to the table at http://da.wikipedia.org/wiki/UTF-8
local function utf8DecodeUnicode(code1, code2)
	code1, code2 = tonumber(code1, 16), tonumber(code2, 16)
	if code1 == 0 and code2 < 0x80 then
		return string_char(code2)
	end
	if code1 < 0x08 then
		return string_char(
			0xC0 + code1 * 4 + floor(code2 / 64),
			0x80 + code2 % 64)
	end
	return string_char(
		0xE0 + floor(code1 / 16),
		0x80 + (code1 % 16) * 4 + floor(code2 / 64),
		0x80 + code2 % 64)
end

local function decodeX(code)
	code = tonumber(code, 16)
	return string_char(code)
end

local doSimpleSub = lpeg.C(lpeg.S("'\"\\/bfnrtvz")) / knownReplacements
local doUniSub = lpeg.P('u') * (lpeg.C(util.hexpair) * lpeg.C(util.hexpair) + lpeg.P(bad_unicode))
local doXSub = lpeg.P('x') * (lpeg.C(util.hexpair) + lpeg.P(bad_hex))

local defaultOptions = {
	badChars = '',
	additionalEscapes = false, -- disallow untranslated escapes
	escapeCheck = #lpeg.S('bfnrtv/\\"xu\'z'), -- no check on valid characters
	decodeUnicode = utf8DecodeUnicode,
	strict_quotes = false
}

default = nil -- Let the buildCapture optimization take place

strict = {
	badChars = '\b\f\n\r\t\v',
	additionalEscapes = false, -- no additional escapes
	escapeCheck = #lpeg.S('bfnrtv/\\"u'), --only these chars are allowed to be escaped
	strict_quotes = true
}

local function buildCaptureString(quote, badChars, escapeMatch)
	local captureChar = (1 - lpeg.S("\\" .. badChars .. quote)) + (lpeg.P("\\") / "" * escapeMatch)
	captureChar = captureChar + (-#lpeg.P(quote) * lpeg.P(bad_character))
	local captureString = captureChar^0
	return lpeg.P(quote) * lpeg.Cs(captureString) * lpeg.P(quote)
end

local function buildCapture(options)
	options = options and merge({}, defaultOptions, options) or defaultOptions
	local quotes = { '"' }
	if not options.strict_quotes then
		quotes[#quotes + 1] = "'"
	end
	local escapeMatch = doSimpleSub
	escapeMatch = escapeMatch + doXSub / decodeX
	escapeMatch = escapeMatch + doUniSub / options.decodeUnicode
	if options.additionalEscapes then
		escapeMatch = escapeMatch + options.additionalEscapes
	end
	if options.escapeCheck then
		escapeMatch = options.escapeCheck * escapeMatch + lpeg.P(bad_escape)
	end
	local captureString
	for i = 1, #quotes do
		local cap = buildCaptureString(quotes[i], options.badChars, escapeMatch)
		if captureString == nil then
			captureString = cap
		else
			captureString = captureString + cap
		end
	end
	return captureString
end

function register_types()
	util.register_type("STRING")
end

function load_types(options, global_options, grammar)
	local capture = buildCapture(options)
	local string_id = util.types.STRING
	grammar[string_id] = capture
	util.append_grammar_item(grammar, "VALUE", lpeg.V(string_id))
end
