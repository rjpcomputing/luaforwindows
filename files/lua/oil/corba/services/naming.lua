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
-- Release: 0.4 alpha                                                         --
-- Title  : Interoperable Naming Service                                      --
-- Authors: Leonardo S. A. Maciel <leonardo@maciel.org>                       --
--------------------------------------------------------------------------------
-- Interface:                                                                 --
--   new() Creates a new instance of a CORBA Naming Service                   --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   See Naming Service Specification v1.3                                    --
--   See section 13.6.10.3 of CORBA 3.0 specification for IIOP corbaloc.      --
--                                                                            --
--   Altough corbaname is specified in section 2.5.3 of Naming Service        --
--   Specification v1.3, it is the responsibility of the ORB to implement it. --
--                                                                            --
--   There are no limitations on the length of a name component.              --
--   There are no limitations on the number of name components in a name.     --
--   There are no limitations on the maximum number of bindings in a context. --
--   There are no limitations on the total number of bindings.                --
--   There are no limitations on the maximum number of contexts.              --
--   There are no limitations on character values or character sequences that --
--   may be used on a name component.                                         --
--   There are no means or policies to deal with orphaned contexts, bindings  --
--   or binding iterators.                                                    --
--   The CannotProceed exception is raised whenever any but the last name     --
--   component of a name is not a context.                                    --
--------------------------------------------------------------------------------

local string = require "string"
local table  = require "table"

local oo                = require "oil.oo"
local assert            = require "oil.assert"
local MapWithArrayOfKey = require "loop.collection.MapWithArrayOfKeys"
local UnorderedArray    = require "loop.collection.UnorderedArray"

module "oil.corba.services.naming"

--------------------------------------------------------------------------------
-- Converting between CosNames, Stringified Names and URLs ---------------------

local function to_url_escape(s)
  return string.gsub(s, "([^a-zA-Z0-9;/:%?@&=%+%$,%-_%.!%~*'%(%)])", function(s)
    return string.format("%%%x", string.byte(s))
  end)
end

local function to_string_escape(s)
  return string.gsub(s, "([/\\.])", "\\%1")
end

local function to_string(n)
  assert.type(n, "table", "name")
  for i = 1,#n do
    local id = n[i].id
    local kind = n[i].kind
    if kind == "" then
      if id == "" then
        n[i] = "."
      else
        n[i] = to_string_escape(id)
      end
    else
      n[i] = to_string_escape(id).."."..to_string_escape(kind)
    end
    --TODO:[lsam] verificar iso-8859-1 ???
    --valid range 32-126 160-255
  end
  local sn = table.concat(n, "/")
  if sn == "" then
    assert.exception{"IDL:omg.org/CosNaming/NamingContext/InvalidName:1.0" }
  end
  return sn
end

local function to_name(sn)
  local n = {}
  local id = ""
  local kind = ""
  local inEscapeMode = false
  local inKindMode = false
  local last = "/"
  --TODO:[lsam] verificar iso-8859-1 ???
  --valid range 32-126 160-255
  for i=1,string.len(sn)+1 do
    local cur = string.sub(sn,i,i)
    if inEscapeMode then
      if inKindMode then
        kind = kind..cur
      else
        id = id..cur
      end
      inEscapeMode = false
    else
      if cur == "\\" then
        inEscapeMode = true
      elseif cur == "." then
        inKindMode = true
      elseif cur == "/" or i == string.len(sn)+1 then
        if last == "/" then
          assert.exception{"IDL:omg.org/CosNaming/NamingContext/InvalidName:1.0" }
        else
          table.insert(n, {id=id, kind=kind})
          id = ""
          kind = ""
          inKindMode = false
        end
      else
        if inKindMode then
          kind = kind..cur
        else
          id = id..cur
        end
      end
    end
    last = cur
  end
  return n
end

--------------------------------------------------------------------------------
-- BindingIterator interface implementation ------------------------------------

BindingIterator = oo.class()

function BindingIterator:__init(bindings)
  return oo.rawnew(self, {bindings = bindings})
