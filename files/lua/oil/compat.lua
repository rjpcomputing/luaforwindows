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
-- Title  : OiL main programming interface (API)                              --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Interface:                                                                 --
--   VERSION                                                                  --
--                                                                            --
--   assemble(flavor)                                                         --
--                                                                            --
--   types                                                                    --
--   loadidl(code)                                                            --
--   loadidlfile(path)                                                        --
--   getLIR()                                                                 --
--   getIR()                                                                  --
--   setIR(ir)                                                                --
--                                                                            --
--   newproxy(objref, [iface])                                                --
--   narrow(proxy, [iface])                                                   --
--                                                                            --
--   newservant(impl, [iface], [key])                                          --
--   deactivate(object, [type])                                               --
--   tostring(object)                                                         --
--                                                                            --
--   Config                                                                   --
--   init()                                                                   --
--   pending()                                                                --
--   step()                                                                   --
--   run()                                                                    --
--   shutdown()                                                               --
--                                                                            --
--   main(function)                                                           --
--   newthread(function, ...)                                                 --
--   pcall(function, ...)                                                     --
--   sleep(time)                                                              --
--   time()                                                                   --
--   tasks                                                                    --
--                                                                            --
--   newencoder()                                                             --
--   newdecoder(stream)                                                       --
--                                                                            --
--   newexcept(body)                                                          --
--   setexcatch(callback, [type])                                             --
--                                                                            --
--   setclientinterceptor([iceptor])                                          --
--   setserverinterceptor([iceptor])                                          --
--                                                                            --
--   createservant(impl, [iface], [key])                                      --
--   createproxy(objref, [iface])                                             --
--                                                                            --
--   writeto(filepath, text)                                                  --
--   readfrom(filepath)                                                       --
--   writeIOR(servant, filepath)                                              --
--   readIOR(filepath)                                                        --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--------------------------------------------------------------------------------

local module   = module
local luapcall = pcall
local require  = require

local io        = require "io"
local coroutine = require "coroutine"

local builder   = require "oil.builder"
local assert    = require "oil.assert"

local OIL_FLAVOR = OIL_FLAVOR

--------------------------------------------------------------------------------
-- OiL main programming interface (API).

-- This API provides access to the basic functionalities of the OiL ORB.
-- More advanced features may be accessed through more specialized interfaces
-- provided by internal components. OiL internal component organization is meant
-- to be customized for the application.

module "oil"

VERSION = "OiL 0.4 beta"

--------------------------------------------------------------------------------
-- Creates and assembles OiL components to compose an ORB instance.
--
-- The 'flavor' parameter defines a list of archtectural levels.
-- Each level defines a set of components and connections that extends the
-- following level.
--
-- Components are created by builder modules registered under namespace
-- 'oil.builder.*' that must provide a 'create(components)' function.
-- The parameter 'components' is a table with all components created by the
-- previous levels builders and that must be used to store the components
-- created by the builder.
--
-- Components created by a previous builder should not be replaced by components
-- created by following builders.
-- After all level components are they are assembled by assembler modules
-- registered under namespace 'oil.arch.*' that must provide a
-- 'assemble(components)' function.
-- The parameter 'components' is a table with all components created by the
-- levels builders.
--
-- NOTE: A default assembly is created when the 'oil' package is first required
-- with levels "corba;typed;cooperative;base" or the one defined by global
-- variable 'OIL_FLAVOR'.
--
-- @param flavor string Semi-colom separated list of component archtectures.
-- @param [comps] table Table where assembled components must be stored.
-- @return table Table with assembled components.
--
-- @usage comps = assemble("corba;typed;cooperative;base")                     .
-- @usage comps = assemble("corba;typed;base")                                 .
-- @usage comps = assemble("ludo;cooperative;base")                            .
--
function assemble(flavor, comps)
	assert.type(flavor, "string", "OiL flavor name")
	return builder.build(flavor, comps)
end

assemble(OIL_FLAVOR or "corba;typed;cooperative;base", _M)
-- UNCOMMENT THIS LINE FOR COMPATIBILITY WITH VERSION 0.3
--assemble(OIL_FLAVOR or "corba;typed;base", _M)

