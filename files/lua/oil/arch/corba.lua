local pairs = pairs

local port      = require "oil.port"
local component = require "oil.component"
local arch      = require "oil.arch"
local base      = require "oil.arch.typed"
local sysex     = require "oil.corba.idl.sysex"                                 --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.arch.corba"

-- TYPES
TypeRepository = component.Template({
	registry  = port.Facet,
	indexer   = port.Facet,
	compiler  = port.Facet,
	delegated = port.Receptacle,
}, base.TypeRepository)

-- MARSHALING
ValueEncoder = component.Template{
	codec    = port.Facet,
	proxies  = port.Receptacle,
	objects  = port.Receptacle,
	profiler = port.HashReceptacle,
}

-- REFERENCES
ReferenceProfiler = component.Template{
	profiler = port.Facet,
	codec    = port.Receptacle,
}
ObjectReferrer = component.Template{
	references = port.Facet,
	codec      = port.Receptacle,
	types      = port.Receptacle,
	profiler   = port.HashReceptacle,
}

-- MESSENGER
MessageMarshaler = component.Template{
	messenger = port.Facet,
	codec     = port.Receptacle,
}

-- REQUESTER
OperationRequester = component.Template{
	requests  = port.Facet,
	messenger = port.Receptacle,
	channels  = port.HashReceptacle,
	profiler  = port.HashReceptacle,
	mutex     = port.Receptacle,
}
ProxyIndexer = component.Template{
	indexer  = port.Facet,
	members  = port.Receptacle,
	invoker  = port.Receptacle,
	profiler = port.HashReceptacle,
	types    = port.Receptacle,
}

-- LISTENER
RequestListener = component.Template{
	listener  = port.Facet,
	messenger = port.Receptacle,
	channels  = port.HashReceptacle,
	indexer   = port.Receptacle,
	mutex     = port.Receptacle,
}
ServantIndexer = component.Template{
	indexer = port.Facet,
	mapper  = port.Facet,
	members = port.Receptacle,
}

function assemble(components)
	arch.start(components)
	
	-- GIOP MAPPINGS
	local IOPClientChannels  = { [0] = ClientChannels }
	local IOPServerChannels  = { [0] = ServerChannels }
	local ReferenceProfilers = {
		[0]  = IIOPProfiler,
		[""] = IIOPProfiler,
		iiop = IIOPProfiler,
	}
	
	-- IDL DEFINITIONS
	TypeRepository.types:register(sysex)
	
	-- MARSHALING
	ValueEncoder.proxies   = ClientBroker.broker
	ValueEncoder.objects   = ServerBroker.broker
	MessageMarshaler.codec = ValueEncoder.codec

	-- REQUESTER
	OperationRequester.messenger = MessageMarshaler.messenger
	OperationRequester.mutex     = OperationInvoker.mutex
	ProxyIndexer.members         = TypeRepository.indexer
	ProxyIndexer.invoker         = OperationInvoker.invoker
	ProxyIndexer.types           = TypeRepository.types

	-- LISTENER
	RequestListener.messenger = MessageMarshaler.messenger
	RequestListener.indexer   = ServantIndexer.indexer
	RequestListener.mutex     = RequestReceiver.mutex
	ServantIndexer.members    = TypeRepository.indexer
	
	-- COMMUNICATION
	for tag, ClientChannels in pairs(IOPClientChannels) do
		ClientChannels.sockets           = BasicSystem.sockets
		OperationRequester.channels[tag] = ClientChannels.channels
	end
	for tag, ServerChannels in pairs(IOPServerChannels) do
		ServerChannels.sockets        = BasicSystem.sockets
		RequestListener.channels[tag] = ServerChannels.channels
	end
	
	-- REFERENCES
	ObjectReferrer.codec = ValueEncoder.codec
	ObjectReferrer.types = ServantIndexer.indexer
	for tag, ReferenceProfiler in pairs(ReferenceProfilers) do
		ReferenceProfiler.codec          = ValueEncoder.codec
		ValueEncoder.profiler[tag]       = ReferenceProfiler.profiler
		ObjectReferrer.profiler[tag]     = ReferenceProfiler.profiler
		OperationRequester.profiler[tag] = ReferenceProfiler.profiler
		ProxyIndexer.profiler[tag]       = ReferenceProfiler.profiler
	end
	
	arch.finish(components)
end
