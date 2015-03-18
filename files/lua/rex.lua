-- @module rex
-- lrexlib regular expressions

-- Default to using PCRE
-- FIXME: allow regular expression type to be selected (?)

require "rex_pcre"

_G.rex = rex_pcre