--------------------------------------------------------------------------------
-- Internal interface repository used by the ORB.
--
-- This is a alias for a facet of the Type Respository component of the internal
-- architecture.
-- If the current assembly does not provide this component, this field is 'nil'.
--
-- @usage oil.types:register(oil.corba.idl.sequence{oil.corba.idl.string})     .
-- @usage oil.types:lookup("CORBA::StructDescription")                         .
-- @usage oil.types:lookup_id("IDL:omg.org/CORBA/InterfaceDef:1.0")            .
--
types = TypeRepository and TypeRepository.types

--------------------------------------------------------------------------------
-- Loads an IDL code strip into the internal interface repository.
--
-- The IDL specified will be parsed by the LuaIDL compiler and the resulting
-- definitions are updated in the internal interface repository.
-- If any errors occurs during the parse no definitions are loaded into the IR.
--
-- @param idlspec string The IDL code strip to be loaded into the local IR.
-- @return ... object IDL descriptors that represents the loaded definitions.
--
-- @usage oil.loadidl [[
--          interface Hello {
--            attribute boolean quiet;
--            readonly attribute unsigned long count;
--            string say_hello_to(in string msg);
--          };
--        ]]                                                                   .
--
function loadidl(idlspec)
	assert.type(idlspec, "string", "IDL specification")
	return assert.results(TypeRepository.compiler:load(idlspec))
end

--------------------------------------------------------------------------------
-- Loads an IDL file into the internal interface repository.
--
-- The file specified will be parsed by the LuaIDL compiler and the resulting
-- definitions are updated in the internal interface repository.
-- If any errors occurs during the parse no definitions are loaded into the IR.
--
-- @param filename string The path to the IDL file that must be loaded.
-- @return ... object IDL descriptors that represents the loaded definitions.
--
-- @usage oil.loadidlfile "/usr/local/corba/idl/CosNaming.idl"                 .
-- @usage oil.loadidlfile("HelloWorld.idl", "/tmp/preprocessed.idl")           .
--
function loadidlfile(filepath)
	assert.type(filepath, "string", "IDL file path")
	return assert.results(TypeRepository.compiler:loadfile(filepath))
end

--------------------------------------------------------------------------------
-- Get the servant of the internal interface repository.
--
-- Function used to retrieve a reference to the integrated Interface Repository.
-- It returns a reference to the object that implements the internal Interface
-- Repository and exports local cached interface definitions.
--
-- @return proxy CORBA object that exports the local interface repository.
--
-- @usage oil.writeto("ir.ior", oil.tostring(oil.getLIR()))                    .
--
function getLIR()
	return newservant(TypeRepository.types,
	                 "IDL:omg.org/CORBA/Repository:1.0",
	                 "InterfaceRepository")
end

--------------------------------------------------------------------------------
-- Get the remote interface repository used to retrieve interface definitions.
--
-- Function used to set the remote Interface Repository that must be used to
-- retrieve interface definitions not stored in the internal IR.
-- Once these definitions are acquired, they are stored in the internal IR.
--
-- @return proxy Proxy for the remote IR currently used.
--
function getIR()
	return TypeRepository.delegated
end

--------------------------------------------------------------------------------
-- Defines a remote interface repository used to retrieve interface definitions.
--
-- Function used to get a reference to the Interface Repository used to retrieve
-- interface definitions not stored in the internal IR.
--
-- @param ir proxy Proxy for the remote IR to be used.
--
-- @usage oil.setIR(oil.newproxy("corbaloc::cos_host/InterfaceRepository",
--                               "IDL:omg.org/CORBA/Repository:1.0"))          .
--
function setIR(ir)
	TypeRepository.delegated = ir
end

