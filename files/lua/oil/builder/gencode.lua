local require = require
local builder = require "oil.builder"
local arch    = require "oil.arch.corba"

module "oil.builder.gencode"

ValueEncoder = arch.ValueEncoder{require "oil.corba.giop.CodecGen"  }

function create(comps)
	return builder.create(_M, comps)
end
