local oil               = require "oil"
local oo                = require "oil.oo"
local assert            = require "oil.assert"

module("oil.corba.services.event.ProxyPushSupplier", oo.class)

function __init(class, admin)
  return oo.rawnew(class, {
    admin = admin,
    connected = false,
    push_consumer = nil
  })
end

-- Implementations shall raise the CORBA standard BAD_PARAM exception if a nil
-- object reference is passed to the connect_push_consumer operation.  If the
-- ProxyPushSupplier is already connected to a PushConsumer, then the
-- AlreadyConnected exception is raised.
--
-- An implementation of a ProxyPushSupplier may put additional requirements on
-- the interface supported by the push consumer.  If the push consumer does not
-- meet those requirements, the ProxyPushSupplier raises the TypeError
-- exception.

function connect_push_consumer(self, push_consumer)                
  if self.connected then
    assert.exception{"IDL:omg.org/CosEventChannelAdmin/AlreadyConnected:1.0"}
  elseif not push_consumer then
    assert.exception{"IDL:omg.org/CORBA/BAD_PARAM:1.0"}
  end
  self.push_consumer = push_consumer
  self.connected = true
  self.admin:add_push_consumer(self, self.push_consumer)
end

-- The disconnect_push_supplier operation terminates the event communication; it
-- releases resources used at the supplier to support the event communication.
-- The PushSupplier object reference is disposed.  Calling
-- disconnect_push_supplier causes the implementation to call the
-- disconnect_push_consumer operation on the corresponding PushConsumer
-- interface (if that interface is known).
-- 
-- Calling a disconnect operation on a consumer or supplier interface may cause
-- a call to the corresponding disconnect operation on the connected supplier or
-- consumer.
--
-- Implementations must take care to avoid infinite recursive calls to these
-- disconnect operations. If a consumer or supplier has received a disconnect
-- call and subsequently receives another disconnect call, it shall raise a
-- CORBA::OBJECT_NOT_EXIST exception.

function disconnect_push_supplier(self)
  if not self.connected then
    assert.exception{"IDL:omg.org/CORBA/OBJECT_NOT_EXIST:1.0"}
  end
  self.connected = false
  assert.results(self.push_consumer)
  self.admin:rem_push_consumer(self, self.push_consumer)
  oil.pcall(self.push_consumer.disconnect_push_consumer, self.push_consumer)
  self.push_consumer = nil
end

