local oil               = require "oil"
local oo                = require "oil.oo"
local assert            = require "oil.assert"

module("oil.corba.services.event.ProxyPushConsumer", oo.class)

-- Proxies are in one of three states: disconnected, connected, or destroyed.  
-- Push/pull operations are only valid in the connected state.

function __init(class, admin)                                        
  assert.results(admin)
  return oo.rawnew(class, {
    admin = admin,
    connected = false,
    push_supplier = nil
  })
end

-- A supplier communicates event data to the consumer by invoking the push 
-- operation and passing the event data as a parameter.

function push(self, data)                                           
  if not self.connected then
    assert.exception{"IDL:omg.org/CosEventComm/Disconnected:1.0"}
  end
  local channel = self.admin.channel
  local event = channel.event_factory:create(data)
  channel.event_queue:enqueue(event)
end

-- A nil object reference may be passed to the connect_push_supplier operation. 
-- If so a channel cannot invoke the disconnect_push_supplier operation on the
-- supplier. The supplier may be disconnected from the channel without being 
-- informed. If a nonnil reference is passed to connect_push_supplier, the
-- implementation calls disconnect_push_supplier via that reference when the 
-- ProxyPushConsumer is destroyed.
-- 
-- If the ProxyPushConsumer is already connected to a PushSupplier, then the
-- AlreadyConnected exception is raised.

function connect_push_supplier(self, push_supplier)                 
  if self.connected then
    assert.exception{"IDL:omg.org/CosEventChannelAdmin/AlreadyConnected:1.0"}
  end
  self.push_supplier = push_supplier
  self.admin:add_push_supplier(self, push_supplier)
  self.connected = true
end

-- The disconnect_push_consumer operation terminates the event communication.
-- It releases resources used at the consumer to support the event
-- communication.  The PushConsumer object reference is disposed.  Calling 
-- disconnect_push_consumer causes the implementation to call the
-- disconnect_push_supplier operation on the corresponding PushSupplier 
-- interface (if that interface is known).
-- 
-- Calling a disconnect operation on a consumer or supplier interface may cause
-- a call to the corresponding disconnect operation on the connected supplier
-- or consumer.  Implementations must take care to avoid infinite recursive
-- calls to these disconnect operations.  If a consumer or supplier has received
-- a disconnect call and subsequently receives another disconnect call, it shall
-- raise a CORBA::OBJECT_NOT_EXIST exception.

function disconnect_push_consumer(self)
  if not self.connected then
    assert.exception{"IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0"}
  end
  self.connected = false
  if self.push_supplier then -- supplier may be nil
    self.admin:rem_push_supplier(self, push_supplier)
    oil.pcall(self.push_supplier.disconnect_push_supplier, self.push_supplier)
    self.push_supplier = nil
  end
end