--------------------------------------------------------------------------------
-- Creates a proxy for a remote object defined by a textual reference.
--
-- The value of reference must be a string containing reference information of
-- the object the new new proxy will represent like a stringfied IOR
-- (Inter-operable Object Reference) or corbaloc.
-- Optionally, an interface supported by the remote object may be defined, in
-- this case no attempt is made to determine the actual object interface, i.e.
-- no network communication is made to check the object's interface.
--
-- @param object string Textual representation of object's reference the new
-- proxy will represent.
-- @param interface string [optional] Interface identification in the interface
-- repository, like a repID or absolute name of a interface the remote object
-- supports (no interface or type check is done).
--
-- @return table Proxy to the remote object.
--
-- @usage oil.newproxy("IOR:00000002B494...")                                  .
-- @usage oil.newproxy("IOR:00000002B494...", "HelloWorld::Hello")             .
-- @usage oil.newproxy("IOR:00000002B494...", "IDL:HelloWorld/Hello:1.0")      .
-- @usage oil.newproxy("corbaloc::host:8080/Key", "IDL:HelloWorld/Hello:1.0")  .
--
function newproxy(object, type)
	if Config then init(Config) end
	assert.type(object, "string", "object reference")
	return assert.results(ClientBroker.broker:fromstring(object, type))
end

--------------------------------------------------------------------------------
-- Narrow an object reference into some more specific interface supported by the
-- remote object.
--
-- The object's reference is defined as a proxy object.
-- If you wish to create a proxy to an object specified by a textual reference
-- like an IOR (Inter-operable Object Reference) that is already narrowed into
-- function.
-- The interface the object reference must be narrowed into is defined by the
-- parameter 'interface' (e.g. an interface repository ID).
-- If no interface is defined, then the object reference is narrowed to the most
-- specific interface supported by the remote object.
-- Note that in the former case, no attempt is made to determine the actual
-- object interface, i.e. no network communication is made to check the object's
-- interface.
--
-- @param proxy table Proxy that represents the remote object which reference
-- must be narrowed.
-- @param interface string [optional] Identification of the interface the
-- object reference must be narrowed into (no interface or type check is
-- made).
--
-- @return table New proxy to the remote object narrowed into some interface
-- supported by the object.
--
-- @usage oil.narrow(ns:resolve_str("HelloWorld"))                             .
-- @usage oil.narrow(ns:resolve_str("HelloWorld"), "IDL:HelloWorld/Hello:1.0") .
--
-- @see newproxy
--
function narrow(object, type)
	assert.type(object, "table", "object proxy")
	if type then assert.type(type, "string", "interface definition") end
	return object and object:_narrow(type)
end

--------------------------------------------------------------------------------
-- Creates a new servant implemented in Lua that supports some interface.
--
-- Function used to create a new servant from a table containing attribute
-- values and operation implementations.
-- The value of impl is used as the implementation of the a servant with
-- interface defined by parameter interface (e.g. repository ID or absolute
-- name of a given IDL interface stored in the IR).
-- Optionally, an object key value may be specified to create persistent
-- references.
-- The servant returned by this function offers all servant attributes and
-- methods, as well as implicit basic operations like CORBA's _interface or
-- _is_a.
-- After this call any requests which object key matches the key of the servant
-- are dispathed to its implementation.
--
-- @param object table Value used as the servant implementation (may be any
-- indexable value, e.g. userdata with a metatable that defined the __index
-- field).
-- @param interface string Interface identification line an absolute name of the
-- interface in the internal interface repository.
-- @param key string [optional] User-defined object key used in creation of the
-- object reference.
--
-- @return table servant created.
--
-- @usage oil.newservant({say_hello_to=print},"IDL:HelloWorld/Hello:1.0")      .
-- @usage oil.newservant({say_hello_to=print},"::HelloWorld::Hello")           .
-- @usage oil.newservant({say_hello_to=print},"::HelloWorld::Hello", "Key")    .
--
function newservant(impl, type, key)
	if Config then init(Config) end
	if not impl then assert.illegal(impl, "servant's implementation") end
	if type then assert.type(type, "string", "interface definition") end
	if key then assert.type(key, "string", "servant's key") end
	return assert.results(ServerBroker.broker:object(impl, key, type))
end

