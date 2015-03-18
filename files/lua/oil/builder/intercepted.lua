local require   = require
local builder   = require "oil.builder"
local base      = require "oil.arch.base"
local corba     = require "oil.arch.corba"
local component = require "loop.component.wrapped"
local port      = require "loop.component.intercepted"

module "oil.builder.intercepted"

-- Avoid using a typed request dispatcher because the GIOP protocol already
-- does type checks prior to decode marshaled values in invocation requests.
-- See notes below:

arch = {
	OperationRequester = component.Template({
		requests  = port.Facet,
		messenger = port.Receptacle,
	}, corba.OperationRequester),
	RequestListener = component.Template({
		messenger = port.Receptacle,
	}, corba.RequestListener),
	RequestDispatcher = component.Template({
		dispatcher = port.Facet,
	}, base.RequestDispatcher), -- use template from base architecture
}

OperationRequester = arch.OperationRequester{require "oil.corba.giop.Requester" }
RequestListener    = arch.RequestListener   {require "oil.corba.giop.Listener"  }
RequestDispatcher  = arch.RequestDispatcher {require "oil.kernel.base.Dispatcher"} -- use implementation from base kernel

function create(comps)
	return builder.create(_M, comps)
end
