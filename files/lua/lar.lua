-----------------------------------------------------------------------------
-- LAR - Lua ARchives
--
-- Support code to use lar files as a virtual file system.
-- Currently using the ZIP or tar.gz formats.
--
-- Version 1.0 (28/04/2004)
--
-- Redefines the following I/O operations:
--  io.open
--  loadfile
--  dofile
--  require
--
-- Usage:
-- call lar.init(format, extension)
-- use I/O operations assuming the original directory structure
--
-- Author: André Carregal (carregal@keplerproject.org)
--
-- Copyright (c) 2004 Kepler Project
-----------------------------------------------------------------------------
local Public = {}
local Private = {}

lar = Public

local larExtension = ""

-----------------------------------------------------------------------------
-- Inits the LAR library
-- @param format the compression format ("ZIP" or "TAR.GZ", default is "ZIP")
-- @param extension the lar file extension (default is "lar")
-----------------------------------------------------------------------------
Public.init = function(format, extension)
  larExtension = extension or "lar"
  format = format or "ZIP"

  if format == "ZIP" then
    if not zip then require "zip" end
    Public.open = Private.openzip
    Public.close = zip.close
  elseif format == "TAR.GZ" then
    if not tar then require "tar" end
    Public.open = Private.opentar
    Public.close = tar.close
  else
    error("Uknown LAR format")
  end

  Private.openedFiles = {} -- file caching

  -- redefines the global I/O functions
  io.open = Private.ioopen
  loadfile = Private.loadfile
  dofile = Private.dofile
  require = Private.require
end

-----------------------------------------------------------------------------
-- Opens a LAR file using tar.gz format.
-----------------------------------------------------------------------------
Private.opentar = function (filepath, mode)
  -- tries to find a lar in the file path
  local current = ""
  local remain = filepath
  local pos
  while remain and remain ~= "" do
    pos = string.find(remain, "/")
    if (pos) then
      current = current..string.sub(remain, 1, pos - 1)
      remain = string.sub(remain, pos + 1)
      local filename = current.."."..larExtension
      if Private.openedFiles[filename] then
        return Private.openedFiles[filename]
      else
        local gfile = gzip.open(filename, "rb")
        if gfile then
          local tarfile = tar.open(gfile)
          if tarfile then
	    local file = tarfile:open(remain)
            Private.openedFiles[filepath] = file
            return file
          end
        else
          current = current.."/"
        end
      end
    else
      current = current..remain
      remain = ""
    end
  end
end

-----------------------------------------------------------------------------
-- Opens a LAR file using ZIP format (default)
-----------------------------------------------------------------------------
Private.openzip = function (filepath, mode)
  -- tries to find a lar in the file path
  local current = ""
  local remain = filepath
  local pos
  while remain and remain ~= "" do
    pos = string.find(remain, "/")
    if (pos) then
      current = current..string.sub(remain, 1, pos - 1)
      remain = string.sub(remain, pos + 1)
      local filename = current.."."..larExtension
      if Private.openedFiles[filepath] then
        return Private.openedFiles[filepath]
      else
        local zfile = zip.open(filename)
        if zfile then
          local file = zfile:open(remain)
          Private.openedFiles[filepath] = file
          zip.close(filename)
          return file
        else
          current = current.."/"
        end
      end
    else
      current = current..remain
      remain = ""
    end
  end
end


local openLars = {}
-----------------------------------------------------------------------------
-- Redefines io.open to handle LAR files.
-----------------------------------------------------------------------------
local open = io.open
Private.ioopen = function (filename, mode)
  local fh, msg = open(filename, mode)
  openLars[filename] = "IO"
  if fh == nil then
    local fh2, msg2 = Public.open(filename, mode)
    openLars[filename] = "LAR"
    if fh2 then
      fh = fh2
      msg = msg2
    end
  end
  return fh, msg
end

-----------------------------------------------------------------------------
-- Redefines io.close to handle LAR files.
-----------------------------------------------------------------------------
local close = io.close
Private.ioclose = function (filename)
  if openLars[filename] == "LAR" then
    Public.close(filename)
  else
    close(filename)
  end
end


-----------------------------------------------------------------------------
-- Redefines loadfile to accept LAR files.
-----------------------------------------------------------------------------
local _loadfile = loadfile
Private.loadfile = function (filename)
  local fh, chunk, msg
  chunk, msg = _loadfile(filename)
  if chunk == nil then
    fh, msg = Public.open(filename)
    if fh ~= nil then
      local contents = fh:read("*a")
      fh:close()
      if contents then
        chunk, msg = loadstring(contents)
      end
    end
  end
  return chunk, msg
end

-----------------------------------------------------------------------------
-- Redefines loadfile to accept LAR files.
-----------------------------------------------------------------------------
local _dofile = dofile
Private.dofile = function (filename)
  local chunk, msg, ret
  chunk, msg = loadfile(filename)
  if chunk then
    ret = chunk()
  end
  return ret
end

-----------------------------------------------------------------------------
-- Redefines require to accept LAR files.
-----------------------------------------------------------------------------
local _require = require
Private.require = function (packagename)
  local status, ret = pcall(_require, packagename)
  if status then
    return ret
  end

  local filepath = string.gsub("?;?.lua", "?", packagename)
  for p in string.gfind(filepath, "([^;]+)") do
    local chunk, msg = loadfile(p)
    if chunk then
      res = chunk() or true
      package.loaded[packagename] = res
    end
  end

  return res
end

Public.init("TAR.GZ")