--------------------------------------------------------------------------------
-- Deactivates a servant by removing its implementation from the object map.
--
-- If 'object' is a servant (i.e. the object returned by 'newservant') then it
-- is deactivated.
-- Alternatively, the 'object' parameter may be the servant's object key.
-- Only in the case that the servant was created with an implicitly created key
-- by the ORB then the 'object' can be the servant's implementation.
-- Since a single implementation object can be used to create many servants with
-- different interface, in this case the 'type' parameter must be provided with
-- the exact servant's interface.
--
-- @param object string|object Servant's object key, servant's implementation or
-- servant itself.
-- @param type string Identification of the servant's interface (e.g. repository
-- ID or absolute name).
--
-- @usage oil.deactivate(oil.newservant(impl, "::MyInterface", "objkey"))      .
-- @usage oil.deactivate("objkey")                                             .
-- @usage oil.deactivate(impl, "MyInterface")                                  .
--
function deactivate(object, type)
	if not object then
		assert.illegal(object,
			"object reference (servant, implementation or object key expected)")
	end
	return ServerBroker.broker:remove(object, type)
end

--------------------------------------------------------------------------------
-- Returns textual information that identifies the servant.
--
-- This function is used to get textual information that references a servant
-- or proxy like an IOR (Inter-operable Object Reference).
--
-- @param servant object Servant which textual referecence must be taken.
--
-- @return string Textual referecence to the servant.
--
-- @usage oil.writeto("ref.ior", oil.tostring(oil.newservant(impl, "::Hello"))).
--
function tostring(object)
	assert.type(object, "table", "servant object")
	return assert.results(ServerBroker.broker:tostring(object))
end

--------------------------------------------------------------------------------
-- Default configuration for creation of the default ORB instance.
--
-- The configuration values may differ accordingly to the underlying protocol.
-- For Internet IOP (IIOP) protocol the current options are the host name or IP
-- address and port that ORB must bind to, as well as the host name or IP
-- address and port that must be used in creation of object references.
--
-- @field tag number Tag of the IOP protocol the ORB shall use. The default is
-- 0, that indicates the Internet IOP (IIOP).
-- @field host string Host name or IP address. If none is provided the ORB binds
-- to all current net interfaces.
-- @field port number Port the ORB must listen. If none is provided, the ORB
-- tries to bind to a port in the range [2809; 9999].
-- @field refhost string Host name or IP address informed in object references.
-- @field refport number Port informed in object references.
--
-- @usage oil.Config.host = "middleware.inf.puc-rio.br"                        .
-- @usage oil.Config.host = "10.223.10.56"                                     .
-- @usage oil.Config.port = 8080                                               .
-- @usage oil.Config = {host = "10.223.10.56", port = 8080 }                   .
--
-- @see init
--
Config = {}

--------------------------------------------------------------------------------
-- Initialize the OiL main ORB.
--
-- Initialize the default ORB instance with the provided configurations like
-- described in 'Config'.
-- If the default ORB already is created then this instance is returned.
-- This default ORB is used by all objects and proxies created by newservant and
-- newproxy functions.
--
-- @param config table Configuration used to create the default ORB instance.
-- @return table Configuration values actually used by the ORB instance.
--
-- @usage oil.init()                                                           .
-- @usage oil.init{ host = "middleware.inf.puc-rio.br" }                       .
-- @usage oil.init{ host = "10.223.10.56", port = 8080 }                       .
--
-- @see Config
--
function init(config)
	config, Config = config or Config, nil
	assert.type(config, "table", "ORB configuration")
	return assert.results(ServerBroker.broker:initialize(config))
end

--------------------------------------------------------------------------------
-- Checks whether there is some request pending
--
-- Function used to checks whether there is some unprocessed ORB request
-- pending.
-- It returns true if there is some request pending that must be processed by
-- the main ORB or false otherwise.
--
-- @return boolean True if there is some ORB request pending or false otherwise.
--
-- @usage while oil.pending() do oil.step() end                                .
--
function pending()
	return assert.results(ServerBroker.broker:pending())
end

--------------------------------------------------------------------------------
-- Waits for an ORB request and process it.
--
-- Function used to wait for an ORB request and process it.
-- Only one single ORB request is processed at each call.
-- It returns true if no exception is raised during request processing, or 'nil'
-- and the raised exception otherwise.
--
-- @usage while oil.pending() do oil.step() end                                .
--
function step()
	return assert.results(ServerBroker.broker:step())
end

