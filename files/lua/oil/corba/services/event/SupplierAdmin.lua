local oil               = require "oil"
local oo                = require "oil.oo"
local assert            = require "oil.assert"
local UnorderedArraySet = require "loop.collection.UnorderedArraySet"
local ProxyPushConsumer = require "oil.corba.services.event.ProxyPushConsumer"

module("oil.corba.services.event.SupplierAdmin", oo.class)

function __init(class, channel)
  return oo.rawnew(class, {
    channel = channel,
    proxypushconsumers = UnorderedArraySet()
  })
end

-- The obtain_push_consumer operation returns a ProxyPushConsumer object.
-- The ProxyPushConsumer object is then used to connect a push-style supplier.

function obtain_push_consumer(self)
  return ProxyPushConsumer(self)
end

-- invoked by ProxyPushConsumer to signal it's connected

function add_push_supplier(self, proxy, push_supplier)
  self.proxypushconsumers:add(proxy)
  self.channel:add_push_supplier(push_supplier)
end

-- invoked by ProxyPushConsumer to signal it's connected

function rem_push_supplier(self, proxy, push_supplier)
  assert.results(self.proxypushconsumers:contains(proxy))
  self.proxypushconsumers:remove(proxy)
  self.channel:rem_push_supplier(push_supplier)
end

-- invoked by the channel to disconnect all proxies of the admin
-- must reverse iterate over proxypushconsumers because the disconnection
-- removes the supplier from the array.

function destroy(self)
  for i=#self.proxypushconsumers,1,-1 do
    local proxy = self.proxypushconsumers[i]
    oil.pcall(proxy.disconnect_push_consumer, proxy)
  end
  self.proxypushconsumers = nil
  self.channel = nil
end