end

function BindingIterator:next_one()
  if not self.bindings then
    assert.exception{"IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0"}
  end
  local obj = table.remove(self.bindings, 1)
  return (obj~=nil), obj
end

function BindingIterator:next_n(how_many)
  if not self.bindings then
    assert.exception{"IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0"}
  end
  local bl = {}
  if how_many == 0 then
    assert.exception{"IDL:omg.org/CORBA/BAD_PARAM:1.0"}
  end
  for i=1,#self.bindings do
    if i > how_many then break end
    table.insert(bl, table.remove(self.bindings,1))
  end
  return (#bl > 0), bl
end

function BindingIterator:destroy()
  if not self.bindings then
    assert.exception{"IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0"}
  end
  self.bindings = nil
end

--------------------------------------------------------------------------------
-- NamingContext interface implementation --------------------------------------

NamingContext = oo.class()

function NamingContext:__init()
  return oo.rawnew(self, {bindings = MapWithArrayOfKey()})
end

function NamingContext:bind(n, obj)
  local sn, except = to_string({n[1]})
  local r = self.bindings:value(sn)
  if #n > 1 then
    if not r then
      assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotFound:1.0",
        why = "missing_node",
        rest_of_name = n
      }
    else
      if r.binding_type ~= "ncontext" then
        assert.exception{"IDL:omg.org/CosNaming/NamingContext/CannotProceed:1.0",
          cxt = self,
          rest_of_name = n
        }
      else
        table.remove(n,1)
        return (r.obj):bind(n, obj)
      end
    end
  else
    if r then
      assert.exception{"IDL:omg.org/CosNaming/NamingContext/AlreadyBound:1.0"}
    else
      self.bindings:add(sn, {binding_type="nobject", obj=obj})
    end
  end
end

function NamingContext:rebind(n, obj)
  local sn, except = to_string({n[1]})
  local r = self.bindings:value(sn)
  if #n > 1 then
    if not r then
      assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotFound:1.0",
        why = "missing_node",
        rest_of_name = n
      }
    else
      if r.binding_type ~= "ncontext" then
        assert.exception{"IDL:omg.org/CosNaming/NamingContext/CannotProceed:1.0",
          cxt = self,
          rest_of_name = n
        }
      else
        table.remove(n,1)
        return (r.obj):rebind(n, obj)
      end
    end
  else
    if r then
      if r.binding_type ~= "nobject" then
        assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotFound:1.0",
          why = "not_object",
          rest_of_name = {n[1]}
        }
      else
        r.obj = obj
      end
    else
      self.bindings:add(sn, {binding_type="nobject", obj=obj})
    end
  end
end

function NamingContext:bind_context(n, nc)
  if not nc then assert.exception{"IDL:omg.org/CORBA/BAD_PARAM:1.0"} end
  local sn, except = to_string({n[1]})
  local r = self.bindings:value(sn)
  if #n > 1 then
    if not r then
      assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotFound:1.0",
        why = "missing_node",
        rest_of_name = n
      }
    else
      if r.binding_type ~= "ncontext" then
        assert.exception{"IDL:omg.org/CosNaming/NamingContext/CannotProceed:1.0",
          cxt = self,
          rest_of_name = n
        }
      else
        table.remove(n,1)
        return (r.obj):bind_context(n, nc)
      end
    end
  else
    if r then
      assert.exception{"IDL:omg.org/CosNaming/NamingContext/AlreadyBound:1.0"}
    else
      self.bindings:add(sn, {binding_type="ncontext", obj=nc})
    end
  end
end