--------------------------------------------------------------------------------
-- Runs the ORB main loop.
--
-- Function used to process all remote requisitions continuously until some
-- exception is raised.
-- If an exception is raised during the processing of requests this function
-- returns nil and the raised exception.
-- This function implicitly initiates the ORB if it was not initialized yet.
--
-- @see init
--
function run()
	if Config then init(Config) end
	return assert.results(ServerBroker.broker:run())
end

--------------------------------------------------------------------------------
-- Shuts down the ORB.
--
-- Stops the ORB main loop if it is executing, handles all pending requests and
-- closes all connections.
--
-- @usage oil.shutdown()
--
function shutdown()
	return assert.results(ServerBroker.broker:shutdown())
end

--------------------------------------------------------------------------------
-- Internal coroutine scheduler used by OiL.
--
-- This is a alias for a facet of the Task Manager component of the internal
-- architecture.
-- If the current assembly does not provide this component, this field is 'nil'.
-- It provides the same API of the 'loop.thread.Scheduler' class.
--
-- @usage thread = oil.tasks:current()
-- @usage oil.tasks:suspend()
-- @usage oil.tasks:resume(thread)
--
tasks = BasicSystem and BasicSystem.tasks

--------------------------------------------------------------------------------
-- Function that must be used to perform protected calls in applications.
--
-- It is a 'coroutine-safe' version of the 'pcall' function of the Lua standard
-- library.
--
-- @param func function Function to be executed in protected mode.
-- @param ... any Additional parameters passed to protected function.
--
-- @param success boolean 'true' if function execution did not raised any errors
-- or 'false' otherwise.
-- @param ... any Values returned by the function or an the error raised by the
-- function.
--
pcall = tasks and tasks:getpcall() or luapcall

--------------------------------------------------------------------------------
-- Function executes the main function of the application.
--
-- The application's main function is executed in a new thread if the current
-- assembly provides thread support.
-- This may only return when the application terminates.
--
-- @param main function Appplication's main function.
--
-- @usage oil.main(oil.run)
-- @usage oil.main(function() print(oil.tostring(oil.getLIR())) oil.run() end)
--
function main(main, ...)
	assert.type(main, "function", "main function")
	if tasks then
		assert.results(tasks:register(coroutine.create(main), tasks.currentkey))
		return BasicSystem.control:run(...)
	else
		return main(...)
	end
end

--------------------------------------------------------------------------------
-- Creates and starts the execution of a new the thread.
--
-- Creates a new thread to execute the function 'func' with the extra parameters
-- provided.
-- This function imediately starts the execution of the new thread and the
-- original thread is only resumed again acordingly to the the scheduler's
-- internal policy.
-- This function can only be invocated from others threads, including the one
-- executing the application's main function (see 'main').
--
-- @param func function Function that the new thread will execute.
-- @param ... any Additional parameters passed to the 'func' function.
--
-- @usage oil.main(function() oil.newthread(oil.run) oil.newproxy(oil.readfrom("ior")):register(localobj) end)
--
-- @see main
--
function newthread(func, ...)
	assert.type(func, "function", "thread body")
	return BasicSystem.tasks:start(func, ...)
end

--------------------------------------------------------------------------------
-- Suspends the execution of the current thread for some time.
--
-- @param time number Delay in seconds that the execution must be resumed.
--
-- @usage oil.sleep(5.5)
--
function sleep(time)
	assert.type(time, "number", "time")
	return BasicSystem.sockets:sleep(time)
end

--------------------------------------------------------------------------------
-- Get the current system time.
--
-- @return number Number of seconds since a fixed point in the past.
--
-- @usage local start = oil.time(); oil.sleep(3); print("I slept for", oil.time() - start)
--
function time()
	return BasicSystem.sockets:gettime()
end

--------------------------------------------------------------------------------
-- Creates a new value encoder that marshal values into strings.
--
-- The encoder marshals values in a CORBA's CDR encapsulated stream, i.e.
-- includes an indication of the endianess used in value codification.
--
-- @return object Value encoder that provides operation 'put(value, [type])' to
-- marshal values and operation 'getdata()' to get the marshaled stream.
--
-- @usage encoder = oil.newencoder(); encoder:put({1,2,3}, oil.corba.idl.sequence{oil.corba.idl.long})
-- @usage encoder = oil.newencoder(); encoder:put({1,2,3}, oil.types:lookup("MyLongSeq"))
--
function newencoder()
	return assert.results(ValueEncoder.codec:encoder(true))
