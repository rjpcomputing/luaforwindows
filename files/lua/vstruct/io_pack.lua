-- write formats
-- return true if they have consumed a value from the input stream
-- return false/nil otherwise (ie, the next value will be preserved
-- for subsequent calls, eg skip/pad)
-- Copyright © 2008 Ben "ToxicFrog" Kelly; see COPYING
local require,error,setmetatable,string,print,math,unpack,io
	= require,error,setmetatable,string,print,math,unpack,io

module((...))

local struct = require (_PACKAGE:sub(1,-2))
local common = require (_PACKAGE.."common")
local fp = require (_PACKAGE.."fp")

local pack = setmetatable({}, { __index = common })

-- boolean
function pack.b(fd, d, w)
	return pack.u(fd, (d and 1) or 0, w)
end

-- counted string
-- a string immediately prefaced with its length as a uint
function pack.c(fd, d, w)
	pack.u(fd, #d, w)
	return pack.s(fd, d)
end

-- floating point
function pack.f(fd, d, w)
	if not fp.w[w] then
		error("struct.pack: illegal floating point width")
	end
--	local f = fp.w[w](d)
--	print(f, type(f))
	return pack.s(fd, fp.w[w](d), w)
end

-- signed int
function pack.i(fd, d, w)
	if d < 0 then
		d = 2^(w*8) + d
	end
	return pack.u(fd, d, w)
end

-- bitmask
-- we use a string here because using an unsigned will lose data on bitmasks
-- wider than lua's native number format
function pack.m(fd, d, w)
	local buf = ""
	
	for i=1,w*8,8 do
		local bits = { unpack(d, i, i+7) }
		local byte = string.char(struct.implode(bits, 8))
		if pack.is_bigendian then
			buf = byte..buf
		else
			buf = buf..byte
		end
	end
	return pack.s(fd, buf, w)
end

-- fixed point bit aligned
function pack.P(fd, d, dp, fp)
	if (dp+fp) % 8 ~= 0 then
		error "total width of fixed point value must be byte multiple"
	end
	return pack.i(fd, d * 2^fp, (dp+fp)/8)
end

-- fixed point byte aligned
function pack.p(fd, d, dp, fp)
	return pack.P(fd, d, dp*8, fp*8)
end

-- fixed length string
-- length 0 is write string as is
-- length >0 is write exactly w bytes, truncating or padding as needed
function pack.s(fd, d, w)
	w = w or #d
	if w == 0 then return end
	
	if #d < w then
		d = d..string.char(0):rep(w-#d)
	end
	
	return fd:write(d:sub(1,w))
end

-- unsigned int
function pack.u(fd, d, w)
	local s = ""

	for i=1,w do
		if pack.is_bigendian then
			s = string.char(d % 2^8) .. s
		else
			s = s .. string.char(d % 2^8)
		end
		d = math.trunc(d/2^8)
	end
	
	return pack.s(fd, s, w)
end

-- skip/pad
-- this is technically a control format, so it has a different signature
-- specifically, there is no "data" argument
function pack.x(fd, w)
	return pack.s(fd, "", w)
end

-- null terminated string
-- w==nil is write string as is + termination
-- w>0 is write exactly w bytes, truncating/padding and terminating
function pack.z(fd, d, w)
	w = w or #d+1
	if #d >= w then
		d = d:sub(1, w-1)
	end
	
	return pack.s(fd, d.."\0", w)
end

return pack
