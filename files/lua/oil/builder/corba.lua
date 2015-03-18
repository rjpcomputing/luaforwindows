local require = require
local builder = require "oil.builder"
local base    = require "oil.arch.base"
local arch    = require "oil.arch.corba"

module "oil.builder.corba"

ValueEncoder       = arch.ValueEncoder      {require "oil.corba.giop.Codec"     }
ObjectReferrer     = arch.ObjectReferrer    {require "oil.corba.giop.Referrer"  }
IIOPProfiler       = arch.ReferenceProfiler {require "oil.corba.iiop.Profiler"  }
OperationRequester = arch.OperationRequester{require "oil.corba.giop.Requester" }
MessageMarshaler   = arch.MessageMarshaler  {require "oil.corba.giop.Messenger" }
ProxyIndexer       = arch.ProxyIndexer      {require "oil.corba.giop.ProxyOps"  }
RequestListener    = arch.RequestListener   {require "oil.corba.giop.Listener"  }
ServantIndexer     = arch.ServantIndexer    {require "oil.corba.giop.ServantOps"}
TypeRepository = arch.TypeRepository{
	registry = require "oil.corba.idl.Registry",
	indexer  = require "oil.corba.idl.Indexer",
	compiler = require "oil.corba.idl.Compiler",
	types    = require "oil.corba.idl.Importer",
}

-- Avoid using a typed request dispatcher because the GIOP protocol already
-- does type checks prior to decode marshaled values in invocation requests.
RequestDispatcher = base.RequestDispatcher{require "oil.kernel.base.Dispatcher"}

function create(comps)
	return builder.create(_M, comps)
end