end

--------------------------------------------------------------------------------
-- Creates a new value decoder that extracts marshaled values from strings.
--
-- The decoder reads CORBA's CDR encapsulated streams, i.e. includes an
-- indication of the endianess used in value codification.
--
-- @param stream string String containing a stream with marshaled values.
--
-- @return object Value decoder that provides operation 'get([type])' to
-- unmarshal values from a marshaled stream.
--
-- @usage decoder = oil.newdecoder(stream); val = decoder:get(oil.corba.idl.sequence{oil.corba.idl.long})
-- @usage decoder = oil.newdecoder(stream); val = decoder:get(oil.types:lookup("MyLongSeq"))
--
function newdecoder(stream)
	assert.type(stream, "string", "byte stream")
	return assert.results(ValueEncoder.codec:decoder(stream, true))
end

--------------------------------------------------------------------------------
-- Creates a new exception object with the given body.
--
-- The 'body' must contain the values of the exceptions fields and must also
-- contain the exception identification in index 1 (in CORBA this
-- identification is a repID).
--
-- @param body table Exception body with all its field values and exception ID.
--
-- @return object Exception that provides meta-method '__tostring' that provides
-- a pretty-printing.
--
-- @usage error(oil.newexcept{ "IDL:omg.org.CORBA/INTERNAL:1.0", minor_code_value = 2 })
--
function newexcept(body)
	assert.type(body, "table", "exception body")
	local except = assert.results(TypeRepository.types:resolve(body[1]))
	assert.type(except, "idl except", "referenced exception type")
	body[1] = except.repID
	return assert.Exception(body)
end

--------------------------------------------------------------------------------
-- Defines a exception handling function for proxies.
--
-- The handling function receives the following parameters:
--   proxy    : object proxy that perfomed the operation.
--   exception: exception/error raised.
--   operation: descriptor of the operation that raised the exception.
-- If the parameter 'type' is provided, then the exception handling function
-- will be applied only to proxies of that type (i.e. interface).
-- Exception handling functions are nor cumulative.
-- For example, is the is an exception handling function defined for all proxies
-- and other only for proxies of a given type, then the later will be used for
-- proxies of that given type.
-- Additionally, exceptions handlers are not inherited through interface
-- hierarchies.
--
-- @param handler function Exception handling function.
-- @param type string Interface ID of a group of proxies (e.g. repID).
--
-- @usage oil.setexcatch(function(_, except) error(tostring(except)) end)
--
function setexcatch(handler, type)
	assert.results(ClientBroker.broker:excepthandler(handler, type))
end

--------------------------------------------------------------------------------
-- This feature is disabled by default.
-- To enable this feature use the following command before requiring the 'oil'
-- package for the first time.
--
--   package.loaded["oil.component"] = require "loop.component.wrapped"
--   package.loaded["oil.port"] = require "loop.component.intercepted"
--
local port       = require "oil.port"
local ClientSide = require "oil.corba.interceptors.ClientSide"
local ServerSide = require "oil.corba.interceptors.ServerSide"

--------------------------------------------------------------------------------
-- Sets a CORBA-specific interceptor for operation invocations in the client-size.
--
-- The interceptor must provide the following operations
--
--  send_request(request): 'request' structure is described below.
--    response_expected: [boolean] (read-only)
--    object_key: [string] (read-only)
--    operation: [string] (read-only) Operation name.
--    service_context: [table] Set this value to define a service context
--      values. See 'ServiceContextList' in CORBA specs.
--    success: [boolean] set this value to cancel invocation:
--      true ==> invocation successfull
--      false ==> invocation raised an exception
--    Note: The integer indexes store the operation's parameter values and
--    should also be used to store the results values if the request is canceled
--    (see note below).
--
--  receive_reply(reply): 'reply' structure is described below.
--    service_context: [table] (read-only) See 'ServiceContextList' in CORBA
--      specs.
--    reply_status: [string] (read-only)
--    success: [boolean] Identifies the kind of result:
--      true ==> invocation successfull
--      false ==> invocation raised an exception
--    Note: The integer indexes store the results that will be sent as request
--    result. For successful invocations these values must be the operation's
--    results (return, out and inout parameters) in the same order they appear
--    in the IDL description. For failed invocations, index 1 must be the
--    exception that identifies the failure.
--
-- The 'request' and 'reply' are the same table in a single invocation.
-- Therefore, the fields of 'request' are also available in 'reply' except for
-- those defined in the description of 'reply'.
--
function setclientinterceptor(iceptor)
	if iceptor then
		iceptor = ClientSide{ interceptor = iceptor }
	end
	local port = require "loop.component.intercepted"
	port.intercept(OperationRequester, "requests", "method", iceptor)
	port.intercept(OperationRequester, "messenger", "method", iceptor)
