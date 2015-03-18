local oil             = require "oil"
local oo              = require "oil.oo"
local assert          = require "oil.assert"
local pairs           = pairs
local next            = next
local io              = io
local coroutine       = coroutine

module("oil.corba.services.event.SingleDeferredDispatcher", oo.class)

local calls = {} -- futures

local function dispatch(consumer, event)
  calls[consumer.__deferred:push(event.data)] = consumer
end

local function waitforresults()
  repeat
    for call, id in pairs(calls) do
      if call:ready() then
        --io.write("ready, ")
        if call:results()
          then --io.write("success\n"); io.flush()
          else io.write("failure\n"); io.flush() -- TODO retry
        end
        calls[call] = nil
      end
    end
    coroutine.yield()
  until next(calls) == nil
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
    waitforresults()
  end
end