function NamingContext:rebind_context(n, nc)
  if not nc then assert.exception{"IDL:omg.org/CORBA/BAD_PARAM:1.0"} end
  local sn, except = to_string({n[1]})
  local r = self.bindings:value(sn)
  if #n > 1 then
    if not r then
      assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotFound:1.0",
        why = "missing_node",
        rest_of_name = n
      }
    else
      if r.binding_type ~= "ncontext" then
        assert.exception{"IDL:omg.org/CosNaming/NamingContext/CannotProceed:1.0",
          cxt = self,
          rest_of_name = n
        }
      else
        table.remove(n,1)
        return (r.obj):rebind_context(n, nc)
      end
    end
  else
    if r then
      if r.binding_type ~= "ncontext" then
        assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotFound:1.0",
          why = "not_context",
          rest_of_name = {n[1]}
        }
      else
        r.obj = nc
      end
    else
      self.bindings:add(sn, {binding_type="ncontext", obj=nc})
    end
  end
end

function NamingContext:resolve(n)
  local sn, except = to_string({n[1]})
  local r = self.bindings:value(sn)
  if not r then
    assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotFound:1.0",
      why = "missing_node",
      rest_of_name = n
    }
  elseif #n > 1 then
    if r.binding_type ~= "ncontext" then
      assert.exception{"IDL:omg.org/CosNaming/NamingContext/CannotProceed:1.0",
        cxt = self,
        rest_of_name = n
      }
    else
      table.remove(n,1)
      return (r.obj):resolve(n)
    end
  else
    return r.obj
  end
end

function NamingContext:unbind(n)
  local sn, except = to_string({n[1]})
  local r = self.bindings:value(sn)
  if not r then
    assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotFound:1.0",
      why = "missing_node",
      rest_of_name = n
    }
  elseif #n > 1 then
    if r.binding_type ~= "ncontext" then
      assert.exception{"IDL:omg.org/CosNaming/NamingContext/CannotProceed:1.0",
        cxt = self,
        rest_of_name = n
      }
    else
      table.remove(n,1)
      return (r.obj):unbind(n)
    end
  else
    self.bindings:remove(sn)
  end
end

function NamingContext:new_context()
  local nc = NamingContext()
  return nc
end

function NamingContext:bind_new_context(n)
  local nc = self:new_context()
  self:bind_context(n, nc)
  return nc
end

function NamingContext:destroy()
  if self.bindings:size() > 0 then
    assert.exception{"IDL:omg.org/CosNaming/NamingContext/NotEmpty:1.0" }
  else
    self.bindings = nil
  end
end

local function BindingList(b, how_many)
  return bl, bi
end

function NamingContext:list(how_many)
  local i = 1
  local bl = {}
  local bi = {}
  for i=1,self.bindings:size() do
    local k = self.bindings:keyat(i)
    local v = self.bindings:valueat(i)
    if i > how_many then
      table.insert(bi, {binding_name=to_name(k), binding_type=v.binding_type})
    else
      table.insert(bl, {binding_name=to_name(k), binding_type=v.binding_type})
    end
  end
  return bl, BindingIterator(bi)
end

--------------------------------------------------------------------------------
-- NamingContextExt interface implementation -----------------------------------

NamingContextExt = oo.class({}, NamingContext)

function NamingContextExt:to_string(n)
  return to_string(n)
end

function NamingContextExt:to_name(sn)
  return to_name(sn)
end

function NamingContextExt:to_url(addr, sn)
  local url = {"corbaname:", addr}
  if not addr or addr == "" then
    assert.exception{"IDL:omg.org/CosNaming/NamingContextExt/InvalidAddress:1.0"}
  end
  if sn and string.len(sn) > 0 then
    local esn = to_url_escape(sn)
    table.insert(url, "#")
    table.insert(url, esn)
  end
  return table.concat(url)
end

function NamingContextExt:resolve_str(sn)
  return self:resolve(to_name(sn))
end

--------------------------------------------------------------------------------
-- Resolve initial Name Service ------------------------------------------------

-- @return 1 table CORBA object which is the root context of the Naming Service.
-- @return 2 string Repository ID of interface supported by the Naming Service.
-- @return 3 string Object key used in the Naming Service object reference.

function new()
  return NamingContextExt(),
         "NamingService",
         "IDL:omg.org/CosNaming/NamingContextExt:1.0"
end
