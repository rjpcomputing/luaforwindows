--[[
	Licensed according to the included 'LICENSE' document
	Author: Thomas Harning Jr <harningt@gmail.com>
]]
local decode = require("json.decode")
local encode = require("json.encode")
local util = require("json.util")

module("json")
_M.decode = decode
_M.encode = encode
_M.util = util
