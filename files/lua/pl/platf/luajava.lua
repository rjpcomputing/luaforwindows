-- experimental support for LuaJava
--
local path = {}


path.link_attrib = nil

local File = luajava.bindClass("java.io.File")
local Array = luajava.bindClass('java.lang.reflect.Array')

local function file(s)
    return luajava.new(File,s)
end

function path.dir(P)
    local ls = file(P):list()
    print(ls)
    local idx,n = -1,Array:getLength(ls)
    return function ()
        idx = idx + 1
        if idx == n then return nil
        else
            return Array:get(ls,idx)
        end
    end
end

function path.mkdir(P)
    return file(P):mkdir()
end

function path.rmdir(P)
    return file(P):delete()
end

--- is this a directory?
-- @param P A file path
function path.isdir(P)
    if P:match("\\$") then
        P = P:sub(1,-2)
    end
    return file(P):isDirectory()
end

--- is this a file?.
-- @param P A file path
function path.isfile(P)
    return file(P):isFile()
end

-- is this a symbolic link?
-- Direct support for symbolic links is not provided.
-- see http://stackoverflow.com/questions/813710/java-1-6-determine-symbolic-links
-- and the caveats therein.
-- @param P A file path
function path.islink(P)
    local f = file(P)
    local canon
    local parent = f:getParent()
    if not parent then
        canon = f
    else
        parent = f.getParentFile():getCanonicalFile()
        canon = luajava.new(File,parent,f:getName())
    end
    return canon:getCanonicalFile() ~= canon:getAbsoluteFile()
end

--- return size of a file.
-- @param P A file path
function path.getsize(P)
    return file(P):length()
end

--- does a path exist?.
-- @param P A file path
-- @return the file path if it exists, nil otherwise
function path.exists(P)
    return file(P):exists() and P
end

--- Return the time of last access as the number of seconds since the epoch.
-- @param P A file path
function path.getatime(P)
    return path.getmtime(P)
end

--- Return the time of last modification
-- @param P A file path
function path.getmtime(P)
    -- Java time is no. of millisec since the epoch
    return file(P):lastModified()/1000
end

---Return the system's ctime.
-- @param P A file path
function path.getctime(P)
    return path.getmtime(P)
end

return path
