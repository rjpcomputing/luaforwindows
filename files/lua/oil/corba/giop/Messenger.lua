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
-- Title  : Client-side CORBA GIOP Protocol                                   --
-- Authors: Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   See section 15.4.1 of CORBA 3.0 specification.                           --
--------------------------------------------------------------------------------
-- messenger:Facet
-- 	success:booelan, [except:table] = sendmsg(channel:object, type:number, header:table, types:table, values...)
-- 	type:number, header:table, decoder:object = receivemsg(channel:object , [wait:boolean])
-- 
-- codec:Receptacle
-- 	encoder:object encoder()
-- 	decoder:object decoder(stream:string)
--------------------------------------------------------------------------------

local ipairs = ipairs
local select = select                                                           --[[VERBOSE]] local type = type

local oo        = require "oil.oo"
local bit       = require "oil.bit"
local giop      = require "oil.corba.giop"
local Exception = require "oil.corba.giop.Exception"                            --[[VERBOSE]] local verbose = require "oil.verbose"

module("oil.corba.giop.Messenger", oo.class)

context = false

--------------------------------------------------------------------------------

magictag    = giop.MagicTag
headersize  = giop.HeaderSize
headertype  = giop.Header_v1_[0]
messagetype = giop.MessageHeader_v1_[0]

header = {
	magic        = magictag,
	GIOP_version = {major=1, minor=0},
	byte_order   = (bit.endianess() == "little"),
	message_type = nil, -- defined later
	message_size = nil, -- defined later
}

--------------------------------------------------------------------------------

function sendmsg(self, channel, type, message, types, ...)                      --[[VERBOSE]] verbose:message(true, "send message ",type)
	--
	-- Create GIOP message body
	--
	local encoder = self.context.codec:encoder()
	encoder:shift(self.headersize) -- alignment accordingly to GIOP header size
	if message then
		encoder:put(message, self.messagetype[type])
	end
	if types then
		for index, type in ipairs(types) do
			encoder:put(select(index, ...), type)
		end
	end
	local stream = encoder:getdata()
	
	--
	-- Create GIOP message header
	--
	local header = self.header
	header.message_size = #stream
	header.message_type = type
	encoder = self.context.codec:encoder()
	encoder:struct(header, self.headertype)
	stream = encoder:getdata()..stream

	--
	-- Send stream over the channel
	--
	local success, except, reset
	repeat
		success, except = channel:send(stream)
		if not success then
			if except == "closed" then
				if reset == nil and channel.reset and channel:reset() then
					-- only clients have 'reset' op.
					reset, success, except = true, nil, nil 
				else
					channel:close()
				end
			end
		end
	until success or except
	if except then
		except = Exception{ "COMM_FAILURE", minor_code_value = 0,
			message = "unable to write into connection",
			reason = except,
			connection = channel,
		}
	end                                                                           --[[VERBOSE]] verbose:message(false)
	
	return success, except
end

--------------------------------------------------------------------------------

function receivemsg(self, channel)                                              --[[VERBOSE]] verbose:message(true, "receive message")
	local success, except = channel:receive(self.headersize)
	if success then
		local decoder = self.context.codec:decoder(success)
		--
		-- Read GIOP message header
			--
		local header = self.headertype
		local magic = decoder:array(header[1].type)
		if magic == self.magictag then
			local version = decoder:struct(header[2].type)
			if version.major == 1 and version.minor == 0 then
				decoder:order(decoder:boolean())
				local type = decoder:octet()
				local size = decoder:ulong()
				--
				-- Read GIOP message body
				--
				success, except = channel:receive(size)
				if success then
					decoder:append(success)
					success = type
					header = self.messagetype[type]
					if header then
						except = decoder:struct(header)
						channel = decoder
					elseif header == nil then
						success = nil
						except = Exception{ "INTERNAL", minor_code_value = 0,
							message = "GIOP 1.0 message type not supported",
							reason = "messageid",
							major = version.major,
							minor = version.minor,
							type = type,
						}
					end
				else
					if except == "closed" then channel:close() end
					except = Exception{ "COMM_FAILURE", minor_code_value = 0,
						message = "unable to read from connection",
						reason = except,
						connection = channel,
					}
				end
			else
				success = nil
				except = Exception{ "INTERNAL", minor_code_value = 0,
					message = "GIOP version not supported",
					reason = "version",
					procotol = "GIOP",
					version = version,
				}
			end
		else
			success = nil
			except = Exception{ "MARSHALL", minor_code_value = 8,
				message = "illegal GIOP message magic tag",
				reason = "magictag",
				tag = magic,
			}
		end
	else
		if except == "closed" then channel:close() end
		except = Exception{ "COMM_FAILURE", minor_code_value = 0,
			message = "unable to read from connection",
			reason = except,
			connection = channel,
		}
	end                                                                           --[[VERBOSE]] verbose:message(false, "got message ",success)
	return success, except, channel
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[VERBOSE]] function verbose.custom:message(...)
--[[VERBOSE]] 	local viewer = self.viewer
--[[VERBOSE]] 	local output = viewer.output
--[[VERBOSE]] 	for i = 1, select("#", ...) do
--[[VERBOSE]] 		local value = select(i, ...)
--[[VERBOSE]] 		if giop.MessageType[value] then
--[[VERBOSE]] 			output:write(giop.MessageType[value])
--[[VERBOSE]] 		elseif type(value) == "string" then
--[[VERBOSE]] 			output:write(value)
--[[VERBOSE]] 		else
--[[VERBOSE]] 			viewer:write(value)
--[[VERBOSE]] 		end
--[[VERBOSE]] 	end
--[[VERBOSE]] end
