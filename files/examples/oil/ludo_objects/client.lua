require "oil"

oil.main(function()
	local broker = oil.init{flavor="ludo;cooperative;base"}
	oil.newthread(broker.run, broker)
	
	local Hello = {}
	function Hello:say(who)
		print(string.format("Hello, %s!", tostring(who)))
	end
	
	local Invoker = broker:newproxy(oil.readfrom("ref.ludo"))
	local proxy = broker:newproxy(
	              	broker:tostring(
	              		broker:newservant(Hello)))
	
	Invoker:invoke(Hello, "say", "there") -- message appear remotely
	Invoker:invoke(proxy, "say", "here") -- message appear locally
	
	broker:shutdown()
end)