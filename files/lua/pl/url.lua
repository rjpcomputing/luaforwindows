--- Python-style URL quoting library.
--
-- @module pl.url

local M = {}

--- Quote the url.
-- @string s the string
-- @bool quote_plus Use quote_plus rules
function M.quote(s, quote_plus)
    function url_quote_char(c)
        return string.format("%%%02X", string.byte(c))
    end

    if not s or not type(s) == "string" then
    	return s
    end

    s = s:gsub("\n", "\r\n")
    s = s:gsub("([^A-Za-z0-9 %-_%./])", url_quote_char)
    if quote_plus then
        s = s:gsub(" ", "+")
        s = s:gsub("/", url_quote_char)
    else
        s = s:gsub(" ", "%%20")
    end

    return s
end

--- Unquote the url.
-- @string s the string
function M.unquote(s)
    if not s or not type(s) == "string" then
    	return s
    end

    s = s:gsub("+", " ")
    s = s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
    s = s:gsub("\r\n", "\n")

    return s
end

return M
