--require 'pl'
require 'pl.strict'
local utils = require 'pl.utils'
utils.printf("that's fine!\n")
local res,err = pcall(function()
   print(x)
   print 'ok?'
end)
assert(err,"variable 'x' is not declared")

