----------------------------------------------------------------------------
-- $Id: md5.lua,v 1.4 2006/08/21 19:24:21 carregal Exp $
----------------------------------------------------------------------------

local core = require"md5.core"
local string = require"string"

module ("md5")

----------------------------------------------------------------------------
-- @param k String with original message.
-- @return String with the md5 hash value converted to hexadecimal digits

function sumhexa (k)
  k = core.sum(k)
  return (string.gsub(k, ".", function (c)
           return string.format("%02x", string.byte(c))
         end))
end
