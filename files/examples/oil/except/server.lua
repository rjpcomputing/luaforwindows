local Server = { data = { a_number = 1234 } }

function Server:read(tag)
	local value = Server.data[tag]
	if value == nil then
		error(orb:newexcept{"Control::AccessError",
			tagname=tag,
			reason="unknown tag name",
		})
	end
	return value
end

function Server:write(tag, value)
	local old = Server.data[tag]
	if type(old) ~= type(value) then
		error(orb:newexcept{"Control::AccessError",
			tagname=tag,
			reason="invalid value for tag",
		})
	end
	Server.data[tag] = value
end

require "oil"

oil.main(function()
	orb = oil.init()
	orb:loadidlfile("control.idl")
	oil.writeto("ref.ior",
		orb:tostring(
			orb:newservant(Server, nil, "Control::Server")))
	orb:run()
end)
