-----------------------------------------------------------------------------
-- tar - Lua Tape ARchive module
--
-- Code for managing tar files
--
-- Version 0.1 (21 AUG 2007)
--
-- Author: Judge Maygarden (jmaygarden@computer.org)
--
-- Copyright (c) 2007 Judge Maygarden
-----------------------------------------------------------------------------

local public = {}
local private = {}
local TarFile = {}
local TarInternalFile = {}
tar = public
TarFile.__index = TarFile
TarInternalFile.__index = TarInternalFile

-----------------------------------------------------------------------------
-- Closes file
-----------------------------------------------------------------------------
function TarInternalFile:close()
end

-----------------------------------------------------------------------------
-- UNSUPPORTED: Saves any written data to file
-----------------------------------------------------------------------------
function TarInternalFile:flush()
	error('Tar file output flushing is unsupported.')
end

-----------------------------------------------------------------------------
-- Returns an iterator function that returns a new line from the file
-- @return String repressenting a line from the file without the newline
-----------------------------------------------------------------------------
function TarInternalFile:lines()
	return function(s, var)
		return self:read("*l")
	end, self, nil
end

-----------------------------------------------------------------------------
-- Reads the file according to the given formats as follows:
-- "*n": reads a number
-- "*a": reads the whole file
-- "*l" reads the next line
-- number: reads a string with up to this number of characters
-- @param variadic list of formats (default "*l")
-- @return list of strings (or numbers) or nil if end of file or format error
-----------------------------------------------------------------------------
function TarInternalFile:read(...)
	local eof = self.offset + self.size
	if self.pointer >= eof then return nil end -- eof
	local t = {}
	self.archive.file:seek("set", self.pointer)
	for i, v in ipairs{...} do
		local s
		if "*a" == v then
			s = self.archive.file:read(eof - self.pointer)
		elseif "*l" == v or "*n" == v or "number" == type(v) then
			s = self.archive.file:read(v)
		else
			error('bad argument %d to %s (%s)', i
				'TarInternalFile:read', 'invalid format')
			return nil
		end
		local last = self.pointer
		self.pointer = self.archive.file:seek()
		if s and self.pointer < eof then
			table.insert(t, s)
		elseif s then
			table.insert(t, string.sub(s, 1, eof - last - 1))
			self.pointer = self.offset + self.size
			break
		else
			break
		end
	end
	return unpack(t)
end

-----------------------------------------------------------------------------
-- Sets and gets the file position measured from the given base as follows:
-- "set": base is position 0 (beginning of the file)
-- "cur": base is current position
-- "end": base is end of file
-- @param base position (default "cur")
-- @param offset in bytes (default 0)
-- @return final position
-----------------------------------------------------------------------------
function TarInternalFile:seek(whence, offset)
	local whence = whence or "cur"
	local offset = offset or 0
	local eof = self.offset + self.size
	local final
	local err

	if "cur" == whence then
		final, err = self.archive.file:seek("set",
			offset + self.pointer) - self.offset

	elseif "set" == whence then
		final, err =  self.archive.file:seek("set",
			offset + self.offset) - self.offset

	elseif "end" == whence then
		final, err =  self.archive.file:seek("set",
			offset + eof - 1) - self.offset

	else
		final, err =  self.archive.file:seek(whence, offset)
	end

	if not final then
		return nil, err
	elseif final < 0 then
		final = 0
	elseif final > self.size then
		final = self.size
	end
	self.pointer = final + self.offset
	
	return final
end

-----------------------------------------------------------------------------
-- UNSUPPORTED: Sets the buffering mode for an output file
-- @param "no" - no buffering, "full" - full buffering, "line" - line buffering
-- @param size of the buffer for "full" and "line" modes
-----------------------------------------------------------------------------
function TarInternalFile:setvbuf(mode, size)
	error('Tar file output buffering is unsupported.')
end

-----------------------------------------------------------------------------
-- UNSUPPORTED: Writes the value of each of its arguments to the file
-- @param string or numbers values only
-----------------------------------------------------------------------------
function TarInternalFile:write(...)
	error('Tar file writes are unsupported.')
end

-----------------------------------------------------------------------------
-- Opens a file inside the tar file archive
-- @param pathname of a file inside the tar file
-- @return file handle or nil if the file is not found
-----------------------------------------------------------------------------
function TarFile:open(filename)
	if not self.list[filename] then return nil end
	local file = {}
	file.archive = self
	file.filename = filename
	file.offset = self.list[filename].offset
	file.pointer = file.offset
	file.size = self.list[filename].size
	setmetatable(file, TarInternalFile)
	return file
end

-----------------------------------------------------------------------------
-- Returns an iterator over all files in the tar archive
-- @return interator function, tar file handle
-----------------------------------------------------------------------------
function TarFile:files()
	return next, self.list, nil
end

-----------------------------------------------------------------------------
-- Data for parsing tar header fields
-----------------------------------------------------------------------------
private.HEADER_DATA = {
	-- { field, offset, size, octal }
	{ "name", 0, 100 },
	{ "mode", 100, 8, true },
	{ "uid", 108, 8, true },
	{ "gid", 116, 8, true },
	{ "size", 124, 12, true },
	{ "mtime", 136, 12, true },
	{ "chksum", 148, 8, true },
	{ "typeflag", 156, 1, true },
	{ "linkname", 157, 100 },
	{ "magic", 257, 6 },
	{ "version", 263, 2 },
	{ "uname", 265, 32 },
	{ "gname", 297, 32 },
	{ "devmajor", 329, 8, true },
	{ "devminor", 337, 8, true },
	{ "prefix", 345, 155 },
}

-----------------------------------------------------------------------------
-- Converts an octal string into a number
-- @param string of octal digits
-- @return number or nil if an invalid string was passed
-----------------------------------------------------------------------------
private.octal = function(s)
	if string.match(s, "[^0-7]") then return nil end
	local n, m = 0, 0
	for i = string.len(s), 1, -1 do
		n = n + (string.byte(s, i) - 48) * 8 ^ m
		m = m + 1
	end
	return n
end

-----------------------------------------------------------------------------
-- Decodes a tar file header
-- @param 512-byte string containing a tar file header block
-- @return table containg the header fields
-----------------------------------------------------------------------------
private.decode = function(header)
	local t = {}
	for _, field in ipairs(private.HEADER_DATA) do
		local s = string.sub(header, field[2] + 1, field[2] + field[3])
		local s = string.match(s, "[^%z]*")
		if field[4] then
			t[field[1]] = private.octal(s)
		else
			t[field[1]] = s
		end
	end
	if 0 < string.len(t.prefix) then
		t.pathname = t.prefix..'/'..t.name
	else
		t.pathname = t.name
	end
	return t
end

-----------------------------------------------------------------------------
-- Opens a tar archive by attaching to the provided Lua file handle.
-- Ownership of the file handle is transferred to the returned table and
-- should no longer be referenced by the user.
-- @param open file handle
-- @return tar file handle
-----------------------------------------------------------------------------
public.open = function(file)
	assert(file, 'invalid file handle')
	local archive = {}
	archive.file = file
	archive.list = {}
	local p = file:seek("set")
	while true do
		local block = file:read(512)
		if not block or not string.match(block, "[^%z]") then break end
		local header = private.decode(block)
		if 0 == header.typeflag then
			archive.list[header.pathname] = {
				["offset"] = file:seek(),
				["size"] = header.size
			}
		end
		local p = file:seek("cur", 512 * math.ceil(header.size / 512))
	end
	setmetatable(archive, TarFile)
	return archive
end

return tar

