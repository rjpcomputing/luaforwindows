-- write formats
-- return true if they have consumed a value from the input stream
-- return false/nil otherwise (ie, the next value will be preserved
-- for subsequent calls, eg skip/pad)
-- Copyright © 2008 Ben "ToxicFrog" Kelly; see COPYING

local name = (...):gsub('%.[^%.]+$', '')
local struct = require (name)
local common = require (name..".common")
local write = setmetatable({}, { __index = common })
local fp = require (name..".fp")

-- boolean
function write.b(fd, d, w)
	return write.u(fd, (d and 1) or 0, w)
end

-- counted string
-- a string immediately prefaced with its length as a uint
function write.c(fd, d, w)
	write.u(fd, #d, w)
	return write.s(fd, d)
end

-- floating point
function write.f(fd, d, w)
	if not fp.w[w] then
		error("struct.pack: illegal floating point width")
	end
--	local f = fp.w[w](d)
--	print(f, type(f))
	return write.s(fd, fp.w[w](d), w)
end

-- signed int
function write.i(fd, d, w)
	if d < 0 then
		d = d + 2^(w*8)
	end
	return write.u(fd, d, w)
end

-- bitmask
-- we use a string here because using an unsigned will lose data on bitmasks
-- wider than lua's native number format
function write.m(fd, d, w)
	local buf = ""
	
	for i=1,w*8,8 do
		local bits = { unpack(d, i, i+7) }
		local byte = string.char(struct.implode(bits))
		if write.is_bigendian then
			buf = byte..buf
		else
			buf = buf..byte
		end
	end
	return write.s(fd, buf, w)
end

-- fixed point bit aligned
function write.P(fd, d, dp, fp)
	assert((dp+fp) % 8 == 0, "total width of fixed point value must be byte multiple")
	return write.u(fd, d * 2^fp, (dp+fp)/8)
end

-- fixed point byte aligned
function write.p(fd, d, dp, fp)
	return write.P(fd, d, dp*8, fp*8)
end

-- fixed length string
-- length 0 is write string as is
-- length >0 is write exactly w bytes, truncating or padding as needed
function write.s(fd, d, w)
	w = w or #d
	if #d < w then
		d = d..string.char(0):rep(w-#d)
	end
	return fd:write(d:sub(1,w))
end

-- unsigned int
function write.u(fd, d, w)
	local s = ""

	for i=1,w do
		if write.is_bigendian then
			s = string.char(d % 2^8) .. s
		else
			s = s .. string.char(d % 2^8)
		end
		d = math.floor(d/2^8)
	end
	
	return write.s(fd, s, w)
end

-- skip/pad
function write.x(fd, d, w)
	write.s(fd, "", w)
	return false
end

-- null terminated string
-- w==nil is write string as is + termination
-- w>0 is write exactly w bytes, truncating/padding and terminating
function write.z(fd, d, w)
	w = w or #d+1
	if #d >= w then
		d = d:sub(1, w-1)
	end
	
	return write.s(fd, d.."\0", w)
end

return write
