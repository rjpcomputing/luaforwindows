-- cursor - a wrapper for strings that makes them look like files
-- exports: seek read write
-- read only supports numeric amounts
-- Copyright © 2008 Ben "ToxicFrog" Kelly; see COPYING

local cursor = {}

-- like fseek
-- seeking past the end of the string is permitted
-- reads will return EOF, writes will fill in the intermediate space with nuls
-- seeking past the start of the string is a soft error
function cursor:seek(whence, offset)
	whence = whence or "cur"
	offset = offset or 0
	
	if whence == "set" then
		self.pos = offset
	elseif whence == "cur" then
		self.pos = self.pos + offset
	elseif whence == "end" then
		self.pos = #self.str + offset
	else
		error "bad argument #1 to seek"
	end
	
	if self.pos < 0 then
		self.pos = 0
		return nil,"attempt to seek prior to start of file"
	end
	
	return self.pos
end

-- read n bytes from the current position
-- reads longer than the string can satisfy return as much as it can
-- reads while the position is at the end return nil,"eof"
function cursor:read(n)
	if self.pos >= #self.str then
		return nil,"eof"
	end
	
    if n == "*a" then
        n = #self.str
    end
    
	local buf = self.str:sub(self.pos+1, self.pos + n)
	self.pos = math.min(self.pos + n, #self.str)
	
	return buf
end

-- write the contents of the buffer at the current position, overwriting
-- any data already present
-- if the write pointer is past the end of the string, also fill in the
-- intermediate space with nuls
function cursor:write(buf)
	if self.pos > #self.str then
		self.str = self.str .. string.char(0):rep(self.pos - #self.str)
	end

	self.str = self.str:sub(1, self.pos)
		.. buf
		.. self.str:sub(self.pos + #buf + 1, -1)
	self.pos = self.pos + #buf

	return self
end	

function cursor:__call(source)
	assert(type(source) == "string", "invalid first argument to cursor()")
	return setmetatable(
		{ str = source, pos = 0 },
		cursor)
end

cursor.__index = cursor

setmetatable(cursor, cursor)

return cursor
