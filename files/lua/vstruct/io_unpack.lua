-- read formats
-- return a value if applicable, which will be packed
-- otherwise return nil
-- Copyright � 2008 Ben "ToxicFrog" Kelly; see COPYING

-- load operations common to both unpack and pack, and set __index so that
-- requests for, say, unpack.seekto will succeed
local require,error,setmetatable,string,print
	= require,error,setmetatable,string,print

module((...))

local struct = require (_PACKAGE:sub(1,-2))
local common = require (_PACKAGE.."common")
local fp = require (_PACKAGE.."fp")

local unpack = setmetatable({}, { __index = common })

-- boolean
-- true if any bit is 1, false otherwise
function unpack.b(fd, w)
	return unpack.u(fd, w) ~= 0
end

-- counted string
-- a string immediately prefaced with its length as a uint
function unpack.c(fd, w)
	w = unpack.u(fd, w)
	
	return unpack.s(fd, w)
end

-- float
-- this is callout to the floating-point read/write module, if installed
function unpack.f(fd, w)
	if not fp.r[w] then
		error("struct.unpack: illegal floating point width")
	end
	
	return fp.r[w](unpack.s(fd,w))
end

-- utility functions for the i, m and u formats
local function directions(w)
	if unpack.is_bigendian then
		return 1,w,1
	else
		return w,1,-1
	end
end

local function pve_unpack(buf, w)
	local i,sof,eof,dir = 0,directions(w)

	for c=sof,eof,dir do
		i = i * 2^8 + buf:byte(c)
	end

	return i
end

local function nve_unpack(buf, w)
	local i,sof,eof,dir = 0,directions(w)
	
	if buf:byte(sof) < 128 then
		return pve_unpack(buf, w)
	end
	
	for c=sof,eof,dir do
		i = i * 2^8 - (255 - buf:byte(c))
	end

	return i-1
end

-- signed int of w bytes
function unpack.i(fd, w)
	local buf = unpack.s(fd, w)
	
	return nve_unpack(buf, w)
end

-- bitmask of w bytes
-- we need to read and unpack it as a string, not an unsigned, because otherwise
-- we're limited to 52 bits
function unpack.m(fd, w)
	local buf = unpack.s(fd, w)
	local mask = {}
	
	local sof,eof,dir = directions(w)

	-- reverse it here because directions() returns numbers for MSB first,
	-- and we want LSB first
	for i=eof,sof,-dir do
		local byte = buf:byte(i)
		local bits = struct.explode(byte)
		for j=1,8 do
			mask[#mask+1] = bits[j] or false
		end
	end
	return mask
end

-- fixed point bit aligned
-- w is in the form d.f, where d is the number of bits in the integer part
-- and f the number of bits in the fractional part
function unpack.P(fd, dp, fp)
	if (dp+fp) % 8 ~= 0 then
		error "total width of fixed point value must be byte multiple"
	end
	return unpack.i(fd, (dp+fp)/8)/(2^fp)
end

-- fixed point byte aligned
function unpack.p(fd, dp, fp)
	return unpack.P(fd, dp*8, fp*8)
end

-- string
-- reads exactly w bytes of data and returns them verbatim
function unpack.s(fd, w)
	if w == 0 then return "" end
	
    local buf,err = fd:read(w or "*a")
    if not buf then
        error(function() return "read error: "..(err or "(unknown error)") end)
    elseif #buf < w then
        error(function() return "short read: wanted "..w.." bytes, got "..#buf end)
    end
    return buf
end

-- unsigned int
function unpack.u(fd, w)
	local buf,err = unpack.s(fd, w)

	return pve_unpack(buf, w)
end

-- skip/pad
-- reads w bytes and discards them
function unpack.x(fd, w)
	fd:read(w)
	return true
end

-- null-terminated string
-- if w is omitted, reads up to and including the first nul, and returns everything
-- except that nul
-- otherwise, reads exactly w bytes and returns everything up to the first nul
function unpack.z(fd, w)
	if w then
		return unpack.s(fd, w):match('^%Z*')
	end
	
	local buf = ""
	local c = unpack.s(fd, 1)
	while #c > 0 and c ~= string.char(0) do
		buf = buf..c
		c = unpack.s(fd, 1)
	end
	return buf
end

return unpack
