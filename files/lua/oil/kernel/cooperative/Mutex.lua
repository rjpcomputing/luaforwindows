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
-- Release: 0.4                                                               --
-- Title  : Remote Object Invoker                                             --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- invoker:Facet
-- 	[results:object], [except:table] invoke(reference, operation, args...)
-- 
-- requester:Receptacle
-- 	channel:object getchannel(reference)
-- 	[request:table], [except:table], [requests:table] request(channel:object, reference, operation, args...)
-- 	[request:table], [except:table], [requests:table] getreply(channel:object, [probe:boolean])
-- 
-- mutex:Facet
-- 	locksend(channel:object)
-- 	freesend(channel:object)
-- 	lockreceive(channel:object, request:table, [probe:boolean])
-- 	freereceive(channel:object)
-- 
-- tasks:Receptacle
-- 	current:thread
-- 	suspend()
-- 	resume(thread:thread)
-- 	register(thread:thread)
--------------------------------------------------------------------------------

local ipairs = ipairs
local next   = next
local select = select

local ObjectCache = require "loop.collection.ObjectCache"
local OrderedSet  = require "loop.collection.OrderedSet"

local oo = require "oil.oo"                                                     --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.kernel.cooperative.Mutex", oo.class)

context = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function newlock()
	return { senders = OrderedSet(), receivers = {} }
end

function __init(self, object)
	self = oo.rawnew(self, object)
	self.locks = ObjectCache{ retrieve = newlock }
	return self
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function locksend(self, channel)
	local lock = self.locks[channel]
	if lock.sending then                                                          --[[VERBOSE]] verbose:mutex(true, "channel being used, waiting notification")
		local tasks = self.context.tasks
		lock.senders:enqueue(tasks.current)
		repeat until tasks:suspend() == channel                                     --[[VERBOSE]] verbose:mutex(false, "notification received")
	else                                                                          --[[VERBOSE]] verbose:mutex "channel free for sending"
		lock.sending = true
	end
end

function freesend(self, channel)
	local lock = self.locks[channel]
	if lock.senders:empty() then
		lock.sending = false                                                        --[[VERBOSE]] verbose:mutex "releasing send lock"
	else                                                                          --[[VERBOSE]] verbose:mutex "resuming sending thread"
		self.context.tasks:resume(lock.senders:dequeue(), channel)
	end
end

function lockreceive(self, channel, key)
	local tasks = self.context.tasks
	local lock = self.locks[channel]
	if not lock.receiving then                                                    --[[VERBOSE]] verbose:mutex "channel free for receiving"
		lock.receiving = tasks.current
	elseif lock.receiving ~= tasks.current then                                   --[[VERBOSE]] verbose:mutex(true, "channel being used, waiting notification")
		key = key or #lock.receivers+1
		lock.receivers[key] = tasks.current
		repeat until tasks:suspend() == channel                                     --[[VERBOSE]] verbose:mutex(false, "notification received")
		lock.receivers[key] = nil
	end
	return lock.receiving == tasks.current
end

function notifyreceived(self, channel, key)
	local thread = self.locks[channel].receivers[key]
	if thread then
		return self.context.tasks:resume(thread, channel)
	end
end

function freereceive(self, channel)
	local tasks = self.context.tasks
	local lock = self.locks[channel]
	local thread = select(2, next(lock.receivers))
	if thread then                                                                --[[VERBOSE]] verbose:mutex "resuming receiving thread"
		lock.receiving = thread
		tasks:resume(thread, channel)
	else                                                                          --[[VERBOSE]] verbose:mutex "releasing receive lock"
		lock.receiving = false
	end
end
