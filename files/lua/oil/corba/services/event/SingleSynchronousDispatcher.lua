local oil             = require "oil"
local oo              = require "oil.oo"
local assert          = require "oil.assert"
local pairs           = pairs

module("oil.corba.services.event.SingleSynchronousDispatcher", oo.class)

local function dispatch(consumer, event)
  local b,e = oil.pcall(consumer.push, consumer, event.data)
  assert.results(b)
end

function __init(class, event_queue, consumers)
  assert.type(event_queue, "table")
  local self = oo.rawnew(class, {
    event_queue = event_queue,
    consumers = consumers or {},
  })
  oil.tasks:start(self.run, self)
  return self
end

function add_consumer(self, push_consumer)
  self.consumers[push_consumer] = true
end

function rem_consumer(self, push_consumer)
  self.consumers[push_consumer] = nil
end

function run(self)
  while true do
    local e = self.event_queue:dequeue()
    for c in pairs(self.consumers) do
      dispatch(c, e)
    end
  end
end

