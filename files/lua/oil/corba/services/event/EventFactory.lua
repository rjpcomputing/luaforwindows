local oil               = require "oil"
local oo                = require "oil.oo"
local assert            = require "oil.assert"
local os                = require "os"

module("oil.corba.services.event.EventFactory", oo.class)

function create(self, data)
  assert.type(data, "table")
  return {
    created = os.time(),
    data = data
  }
end

