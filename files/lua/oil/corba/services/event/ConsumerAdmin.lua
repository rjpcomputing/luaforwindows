local oil               = require "oil"
local oo                = require "oil.oo"
local assert            = require "oil.assert"
local UnorderedArraySet = require "loop.collection.UnorderedArraySet"
local ProxyPushSupplier = require "oil.corba.services.event.ProxyPushSupplier"

module("oil.corba.services.event.ConsumerAdmin", oo.class)

function __init(class, channel)
  return oo.rawnew(class, {
    channel = channel,
    proxypushsuppliers = UnorderedArraySet()
  })
end

-- The obtain_push_supplier operation returns a ProxyPushSupplier object. The
-- ProxyPushSupplier object is then used to connect a push-style consumer.

function obtain_push_supplier(self)
  return ProxyPushSupplier(self)
end

-- invoked by ProxyPushSupplier to signal it's connected

function add_push_consumer(self, proxy, push_consumer)
  self.proxypushsuppliers:add(proxy)
  self.channel:add_push_consumer(push_consumer)
end

-- invoked by ProxyPushSupplier to signal it's disconnected

function rem_push_consumer(self, proxy, push_consumer)
  assert.results(self.proxypushsuppliers:contains(proxy))
  self.proxypushsuppliers:remove(proxy)
  self.channel:rem_push_consumer(push_consumer)
end

-- invoked by the channel to disconnect all proxies of the admin.
-- must reverse iterate over proxypushsuppliers because the disconnection
-- removes the consumer from the array.

function destroy(self)
  for i=#self.proxypushsuppliers,1,-1 do
    local proxy = self.proxypushsuppliers[i]
    oil.pcall(proxy.disconnect_push_supplier, proxy) 
  end
  self.proxypushsuppliers = nil
  self.channel = nil
end

