--------------------------------------------------------------------------------
------------------------------  #####      ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------ ##   ## ##  ##     ------------------------------
------------------------------ ##   ##  #  ##     ------------------------------
------------------------------  #####  ### ###### ------------------------------
--------------------------------                --------------------------------
----------------------- An Object Request Broker in Lua ------------------------
--------------------------------------------------------------------------------
-- Project: OiL - ORB in Lua                                                  --
-- Release: 0.4                                                               --
-- Title  : Client-side LuDO Protocol                                         --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- requests:Facet
-- 	channel:object getchannel(reference:table)
-- 	reply:object, [except:table], [requests:table] newrequest(channel:object, reference:table, operation:table, args...)
-- 	reply:object, [except:table], [requests:table] getreply(channel:object, [probe:boolean])
-- 
-- codec:Receptacle
-- 	encoder:object encoder()
-- 	decoder:object decoder(stream:string)
-- 
-- channels:Receptacle
-- 	channel:object retieve(configs:table)
--------------------------------------------------------------------------------

local select  = select

local oo = require "oil.oo"                                                     --[[VERBOSE]] local verbose = require "oil.verbose"

module "oil.ludo.Requester"

oo.class(_M, Messenger)

context = false

--------------------------------------------------------------------------------

function getchannel(self, reference)
	return self.context.channels:retrieve(reference)
end

--------------------------------------------------------------------------------

function newrequest(self, channel, reference, operation, ...)
	local encoder = self.context.codec:encoder()
	local requestid = #channel+1
	encoder:put(requestid, reference.object, operation, ...)
	local result, except = channel:send(encoder:__tostring():gsub("\n","%z").."\n")
	if result then
		result = {}
		channel[requestid] = result
	else
		if except == "closed" then channel:close() end
	end
	return result, except
end

--------------------------------------------------------------------------------

local function update(channel, requestid, success, ...)
	local request, except = channel[requestid]
	if request then
		channel[requestid] = nil
		request.success = success
		request.resultcount = select("#", ...)
		for i = 1, request.resultcount do
			request[i] = select(i, ...)
		end
	else
		except = "unexpected reply"
	end
	return request, except
end

function getreply(self, channel, probe)
	if probe and not channel:probe() then
		return true
	end
	local result, errmsg = channel:receive()
	if result then
		local decoder = self.context.codec:decoder(result:gsub("%z", "\n"))
		result, errmsg = update(channel, decoder:get())
	end
	return result, errmsg, errmsg and channel
end
