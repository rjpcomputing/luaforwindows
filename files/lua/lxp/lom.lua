-- See Copyright Notice in license.html
-- $Id: lom.lua,v 1.6 2005/06/09 19:18:40 tuler Exp $

require "lxp"

local tinsert, tremove, getn = table.insert, table.remove, table.getn
local assert, type, print = assert, type, print
local lxp = lxp

module ("lxp.lom")

local function starttag (p, tag, attr)
  local stack = p:getcallbacks().stack
  local newelement = {tag = tag, attr = attr}
  tinsert(stack, newelement)
end

local function endtag (p, tag)
  local stack = p:getcallbacks().stack
  local element = tremove(stack)
  assert(element.tag == tag)
  local level = getn(stack)
  tinsert(stack[level], element)
end

local function text (p, txt)
  local stack = p:getcallbacks().stack
  local element = stack[getn(stack)]
  local n = getn(element)
  if type(element[n]) == "string" then
    element[n] = element[n] .. txt
  else
    tinsert(element, txt)
  end
end

function  parse (o)
  local c = { StartElement = starttag,
              EndElement = endtag,
              CharacterData = text,
              _nonstrict = true,
              stack = {{}}
            }
  local p = lxp.new(c)
  local status, err
  if type(o) == "string" then
    status, err = p:parse(o)
    if not status then return nil, err end
  else
    for l in o do
      status, err = p:parse(l)
      if not status then return nil, err end
    end
  end
  status, err = p:parse()
  if not status then return nil, err end
  p:close()
  return c.stack[1][1]
end

