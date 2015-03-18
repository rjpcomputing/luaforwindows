local port      = require "oil.port"
local component = require "oil.component"
local arch      = require "oil.arch"
local base      = require "oil.arch.base"

module "oil.arch.typed"

-- TYPES
TypeRepository = component.Template{
	types = port.Facet,
}

-- CLIENT SIDE
ClientBroker = component.Template({
	types = port.Receptacle,
}, base.ClientBroker)
ObjectProxies = component.Template({
	caches  = port.Facet,
	indexer = port.Receptacle,
}, base.ObjectProxies)

-- SERVER SIDE
ServerBroker = component.Template({
	types  = port.Receptacle,
	mapper = port.Receptacle,
}, base.ServerBroker)
RequestDispatcher = component.Template({
	indexer = port.Receptacle,
}, base.RequestDispatcher)

function assemble(components)
	arch.start(components)
	
	-- CLIENT SIDE
	ObjectProxies.indexer = ProxyIndexer.indexer
	ClientBroker.types    = TypeRepository.types
	
	-- SERVER SIDE
	RequestDispatcher.indexer = ServantIndexer.indexer
	ServerBroker.mapper       = ServantIndexer.mapper
	ServerBroker.types        = TypeRepository.types
	
	arch.finish(components)
end
