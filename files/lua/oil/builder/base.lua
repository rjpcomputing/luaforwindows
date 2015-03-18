local require = require
local builder = require "oil.builder"
local arch    = require "oil.arch.base"

module "oil.builder.base"

BasicSystem       = arch.BasicSystem      {require "oil.kernel.base.Sockets"   }
ClientChannels    = arch.SocketChannels   {require "oil.kernel.base.Connector" }
ClientBroker      = arch.ClientBroker     {require "oil.kernel.base.Client"    }
ObjectProxies     = arch.ObjectProxies    {require "oil.kernel.base.Proxies"   }
OperationInvoker  = arch.OperationInvoker {require "oil.kernel.base.Invoker"   }
ServerChannels    = arch.SocketChannels   {require "oil.kernel.base.Acceptor"  }
ServerBroker      = arch.ServerBroker     {require "oil.kernel.base.Server"    }
RequestDispatcher = arch.RequestDispatcher{require "oil.kernel.base.Dispatcher"}
RequestReceiver   = arch.RequestReceiver  {require "oil.kernel.base.Receiver"  }

function create(comps)
	return builder.create(_M, comps)
end
