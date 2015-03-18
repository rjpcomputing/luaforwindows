local require = require
local builder = require "oil.builder"
local arch    = require "oil.arch.typed"

module "oil.builder.typed"

ClientBroker      = arch.ClientBroker     {require "oil.kernel.typed.Client"    }
ObjectProxies     = arch.ObjectProxies    {require "oil.kernel.typed.Proxies"   }
ServerBroker      = arch.ServerBroker     {require "oil.kernel.typed.Server"    }
RequestDispatcher = arch.RequestDispatcher{require "oil.kernel.typed.Dispatcher"}

function create(comps)
	return builder.create(_M, comps)
end
