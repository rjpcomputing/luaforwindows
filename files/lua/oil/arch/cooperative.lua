local port      = require "oil.port"
local component = require "oil.component"
local arch      = require "oil.arch"
local base      = require "oil.arch.base"                                       --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.arch.cooperative"

BasicSystem = component.Template({
	control = port.Facet,
	tasks   = port.Facet,
}, base.BasicSystem)

OperationInvoker = component.Template({
	mutex = port.Facet,
	tasks = port.Receptacle,
}, base.OperationInvoker)

RequestReceiver = component.Template({
	mutex = port.Facet,
	tasks = port.Receptacle,
}, base.RequestReceiver)

function assemble(components)
	arch.start(components)
	
	OperationInvoker.tasks = BasicSystem.tasks
	RequestReceiver.tasks  = BasicSystem.tasks
	
	-- define 'pcall' used in invocation dispatching.
	-- the function is retrieved by a method call because contained
	-- components cannot index functions that are not executed as methods.
	RequestDispatcher.dispatcher.pcall = BasicSystem.tasks:getpcall()
	
	arch.finish(components)
end
