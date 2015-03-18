local port      = require "oil.port"
local component = require "oil.component"
local arch      = require "oil.arch"

module "oil.arch.ludo"

-- MARSHALING
ValueEncoder = component.Template{
	codec = port.Facet,
}

-- REFERENCES
ObjectReferrer = component.Template{
	references = port.Facet,
}

-- REQUESTER
OperationRequester = component.Template{
	requests = port.Facet,
	channels = port.Receptacle,
	codec    = port.Receptacle,
}

-- LISTENER
RequestListener = component.Template{
	listener = port.Facet,
	channels = port.Receptacle,
	codec = port.Receptacle,
}

function assemble(components)
	arch.start(components)
	
	-- COMMUNICATION
	ClientChannels.sockets = BasicSystem.sockets
	ServerChannels.sockets = BasicSystem.sockets
	
	-- REQUESTER
	OperationRequester.codec    = ValueEncoder.codec
	OperationRequester.channels = ClientChannels.channels
	
	-- LISTENER
	RequestListener.codec    = ValueEncoder.codec
	RequestListener.channels = ServerChannels.channels
	
	-- MARSHALING
	ValueEncoder.codec:localresources(components)
	
	arch.finish(components)
end
