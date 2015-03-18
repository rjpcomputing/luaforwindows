--- File manipulation functions: reading, writing, moving and copying.
--
-- Dependencies: `pl.utils`, `pl.dir`, `pl.path`
-- @module pl.file
local os = os
local utils = require 'pl.utils'
local dir = require 'pl.dir'
local path = require 'pl.path'

--[[
module ('pl.file',utils._module)
]]
local file = {}

--- return the contents of a file as a string
-- @class function
-- @name file.read
-- @param filename The file path
-- @return file contents
file.read = utils.readfile

--- write a string to a file
-- @class function
-- @name file.write
-- @param filename The file path
-- @param str The string
file.write = utils.writefile

--- copy a file.
-- @class function
-- @name file.copy
-- @param src source file
-- @param dest destination file
-- @param flag true if you want to force the copy (default)
-- @return true if operation succeeded
file.copy = dir.copyfile

--- move a file.
-- @class function
-- @name file.move
-- @param src source file
-- @param dest destination file
-- @return true if operation succeeded, else false and the reason for the error.
file.move = dir.movefile

--- Return the time of last access as the number of seconds since the epoch.
-- @class function
-- @name file.access_time
-- @param path A file path
file.access_time = path.getatime

---Return when the file was created.
-- @class function
-- @name file.creation_time
-- @param path A file path
file.creation_time = path.getctime

--- Return the time of last modification
-- @class function
-- @name file.modified_time
-- @param path A file path
file.modified_time = path.getmtime

--- Delete a file
-- @class function
-- @name file.delete
-- @param path A file path
file.delete = os.remove

return file
