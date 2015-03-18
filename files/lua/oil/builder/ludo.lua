local require = require
local builder = require "oil.builder"
local arch    = require "oil.arch.ludo"

module "oil.builder.ludo"

ValueEncoder       = arch.ValueEncoder      {require "oil.ludo.Codec"    }
ObjectReferrer     = arch.ObjectReferrer    {require "oil.ludo.Referrer" }
OperationRequester = arch.OperationRequester{require "oil.ludo.Requester"}
RequestListener    = arch.RequestListener   {require "oil.ludo.Listener" }

function create(comps)
	return builder.create(_M, comps)
end
