-- $Id$
--******************************************************************************
-- Copyright 2002 Noemi Rodriquez & Roberto Ierusalimschy. All rights reserved. 
--******************************************************************************

--------------------------------------------------------------------------------
------------------------------  #####      ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------ ##   ## ##  ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------  #####  ### ###### ------------------------------
--------------------------------                --------------------------------
----------------------- An Object Request Broker in Lua ------------------------
--------------------------------------------------------------------------------
-- Project: OiL - ORB in Lua: An Object Request Broker in Lua                 --
-- Release: 0.4                                                               --
-- Title  : Properties management package for OiL                             --
-- Authors: Leonardo S. A. Maciel <leonardo@maciel.org>                       --
--------------------------------------------------------------------------------
-- Interface:                                                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--------------------------------------------------------------------------------

local require    = require
local rawget     = rawget
local rawset     = rawset
local oo         = require "loop.base"

module("oil.properties", oo.class)                                              --[[VERBOSE]] local verbose = require "oil.verbose"

--------------------------------------------------------------------------------
-- Key constants ---------------------------------------------------------------

local PARENT = {}
local DEFAULT = {}

--------------------------------------------------------------------------------
-- Properties implementation ---------------------------------------------------

function __index(self, key)
    if key then
        local parent = rawget(self, PARENT)
        local default = rawget(self, DEFAULT)
        local value = parent and parent[key] or default and default[key] or nil
        rawset(self, key, value)
        return value
    else
        return nil
    end
end

function __init(self, parent, default)
    return oo.rawnew(self, {[PARENT] = parent,
                            [DEFAULT]= default})
end