end

--------------------------------------------------------------------------------
-- Sets a CORBA-specific interceptor for operation invocations in the server-size.
--
-- The interceptor must provide the following operations
--
--  receive_request(request): 'request' structure is described below.
--    service_context: [table] (read-only) See 'ServiceContextList' in CORBA
--      specs.
--    request_id: [number] (read-only)
--    response_expected: [boolean] (read-only)
--    object_key: [string] (read-only)
--    operation: [string] (read-only) Operation name.
--    servant: [object] (read-only) Local object the invocation will be dispatched to.
--    method: [function] (read-only) Function that will be invoked on object 'servant'.
--    success: [boolean] Set this value to cancel invocation:
--      true ==> invocation successfull
--      false ==> invocation raised an exception
--    Note: The integer indexes store the operation's parameter values and
--    should also be used to store the results values if the request is canceled
--    (see note below).
--
--  send_reply(reply): 'reply' structure is described below.
--    service_context: [table] Set this value to define a service context
--      values. See 'ServiceContextList' in CORBA specs.
--    success: [boolean] identifies the kind of result:
--      true ==> invocation successfull
--      false ==> invocation raised an exception
--    Note: The integer indexes store the results that will be sent as request
--    result. For successful invocations these values must be the operation's
--    results (return, out and inout parameters) in the same order they appear
--    in the IDL description. For failed invocations, index 1 must be the
--    exception that identifies the failure.
--
-- The 'request' and 'reply' are the same table in a single invocation.
-- Therefore, the fields of 'request' are also available in 'reply' except for
-- those defined in the description of 'reply'.
--
function setserverinterceptor(iceptor)
	if iceptor then
		iceptor = ServerSide{ interceptor = iceptor }
	end
	local port = require "loop.component.intercepted"
	port.intercept(RequestListener, "messenger", "method", iceptor)
	port.intercept(RequestDispatcher, "dispatcher", "method", iceptor)
end

--------------------------------------------------------------------------------
-- Alias of 'newservant' function.
--
-- For compatibility with old OiL applications.
--
-- @see newservant
--
newobject = newservant

--------------------------------------------------------------------------------
-- Alias of 'newservant' function.
--
-- For compatibility with LuaOrb applications.
--
-- @see newservant
--
createservant = newservant

--------------------------------------------------------------------------------
-- Alias of 'newproxy' function.
--
-- For compatibility with LuaOrb applications.
--
-- @see newproxy
--
createproxy = newproxy

--------------------------------------------------------------------------------
-- Writes a text into file.
--
-- Utility function for writing stringfied IORs into a file.
--
function writeto(filepath, text)
	local result, errmsg = io.open(filepath, "w")
	if result then
		local file = result
		result, errmsg = file:write(text)
		file:close()
	end
	return result, errmsg
end

--------------------------------------------------------------------------------
-- Read the contents of a file.
--
-- Utility function for reading stringfied IORs from a file.
--
function readfrom(filepath)
	local result, errmsg = io.open(filepath)
	if result then
		local file = result
		result, errmsg = file:read("*a")
		file:close()
	end
	return result, errmsg
end

--------------------------------------------------------------------------------
-- Creates a file with the IOR of an object.
--
-- For compatibility with older versions of OiL.
--
function writeIOR(object, file)
	return writeto(file, tostring(object))
end

--------------------------------------------------------------------------------
-- Alias of 'readfrom' function.
--
-- For compatibility with older versions of OiL.

readIOR = readfrom

--------------------------------------------------------------------------------
return _M