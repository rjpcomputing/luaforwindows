-- vstruct, the versatile struct library
-- Copyright � 2008 Ben "ToxicFrog" Kelly; see COPYING

local table,math,type,require,assert,_unpack = table,math,type,require,assert,unpack

local print = print

module((...))

cursor = require (_NAME..".cursor")
compile = require (_NAME..".compile")

function math.trunc(n)
	if n < 0 then
		return math.ceil(n)
	else
		return math.floor(n)
	end
end

-- turn an int into a list of booleans
-- the length of the list will be the smallest number of bits needed to
-- represent the int
function explode(int, size)
    assert(int, "struct.explode: missing argument")
    size = size or 0
    
	local mask = {}
	while int ~= 0 or #mask < size do
		table.insert(mask, int % 2 ~= 0)
		int = math.trunc(int/2)
	end
	return mask
end

-- turn a list of booleans into an int
-- the converse of explode
function implode(mask, size)
    size = size or #mask
    
	local int = 0
	for i=size,1,-1 do
		int = int*2 + ((mask[i] and 1) or 0)
	end
	return int
end

-- given a source, which is either a string or a file handle,
-- unpack it into individual data based on the format string
function unpack(fmt, source, untable)
	-- wrap it in a cursor so we can treat it like a file
	if type(source) == 'string' then
		source = cursor(source)
	end

	assert(fmt and source and type(fmt) == "string", "struct: invalid arguments to unpack")

	-- the lexer will take our format string and generate code from it
	-- it returns a function that when called with our source, will
	-- unpack the data according to the format string and return all
	-- values from said unpacking in a list
    if untable then
        --local t = compile.unpack(fmt)(source)
        --print(t)
       -- print(_unpack(t))
    	return _unpack((compile.unpack(fmt)(source)))
    else
        return compile.unpack(fmt)(source)
    end
end

-- given a format string and a list of data, pack them
-- if 'fd' is omitted, pack them into and return a string
-- otherwise, write them directly to the given file
function pack(fmt, fd, data)
	local str_fd
	
	if not data then
		data = fd
		fd = ""
	end
	
	if type(fd) == 'string' then
		fd = cursor("")
		str_fd = true
	end
	
	assert(fmt and fd and data and type(fmt) == "string", "struct: invalid arguments to pack")
	
	local fd,len = compile.pack(fmt)(fd, data)
	return (str_fd and fd.str) or fd,len
end

return struct
