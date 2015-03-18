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
-- Title  : Event Service                                                     --
-- Authors: Leonardo S. A. Maciel <leonardo@maciel.org>                       --
--------------------------------------------------------------------------------
-- Interface:                                                                 --
--   new() Creates a new instance of a CORBA Event Channel                    --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   This implementation currently does not support typed events.             --
--   This implementation currently does not support pull event model.         --
--------------------------------------------------------------------------------

local oil               = require "oil"
local oo                = require "oil.oo"
local assert            = require "oil.assert"
local EventQueue        = require "oil.corba.services.event.EventQueue"
local EventFactory      = require "oil.corba.services.event.EventFactory"
local EventDispatcher   = require "oil.corba.services.event.SingleSynchronousDispatcher"
--local EventDispatcher   = require "oil.corba.services.event.SingleDeferredDispatcher"
local ConsumerAdmin     = require "oil.corba.services.event.ConsumerAdmin"
local SupplierAdmin     = require "oil.corba.services.event.SupplierAdmin"

module "oil.corba.services.event"

--------------------------------------------------------------------------------
-- In this new version, ConsumerAdmin and SupplierAdmin objects were
-- suppressed and the event channel implements their interface.
--

local EventChannel = oo.class()

function EventChannel.__init(class)
  self = oo.rawnew(class, {
    push_consumer_count = 0,
    push_supplier_count = 0,
    event_queue = EventQueue(),
    event_factory = EventFactory()
  })
  self.event_dispatcher = EventDispatcher(self.event_queue)
  self.consumer_admin = ConsumerAdmin(self)
  self.supplier_admin = SupplierAdmin(self)
  return self
end

-- The destroy operation destroys the event channel. Destroying an event channel
-- destroys all ConsumerAdmin and SupplierAdmin objects that were created via
-- that channel. Destruction of a ConsumerAdmin or SupplierAdmin object causes
-- the implementation to invoke the disconnect operation on all proxies that were
-- created via that ConsumerAdmin or SupplierAdmin object.

function EventChannel:destroy()
  self.event_queue = nil
  self.event_factory = nil
  self.consumer_admin:destroy()
  self.consumer_admin = nil
  self.supplier_admin:destroy()
  self.supplier_admin = nil
  self.event_dispatcher = nil
  self.push_consumer_count = 0
  self.push_supplier_count = 0
end

-- returns an object reference that supports the ConsumerAdmin interface

function EventChannel:for_consumers()
  return self.consumer_admin
end

-- returns an object reference that supports the SupplierAdmin interface

function EventChannel:for_suppliers()
  return self.supplier_admin
end

-- invoked by ConsumerAdmin

function EventChannel:add_push_consumer(push_consumer)
  self.event_dispatcher:add_consumer(push_consumer)
  self.push_consumer_count = self.push_consumer_count + 1
end

-- invoked by ConsumerAdmin

function EventChannel:rem_push_consumer(push_consumer)
  self.event_dispatcher:rem_consumer(push_consumer)
  self.push_consumer_count = self.push_consumer_count - 1
end

-- invoked by SupplierAdmin

function EventChannel:add_push_supplier(push_supplier)
  self.push_supplier_count = self.push_supplier_count + 1
end

-- invoked by SupplierAdmin

function EventChannel:rem_push_supplier(push_supplier)
  self.push_supplier_count = self.push_supplier_count - 1
end


--------------------------------------------------------------------------------
-- Creates a new instance of a CORBA Event Channel -----------------------------

-- @param props table [optional] Properties instance.

-- @return 1 table CORBA object which is an untyped Event Channel.
-- @return 2 string Repository ID of interface supported by the Event Channel.
-- @return 3 string Default Event Channel object key.

function new()
  return EventChannel(),
         "DefaultEventChannel",
         "IDL:omg.org/CosEventChannelAdmin/EventChannel:1.0"
end

