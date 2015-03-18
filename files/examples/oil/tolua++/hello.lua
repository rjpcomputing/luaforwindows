require "oil"

local orb = oil.init()
orb:loadidlfile "../hello/hello.idl"

local impl = Hello.HelloWorld:new(true)
local hello = orb:newservant(impl, nil, "IDL:Hello:1.0")

oil.writeto("../hello/hello.ior", orb:tostring(hello))

orb:run()
